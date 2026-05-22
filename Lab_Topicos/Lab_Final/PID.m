%% =========================================================================
%  POLYNOMIAL / STATE-SPACE CONTROLLER DESIGN
%  Rack-Pinion Position Control  |  ESP32 + H-bridge + DC Motor
%
%  Plant (Ts = 0.1 s):
%         0.07849 z + 0.06092
%  Gd = -------------------------
%          z^2 - 1.466 z + 0.4661
%
%  Physical system:
%    - Actuator : DC motor via H-bridge, PWM in [-250, 250]
%    - Sensor   : position of rack-pinion, range 0-32 cm
%    - MCU      : ESP32 (Xtensa LX6, 32-bit float, no native FPU)
%    - Ts       : 0.1 s (100 ms)
%
%  Design target: zeta = 0.7, step tracking (zero steady-state error)
%
%  METHOD: Observer Canonical Form (OCF) state-space + integral action.
%    - OCF has y = x1 directly (position is state 1, no observer needed).
%    - x2 is reconstructed exactly from the plant difference equation.
%    - No Luenberger observer required -> simpler, more robust on MCU.
%
%  WHY NOT THE CLASSICAL POLYNOMIAL METHOD:
%    The Diophantine equation A*Ac + B*Bc = Pd with
%    Ac = (1-z^-1)(1+s0*z^-1) yields an ILL-CONDITIONED Sylvester matrix
%    for this plant, and the free parameter s0 may fall outside the unit
%    circle. See Section 1 for diagnosis.
% =========================================================================

clear; close all; clc; format long;

fprintf('=========================================================\n');
fprintf('  RACK-PINION POSITION CONTROLLER DESIGN\n');
fprintf('  Gd = (0.07849z + 0.06092)/(z^2 - 1.466z + 0.4661)\n');
fprintf('  Ts = 0.1 s  |  Target: zeta = 0.7\n');
fprintf('=========================================================\n\n');

%% =========================================================================
%  SECTION 1: PLANT ANALYSIS AND POLYNOMIAL METHOD DIAGNOSIS
%% =========================================================================
Ts = 0.1;

% Plant in z-domain
b_num = [0.07849,  0.06092];
a_den = [1, -1.466, 0.4661];
Gd    = tf(b_num, a_den, Ts);

b1_tf = b_num(1);   % 0.07849
b0_tf = b_num(2);   %  0.06092
a1_tf = a_den(2);   % -1.466
a0_tf = a_den(3);   %  0.4661

plant_poles = roots(a_den);
plant_zeros = roots(b_num);

fprintf('--- PLANT ANALYSIS ---\n');
fprintf('Poles (z):  p1=%.8f  p2=%.8f\n', plant_poles(1), plant_poles(2));
fprintf('Zeros (z):  z1=%.8f\n', plant_zeros(1));
fprintf('Time constants:  tau1=%.4f s   tau2=%.4f s\n', ...
    -Ts/log(plant_poles(1)), -Ts/log(plant_poles(2)));
fprintf('DC gain B(1)/A(1) = %.6f/%.6f = %.4f\n\n', ...
    sum(b_num), sum(a_den), sum(b_num)/sum(a_den));

fprintf('--- POLYNOMIAL METHOD DIAGNOSIS ---\n');
% Diophantine: A*Ac + B*Bc = Pd with Ac=(1-z^-1)(1+s0*z^-1), Bc=r0+r1*z^-1+r2*z^-2
b1 = b1_tf; b2 = b0_tf; a1 = a1_tf; a2 = a0_tf;

% Desired polynomial for demonstration (zeta=0.7, wn=4 rad/s, alpha=0.2 aux)
zeta_demo = 0.7; wn_demo = 4; alpha = 0.2;
p_d = exp((-zeta_demo*wn_demo + 1j*wn_demo*sqrt(1-zeta_demo^2))*Ts);
Pd  = conv([1, -2*real(p_d), abs(p_d)^2], [1, -2*alpha, alpha^2]);

M_poly = [b1,  0,   0,   1;
           b2,  b1,  0,   (a1-1);
            0,  b2,  b1,  (a2-a1);
            0,   0,  b2,  (-a2)  ];
rhs_poly = [Pd(2)-a1+1; Pd(3)-a2+a1; Pd(4)+a2; Pd(5)];
cond_M   = cond(M_poly);
sol_poly = M_poly \ rhs_poly;
s0_val   = sol_poly(4);

fprintf('Sylvester matrix condition number: %.0f\n', cond_M);
fprintf('Solution s0 = %.4f  (controller pole at z = %.4f)\n', s0_val, -s0_val);
if s0_val < 0
    fprintf('--> s0 < 0: controller pole OUTSIDE unit circle (unstable).\n');
    fprintf('--> Polynomial method with this Ac structure is INCOMPATIBLE\n');
    fprintf('    with this plant. Using OCF state-space instead.\n\n');
else
    fprintf('--> s0 >= 0: polynomial method may work, but OCF is used for robustness.\n\n');
end

%% =========================================================================
%  SECTION 2: OBSERVER CANONICAL FORM (OCF) STATE-SPACE
%% =========================================================================
fprintf('--- OBSERVER CANONICAL FORM (OCF) ---\n\n');

% OCF for Gd = (b1*z + b0)/(z^2 + a1*z + a0):
%   x1[k+1] = -a1*x1[k] + x2[k] + b1*u[k]
%   x2[k+1] = -a0*x1[k]         + b0*u[k]
%   y[k]    =  x1[k]
%
% KEY PROPERTY: y = x1 is directly MEASURED (position sensor).
%               x2 can be computed EXACTLY from y and u (no observer needed).
%               x2[k+1] = -a0 * y[k] + b0 * u[k]

A_ocf = [-a1_tf, 1; -a0_tf, 0];   % [[1.466, 1],[-0.4661, 0]]
B_ocf = [b1_tf; b0_tf];            % [0.07849; 0.06092]
C_ocf = [1, 0];                     % y = x1

fprintf('A_ocf = [%.6f  %.4f]\n        [%.6f  %.4f]\n', ...
    A_ocf(1,1), A_ocf(1,2), A_ocf(2,1), A_ocf(2,2));
fprintf('B_ocf = [%.8f; %.8f]\n', B_ocf(1), B_ocf(2));
fprintf('C_ocf = [1, 0]  <-- y = x1 (position is state 1!)\n\n');

% Verify TF
Gd_check = tf(ss(A_ocf, B_ocf, C_ocf, 0, Ts));
fprintf('TF verification: numerator   = [');
fprintf('%.6f  ', Gd_check.Numerator{1}); fprintf(']\n');
fprintf('                 denominator = [');
fprintf('%.6f  ', Gd_check.Denominator{1}); fprintf(']\n\n');

% State x2 reconstruction (no observer):
% x2[k+1] = A_ocf(2,1)*y[k] + B_ocf(2)*u[k]
fprintf('x2 reconstruction (exact, open-loop):\n');
fprintf('  x2[k+1] = %.6f * y[k] + %.8f * u[k]\n\n', A_ocf(2,1), B_ocf(2));

%% =========================================================================
%  SECTION 3: AUGMENTED SYSTEM (add integral state xi)
%% =========================================================================
fprintf('--- AUGMENTED SYSTEM [x1, x2, xi] ---\n\n');

% Augment with integral state for zero steady-state error:
%   xi[k+1] = xi[k] + e[k] = xi[k] + r[k] - y[k] = xi[k] - x1[k] + r[k]
%
% Augmented state: [x1; x2; xi]
A_aug = [A_ocf,  zeros(2,1);
        -C_ocf,  1          ];
B_aug = [B_ocf; 0];
B_r   = [0; 0; 1];   % reference enters xi equation

fprintf('A_aug (3x3):\n');
disp(A_aug);

% Check controllability
Wc = [B_aug, A_aug*B_aug, A_aug^2*B_aug];
fprintf('Controllability rank = %d (must be 3)\n\n', rank(Wc));

%% =========================================================================
%  SECTION 4: POLE PLACEMENT - DESIGN PARAMETERS
%% =========================================================================
fprintf('--- POLE PLACEMENT ---\n\n');

% Design parameters (TUNING KNOBS):
% With Ts = 0.1 s, choose wn_d conservatively (wn_d*Ts << 1 for good discretisation)
zeta_d = 0.7;    % damping ratio  [tune: increase to reduce overshoot]
wn_d   = 4;      % natural freq [rad/s]  [tune: wn_d*Ts=0.4, reasonable for Ts=0.1]
%                  Estimated settling time: ~4/(zeta*wn) = ~1.43 s

sigma_d = zeta_d * wn_d;
wd_d    = wn_d * sqrt(1 - zeta_d^2);
p_des   = exp((-sigma_d + 1j*wd_d)*Ts);   % dominant complex pole pair
p3      = exp(-wn_d * Ts);                  % 3rd real pole (integral mode)

fprintf('Desired poles:\n');
fprintf('  p1,p2 = %.8f +/- j%.8f   |p| = %.8f\n', ...
    real(p_des), imag(p_des), abs(p_des));
fprintf('  p3    = %.8f   (real, integrator mode)\n\n', p3);
fprintf('Target performance:\n');
fprintf('  Settling time (~2%%):  %.2f s\n', 4/(zeta_d*wn_d));
fprintf('  Expected overshoot:   ~2%%\n\n');

% Compute control gains via pole placement
K_aug = place(A_aug, B_aug, [p_des, conj(p_des), p3]);
K1 = K_aug(1);
K2 = K_aug(2);
Ki = K_aug(3);

fprintf('Control gains [K1, K2, Ki]:\n');
fprintf('  K1 = %+.10f  (position x1 = y)\n', K1);
fprintf('  K2 = %+.10f  (state x2)\n', K2);
fprintf('  Ki = %+.10f  (integral xi)\n\n', Ki);

% Verify closed-loop poles
A_cl     = A_aug - B_aug * K_aug;
cl_poles = eig(A_cl);
fprintf('Actual closed-loop poles:\n');
for k = 1:length(cl_poles)
    fprintf('  p%d = %+.8f %+.8fj   |p%d| = %.8f\n', ...
        k, real(cl_poles(k)), imag(cl_poles(k)), k, abs(cl_poles(k)));
end
fprintf('All inside unit circle: %s\n\n', mat2str(all(abs(cl_poles) < 1)));

%% =========================================================================
%  SECTION 5: PHYSICAL UNIT SCALING
%% =========================================================================
fprintf('--- PHYSICAL UNIT SCALING ---\n\n');
fprintf('IMPORTANT: The model Gd was identified with normalized data in ident.\n');
fprintf('You must verify which normalization was applied.\n\n');

K_dc = sum(b_num) / sum(a_den);
fprintf('Identified model DC gain = %.4f\n\n', K_dc);

fprintf('CASE A -- ident used raw data (no normalization):\n');
fprintf('  Input u  : PWM values as-is\n');
fprintf('  Output y : position in its raw sensor unit\n');
fprintf('  --> Controller output u is directly in PWM units.\n');
fprintf('  --> Saturation: clip u to [-250, 250].\n\n');

fprintf('CASE B -- ident normalized both channels to [0,1]:\n');
fprintf('  u_norm in [0,1] -> u_pwm = u_norm * 500 - 250\n');
fprintf('  y_norm in [0,1] -> pos_m = y_norm * 0.32\n');
fprintf('  r_norm = target_pos_m / 0.32\n\n');

fprintf('VERIFY IN MATLAB:\n');
fprintf('  >> m.InputOffset   %%%% and InputNormalization\n');
fprintf('  >> m.OutputOffset  %%%% and OutputNormalization\n');
fprintf('  If both are 0 with scale 1: CASE A applies.\n\n');

U_PWM_MAX =  250;
U_PWM_MIN = -250;
fprintf('Actuator limits: [%d, %d] PWM\n\n', U_PWM_MIN, U_PWM_MAX);

%% =========================================================================
%  SECTION 6: SIMULATION
%% =========================================================================
fprintf('--- SIMULATION (15 seconds, unit step reference) ---\n\n');

N_sim = round(15 / Ts);   % 15 s / 0.1 s = 150 steps
t_sim = (0:N_sim-1) * Ts;

x_plant   = [0; 0];
x2_hat    = 0;
xi        = 0;
y_sim     = zeros(1, N_sim);
u_sim     = zeros(1, N_sim);
u_raw_sim = zeros(1, N_sim);

r_ref = 1.0;   % unit step reference

for k = 1:N_sim
    % 1. Measure output (x1 = y from OCF)
    y_k      = C_ocf * x_plant;
    y_sim(k) = y_k;

    % 2. Compute control signal
    u_raw         = -(K1*y_k + K2*x2_hat + Ki*xi);
    u_raw_sim(k)  = u_raw;
    u_k           = max(U_PWM_MIN, min(U_PWM_MAX, u_raw));
    u_sim(k)      = u_k;

    % 3. Reconstruct x2 (exact, no observer)
    %    x2[k+1] = A_ocf(2,1)*y[k] + B_ocf(2)*u[k]
    x2_hat_new = A_ocf(2,1)*y_k + B_ocf(2)*u_k;

    % 4. Update integral with anti-windup
    if abs(u_raw) <= U_PWM_MAX
        xi = xi + (r_ref - y_k);
    end

    % 5. Advance plant
    x_plant = A_ocf * x_plant + B_ocf * u_k;
    x2_hat  = x2_hat_new;
end

% Performance metrics
y_final    = mean(y_sim(end-20:end));
[y_peak, k_peak] = max(y_sim);
overshoot  = max(0, (y_peak - y_final)/y_final * 100);
idx_rise   = find(y_sim >= 0.9*y_final, 1, 'first');
idx_settle = find(abs(y_sim - y_final) > 0.02*y_final, 1, 'last');
if isempty(idx_settle); idx_settle = 1; end

fprintf('Step response metrics:\n');
fprintf('  Rise time (0->90%%):  %.3f s\n', t_sim(idx_rise));
fprintf('  Peak overshoot:      %.2f %%\n', overshoot);
fprintf('  Settling time (2%%):  %.3f s\n', t_sim(idx_settle));
fprintf('  Steady-state error:  %.2e\n\n', abs(y_final - r_ref));

%% =========================================================================
%  SECTION 7: FIGURES
%% =========================================================================
figure('Name','Rack-Pinion Controller Analysis','Position',[50,50,1400,900]);

% --- Step response ---
subplot(2,3,1);
plot(t_sim, y_sim, 'b-', 'LineWidth', 1.5); hold on;
plot(t_sim, r_ref*ones(size(t_sim)), 'r--', 'LineWidth', 1);
plot(t_sim, 1.02*ones(size(t_sim)), 'g:', 'LineWidth', 1);
plot(t_sim, 0.98*ones(size(t_sim)), 'g:', 'LineWidth', 1);
grid on; xlabel('Time [s]'); ylabel('Position (normalized)');
title(sprintf('Step response  \\zeta=%.1f  \\omega_n=%.0f rad/s', zeta_d, wn_d));
legend('y(t)', 'Reference', '\pm2% band', 'Location', 'SouthEast');
ylim([-0.05, 1.15]);

% --- Control signal ---
subplot(2,3,2);
plot(t_sim, u_sim,     'g-',  'LineWidth', 1.2); hold on;
plot(t_sim, u_raw_sim, 'b--', 'LineWidth', 0.8);
plot(t_sim,  U_PWM_MAX*ones(size(t_sim)), 'r-', 'LineWidth', 0.8);
plot(t_sim,  U_PWM_MIN*ones(size(t_sim)), 'r-', 'LineWidth', 0.8);
grid on; xlabel('Time [s]'); ylabel('PWM');
title('Control signal u');
legend('u (saturated)', 'u (raw)', 'PWM limits', 'Location', 'NorthEast');

% --- Pole-zero map ---
subplot(2,3,3);
theta = linspace(0, 2*pi, 300);
plot(cos(theta), sin(theta), 'k--', 'LineWidth', 0.8); hold on;
plot(real(plant_poles), imag(plant_poles), 'bx', 'MarkerSize', 12, 'LineWidth', 2.5);
plot(real(plant_zeros), imag(plant_zeros), 'bo', 'MarkerSize',  8, 'LineWidth', 2);
plot(real(p_des),       imag(p_des),       'r*', 'MarkerSize', 14, 'LineWidth', 2);
plot(real(conj(p_des)), imag(conj(p_des)), 'r*', 'MarkerSize', 14, 'LineWidth', 2);
plot(real(p3),          0,                 'rs', 'MarkerSize', 10, 'LineWidth', 2);
plot(real(cl_poles),    imag(cl_poles),    'gp', 'MarkerSize', 10, 'LineWidth', 2, ...
    'MarkerFaceColor', 'g');
axis equal; grid on; xlim([-1.3, 1.3]); ylim([-1.3, 1.3]);
legend({'Unit circle','Plant poles','Plant zero','Desired CL','','','Actual CL'}, ...
    'Location','NorthWest','FontSize',8);
title('Pole-zero map');

% --- Effect of different zeta values ---
subplot(2,3,4);
colors = {'b','g','r','m'};
labels = {};
for ii = 1:4
    zeta_t = 0.5 + (ii-1)*0.15;
    sd2 = zeta_t*wn_d; wd2 = wn_d*sqrt(1-zeta_t^2);
    pd2 = exp((-sd2+1j*wd2)*Ts);
    p3t = exp(-wn_d*Ts);
    try
        Kt = place(A_aug, B_aug, [pd2, conj(pd2), p3t]);
        xp2=[0;0]; x2h=0; xi2=0; ya2=zeros(1,N_sim);
        for k=1:N_sim
            yk2=C_ocf*xp2; ya2(k)=yk2;
            ur2=-(Kt(1)*yk2+Kt(2)*x2h+Kt(3)*xi2);
            uk2=max(U_PWM_MIN,min(U_PWM_MAX,ur2));
            x2hn=A_ocf(2,1)*yk2+B_ocf(2)*uk2;
            if abs(ur2)<=U_PWM_MAX; xi2=xi2+(r_ref-yk2); end
            xp2=A_ocf*xp2+B_ocf*uk2; x2h=x2hn;
        end
        plot(t_sim, ya2, colors{ii}, 'LineWidth', 1.2); hold on;
        labels{end+1} = sprintf('\\zeta=%.2f', zeta_t);
    catch; end
end
plot(t_sim, ones(size(t_sim)), 'k--', 'LineWidth', 1);
grid on; xlabel('Time [s]'); ylabel('Position');
title(sprintf('Effect of \\zeta (\\omega_n=%.0f rad/s)', wn_d));
legend([labels, {'Reference'}], 'Location', 'SouthEast', 'FontSize', 8);

% --- Bode plot of plant ---
subplot(2,3,5);
bode(Gd); grid on;
title('Plant Gd - open-loop Bode');

% --- Polynomial method s0 and cond(M) vs wn ---
subplot(2,3,6);
b1v = b_num(1); b2v = b_num(2);
a1v = a_den(2); a2v = a_den(3);
wn_range  = 1:10;   % lower range suitable for Ts=0.1
s0_vals   = zeros(size(wn_range));
cond_vals = zeros(size(wn_range));
for ii = 1:length(wn_range)
    wn_i = wn_range(ii);
    p_i  = exp((-0.7*wn_i + 1j*wn_i*0.7141)*Ts);
    P1i  = -2*real(p_i); P2i = abs(p_i)^2;
    Pdi  = conv([1,P1i,P2i],[1,-0.4,0.04]);
    Mi   = [b1v,0,0,1; b2v,b1v,0,(a1v-1); 0,b2v,b1v,(a2v-a1v); 0,0,b2v,-a2v];
    rhsi = [Pdi(2)-a1v+1; Pdi(3)-a2v+a1v; Pdi(4)+a2v; Pdi(5)];
    si   = Mi\rhsi;
    s0_vals(ii)   = si(4);
    cond_vals(ii) = cond(Mi);
end
yyaxis left;
plot(wn_range, s0_vals, 'b-o', 'MarkerSize', 4, 'LineWidth', 1.5);
ylabel('s0 (must be >0 for stable ctrl)');
hold on;
plot(wn_range, zeros(size(wn_range)), 'b--');
yyaxis right;
plot(wn_range, cond_vals/1e3, 'r-s', 'MarkerSize', 4, 'LineWidth', 1.5);
ylabel('cond(M) x10^3');
xlabel('\omega_n [rad/s]');
title('Polynomial method: s0 and cond(M) vs \omega_n');
legend({'s0','s0=0','cond(M)/10^3'}, 'Location','NorthEast');
grid on;