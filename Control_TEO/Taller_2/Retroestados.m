%% Controladores
clc; clear; close all;

syms k1 k2 k3 k4 ki s

% Parámetros de diseño
ts = 1.25;
z = 0.9;
wnd = 4/(ts*z);

% Parametros fisicos
M = 0.2;
m = 0.5;
L = 0.6;
g = 9.806;
k = 80;

%% Coeficientes del polinomio deseado (s^2 + 2*ζ*ω_n*s + ω_n^2)*(s + 10*ζ*ω_n)^2
pnd = 2;
PolD = (s^2 + 2*z*wnd*s + wnd^2)*(s + 10*z*wnd)^pnd;
vpa(expand(PolD), 4)

%% Matrices lineales

A = [0 1 0 0;
     -k/m 0 (M*g)/m 0;
     0 0 0 1;
     k/(L*m) 0 -((M+m)*g)/(m*L) 0]

B = [0; 1/M; 0; -1/(M*L)]

C = [1 0 0 0]

D = [0]

% Obtener función de transferencia
[num, den] = ss2tf(A, B, C, D);

% Asegurar formato correcto
num = num(1,:);
num = [zeros(1, length(den)-length(num)) num];  % igualar longitud
den = den(:)';

% Mostrar automáticamente en consola
disp('Función de Transferencia:')
f_s = tf(num, den)

roots(den)

S = [B A*B (A^2)*B (A^3)*B]
det(S)

O = [C;
     C*A;
     C*A^2;
     C*A^3]
det(O)

SI = eye(4)*s;
SIA = vpa(det(SI-A))

M = [152.6 87.83 4.6667 1;
    87.83 4.6667 1 0;
    4.6667 1 0 0;
    1 0 0 0]
Q = inv(M*O)
T = S*M

%% FCC MATRIZ
Afcc = [0 1 0 0;
        0 0 1 0;
        0 0 0 1;
        2616 0 182.89 0]
Bfcc = [0; 0; 0; 1]
Cfcc = [0 0 3.333 -9.999]
Dfcc = [0]

%% FCO MATRIZ
Afco = vpa(inv(Q)*A*Q, 4)
Bfco = vpa(inv(Q)*B, 4)
Cfco = vpa(C*Q, 4)
Dfco = vpa(D, 4)

%% Asignacion de POLOS
[n, Columnas] = size(Afcc);

k = sym('k', [1 n]);

BK = [0 0 0 k1;
      0 0 0 k2;
      0 0 0 k3;
      0 0 0 k4]

Aa = [Afcc-BK Bfcc*k2 Bfcc*k1;
      0 0 0 0 1 1;
      -Cfcc 0 0];
vpa(Aa, 4)

[j, Col] = size(Aa);

SI = eye(j)*s;

vpa(collect(det(SI-Aa)))
