clc; clear all;
num = [1.273];
den = [1 0.0089];
tfc = tf(num, den)

kp = 0.114;
ki1 = 0.0055;
ki2 = 0.000065;
ki3 = 0.000000385;
T = 52;

q0 = kp + ki1*T + ki2*T^2 + ki3*T^3
q1 = -3*kp -2*ki1*T - ki2*T^2
q2 = 3*kp + ki1*T
q3 = kp

tfd = c2d(tfc, 11)
