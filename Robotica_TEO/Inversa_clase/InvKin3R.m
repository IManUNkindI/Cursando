function [Q] = InvKin3R(P,L)

Px=P(1);
Py=P(2);
Pz=P(3);

q1=atan2(Py,Px);
m=sqrt(Px^2+Py^2)
n=Pz-L(1)

C3=(m^2+n^2-(L(2)^2)-(L(3)^2))/(2*L(2)*L(3))
S3=sqrt(1-(C3^2))
q3=atan2(S3,C3)

Beta=atan2(n,m)
Sigma=atan2(L(3)*S3,(L(2)+L(3)*C3))

q2=Beta-Sigma

Q=[q1 q2 q3];
end