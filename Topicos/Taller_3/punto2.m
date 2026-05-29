clc;
clear;
close all;

%% =========================================================
% CONTROL POR RETROALIMENTACION DE ESTADOS
% ENTRADA PARABOLICA
%
% Sistema:
%
% G(z)=1/(1-z^-1)
%
% Forma canonica controlable
%% =========================================================

Ts = 0.05;

zeta = 0.7;
wn = 5.71;

%% =========================================================
% POLOS CONTINUOS DOMINANTES
%% =========================================================

wd = wn*sqrt(1-zeta^2);

s1 = -zeta*wn + 1j*wd;
s2 = -zeta*wn - 1j*wd;

%% =========================================================
% POLOS DISCRETOS
%% =========================================================

z1 = exp(s1*Ts);
z2 = exp(s2*Ts);

% polos adicionales
% deben ser reales y mas rapidos

z3 = 0.5;
z4 = 0.4;

Pdeseados = [z1 z2 z3 z4];

disp('Polos deseados:')
disp(Pdeseados)

%% =========================================================
% POLINOMIO DESEADO
%% =========================================================

Phi_d = real(poly(Pdeseados));

disp('Polinomio deseado:')
disp(Phi_d)

%% =========================================================
% SISTEMA AUMENTADO
%
% Tipo 3 -> entrada parabólica
%
% (z-1)^4
%% =========================================================

Phi = poly([1 1 1 1]);

disp('Polinomio original:')
disp(Phi)

%% =========================================================
% COEFICIENTES
%% =========================================================

a1 = Phi(2);
a2 = Phi(3);
a3 = Phi(4);
a4 = Phi(5);

%% =========================================================
% FORMA CANONICA CONTROLABLE
%% =========================================================

A = [ 0 1 0 0;
      0 0 1 0;
      0 0 0 1;
     -a4 -a3 -a2 -a1];

B = [0;
     0;
     0;
     1];

C = [1 0 0 0];

n = size(A,1);

%% =========================================================
% VERIFICACION CONTROLABILIDAD
%% =========================================================

Mc = ctrb(A,B);

if rank(Mc) ~= n
    error('Sistema NO controlable')
end

disp('Sistema controlable')

%% =========================================================
% METODO 1
% ASIGNACION DIRECTA
%
% En forma canonica controlable:
%
% K = alpha - a
%% =========================================================

a = Phi(2:end);

alpha = Phi_d(2:end);

K1 = alpha - a;

disp('K metodo algebraico:')
disp(K1)

%% =========================================================
% METODO 2
% ACKERMANN
%% =========================================================

K2 = real(acker(A,B,Pdeseados));

disp('K Ackermann:')
disp(K2)

%% =========================================================
% AJUSTE NUMERICO
%% =========================================================

K1 = round(K1,10);
K2 = round(K2,10);

disp('----------------------------------')
disp('Diferencia entre métodos:')
disp(K1-K2)

%% =========================================================
% COMPROBACION
%% =========================================================

if isequal(K1,K2)

    disp('AMBOS METODOS SON IDENTICOS')

else

    disp('Existe diferencia numerica')

end

%% =========================================================
% SISTEMA EN LAZO CERRADO
%% =========================================================

Acl = A - B*K1;

disp('Polos obtenidos:')
disp(eig(Acl))

%% =========================================================
% SIMULACION
%% =========================================================

N = 120;

x = zeros(n,1);

y = zeros(1,N);

u = zeros(1,N);

r = zeros(1,N);

%% referencia parabólica

for k=1:N

    r(k) = 0.01*k^2;

end

%% simulacion

for k=1:N

    u(k) = -K1*x + r(k);

    x = A*x + B*u(k);

    y(k) = C*x;

end

%% =========================================================
% GRAFICAS
%% =========================================================

t = (0:N-1)*Ts;

figure;

plot(t,r,'r--','LineWidth',2)
hold on

plot(t,y,'b','LineWidth',2)

grid on

xlabel('Tiempo [s]')
ylabel('Salida')

legend('Referencia parabólica','Salida')

title('Retroalimentacion de estados')

%% =========================================================
% CONTROL
%% =========================================================

figure;

plot(t,u,'LineWidth',2)

grid on

xlabel('Tiempo [s]')
ylabel('u(k)')

title('Señal de control')