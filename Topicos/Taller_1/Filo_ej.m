%% Controladores
clc; clear; close all;
w=1; amp=1;

syms k_1 k_2 k_3 k_4 k_i s l1 l2 l3 l4 s x

% Parámetros de diseño
ts = 1;
z = 0.5;
wnd = 4/(ts*z);
%% Coeficientes del polinomio deseado (s^2 + 2*ζ*ω_n*s + ω_n^2)*(s + 10*ζ*ω_n)^2
alfa1 = 128 / ts;
alfa2 = (16 * (360*z^2 + 1)) / (ts^2 * z^2);
alfa3 = (640 * (160*z^2 + 3)) / (ts^3 * z^2);
alfa4 = (25600 * (20*z^2 + 3)) / (ts^4 * z^2);
alfa5 = 1024000 / (ts^5 * z^2);

% Parámetros físicos
k1 = 20; 
k2 = 30; 
b1 = 4; 
b2 = 3;
M = 1; 
m = 1.5; 
g = 9.81;
L = 0.3; 

x_op = 0.5;


% Matriz A y B del sistema linealizado
A = [0 1 0 0;
    -(k1+k2)/m -(b1+b2)/m M*g/m 0;
    0 0 0 1;
    (k1+k2)/(m*L) (b1+b2)/(m*L) ((-M/m)-1)*g/L 0]

B = [0; 1/m; 0; -1/(m*L)]

% Entrada PERTURBACION
E = [0; M/m; 0; -M + m/L*m]
FM =[0]
C = [1 0 0 0]
D = [0]

% Obtener función de transferencia
[num, den] = ss2tf(A, B, C, D);

% Asegurar formato correcto
num = num(1,:);
num = [zeros(1, length(den)-length(num)) num];  % igualar longitud
den = den(:)';

funcion = tf(num, den);

% Mostrar automáticamente en consola
disp('Función de Transferencia:')
funcion 

y = x;

T=0;

S = [B A*B (A^2)*B (A^3)*B]
det(S)
O = [C;
     C*A;
     C*A^2;
     C*A^3]
det(O)

SI = eye(4)*s;
SIA= vpa(det(SI-A))

M=[152.6 87.83 4.6667 1;
    87.83 4.6667 1 0;
    4.6667 1 0 0;
    1 0 0 0]
Q=inv(M*O)
T=S*M

%% FCC MATRIZ
Afcc=inv(T)*A*T
Bfcc=inv(T)*B
Cfcc=C*T
Dfcc=D
Efcc=inv(T)*E
Ffcc=FM

%% FCO MATRIZ
Afco=inv(Q)*A*Q
Bfco=inv(Q)*B
Cfco=C*Q
Dfco=D
Efco=inv(Q)*E
Ffco=FM

%% Asignacion de POLOS

%PARA A,B,C,D,E,F

Ap = A;
Bp = B;
Cp = C;
Dp = D;

[n, Columnas] = size(Ap);

k = sym('k', [1 n]);

syms s ki

AA = [Ap - Bp*k, Bp*ki;
      -Cp,       0];

Matriz = s*eye(n+1) - AA;

pol = expand(det(Matriz));

pol_ordenado = collect(pol, s);

% Obtiene los coeficientes y los términos base (potencias de s)
[coef_1, potencias] = coeffs(pol_ordenado, s);



pol_d = vpa(expand((s^2 + 2*z*wnd*s + wnd^2) * (s + 10*z*wnd)^3));
pol_d = collect(pol_d, s);

coef_2 = fliplr(coeffs(pol_d, s));

ecuaciones = coef_2 == coef_1;

solv = solve(ecuaciones, [k, ki]);

k_valores = arrayfun(@(i) double(solv.(sprintf('k%d', i))), 1:length(k));

solv_ki = double(solv.ki);

solv_vector = double(k_valores);

% FCC
Apc = Afcc;
Bpc = Bfcc;
Cpc = Cfcc;
Dpc = Dfcc;

[nc, Columnasc] = size(Apc);

kc = sym('k', [1 nc]);

syms s kic

AAc = [Apc - Bpc*kc, Bpc*kic;
      -Cpc,       0];

Matrizc = s*eye(nc+1) - AAc;

polc = expand(det(Matrizc));

pol_ordenadoc = collect(polc, s);

% Obtiene los coeficientes y los términos base (potencias de s)
[coef_1c, potenciasc] = coeffs(pol_ordenadoc, s);



pol_dc = vpa(expand((s^2 + 2*z*wnd*s + wnd^2) * (s + 10*z*wnd)^3));
pol_dc = collect(pol_dc, s);

coef_2c = fliplr(coeffs(pol_dc, s));

ecuacionesc = coef_2c == coef_1c;

solvc = solve(ecuacionesc, [kc, kic]);

k_valoresc = arrayfun(@(i) double(solvc.(sprintf('k%d', i))), 1:length(k));

solv_kic = double(solvc.kic);

solv_vectorc = double(k_valoresc);
% FCO
Apo = Afco;
Bpo = Bfco;
Cpo = Cfco;
Dpo = Dfco;

[n, Columnas] = size(Apo);

ko = sym('k', [1 n]);

syms s ki

AAo = [Apo - Bpo*ko, Bpo*ki;
      -Cpo,       0];

Matrizo = s*eye(n+1) - AAo;

pol_o = expand(det(Matrizo));

pol_ordenado_o = collect(pol_o, s);

% Obtiene los coeficientes y los términos base (potencias de s)
[coef_1o, potencias] = coeffs(pol_ordenado_o, s);



pol_do = vpa(expand((s^2 + 2*z*wnd*s + wnd^2) * (s + 10*z*wnd)^3));
pol_do = collect(pol_do, s);

coef_2o = fliplr(coeffs(pol_do, s));

ecuaciones_o = coef_2o == coef_1o;

solvo = solve(ecuaciones_o, [ko, ki]);

k_valoreso = arrayfun(@(i) double(solvo.(sprintf('k%d', i))), 1:length(ko));

solv_kio = double(solvo.ki);

solv_vectoro = double(k_valoreso);
%% Matriz de transformacion

%PARA A,B,C,D,E,F
SIC = eye(5)*s;
emp = [0;0;0;0];
Aemp = [A emp;-C 0];
Bemp = [B ;0];
Semp = [Bemp Aemp*Bemp Aemp^2*Bemp Aemp^3*Bemp Aemp^4*Bemp];
SIAemp = SIC-Aemp
dSIAemp = det(SIAemp)
[CoefEmp, terminos] = coeffs(dSIAemp, s, 'All')
coeficientes_decimales = vpa(CoefEmp, 4)

M1 = [CoefEmp(5) CoefEmp(4) CoefEmp(3) CoefEmp(2) 1; 
      CoefEmp(4) CoefEmp(3) CoefEmp(2) 1 0;
      CoefEmp(3) CoefEmp(2) 1 0 0;
      CoefEmp(2) 1 0 0 0;
      1 0 0 0 0                                 ];

T = [Semp*M1];
Tinv = inv(T);
Kmatriz = [coef_2(6)-CoefEmp(6) coef_2(5)-CoefEmp(5) coef_2(4)-CoefEmp(4) coef_2(3)-CoefEmp(3) coef_2(2)-CoefEmp(2)];
KKm = Kmatriz*Tinv
KKm_k=double(KKm(1:end-1))
ki_m= double(KKm(end))

%FCC
SICc = eye(5)*s;
empc = [0;0;0;0];
Aempc = [Afcc empc;-Cfcc 0];
Bempc = [Bfcc ;0];
Sempc = [Bempc Aempc*Bempc Aempc^2*Bempc Aempc^3*Bempc Aempc^4*Bempc];
SIAempc = SICc-Aempc
dSIAempc = det(SIAempc)
[CoefEmpc, terminosc] = coeffs(dSIAempc, s, 'All')
coeficientes_decimalesc = vpa(CoefEmpc, 4)

M1c = [CoefEmpc(5) CoefEmpc(4) CoefEmpc(3) CoefEmpc(2) 1; 
      CoefEmpc(4) CoefEmpc(3) CoefEmpc(2) 1 0;
      CoefEmpc(3) CoefEmpc(2) 1 0 0;
      CoefEmpc(2) 1 0 0 0;
      1 0 0 0 0                                 ];

Tcm = [Sempc*M1c];
Tinvcm = inv(Tcm);
Kmatrizc = [coef_2c(6)-CoefEmpc(6) coef_2c(5)-CoefEmpc(5) coef_2c(4)-CoefEmpc(4) coef_2c(3)-CoefEmpc(3) coef_2c(2)-CoefEmpc(2)];
KKmc = Kmatrizc*Tinvcm
KKm_kc=double(KKmc(1:end-1))
ki_mc= double(KKmc(end))

%FCO
SICo = eye(5)*s;
empo = [0;0;0;0];
Aempo = [Afco empo;-Cfco 0];
Bempo = [Bfco ;0];
Sempo = [Bempo Aempo*Bempo Aempo^2*Bempo Aempo^3*Bempo Aempo^4*Bempo];
SIAempo = SICo-Aempo
dSIAempo = det(SIAempo)
[CoefEmpo, terminoso] = coeffs(dSIAempo, s, 'All')
coeficientes_decimaleso = vpa(CoefEmpo, 4)

M1o = [CoefEmpo(5) CoefEmpo(4) CoefEmpo(3) CoefEmpo(2) 1; 
      CoefEmpo(4) CoefEmpo(3) CoefEmpo(2) 1 0;
      CoefEmpo(3) CoefEmpo(2) 1 0 0;
      CoefEmpo(2) 1 0 0 0;
      1 0 0 0 0                                 ];

Tom = [Sempo*M1o];
Tinvom = inv(Tom);
Kmatrizo = [coef_2o(6)-CoefEmpo(6) coef_2o(5)-CoefEmpo(5) coef_2o(4)-CoefEmpo(4) coef_2o(3)-CoefEmpo(3) coef_2o(2)-CoefEmpo(2)];
KKmo = Kmatrizo*Tinvom
KKm_ko=double(KKmo(1:end-1))
ki_mo= double(KKmo(end))



%% Ackerman
Ack = A;
Bck = B;
Cck = C;

[nak, Columnasak] = size(Ack)

z = 0.5;
ts = 1; 
wn = 4/(z*ts);
pol_dak = vpa(expand((s^2+2*z*wn*s+wn^2)*(s+10*z*wn)^3));
pol_dak = collect(pol_dak,s)

coef_2ak = fliplr(coeffs(pol_dak,s))

A_empak = [Ack zeros(n, 1);-Cck 0]
B_empak = [B; 0]
S_empak = [B_empak A_empak*B_empak (A_empak^2)*B_empak (A_empak^3)*B_empak (A_empak^4)*B_empak]
RoAak = A_empak^5 + coef_2ak(2)*(A_empak^4) + coef_2ak(3)*(A_empak^3) + coef_2ak(4)*(A_empak^2) + coef_2ak(5)*A_empak + coef_2ak(6)*eye(n+1)                                              
K_ackak = [zeros(1, n) 1]*inv(S_empak)*RoAak

v_ackak = double(K_ackak(1:end-1))
ki_ackak = double(K_ackak(end))

% OBSERVADOR ACKERMAN

tso = ts/10;
wno = 4/(z*tso);
pol_d_o = vpa(expand((s^2+2*z*wno*s+wno^2)*(s+10*z*wno)^2));
pol_d_o = collect(pol_d_o,s)

coef_2o = fliplr(coeffs(pol_d_o,s))

RoA_o = Ack^4 + coef_2o(2)*(Ack^3) + coef_2o(3)*(Ack^2) + coef_2o(4)*Ack + coef_2o(5)*eye(n)                                              

Ock = [Cck; Cck*Ack; Cck*(Ack^2); Cck*(Ack^3)];

L_ack = double(RoA_o*inv(Ock)*[zeros(n-1,1); 1])

%FCO
Acko = Afco;
Bcko = Bfco;
Ccko = Cfco;

[nako, Columnasako] = size(Acko)

coef_2ako = fliplr(coeffs(pol_dak,s))

A_empako = [Acko zeros(n, 1);-Ccko 0]
B_empako = [Bfco; 0]
S_empako = [B_empako A_empako*B_empako (A_empako^2)*B_empako (A_empako^3)*B_empako (A_empako^4)*B_empako]
RoAako = A_empako^5 + coef_2ako(2)*(A_empako^4) + coef_2ako(3)*(A_empako^3) + coef_2ako(4)*(A_empako^2) + coef_2ako(5)*A_empako + coef_2ako(6)*eye(n+1)                                              
K_ackako = [zeros(1, n) 1]*inv(S_empako)*RoAako

v_ackako = double(K_ackako(1:end-1))
ki_ackako = double(K_ackako(end))

% OBSERVADOR ACKERMAN

RoA_ofco = Acko^4 + coef_2o(2)*(Acko^3) + coef_2o(3)*(Acko^2) + coef_2o(4)*Acko + coef_2o(5)*eye(n)                                              

Ocko = [Ccko; Ccko*Acko; Ccko*(Acko^2); Ccko*(Acko^3)];

L_acko = double(RoA_ofco*inv(Ocko)*[zeros(n-1,1); 1])

%FCC

Ackc = Afcc;
Bckc = Bfcc;
Cckc = Cfcc;

[nak, Columnasak] = size(Ackc)

pol_dakc = vpa(expand((s^2+2*z*wn*s+wn^2)*(s+10*z*wn)^3));
pol_dakc = collect(pol_dakc,s)

coef_2akc = fliplr(coeffs(pol_dakc,s))

A_empakc = [Ackc zeros(n, 1);-Cckc 0]
B_empakc = [Bfcc; 0]
S_empakc = [B_empakc A_empakc*B_empakc (A_empakc^2)*B_empakc (A_empakc^3)*B_empakc (A_empakc^4)*B_empakc]
RoAakc = A_empakc^5 + coef_2akc(2)*(A_empakc^4) + coef_2akc(3)*(A_empakc^3) + coef_2akc(4)*(A_empakc^2) + coef_2akc(5)*A_empakc + coef_2ak(6)*eye(n+1)                                             
K_ackakc = [zeros(1, n) 1]*inv(S_empakc)*RoAakc
                                              

v_ackakc = double(K_ackakc(1:end-1))
ki_ackakc = double(K_ackakc(end))

% OBSERVADOR ACKERMAN

RoA_oc = Ackc^4 + coef_2o(2)*(Ackc^3) + coef_2o(3)*(Ackc^2) + coef_2o(4)*Ackc + coef_2o(5)*eye(n)                                              

Ockc = [Cckc; Cckc*Ackc; Cckc*(Ackc^2); Cckc*(Ackc^3)];

L_ackc = double(RoA_oc*inv(Ockc)*[zeros(n-1,1); 1])

%% Observador por matriz de transformada
tsd1 = ts/10;
wnd1 = 4/(tsd1*z);
PolD2 = vpa(expand((s^2 + 2*wnd1*z*s + wnd1^2) * (s + 10*wnd1*z)^2));
coef_22 = fliplr(coeffs(PolD2,s));
Vobs = [coef_22(5)-den(5); coef_22(4)-den(4); coef_22(3)-den(3); coef_22(2)-den(2)];

M2 = [den(4) den(3) den(2) 1; 
      den(3) den(2) 1 0;
      den(2) 1 0 0;
      1 0 0 0;            ];

Q = inv(M2*O);
Lt = double(Q*Vobs)

% FCC

PolD2c = vpa(expand((s^2 + 2*wnd1*z*s + wnd1^2) * (s + 10*wnd1*z)^2));
coef_22c = fliplr(coeffs(PolD2c,s));
Vobsc = [coef_22c(5)-den(5); coef_22c(4)-den(4); coef_22c(3)-den(3); coef_22c(2)-den(2)];

M2c = [den(4) den(3) den(2) 1; 
      den(3) den(2) 1 0;
      den(2) 1 0 0;
      1 0 0 0;            ];

Qc = inv(M2c*O);
Ltc = double(Qc*Vobsc)

% FCO

PolD2o = vpa(expand((s^2 + 2*wnd1*z*s + wnd1^2) * (s + 10*wnd1*z)^2));
coef_22o = fliplr(coeffs(PolD2o,s));
Vobso = [coef_22o(5)-den(5); coef_22o(4)-den(4); coef_22o(3)-den(3); coef_22o(2)-den(2)];

M2o = [den(4) den(3) den(2) 1; 
      den(3) den(2) 1 0;
      den(2) 1 0 0;
      1 0 0 0;            ];

Qo = inv(M2o*O);
Lto = double(Qo*Vobso)

%% Observador de estados por asignacion de polos
Lo = sym('L', [1 n]);
Lo = Lo.';

% Matriz_o = s*eye(n)-(Ap-Lo*Cp)
Matriz_o = s*eye(n)-(Ap-Lo*Cp);

pol_obs = expand(det(Matriz_o));

pol_obs_ordenado = collect(pol_obs, s);

[coef_1o, potencias_o] = coeffs(pol_obs_ordenado, s);

%tso = ts/10;
wno = 4/(z*tso);
pol_d_o = vpa(expand((s^2+2*z*wno*s+wno^2)*(s+10*z*wno)^2));
pol_d_o = collect(pol_d_o,s);

coef_2o = fliplr(coeffs(pol_d_o,s));

ecuaciones = coef_2o == coef_1o;

sol_o = solve(ecuaciones, Lo);

l_valores = arrayfun(@(i) double(sol_o.(sprintf('L%d', i))), 1:length(Lo));

sol_vector_o = double(l_valores)

% FCC

Loc = sym('L', [1 n]);
Loc = Loc.';

% Matriz_o = s*eye(n)-(Ap-Lo*Cp)
Matriz_oc = s*eye(n)-(Ap-Loc*Cp);

pol_obsc = expand(det(Matriz_oc));

pol_obs_ordenadoc = collect(pol_obsc, s);

[coef_1oc, potencias_o] = coeffs(pol_obs_ordenadoc, s);

%tso = ts/10;
wno = 4/(z*tso);
pol_d_oc = vpa(expand((s^2+2*z*wno*s+wno^2)*(s+10*z*wno)^2));
pol_d_oc = collect(pol_d_oc,s);

coef_2oc = fliplr(coeffs(pol_d_oc,s));

ecuacionesc = coef_2oc == coef_1oc;

sol_oc = solve(ecuacionesc, Loc);

l_valoresc = arrayfun(@(i) double(sol_oc.(sprintf('L%d', i))), 1:length(Lo));

sol_vector_oc = double(l_valoresc)

% FCO

Loo = sym('L', [1 n]);
Loo = Loo.';

% Matriz_o = s*eye(n)-(Ap-Lo*Cp)
Matriz_oo = s*eye(n)-(Ap-Loo*Cp);

pol_obso = expand(det(Matriz_oo));

pol_obs_ordenadoo = collect(pol_obso, s);

[coef_1oo, potencias_oo] = coeffs(pol_obs_ordenadoo, s);

%tso = ts/10;
wno = 4/(z*tso);
pol_d_oo = vpa(expand((s^2+2*z*wno*s+wno^2)*(s+10*z*wno)^2));
pol_d_oo = collect(pol_d_oo,s);

coef_2oo = fliplr(coeffs(pol_d_oo,s));

ecuacioneso = coef_2oo == coef_1oo;

sol_oo = solve(ecuacioneso, Loo);

l_valoreso = arrayfun(@(i) double(sol_oo.(sprintf('L%d', i))), 1:length(Lo));

sol_vector_oo = double(l_valoreso)