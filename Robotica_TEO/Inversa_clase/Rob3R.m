clear;clc;
L=[10 15 15];

R(1)=Link('revolute','d',L(1),'alpha',pi/2,'a',0,'offset',0);
R(2)=Link('revolute','d',0,'alpha',0,'a',L(2),'offset',0);
R(3)=Link('revolute','d',0,'alpha',0,'a',L(3),'offset',0);
Rob=SerialLink(R);

% i=0;
% for q1=-pi/2:pi/20:pi/2
%     for q2=0:pi/20:pi
%         for q3=0:pi/20:pi
%     i=i+1;
%     T=Patroclo.fkine([q1 q2 q3]);
%     Px(i)=T.t(1);
%     Py(i)=T.t(2);
%     Pz(i)=T.t(3);
%         end
%     end
% end
% i
home=[0 0 0];
rad2deg(home)
figure(1)
Rob.plot(home)
zlim([-2 50]);
Rob.teach(home);
hold on
% plot3(Px,Py,Pz,'r.');



P1=[18 13 -9];
Q1=InvKin3R(P1,L);
p1=ForwKin3R(Q1,L);

P2=[-9 14 32];
Q2=InvKin3R(P2,L);
p2=ForwKin3R(Q2,L);


% Q=[0 0 0]
% Rob.plot(Q2)
% zlim([-30 50])
% Rob.teach(Q2)
% view(25,35)


% P1=[-11 4 4];
% Q1=InvKin3R(P2,L)
% p1=ForwKin3R(Q2,L);

%Init Pos and Way Points
% Rob.plot([0 0 0])
% Rob.teach([0 0 0])
% zlim([-5 60])
% view(35,45)
% hold on
% plot3(P1(1),P1(2),P1(3),'r*')
% plot3(P2(1),P2(2),P2(3),'b*')
% 
% pause(5);
% 
% zlim([-5 60])
% view(35,45)

% % Linear Interpolation in the space of joint variables
% q1t=linspace(Q1(1),Q2(1),50)
% q2t=linspace(Q1(2),Q2(2),50)
% q3t=linspace(Q1(3),Q2(3),50)
% for n=1:1:50
% Q=[q1t(n) q2t(n) q3t(n)];
% p=ForwKin3R(Q,L);
% Rob.plot(Q)
% Rob.teach(Q)
% zlim([-5 60])
% view(35,45)    
% hold on
% plot3(p(1),p(2),p(3),'k*')
% drawnow;
% pause(0.1);
% end



% Linear Interpolation in the space of TCP
Pxt=linspace(P1(1),P2(1),50);
Pyt=linspace(P1(2),P2(2),50);
Pzt=linspace(P1(3),P2(3),50);

% for n=1:1:50
% P=[Pxt(n) Pyt(n) Pzt(n)];
% Q(n,:)=InvKin3R(P,L);
% p=ForwKin3R(Q(n,:),L);
% Rob.plot(Q(n,:))
% Rob.teach(Q(n,:))
% zlim([-5 60])
% view(35,45)    
% hold on
% plot3(p(1),p(2),p(3),'k*')
% drawnow;
% pause(0.1);
% end
