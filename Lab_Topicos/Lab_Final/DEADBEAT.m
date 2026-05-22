%% =========================================================
%  DEAD-BEAT REDESIGN — T = 0.1 s
%  New plant:
%    Gd(z) = (0.07849z + 0.06092) / (z^2 - 1.466z + 0.4661)
%  Parabolic input (q=2)
% =========================================================
clear; clc; close all;

T = 0.1;

Gd_num_z = [0.07849,  0.06092];
Gd_den_z = [1, -1.466, 0.4661];
Gd = tf(Gd_num_z, Gd_den_z, T);

%% ----------------------------------------------------------
%  1. PLANT ANALYSIS
% ----------------------------------------------------------
plant_zeros = roots(Gd_num_z);
plant_poles = roots(Gd_den_z);

fprintf('=== Plant poles & zeros (T=0.1s) ===\n');
fprintf('Zero  : %.8f\n', plant_zeros);
fprintf('Poles : %.8f  %.8f\n', plant_poles(1), plant_poles(2));
fprintf('|poles|: %.8f  %.8f\n', abs(plant_poles(1)), abs(plant_poles(2)));

b0 = Gd_num_z(1);
b1 = Gd_num_z(2);
b1_tilde = b1 / b0;
zero_loc = -b1_tilde;
fprintf('\nPlant zero location: z0 = %.8f\n', zero_loc);
if abs(zero_loc) < 1
    fprintf('Zero INSIDE unit circle -> N(z)=1, safe to keep\n');
else
    fprintf('WARNING: zero OUTSIDE unit circle -> non-minimum phase!\n');
end

%% ----------------------------------------------------------
%  2. F(z) — same derivation, independent of plant
%
%  Parabolic q=2 -> (1-z^{-1})^3
%  F(z) = 3z^{-1} - 3z^{-2} + z^{-3}
%  1 - F(z) = (1-z^{-1})^3  ✓
% ----------------------------------------------------------
F_z = [3, -3, 1];   % 3z^2 - 3z + 1

fprintf('\n=== F(z) ===\n');
fprintf('F(z) = 3z^2 - 3z + 1\n');
one_minus_F  = [1, -3, 3, -1];
zm1_3        = conv(conv([1,-1],[1,-1]),[1,-1]);
fprintf('Verify 1-F == (1-z^{-1})^3: %s\n', ...
        mat2str(isequal(one_minus_F, zm1_3)));

%% ----------------------------------------------------------
%  3. CONTROLLER
%
%  Gc(z) = F_z * Gd_den / [Gd_num * (z-1)^3]
% ----------------------------------------------------------
Gc_num_z = conv(F_z, Gd_den_z);
Gc_den_z = conv(Gd_num_z, zm1_3);
Gc = tf(Gc_num_z, Gc_den_z, T);

fprintf('\n=== Controller Gc(z) ===\n');
fprintf('Gc_num: '); fprintf('%+.8f  ', Gc_num_z); fprintf('\n');
fprintf('Gc_den: '); fprintf('%+.8f  ', Gc_den_z); fprintf('\n');
fprintf('\nGc zpk:\n'); zpk(Gc)

%% ----------------------------------------------------------
%  4. ANALYTICAL CLOSED LOOP
%
%  OL = Gc*Gd = F(z)/(z-1)^3
%  CL = F(z)/z^3 = (3z^2-3z+1)/z^3
%  ALL poles at z=0
% ----------------------------------------------------------
OL_exact = tf(F_z, zm1_3, T);
CL_exact = tf(F_z, [1,0,0,0], T);
TF_u     = Gc / (1 + Gc*Gd);   % r -> u

fprintf('\n=== Closed-loop poles ===\n');
fprintf('Analytical: '); fprintf('%.6f  ', roots([1,0,0,0])); fprintf('\n');
fprintf('Numeric   : '); fprintf('%.6f  ', abs(pole(feedback(Gc*Gd,1)))); fprintf('\n');

%% ----------------------------------------------------------
%  5. DIFFERENCE EQUATION
%     Normalized by Gc_den(1) = Gd_num(1) = b0
% ----------------------------------------------------------
[nc, dc] = tfdata(Gc, 'v');
nc_n = nc / dc(1);
dc_n = dc / dc(1);

fprintf('\n=== Difference equation (e[m], u[normalized -1..1]) ===\n');
fprintf('u(k) =');
for i=1:length(nc_n)
    if i==1, fprintf(' %+.8f*e(k)',    nc_n(i));
    else,    fprintf('\n     %+.8f*e(k-%d)', nc_n(i), i-1); end
end
fprintf('\n');
for i=2:length(dc_n)
    fprintf('     %+.8f*u(k-%d)\n', -dc_n(i), i-1);
end

%% ----------------------------------------------------------
%  6. RESCALE TO mm / PWM
%     e [mm], u [PWM -255..255]
%     factor = 250/1000 = 0.25 on e-coefficients
% ----------------------------------------------------------
nc_pwm = nc_n * 0.25;   % e: mm -> m needs /1000, u: norm -> PWM needs *250
                         % net: *250/1000 = *0.25

fprintf('\n=== Difference equation RESCALED (e[mm], u[PWM]) ===\n');
fprintf('Saturation threshold: |e| > %.4f mm\n', 255/max(abs(nc_pwm)));
fprintf('\nu(k) =');
for i=1:length(nc_pwm)
    if i==1, fprintf(' %+.8f*e(k)',    nc_pwm(i));
    else,    fprintf('\n     %+.8f*e(k-%d)', nc_pwm(i), i-1); end
end
fprintf('\n');
for i=2:length(dc_n)
    fprintf('     %+.8f*u(k-%d)\n', -dc_n(i), i-1);
end

%% ----------------------------------------------------------
%  7. ROBUSTNESS
% ----------------------------------------------------------
fprintf('\n=== Robustness ===\n');
Gc_den_poles = roots(Gc_den_z);
fprintf('Gc denominator roots:\n');
fprintf('  z = %.8f\n', Gc_den_poles);
fprintf('Controller gain (1/b0): %.4f\n', 1/b0);
fprintf('Old gain (T=0.01): 329.45  |  New gain (T=0.1): %.4f\n', nc_n(1));

%% ----------------------------------------------------------
%  8. SIMULATION
% ----------------------------------------------------------
N = 60; k = (0:N-1)'; t = k*T;
r_step = ones(N,1);
r_ramp = k*T*0.5;
r_para = 0.5*k.^2*T^2;

[y_step, ~] = lsim(CL_exact, r_step, t);
[y_ramp, ~] = lsim(CL_exact, r_ramp, t);
[y_para, ~] = lsim(CL_exact, r_para, t);
[u_step, ~] = lsim(TF_u,     r_step, t);
[u_ramp, ~] = lsim(TF_u,     r_ramp, t);

fprintf('\n=== Settling verification ===\n');
fprintf('Step  max|e| k>3: %.2e\n', max(abs(r_step(4:end)-y_step(4:end))));
fprintf('Ramp  max|e| k>3: %.2e\n', max(abs(r_ramp(4:end)-y_ramp(4:end))));
fprintf('Parab max|e| k>3: %.2e\n', max(abs(r_para(4:end)-y_para(4:end))));

fprintf('\n=== Control effort ===\n');
fprintf('Step  peak |u| normalized: %.6f  ->  PWM: %.2f\n', ...
        max(abs(u_step)), max(abs(u_step))*250);
fprintf('Ramp  peak |u| normalized: %.6f  ->  PWM: %.2f\n', ...
        max(abs(u_ramp)), max(abs(u_ramp))*250);

%% ----------------------------------------------------------
%  9. TRAPEZOIDAL FOR 320mm MOVE
% ----------------------------------------------------------
fprintf('\n=== Trapezoidal 320mm move (normalized units) ===\n');
v_max=0.08; a_max=0.2; d_total=0.32;
t_acc = v_max/a_max;
d_acc = 0.5*a_max*t_acc^2;
if 2*d_acc > d_total
    t_acc = sqrt(d_total/a_max); t_cst=0; v_pk=a_max*t_acc;
else
    t_cst=(d_total-2*d_acc)/v_max; v_pk=v_max;
end
t_tot = 2*t_acc+t_cst;
N_T = round((t_tot+1)/T)+1; k_T=(0:N_T-1)'; t_T=k_T*T;
r_T = zeros(N_T,1);
for ki=1:N_T
    tt=t_T(ki);
    if tt<=t_acc, r_T(ki)=0.5*a_max*tt^2;
    elseif tt<=t_acc+t_cst, r_T(ki)=d_acc+v_pk*(tt-t_acc);
    elseif tt<=t_tot
        dt=tt-(t_acc+t_cst);
        r_T(ki)=d_total-d_acc+v_pk*dt-0.5*a_max*dt^2;
    else, r_T(ki)=d_total; end
end
[y_T,~]=lsim(CL_exact,r_T,t_T);
[u_T,~]=lsim(TF_u,r_T,t_T);
fprintf('Peak |u| normalized: %.6f  ->  PWM: %.2f\n', ...
        max(abs(u_T)), max(abs(u_T))*250);
fprintf('Max |e| during move: %.4e m = %.4f mm\n', ...
        max(abs(r_T-y_T)), max(abs(r_T-y_T))*1000);

%% ----------------------------------------------------------
%  10. PLOTS
% ----------------------------------------------------------
figure('Color','w','Position',[60 60 1200 700]);

subplot(2,3,1);
plot(k,r_step,'b--','LineWidth',1.5,'DisplayName','r'); hold on;
plot(k,y_step,'r-','LineWidth',2,'DisplayName','y');
xline(3,'k:','k=3'); legend; grid on;
title('Step (analytical CL)'); xlabel('k'); ylabel('y');

subplot(2,3,2);
stem(k(1:20),u_step(1:20)*250,'filled','MarkerSize',4,'Color',[0.2 0.4 0.8]);
yline(255,'r--','255'); yline(-255,'r--');
grid on; title('Step u(k) [PWM]'); xlabel('k');

subplot(2,3,3);
semilogy(k(2:end),abs(r_step(2:end)-y_step(2:end))+1e-20,'r','LineWidth',1.5);
xline(3,'k:'); grid on; title('Step |error| log'); xlabel('k');

subplot(2,3,4);
plot(k_T,r_T*1000,'b--','LineWidth',1.5,'DisplayName','r [mm]'); hold on;
plot(k_T,y_T*1000,'r-','LineWidth',2,'DisplayName','y [mm]');
legend; grid on; title('320mm Trapezoidal move'); xlabel('k'); ylabel('mm');

subplot(2,3,5);
plot(k_T,u_T*250,'Color',[0.2 0.5 0.8],'LineWidth',1.5);
yline(255,'r--'); yline(-255,'r--');
grid on; title('Trapez u(k) [PWM]'); xlabel('k'); ylabel('PWM');

subplot(2,3,6);
semilogy(k_T(2:end),abs(r_T(2:end)-y_T(2:end))+1e-20,'r','LineWidth',1.5);
grid on; title('Trapez |error| log'); xlabel('k');

sgtitle('Dead-Beat Redesign — T=0.1s | New Plant','FontWeight','bold','FontSize',13);

fprintf('\n=== DONE ===\n');