%% =========================================================
%  DISCRETE ROOT LOCUS COMPENSATOR DESIGN
%  Plant: Gd(z) = (0.07849*z + 0.06092) / (z^2 - 1.466*z + 0.4661)
%  T = 0.1 s,  desired zeta_d = 0.7
%  Procedure follows: angle condition -> geometry -> gain
%% =========================================================
clear; clc; close all;

%% ---- 1. PLANT ------------------------------------------------
T      = 0.1;
num_G  = [0.07849,  0.06092];
den_G  = [1, -1.466, 0.4661];
Gd     = tf(num_G, den_G, T);

plant_poles = roots(den_G);   % two poles of the plant
plant_zeros = roots(num_G);   % one zero of the plant

fprintf('=== LGR ===\n');
fprintf('=== PLANT ANALYSIS ===\n');
fprintf('Plant poles: %.6f + %.6fj\n', real(plant_poles(1)), imag(plant_poles(1)));
fprintf('             %.6f + %.6fj\n', real(plant_poles(2)), imag(plant_poles(2)));
fprintf('Plant zero:  %.6f\n', real(plant_zeros(1)));

% Natural frequency and damping of plant poles (s-domain equivalent)
% z = e^(s*T)  =>  s = ln(z)/T
s_poles    = log(plant_poles) / T;
wn_plant   = abs(s_poles(1));
zeta_plant = -real(s_poles(1)) / wn_plant;
fprintf('Plant s-equivalent: sigma=%.4f, wd=%.4f rad/s\n', real(s_poles(1)), imag(s_poles(1)));
fprintf('Plant wn=%.4f rad/s,  zeta_plant=%.4f\n', wn_plant, zeta_plant);
fprintf('NOTE: poles close to z=1 -> slow, lightly damped system\n\n');

%% ---- 2. DESIRED POLES ----------------------------------------
zeta_d = 0.7;

% --- Settling time spec (2% criterion: ts ~ 4/(zeta*wn)) ---
% Adjust ts_desired as needed:
ts_desired = 1.0;   % [seconds]  <-- ADJUST AS NEEDED

wn_d  = 4 / (zeta_d * ts_desired);          % desired natural frequency
wd_d  = wn_d * sqrt(1 - zeta_d^2);          % damped natural frequency
sig_d = zeta_d * wn_d;                       % decay rate

fprintf('=== DESIRED SPECS ===\n');
fprintf('zeta_d=%.2f,  ts_desired=%.2f s\n', zeta_d, ts_desired);
fprintf('=> wn_d=%.4f rad/s,  wd_d=%.4f rad/s,  sigma_d=%.4f\n', wn_d, wd_d, sig_d);

% Map desired s-plane poles to z-plane
s_d = -sig_d + 1j*wd_d;
zd  = exp(s_d * T);                          % desired z-plane pole

fprintf('Desired s-pole: %.4f + %.4fj\n', real(s_d), imag(s_d));
fprintf('Desired z-pole: %.6f + %.6fj   |zd|=%.6f\n', real(zd), imag(zd), abs(zd));

% Sanity check: desired pole must be inside unit circle
if abs(zd) >= 1
    error('Desired pole is outside or on unit circle. Reduce ts_desired or check zeta_d.');
end

% Warn if desired pole is very close to a plant pole
min_dist = min(abs(zd - plant_poles));
fprintf('Distance from desired pole to nearest plant pole: %.6f\n', min_dist);
if min_dist < 0.05
    warning('Desired pole is very close to a plant pole. Angle contributions will be sensitive.');
end
fprintf('\n');

%% ---- 3. ANGLE CONDITION AT DESIRED POLE ----------------------
%
%  Root locus condition: angle( Gd(zd) ) = (2k+1)*180 deg
%
%  angle_total = sum(angles from zeros) - sum(angles from poles)

% Angles contributed by plant zeros (positive contribution)
angles_zeros = angle(zd - plant_zeros) * (180/pi);   % degrees

% Angles contributed by plant poles (negative contribution)
angles_poles = angle(zd - plant_poles) * (180/pi);   % degrees

angle_total = sum(angles_zeros) - sum(angles_poles);

% Wrap to (-180, 180] to check if condition is satisfied
angle_mod = mod(angle_total + 180, 360) - 180;

fprintf('=== ANGLE CONDITION CHECK ===\n');
fprintf('Angle from plant zero:    ');
fprintf('%.4f deg  ', angles_zeros); fprintf('\n');
fprintf('Angle from plant poles:   ');
fprintf('%.4f deg  ', angles_poles); fprintf('\n');
fprintf('Total open-loop angle at zd: %.4f deg\n', angle_total);
fprintf('Normalized (mod 360) angle:  %.4f deg\n', angle_mod);

angle_tol = 1.0;   % degrees
if abs(abs(angle_mod) - 180) < angle_tol
    fprintf('\n*** Angle condition ALREADY SATISFIED (within %.1f deg tolerance) ***\n', angle_tol);
    fprintf('No phase compensation needed. Only gain K required.\n');
    compensator_needed = false;
    angle_deficiency   = 0;
    n_stages           = 0;
else
    compensator_needed = true;
    % Find nearest odd multiple of 180 deg as target
    k_values = -3:3;
    targets  = (2*k_values + 1) * 180;
    [~, idx] = min(abs(targets - angle_total));
    target   = targets(idx);
    angle_deficiency = target - angle_total;

    fprintf('\nNearest target angle: %.1f deg\n', target);
    fprintf('Angle deficiency (compensator must provide): %.4f deg\n', angle_deficiency);

    if abs(angle_deficiency) > 180
        warning('Deficiency > 180 deg. May need multiple compensator stages.');
        n_stages = ceil(abs(angle_deficiency) / 60);
        fprintf('Suggestion: use %d compensator stages of %.4f deg each\n', ...
                n_stages, angle_deficiency/n_stages);
    else
        n_stages = 1;
        fprintf('Single compensator stage sufficient.\n');
    end
end
fprintf('\n');

%% ---- 4. COMPENSATOR GEOMETRY (if needed) ---------------------
%
%  Lead compensator:  fc(z) = K * (z - zc) / (z - pc)
%
%  Geometric (bisector + sine rule) method.

if compensator_needed
    fprintf('=== COMPENSATOR GEOMETRY ===\n');

    deficiency_per_stage = angle_deficiency / n_stages;
    fprintf('Deficiency per stage: %.4f deg\n', deficiency_per_stage);

    % --- BISECTOR METHOD ---
    [~, idx_near_pole] = min(abs(zd - plant_poles));
    nearest_pole = plant_poles(idx_near_pole);
    nearest_zero = plant_zeros(1);   % only one zero

    vec_to_pole = nearest_pole - zd;
    vec_to_zero = nearest_zero - zd;

    ang_to_pole = angle(vec_to_pole) * 180/pi;
    ang_to_zero = angle(vec_to_zero) * 180/pi;

    M = abs(zd);   % distance of desired pole from origin
    fprintf('|zd| = %.6f\n', M);
    fprintf('Angle from zd to nearest plant pole: %.4f deg\n', ang_to_pole);
    fprintf('Angle from zd to plant zero:         %.4f deg\n', ang_to_zero);

    Omega = (ang_to_pole + ang_to_zero) / 2;
    beta  = 180 - Omega;

    fprintf('Bisector direction (Omega): %.4f deg\n', Omega);
    fprintf('beta = 180 - Omega = %.4f deg\n', beta);

    phi_half = abs(deficiency_per_stage) / 2;

    ang_zero_triangle = beta + phi_half;
    ang_pole_triangle = beta - phi_half;

    fprintf('\nSine rule angles:\n');
    fprintf('  For compensator zero: %.4f deg\n', ang_zero_triangle);
    fprintf('  For compensator pole: %.4f deg\n', ang_pole_triangle);

    if ang_pole_triangle <= 0
        warning(['Geometry breakdown: beta - phi/2 = %.4f deg <= 0.\n' ...
                 'Switching entirely to numerical placement.'], ang_pole_triangle);
        ang_pole_triangle = eps;   % force numerical fallback below
    end

    dist_to_comp_zero = M * sind(phi_half) / sind(ang_zero_triangle);
    dist_to_comp_pole = M * sind(phi_half) / sind(ang_pole_triangle);

    comp_zero = real(zd) + dist_to_comp_zero * cosd(ang_zero_triangle);
    comp_pole = real(zd) + dist_to_comp_pole * cosd(ang_pole_triangle);

    fprintf('\nCompensator zero (zc): %.6f\n', comp_zero);
    fprintf('Compensator pole (pc): %.6f\n', comp_pole);

    % Verify angle contribution
    phi_check = (angle(zd - comp_zero) - angle(zd - comp_pole)) * 180/pi;
    fprintf('Verification - angle from compensator at zd: %.4f deg (target: %.4f deg)\n', ...
            phi_check, deficiency_per_stage);

    if abs(phi_check - deficiency_per_stage) > 2
        warning('Angle error > 2 deg. Refining compensator pole numerically...');
        ang_zero_actual  = angle(zd - comp_zero) * 180/pi;
        required_ang_pole = (ang_zero_actual - deficiency_per_stage) * pi/180;
        comp_pole_refined = real(zd) - imag(zd)/tan(required_ang_pole);
        phi_check2 = (angle(zd - comp_zero) - angle(zd - comp_pole_refined)) * 180/pi;
        fprintf('Refined comp pole: %.6f  (angle check: %.4f deg)\n', comp_pole_refined, phi_check2);
        comp_pole = comp_pole_refined;
    end

    % Build compensator TF (single stage)
    num_c     = [1, -comp_zero];
    den_c     = [1, -comp_pole];
    Gc_stage  = tf(num_c, den_c, T);

    % Stack n_stages if needed
    Gc_unscaled = Gc_stage;
    for i = 2:n_stages
        Gc_unscaled = series(Gc_unscaled, Gc_stage);
    end

else
    fprintf('No geometric compensator needed.\n');
    Gc_unscaled = tf(1, 1, T);
    comp_zero   = NaN;
    comp_pole   = NaN;
end

%% ---- 5. GAIN CALCULATION ------------------------------------
%
%  |Gd(zd) * Gc_unscaled(zd)| = 1  =>  K = 1 / |Gd(zd)*Gc(zd)|

fprintf('\n=== GAIN CALCULATION ===\n');

Gd_at_zd = polyval(num_G, zd) / polyval(den_G, zd);

if compensator_needed
    Gc_at_zd = ((zd - comp_zero) / (zd - comp_pole))^n_stages;
else
    Gc_at_zd = 1;
end

loop_at_zd = Gd_at_zd * Gc_at_zd;
K          = 1 / abs(loop_at_zd);

fprintf('|Gd(zd)|       = %.6f\n', abs(Gd_at_zd));
fprintf('|Gc(zd)|       = %.6f\n', abs(Gc_at_zd));
fprintf('|Gd*Gc|(zd)    = %.6f\n', abs(loop_at_zd));
fprintf('Required gain K = %.6f\n', K);

loop_angle = angle(loop_at_zd * K) * 180/pi;
fprintf('Angle of K*Gd*Gc at zd: %.4f deg (should be ±180)\n', loop_angle);

%% ---- 6. FINAL COMPENSATOR ------------------------------------
fprintf('\n=== FINAL COMPENSATOR ===\n');

if compensator_needed
    if n_stages == 1
        num_fc = K * [1, -comp_zero];
        den_fc =     [1, -comp_pole];
        fprintf('fc(z) = %.6f * (z - %.6f) / (z - %.6f)\n', K, comp_zero, comp_pole);
    else
        num_fc = K * conv_n(repmat({[1, -comp_zero]}, 1, n_stages));
        den_fc =     conv_n(repmat({[1, -comp_pole]},  1, n_stages));
        fprintf('fc(z) = %.6f * (z - %.6f)^%d / (z - %.6f)^%d\n', ...
                K, comp_zero, n_stages, comp_pole, n_stages);
    end
else
    num_fc = K;
    den_fc = 1;
    fprintf('fc(z) = %.6f  (pure gain, no poles/zeros needed)\n', K);
end

fc = tf(num_fc, den_fc, T);
fprintf('\nCompensator tf:\n');
fc

%% ---- 7. OPEN AND CLOSED LOOP ---------------------------------
OL = series(fc, Gd);
CL = feedback(OL, 1);

fprintf('Closed-loop poles:\n');
cl_poles = pole(CL);
for i = 1:length(cl_poles)
    fprintf('  z = %.6f + %.6fj   |z|=%.6f\n', ...
            real(cl_poles(i)), imag(cl_poles(i)), abs(cl_poles(i)));
end

[~, idx_match] = min(abs(cl_poles - zd));
fprintf('\nDesired pole zd       = %.6f + %.6fj\n', real(zd), imag(zd));
fprintf('Nearest CL pole       = %.6f + %.6fj\n', real(cl_poles(idx_match)), imag(cl_poles(idx_match)));
fprintf('Error |zd - CL_pole|  = %.2e\n', abs(zd - cl_poles(idx_match)));

%% ---- 8. PLOTS ------------------------------------------------

figure('Name','Root Locus','NumberTitle','off');
rlocus(OL);
hold on;
plot(real(zd),  imag(zd),  'r*', 'MarkerSize', 14, 'LineWidth', 2);
plot(real(zd), -imag(zd),  'r*', 'MarkerSize', 14, 'LineWidth', 2);
theta = linspace(0, 2*pi, 300);
plot(cos(theta), sin(theta), 'k--', 'LineWidth', 0.8);   % unit circle
title('Root locus with desired poles (red *)');
xlabel('Real'); ylabel('Imag'); grid on; axis equal;
xlim([-1.5 1.5]); ylim([-1.5 1.5]);

figure('Name','Step Response','NumberTitle','off');
[y, t] = step(CL, 5*ts_desired);
plot(t, y, 'b-', 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Output');
title(sprintf('Closed-loop step response  (\\zeta_d=%.2f,  t_s=%.2f s)', zeta_d, ts_desired));
yline(0.98, 'r--', '98%'); yline(1.02, 'r--', '102%');

figure('Name','Ramp Response','NumberTitle','off');
t_r = 0:T:5*ts_desired;
r_r = t_r;
y_r = lsim(CL, r_r, t_r);
plot(t_r, r_r, 'r--', 'LineWidth', 1.5); hold on;
plot(t_r, y_r, 'b',   'LineWidth', 1.5);
grid on;
xlabel('Time (s)'); ylabel('Output');
legend('Reference','Output');
title('Closed-loop ramp response');

figure('Name','Parabolic Response','NumberTitle','off');
t_p = 0:T:5*ts_desired;
r_p = t_p.^2;
y_p = lsim(CL, r_p, t_p);
plot(t_p, r_p, 'r--', 'LineWidth', 1.5); hold on;
plot(t_p, y_p, 'b',   'LineWidth', 1.5);
grid on;
xlabel('Time (s)'); ylabel('Output');
legend('Reference','Output');
title('Closed-loop parabolic response');

figure('Name','Bode - Open Loop','NumberTitle','off');
bode(OL); grid on;
title('Open-loop Bode diagram');

fprintf('\n=== DESIGN COMPLETE ===\n');

%% ---- HELPER: multiply cell array of polynomials --------------
function p = conv_n(polys)
    p = polys{1};
    for k = 2:length(polys)
        p = conv(p, polys{k});
    end
end