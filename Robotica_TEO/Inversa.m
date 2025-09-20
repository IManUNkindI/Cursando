%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;
A=2;
D=2;
B=12;
C=10;

R(1) = Link('revolute','offset',0,'d',A,'alpha',0,'a',B);
R(2) = Link('revolute','offset',0,'d',D,'alpha',0,'a',C);
patroclo = SerialLink(R,'name','PARIN');

[Q] = [0 0];
home = Q; 
rad2deg(home)
figure(1)
patroclo.plot(home)
zlim([-2 10])
patroclo.teach(home)