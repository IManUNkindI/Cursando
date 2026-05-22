syms q1 q2 q3 q4 q5 L1 L2 L3 

theta = [q1,pi/2,0];
d = [0.2,q2+0.2,q3+0.2];
alpha = [0,pi/2,0];
a = [0,0,0];

DH01 = vpa(DHFK(theta(1), d(1), alpha(1), a(1)))
 
DH12 = vpa(DHFK(theta(2), d(2), alpha(2), a(2)))

DH23 = vpa(DHFK(theta(3), d(3), alpha(3), a(3)))

DH03 = simplify(DH01*DH12*DH23)


function [ DH ] = DHFK( theta, d, alpha, a )
%DenavitH Summary of this function goes here
%   Calcula la matriz de Denavit-Hartenberg de una articulacion.
DH=[cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);
    sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);
    0 sin(alpha) cos(alpha) d
    0 0 0 1];
end