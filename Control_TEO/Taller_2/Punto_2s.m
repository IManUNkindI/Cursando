num = [1 0 -19.62];          % s^2 - 19.62  (coeficientes)
den = [1 0 182.89 0 2616];     % s^4 -21.582 s^2  -> as polynomial s^4 +0 s^3 -21.582 s^2 +0 s +0
G = tf(num, den);
roots(den)