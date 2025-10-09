%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;
L = [200 300 200];
R(1) = Link('prismatic', 'theta', 0, 'offset', L(1), 'alpha', 0, 'a', 0, 'qlim', [0 1200]);
R(2) = Link('revolute',  'd', 0, 'a', 0, 'alpha', -pi/2, 'offset', -pi/2);
R(3) = Link('prismatic', 'theta', 0, 'offset', L(2) + L(3), 'alpha', 0, 'a', 0, 'qlim', [0 1200]); 
Rob3r = SerialLink(R,'name','PARIN');

L6 = [200 300 50 150 50 50];
R6(1) = Link('prismatic', 'theta', 0, 'offset', L6(1), 'alpha', 0, 'a', 0, 'qlim', [0 1200]);
R6(2) = Link('revolute',  'd', 0, 'a', 0, 'alpha', -pi/2, 'offset', -pi/2);
R6(3) = Link('prismatic', 'theta', 0, 'offset', L6(2) + L6(3), 'alpha', 0, 'a', 0, 'qlim', [0 1200]); 
R6(4) = Link('revolute',  'd', L6(4), 'a', 0, 'alpha', pi/2, 'offset', pi/2);
R6(5) = Link('revolute',  'd', 0, 'a', 0, 'alpha', -pi/2, 'offset', 0);
R6(6) = Link('revolute',  'd', L6(6) + L6(5), 'a', 0, 'alpha', 0, 'offset', -pi/2);
Rob6r = SerialLink(R6, 'name', 'PARIN');

LPW = [ 0; 0; L6(5) + L6(6)];
home = [0 0 0 0 0 0];

QEF = [-170 20 170];        % Angulo deseado de la herramienta
RT = rot(QEF);
QEFH = [180 0 -180];
RTH = rot(QEFH);

PHD = [150 -1000 200];          % Punto Home
PWH = PHD' - RTH*LPW;
QH = InvKin3R(PWH,L);
ph = ForwKin3R(QH,L);

P1D = [675 825 1200];       % Punto deseado 1
PW1 = P1D' - RT*LPW;
Q1 = InvKin3R(PW1,L);
p1 = ForwKin3R(Q1,L);

P2D = [525 825 1200];       % Punto deseado 2
PW2 = P2D' - RT*LPW;
Q2 = InvKin3R(PW2,L);
p2 = ForwKin3R(Q2,L);

P3D = [675 975 1200];       % Punto deseado 3
PW3 = P3D' - RT*LPW;
Q3 = InvKin3R(PW3,L);
p3 = ForwKin3R(Q3,L);

P4D = [525 975 1200];       % Punto deseado 4
PW4 = P4D' - RT*LPW;
Q4 = InvKin3R(PW4,L);
p4 = ForwKin3R(Q4,L);

disp("Punto muñeca Home:")
vpa(PWH,5)
disp("Punto muñeca 1:")
vpa(PW1,5)
disp("Punto muñeca 2:")
vpa(PW2,5)
disp("Punto muñeca 3:")
vpa(PW3,5)
disp("Punto muñeca 4:")
vpa(PW4,5)

rad2deg(QH(2));
rad2deg(Q1(2));
rad2deg(Q2(2));
rad2deg(Q3(2));
rad2deg(Q4(2));

% figure(1)
% Rob3r.plot(Q3)
% zlim([-50 1750])
% Rob3r.teach(Q3)
% hold on
% plot3(p1(1),p1(2),p1(3),'r*')
% plot3(p2(1),p2(2),p2(3),'b*')
% plot3(p3(1),p3(2),p3(3),'g*')
% plot3(p4(1),p4(2),p4(3),'y*')
T0_3QH = Rob3r.fkine(QH);
R0_3QH = [T0_3QH.n T0_3QH.o T0_3QH.a];
R3_6QH = R0_3QH \ RTH;
eulQH = rotm2eul(R3_6QH, "ZXZ");

T0_3Q1 = Rob3r.fkine(Q1);
R0_3Q1 = [T0_3Q1.n T0_3Q1.o T0_3Q1.a];
R3_6Q1 = R0_3Q1 \ RT;
eulQ1 = rotm2eul(R3_6Q1, "ZXZ");

T0_3Q2 = Rob3r.fkine(Q2);
R0_3Q2 = [T0_3Q2.n T0_3Q2.o T0_3Q2.a];
R3_6Q2 = R0_3Q2 \ RT;
eulQ2 = rotm2eul(R3_6Q2, "ZXZ");

T0_3Q3 = Rob3r.fkine(Q3);
R0_3Q3 = [T0_3Q3.n T0_3Q3.o T0_3Q3.a];
R3_6Q3 = R0_3Q3 \ RT;
eulQ3 = rotm2eul(R3_6Q3, "ZXZ");

T0_3Q4 = Rob3r.fkine(Q4);
R0_3Q4 = [T0_3Q4.n T0_3Q4.o T0_3Q4.a];
R3_6Q4 = R0_3Q4 \ RT;
eulQ4 = rotm2eul(R3_6Q4, "ZXZ");

QHT = [QH eulQH];
Q1T = [Q1 eulQ1];
Q2T = [Q2 eulQ2];
Q3T = [Q3 eulQ3];
Q4T = [Q4 eulQ4];

disp("Angulos de Euler Home:")
vpa(rad2deg(eulQH),5)
disp("Angulos de Euler 1:")
vpa(rad2deg(eulQ1),5)
disp("Angulos de Euler 2:")
vpa(rad2deg(eulQ2),5)
disp("Angulos de Euler 3:")
vpa(rad2deg(eulQ3),5)
disp("Angulos de Euler 4:")
vpa(rad2deg(eulQ4),5)

figure(2)
Rob6r.plot(QHT)
zlim([-50 1750])
Rob6r.teach(QHT)
hold on
plot3(PHD(1),PHD(2),PHD(3),'k*')
plot3(P1D(1),P1D(2),P1D(3),'r*')
plot3(P2D(1),P2D(2),P2D(3),'b*')
plot3(P3D(1),P3D(2),P3D(3),'g*')
plot3(P4D(1),P4D(2),P4D(3),'y*')


% Linear Interpolation in the space of joint variables
q1t=linspace(QHT(1),Q1T(1),25);
q2t=linspace(QHT(2),Q1T(2),25);
q3t=linspace(QHT(3),Q1T(3),25);
q4t=linspace(QHT(4),Q1T(4),25);
q5t=linspace(QHT(5),Q1T(5),25);
q6t=linspace(QHT(6),Q1T(6),25);
for n=1:1:25
Q=[q1t(n) q2t(n) q3t(n) q4t(n) q5t(n) q6t(n)];
p=ForwKin3R(Q,L);
Rob6r.plot(Q)
Rob6r.teach(Q)
zlim([-50 1750])
view(35,45)    
hold on
plot3(p(1),p(2),p(3),'r*')
drawnow;
pause(0.01);
end

% Linear Interpolation in the space of joint variables
q1t=linspace(Q2T(1),QHT(1),25);
q2t=linspace(Q2T(2),QHT(2),25);
q3t=linspace(Q2T(3),QHT(3),25);
q4t=linspace(Q2T(4),QHT(4),25);
q5t=linspace(Q2T(5),QHT(5),25);
q6t=linspace(Q2T(6),QHT(6),25);
for n=1:1:25
Q=[q1t(n) q2t(n) q3t(n) q4t(n) q5t(n) q6t(n)];
p=ForwKin3R(Q,L);
Rob6r.plot(Q)
Rob6r.teach(Q)
zlim([-50 1750])
view(35,45)    
hold on
plot3(p(1),p(2),p(3),'b*')
drawnow;
pause(0.01);
end

% Linear Interpolation in the space of joint variables
q1t=linspace(QHT(1),Q3T(1),25);
q2t=linspace(QHT(2),Q3T(2),25);
q3t=linspace(QHT(3),Q3T(3),25);
q4t=linspace(QHT(4),Q3T(4),25);
q5t=linspace(QHT(5),Q3T(5),25);
q6t=linspace(QHT(6),Q3T(6),25);
for n=1:1:25
Q=[q1t(n) q2t(n) q3t(n) q4t(n) q5t(n) q6t(n)];
p=ForwKin3R(Q,L);
Rob6r.plot(Q)
Rob6r.teach(Q)
zlim([-50 1750])
view(35,45)    
hold on
plot3(p(1),p(2),p(3),'g*')
drawnow;
pause(0.01);
end

% Linear Interpolation in the space of joint variables
q1t=linspace(Q4T(1),QHT(1),25);
q2t=linspace(Q4T(2),QHT(2),25);
q3t=linspace(Q4T(3),QHT(3),25);
q4t=linspace(Q4T(4),QHT(4),25);
q5t=linspace(Q4T(5),QHT(5),25);
q6t=linspace(Q4T(6),QHT(6),25);
for n=1:1:25
Q=[q1t(n) q2t(n) q3t(n) q4t(n) q5t(n) q6t(n)];
p=ForwKin3R(Q,L);
Rob6r.plot(Q)
Rob6r.teach(Q)
zlim([-50 1750])
view(35,45)    
hold on
plot3(p(1),p(2),p(3),'y*')
drawnow;
pause(0.01);
end

function T = rot(QD)

    theta_x = deg2rad(QD(1));
    theta_y = deg2rad(QD(2));
    theta_z = deg2rad(QD(3));

    % Matrices de rotación elemental
    Rx = [1,            0,             0;
          0, cos(theta_x), -sin(theta_x);
          0, sin(theta_x),  cos(theta_x)];

    Ry = [cos(theta_y),  0, sin(theta_y);
                     0,  1,            0;
          -sin(theta_y), 0, cos(theta_y)];

    Rz = [cos(theta_z), -sin(theta_z), 0;
          sin(theta_z),  cos(theta_z), 0;
          0           ,             0, 1];

    T = Rx * Ry * Rz;
end
function [Q] = InvKin3R(P, L)

Px=P(1);
Py=P(2);
Pz=P(3);

q2 = pi/2 - atan2(Px,Py);

m  = sqrt(Px^2+Py^2);
q3 = m - 500;

q1 = Pz - 200;


Q = [q1 q2 q3];
end
function [ DH ] = DHFK( theta, d, alpha, a )
%   Calcula la matriz de Denavit-Hartenberg de una articulacion.
DH=[cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);
    sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);
    0 sin(alpha) cos(alpha) d
    0 0 0 1];
end
function [P] = ForwKin3R(Q,L)

T0_1=DHFK( 0   , Q(1) + L(1), 0    ,  0 );
T1_2=DHFK( Q(2) -pi/2,0 , -pi/2 ,  0);
T2_3=DHFK( 0   , Q(3) + L(3) + L(2), 0    ,  0 );

T0_3=T0_1*T1_2*T2_3;

P=T0_3(1:3,4);

end
