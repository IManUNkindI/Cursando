%% =========================================================
%  ANALISIS DE CONTROLABILIDAD, OBSERVABILIDAD
%  FORMAS CANONICAS (ORDEN ARBITRARIO n)
% =========================================================

clc; clear;
syms s

%% ===== DEFINICION DEL SISTEMA =====
A = [0 1 0 0;
     -33.33 -4.6667 6.54 0;
     0 0 0 1; 
     111.111 15.5556 -54.5 0]

B = [0; 0.6667; 0; -2.222]
C = [1 0 0 0]
D = 0

E = [0; 0.6667; 0; 6.5]
F = 0

n = size(A,1)   % Orden del sistema

%% =========================================================
%  MATRIZ DE CONTROLABILIDAD
% =========================================================
controla = sym(zeros(n,n)); 

for k = 1:n
    controla(:,k) = A^(k-1)*B;
end

vpa(controla, 4)

det_controla = vpa(det(controla), 4)

%% =========================================================
%  POLINOMIO CARACTERISTICO
% =========================================================
FNC = expand(det(s*eye(n) - A))
coef = coeffs(FNC, s, 'All');  % [a0 a1 ... a_{n-1} 1]

%% =========================================================
%  MATRIZ M (FORMA CANONICA CONTROLABLE)
% =========================================================
M = sym(zeros(n));

for i = 1:n
    for j = 1:n
        idx = n + 2 - i - j;
        if idx >= 1 && idx <= length(coef)
            M(i,j) = coef(idx);
        else
            M(i,j) = 0;
        end
    end
end

vpa(M, 4)

%% =========================================================
%  TRANSFORMACION A FORMA CANONICA CONTROLABLE
% =========================================================
T = vpa(controla * M, 4)

Afcc = vpa(inv(T)*A*T, 4)
Bfcc = vpa(inv(T)*B, 4)
Cfcc = vpa(C*T, 4)
Dfcc = D

Efcc = vpa(inv(T)*E, 4)
Ffcc = F

%% =========================================================
%  MATRIZ DE OBSERVABILIDAD
% =========================================================
observa = sym(zeros(n,n));

for k = 1:n
    observa(k,:) = C*A^(k-1);
end

vpa(observa, 4) 

det_observa = vpa(det(observa), 4)

%% =========================================================
%  TRANSFORMACION A FORMA CANONICA OBSERVABLE
% =========================================================
Q = vpa(inv(M*observa), 4)

Afco = vpa(inv(Q)*A*Q, 4)
Bfco = vpa(inv(Q)*B, 4)
Cfco = vpa(C*Q, 4)
Dfco = D

Efco = vpa(inv(Q)*E, 4)
Ffco = F