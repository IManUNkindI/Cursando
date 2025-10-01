%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;
L = [0.10 0.12 0.11]

R(1) = Link('revolute' ,'offset', 0, 'd', L(1), 'alpha', 0, 'a', 0);
R(2) = Link('prismatic', 'theta', pi/2, 'a', 0, 'alpha', pi/2, 'qlim',[L(2) L(2)+0.1]);  
R(3) = Link('prismatic', 'theta', 0, 'a', 0, 'alpha', 0, 'qlim',[L(3) L(3)+0.1]);
robot = SerialLink(R,'name','PARIN');

[Q] = [0 0.12 0.11];
home = Q; 
rad2deg(home)
figure(1)
robot.plot(home)
zlim([0 0.5])
robot.teach(home)

P1 = [0.12 0.11 0.31];
Q1 = InvKin3R(P1,L);
P2 = [-0.14 0.07 0.25];
Q2 = InvKin3R(P2,L);
P3 = [-0.16 -0.12 0.41];
Q3 = InvKin3R(P3,L);