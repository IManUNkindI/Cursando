function [P] = ForwKin3R(Q,L)

T0_1=DHFK( 0   , Q(1) + L(1), 0    ,  0 );
T1_2=DHFK( Q(2) -pi/2,0 , -pi/2 ,  0);
T2_3=DHFK( 0   , Q(3) + L(3) + L(2), 0    ,  0 );

T0_3=T0_1*T1_2*T2_3;

P=T0_3(1:3,4);

end
