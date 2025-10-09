%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;
L = [3 8];

R(1) = Link('prismatic', 'theta', 0, 'a', 0, 'alpha', pi/2, 'offset', L(1), 'qlim', [0 10]);
R(2) = Link('revolute' ,'offset', pi/2, 'd', 0, 'alpha', 0, 'a', L(2));
Rob = SerialLink(R,'name','PARIN');

home = [0 0];

P1 = [11 0 0];
Q1 = InvKin3R(P1,L);


figure(1)
Rob.plot(Q1)
zlim([-10 25])
view(0,0) 
Rob.teach(Q1)
hold on

for n=0:1:10  
    for m=0:1:60
        w = 90 - m*3;
        P = [L(2)*sin(w) L(1)+n+L(2)*cos(w)];
        if(P(1)<0 && P(2)>L(1)+n-7)
            plot3(P(1),0,P(2),'r*')
        end
    end
end

function [Q] = InvKin3R(P, L)

Pz=P(1);
Py=P(2);
Px=P(3);

q2 = acos(Px/L(2)) - pi/2;

q1 = Pz - L(1) - (L(2)*sin(q2 + pi/2));

Q = [q1 q2];
end