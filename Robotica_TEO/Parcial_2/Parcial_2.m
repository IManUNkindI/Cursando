%run('C:\Semestre\Cursando\Robotica_TEO\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m');
clear;clc;
L = [200 300 200];

R(1) = Link('prismatic', 'theta', 0, 'a', 0, 'alpha', 0, 'offset', L(1), 'qlim', [0 100]);  
R(2) = Link('revolute' , 'offset', 0, 'd', 0, 'alpha', 0, 'a', L(2));
R(3) = Link('prismatic', 'theta', 0, 'a', 0, 'alpha', 0, 'offset', L(3), 'qlim', [0 100]);
Rob = SerialLink(R,'name','PARIN');

P1 = [640.79 808.68 212.59];
Q1 = InvKin3R(P1,L);
p1 = ForwKin3R(Q1,L);

P2 = [0 0 0];
Q2 = InvKin3R(P2,L);
p2 = ForwKin3R(Q2,L);

P3 = [-16 -12 41];
Q3 = InvKin3R(P3,L);
p3 = ForwKin3R(Q3,L);

rad2deg(Q1(2));
rad2deg(Q2(2));
rad2deg(Q3(2));


figure(1)
Rob.plot(P2)
zlim([0 500])
Rob.teach(P2)
hold on
plot3(p1(1),p1(2),p1(3),'r*')
plot3(p2(1),p2(2),p2(3),'b*')
plot3(p3(1),p3(2),p3(3),'g*')


% % Linear Interpolation in the space of joint variables
% q1t=linspace(Q1(1),Q2(1),25)
% q2t=linspace(Q1(2),Q2(2),25)
% q3t=linspace(Q1(3),Q2(3),25)
% for n=1:1:25
% Q=[q1t(n) q2t(n) q3t(n)];
% p=ForwKin3R(Q,L);
% Rob.plot(Q)
% Rob.teach(Q)
% zlim([-5 60])
% view(35,45)    
% hold on
% plot3(p(1),p(2),p(3),'r*')
% drawnow;
% pause(0.1);
% end

% % Linear Interpolation in the space of TCP
% Pxt=linspace(P2(1),P3(1),25);
% Pyt=linspace(P2(2),P3(2),25);
% Pzt=linspace(P2(3),P3(3),25);
% 
% for n=1:1:25
% P=[Pxt(n) Pyt(n) Pzt(n)];
% Q(n,:)=InvKin3R(P,L);
% p=ForwKin3R(Q(n,:),L);
% Rob.plot(Q(n,:))
% Rob.teach(Q(n,:))
% zlim([-5 60])
% view(35,45)    
% hold on
% plot3(p(1),p(2),p(3),'g*')
% drawnow;
% pause(0.1);
% end