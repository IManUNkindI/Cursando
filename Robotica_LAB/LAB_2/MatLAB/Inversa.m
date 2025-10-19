%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;
L = [105.28 120 155.25];
R(1) = Link('revolute',  'd', L(1), 'a', 0, 'alpha', pi/2, 'offset', pi);
R(2) = Link('revolute',  'd', 0, 'a', L(2), 'alpha', 0, 'offset', 0);
R(3) = Link('revolute',  'd', 0, 'a', L(3), 'alpha', 0, 'offset', -pi/2);

Rob3r = SerialLink(R,'name','PARIN');

L5 = [105.28 120 89.75 65.5 38];
R5(1) = Link('revolute',  'd', L5(1), 'a', 0, 'alpha', pi/2, 'offset', pi);
R5(2) = Link('revolute',  'd', 0, 'a', L5(2), 'alpha', 0, 'offset', 0);
R5(3) = Link('revolute',  'd', 0, 'a', 0, 'alpha', pi/2, 'offset', 0);
R5(4) = Link('revolute',  'd', L5(4)+L5(3), 'a', 0, 'alpha', pi/2, 'offset', 0);
R5(5) = Link('revolute',  'd', 0, 'a', L5(5), 'alpha', 0, 'offset', pi);
Rob5r = SerialLink(R5, 'name', 'PARIN');

LPW = [ 0; 0; L5(5)];
home = [0 0 0 0 0];



P1D = [0 -250 10];       % Punto deseado 1
Q1F = [0 0 rad2deg(atan(P1D(2)/P1D(1)))];        % Angulo deseado de la herramienta
RT1 = rot(Q1F);
PW1 = P1D' + RT1*LPW;
Q1 = InvKin3R(PW1,L);



P2D = [200 -120 150];       % Punto deseado 2
Q2F = [0 0 rad2deg(atan(P2D(2)/P2D(1)))];        % Angulo deseado de la herramienta
RT2 = rot(Q2F);
PW2 = P2D' + RT2*LPW;
Q2 = InvKin3R(PW2,L);

disp("Punto muñeca 1:")
vpa(PW1,5)
disp("Punto muñeca 2:")
vpa(PW2,5)

T0_3Q1 = Rob3r.fkine(Q1);
R0_3Q1 = [T0_3Q1.n T0_3Q1.o T0_3Q1.a];
R3_6Q1 = R0_3Q1 \ RT1;
eulQ1 = rotm2eul(R3_6Q1, "YXY");

T0_3Q2 = Rob3r.fkine(Q2);
R0_3Q2 = [T0_3Q2.n T0_3Q2.o T0_3Q2.a];
R3_6Q2 = R0_3Q2 \ RT2;
eulQ2 = rotm2eul(R3_6Q2, "YXY");

Q1T = [Q1 eulQ1(1) eulQ1(3)]
Q2T = [Q2 eulQ2(1) eulQ2(3)]

disp("Angulos de Euler 1:")
vpa(rad2deg(eulQ1),5)
disp("Angulos de Euler 2:")
vpa(rad2deg(eulQ2),5)

figure(2)
Rob5r.plot(Q1T)
zlim([-10 400])
Rob5r.teach(Q1T)
hold on
plot3(P1D(1),P1D(2),P1D(3),'r*')
plot3(P2D(1),P2D(2),P2D(3),'g*')

% Linear Interpolation in the space of joint variables
q1t=linspace(Q1T(1),Q2T(1),25);
q2t=linspace(Q1T(2),Q2T(2),25);
q3t=linspace(Q1T(3),Q2T(3),25);
q4t=linspace(Q1T(4),Q2T(4),25);
q5t=linspace(Q1T(5),Q2T(5),25);
for n=1:1:25
Q=[q1t(n) q2t(n) q3t(n) q4t(n) q5t(n)];
Rob5r.plot(Q)
Rob5r.teach(Q)
zlim([-10 500])
view(35,45)    
hold on
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

if(P(2)==0)
    q1 = pi + atan2(Py,Px);
    
    m2 = sqrt(Py^2 + Px^2);
    m1 = sqrt((Pz-L(1))^2 + m2^2);
    q2 = atan2((Pz-L(1)),m2) + acos(((m1^2) + (L(2)^2) - (L(3)^2))/(2*L(2)*m1));

    q3 = acos(((L(2)^2) + (L(3)^2) - (m1^2))/(2*L(2)*L(3))) - pi/2;
else
    q1 = pi + atan2(Py,Px);

    m2 = sqrt(Py^2 + Px^2);
    m1 = sqrt((Pz-L(1))^2 + m2^2);
    q2 = atan((Pz-L(1))/m2) + acos(((m1^2) + (L(2)^2) - (L(3)^2))/(2*L(2)*m1));

    q3 = acos(((L(2)^2) + (L(3)^2) - (m1^2))/(2*L(2)*L(3))) - pi/2;
end

Q = [q1 q2 q3];
end
