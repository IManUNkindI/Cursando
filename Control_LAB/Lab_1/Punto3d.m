clc; clear; close all;

% Parámetros
R1 = 2;      % Ohm
R2 = 7;      % Ohm
C  = 25e-3;  % F
L  = 4.444;  % H
Vf = 9;      % V

% Matrices de espacio de estados
A = [-1/(R2*C),   -1/C;
      1/L,         0];
B = [1/(R2*C);
     0];
Cmat = eye(2);
D = [0;0];

% Simulación
t = 0:0.001:2;
u = Vf*ones(size(t));
sys = ss(A,B,Cmat,D);
x0 = [0;0]; % condiciones iniciales
[y,~,x] = lsim(sys,u,t,x0);

% Graficar
figure;
subplot(2,1,1)
plot(t,x(:,1),'LineWidth',1.5)
xlabel('Tiempo [s]'); ylabel('v_C(t) [V]'); grid on
title('Voltaje en el condensador')

subplot(2,1,2)
plot(t,x(:,2),'LineWidth',1.5)
xlabel('Tiempo [s]'); ylabel('i_L(t) [A]'); grid on
title('Corriente en el inductor')
