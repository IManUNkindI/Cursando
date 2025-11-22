clear;clc;
L1=15;
L2=30;
L3=15;
L4=30;
E(1) = Link('revolute','d',L1,'alpha',0,'a',L2,'offset',0);
E(2) = Link('revolute','d',L3,'alpha',0,'a',L4,'offset',0);
Robot=SerialLink(E,'name','ART2R');
q=[0 0];
syms q1 q2 l1 l2 l3 l4
MTH=simplify(Art_2R_fkin([q1 q2],l1,l2,l3,l4));
PosVector=simplify(MTH(1:3,4));
J2R=(jacobian(PosVector,[q1 q2]));
J2R=(J2R(1:2,1:2));
J2Rinv=simplify(inv(J2R));
qin=[pi/3 pi/3]';
qtraj=[0 0]';
for i=1:1:50
i
Thetadot=eval(subs(J2Rinv*[0.5;-0.1],[q1 q2 l1 l2 l3 l4],[qin(1) qin(2) L1 L2 L3 L4]));
qin=qin+Thetadot;
qtraj(1:2,i)=qin;
MTH=Art_2R_fkin(qin,L1,L2,L3,L4);
Robot.plot(qin');
hold on
Px(i)=MTH(1,4);
Py(i)=MTH(2,4);
Pz(i)=MTH(3,4);
plot3(MTH(1,4),MTH(2,4),MTH(3,4),'r.');
pause(0.001)
drawnow();
end

for i=1:1:50
i
Thetadot=eval(subs(J2Rinv*[0.0;-0.5],[q1 q2 l1 l2 l3 l4],[qin(1) qin(2) L1 L2 L3 L4]));
qin=qin+Thetadot;
qtraj(1:2,i)=qin;
MTH=Art_2R_fkin(qin,L1,L2,L3,L4);
Robot.plot(qin');
hold on
Px(i)=MTH(1,4);
Py(i)=MTH(2,4);
Pz(i)=MTH(3,4);
plot3(MTH(1,4),MTH(2,4),MTH(3,4),'r.');
pause(0.001)
drawnow();
end

for i=1:1:50
i
Thetadot=eval(subs(J2Rinv*[-0.5;0.1],[q1 q2 l1 l2 l3 l4],[qin(1) qin(2) L1 L2 L3 L4]));
qin=qin+Thetadot;
qtraj(1:2,i)=qin;
MTH=Art_2R_fkin(qin,L1,L2,L3,L4);
Robot.plot(qin');
hold on
Px(i)=MTH(1,4);
Py(i)=MTH(2,4);
Pz(i)=MTH(3,4);
plot3(MTH(1,4),MTH(2,4),MTH(3,4),'r.');
pause(0.001)
drawnow();
end

for i=1:1:50
i
Thetadot=eval(subs(J2Rinv*[0.0;0.5],[q1 q2 l1 l2 l3 l4],[qin(1) qin(2) L1 L2 L3 L4]));
qin=qin+Thetadot;
qtraj(1:2,i)=qin;
MTH=Art_2R_fkin(qin,L1,L2,L3,L4);
Robot.plot(qin');
hold on
Px(i)=MTH(1,4);
Py(i)=MTH(2,4);
Pz(i)=MTH(3,4);
plot3(MTH(1,4),MTH(2,4),MTH(3,4),'r.');
pause(0.001)
drawnow();
end

function MTH=Art_2R_fkin(q,L1,L2,L3,L4)
T1=MiDH(q(1)+0,L1,0,L2);
T2=MiDH(q(2)+0,L3,0,L4);
MTH=T1*T2;
end