clc;clear; close all;
%% Ackermann Discreto

% Matrices del sistema
G = [0 0; 
     1 0];        % Matriz de estado
 H = [0; 
      -7.01];       % Matriz de entrada

C = [0 1];         % Matriz de salida
D = 0;             % Matriz de transmisión directa

% Construcción del sistema extendido
Gep = [G  zeros(2,2); 
       -C*G 1 1;
       -C*G 0 1]   % Matriz extendida de estados

Hep = [H; 
       -C*H;
       -C*H]      % Vector extendido de entradas

% Matriz de controlabilidad extendida
Sep = [Hep  Gep*Hep  Gep^2*Hep Gep^3*Hep]  % hasta orden n (aquí n=3)

% Parámetros de diseño
zeta = 0.8;      % coeficiente de amortiguamiento %1
Ts   = 2;      % tiempo de asentamiento deseado (2%) 2
Tm   = 0.1;    % tiempo de muestreo 0.1

% Cálculo de wn
wn = 4 / (zeta * Ts);

syms s;

%Polinomio Des Continuo

% POL = expand((s^2 + 2*zeta*wn*s + wn^2) * (s + 10*zeta*wn));
POL = expand((s^2 + 2*zeta*wn*s + wn^2));
pretty(POL);

% Resolver raíces (polos)
polos = solve(POL == 0, s);
disp('Polos del sistema:');
disp(polos);

% Coeficientes numéricos
P1 = -2 * exp(-zeta*wn*Tm) * cos(wn*Tm*sqrt(1 - zeta^2));
P2 = exp(-2*zeta*wn*Tm);

disp('P1 ='); disp(P1);
disp('P2 ='); disp(P2);

% Polinomio en Discreto
syms z
alpha = -0.1;   % Debe ser negativo acá

% Definir polinomio con coeficientes numéricos
POLD = expand((z^2 + P1*z + P2) * (z + alpha)^2);

% Convertir a decimales (sin fracciones simbólicas)
POLD = vpa(POLD, 3);   % 3 cifras significativas

disp('Polinomio discreto expandido:');
pretty(POLD)

I = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]; %Identidad  3x3
fiG = Gep^4 - 1.84*Gep^3 +1*Gep^2 -0.15*Gep +0.067*I % cambiar por lo que del POLD

K = [0 0 0 1]*inv(Sep)*fiG %Ackerman

%% Observador Discreto:

tso = Ts/10
wndo = 4 / (zeta*tso)
POLO = expand((s^2 + 2*zeta*wndo*s + wndo^2));
pretty(POLO);
% Resolver raíces (polos)
polosO = solve(POLO == 0, s);
disp('Polos del sistema OBSERVADOR:');
vpa(polosO, 3);
pretty(polosO)
% Pol Dis Obser
P1O = -2 * exp(-zeta*wndo*Tm) * cos(wndo*Tm*sqrt(1 - zeta^2));
P2O = exp(-2*zeta*wndo*Tm);
disp('P1O ='); disp(P1O);
disp('P2O ='); disp(P2O);

POLDO = expand((z^2 + P1O*z + P2O));

POLDO = vpa(POLDO, 3);   % 3 cifras significativas

disp('Polinomio discreto expandido: OBSERVADOR');
pretty(POLDO)

L = [P2O+G(1,2); P1O+G(2,2)]

