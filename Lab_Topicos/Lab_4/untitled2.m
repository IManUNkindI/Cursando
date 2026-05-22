syms q1 q2 q3 pq1 pq2 pq3 T1 F2 F3

L = 0.2
M = 0.5;
J = 2*M*L^2;
g = 9.81;

pz2 = pq2;
  
px3 = 0
py3 = 0  
pz3 = pq2

px4 = pq3*cos(q1) - (L+q3)*pq1*sin(q1)
py4 = pq3*sin(q1) + (L+q3)*pq1*cos(q1) 
pz4 = pq2

v3_2 = simplify(expand(px3^2 + py3^2 + pz3^2))
v4_2 = simplify(expand(px4^2 + py4^2 + pz4^2))

Ek = J*(pq1^2)/2 + M*(pz2^2)/2 + M*v3_2/2 +  M*v4_2/2;

Ep = M*g*(7*L+3*q2);

L = Ek - Ep;

dL_pq1 = diff(L, pq1);
dL_q1 = diff(L, q1);
dL_pq2 = diff(L, pq2);
dL_q2 = diff(L, q2);
dL_pq3 = diff(L, pq3);
dL_q3 = diff(L, q3);

%%

syms q1 q2 q3 w1 v2 v3 T1 F2 F3

pq1 = w1;
pq2 = v2;
pq3 = v3;

ppq1 = (T1-pq1*q3*pq3-pq1*pq3/5)/((q3^2)/2 +q3/5 +3/50);

ppq2 = 2*F2/3 -9.81;

ppq3 = 2*F3 +(pq1^2)*q3 +(pq1^2)/5;

eqs = [pq1; ppq1; pq2; ppq2; pq3; ppq3];
qs = [q1; w1; q2; v2; q3; v3];
fs = [T1; F2; F3];

A_sym = jacobian(eqs, qs)
B_sym = jacobian(eqs, fs)
 
qs0 = [q1;0;q2;0;q3;0];
fs0 = [0;14.715;0];

A = (subs(A_sym, [qs; fs], [qs0; fs0]))
B = (subs(B_sym, [qs; fs], [qs0; fs0]))
C = [0, 1, 0, 0, 0, 0; 0, 0, 0, 1, 0, 0; 0, 0, 0, 0, 0, 1]

%%











