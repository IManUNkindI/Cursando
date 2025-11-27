clc; clear all;
num = [0.1727];
den = [1 2.164 1467.91];
tfc = tf(num, den)

kd = 48.616;
kp = -8405.61;
ki = 39.46;
T = 1.988;

q0 = (kd/T) + kp + (ki*T)
q1 = - (2*kd/T) - kp 
q2 = kd/T

tfd = c2d(tfc, 0.09)