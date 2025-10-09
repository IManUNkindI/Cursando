function [Q] = InvKin3R(P,L)

Px=P(1);
Py=P(2);
Pz=P(3);

q2 = pi/2 - atan2(Px,Py);

m  = sqrt(Px^2+Py^2);
q3 = m - 500;

q1 = Pz - 200;


Q = [q1 q2 q3];
end