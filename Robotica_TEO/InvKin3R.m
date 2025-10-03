function [Q] = InvKin3R(P,L)

Px=P(1);
Py=P(2);
Pz=P(3);

q1 = atan2(Py,Px);

m  = sqrt(Px^2+Py^2);
q3 = m - 11;

q2 = Pz - 10 - 12;


Q=[q1 q2 q3]
end