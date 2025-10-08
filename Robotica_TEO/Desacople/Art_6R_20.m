%% MODELO DH DE ROBOT 6DoF Completo
clear;clc;clf;
Pai=str2sym('acos(-1)');
syms q1 q2 q3 q4 q5 q6
Ls=[20 20 20 5 5 5];
L=[Ls(1) 0 0 Ls(3)+Ls(4) 0 Ls(5)+Ls(6)];
alpha=[pi/2 0 pi/2 -pi/2 pi/2 0];
a=[0 Ls(2) 0 0 0 0];
ofs=[0 pi/2 0 0 0 0];
lims=[-pi pi];
E6(1) = Revolute('d',L(1),'alpha',alpha(1),'a',a(1),'offset',ofs(1),'qlim',lims);
E6(2) = Revolute('d',L(2),'alpha',alpha(2),'a',a(2),'offset',ofs(2),'qlim',lims);
E6(3) = Revolute('d',L(3),'alpha',alpha(3),'a',a(3),'offset',ofs(3),'qlim',lims);
E6(4) = Revolute('d',L(4),'alpha',alpha(4),'a',a(4),'offset',ofs(4),'qlim',lims);
E6(5) = Revolute('d',L(5),'alpha',alpha(5),'a',a(5),'offset',ofs(5),'qlim',lims);
E6(6) = Revolute('d',L(6),'alpha',alpha(6),'a',a(6),'offset',ofs(6),'qlim',lims);
BOT6=SerialLink(E6,'name','6DoF');
% q=[pi/4 -pi/3 -pi/9 -pi/10 pi/6 pi/3];
% w=50;
% BOT6.teach(q,'scale',0.5,'workspace',[-w w -w w -w w],'rpy');
% zlim([-10 w]);
% view(25,35)

alphas=[Pai/2 0 Pai/2 -Pai/2 Pai/2 0];
ofss=[0 Pai/2 0 0 0 0];

T0_1=MiDH(q1+ofss(1),L(1),alphas(1),a(1));
T1_2=MiDH(q2+ofss(2),L(2),alphas(2),a(2));
T2_3=MiDH(q3+ofss(3),L(3),alphas(3),a(3));
T3_4=MiDH(q4+ofss(4),L(4),alphas(4),a(4));
T4_5=MiDH(q5+ofss(5),L(5),alphas(5),a(5));
T5_6=MiDH(q6+ofss(6),L(6),alphas(6),a(6));

T0_3=T0_1*T1_2*T2_3
T3_6=T3_4*T4_5*T5_6

T0_6=T0_3*T3_6;



%% Selección de la posición y la orientación deseada
Pos_D=[28 40 18]';
Ori_D=deg2rad([-45 0 65]');
% Matriz de rotación de SC0 al SC6
R0_6=rotx(Ori_D(1))*roty(Ori_D(2))*rotz(Ori_D(3))
%% Desacople cinemático
Pos_Cw=Pos_D-R0_6*[0 0 Ls(5)+Ls(6)]'
% Inversa del robot para calcular q1,q2 y q3
[qn,~] = Inversa_Articulado(Pos_Cw,Ls(1),Ls(2),Ls(3)+Ls(4))
% Calculo de la matriz de rotación del SC0 al SC3
E3(1) = Revolute('d',L(1),'alpha',alpha(1),'a',a(1),'offset',ofs(1),'qlim',lims);
E3(2) = Revolute('d',L(2),'alpha',alpha(2),'a',a(2),'offset',ofs(2),'qlim',lims);
E3(3) = Revolute('d',L(3),'alpha',alpha(3),'a',a(3),'offset',ofs(3),'qlim',lims);
BOT3=SerialLink(E3,'name','6DoF_Pos');
T0_3=BOT3.fkine(qn);
R0_3=[T0_3.n T0_3.o T0_3.a] 
% Calculo de la matriz de rotación para la orientación. 
R3_6=inv(R0_3)*R0_6
q4_5_6=tr2eul(R3_6)
%q4=atan2(R3_6(2,3),R3_6(1,3))
%q5=acos(R3_6(3,3))
%q6=atan2(R3_6(3,2),-R3_6(3,1))
% q4_5_6=rotm2eul(R3_6, 'ZYZ')
w=50;
BOT6.teach([qn q4_5_6],'scale',0.5,'workspace',[-w w -w w -w w]);
zlim([-10 w]);
view(25,35);





function [q,q_grados] = Inversa_Articulado(Pos,L1,L2,L3)
t1=atan2(Pos(2),Pos(1));
r=Pos(3)-L1;
m=sqrt((Pos(1)^2)+(Pos(2)^2));
v=sqrt((m^2)+(r^2));
c3=(v^2-L2^2-L3^2)/(2*L2*L3);
s3=sqrt(1-(c3^2));
t3=atan2(s3,c3);
beta=atan2(r,m);
alpha=atan2((L3*sin(t3)),(L2+L3*cos(t3)));
t2=beta-alpha;
q=([t1 t2 t3])
q_grados=rad2deg(q);
end