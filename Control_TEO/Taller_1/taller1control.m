syms s kp ki ki2 ki3 ki4 ki5 kd kd2 kd3 kd4 kd5;

tf_den = -0.303; 
tf_num = s^3 + 10.39*s^2 + 94.58*s + 909.091;
tf = tf_den / tf_num;
pretty(vpa(tf , 4))

PID_den = kd*s^4 + kd2*s^3 + kp*s^2 + ki*s + ki2;
PID_num = s^2;
PID = PID_den / PID_num;
pretty(PID)

tf_PID = tf_den * PID_den + tf_num * PID_num;
vpa(collect(expand(tf_PID) , s) , 4)
