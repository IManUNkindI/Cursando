function [ DH ] = DHFK( theta, d, alpha, a )
%DenavitH Summary of this function goes here
%   Calcula la matriz de Denavit-Hartenberg de una articulacion.
DH=[cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);
    sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);
    0 sin(alpha) cos(alpha) d
    0 0 0 1];
end
