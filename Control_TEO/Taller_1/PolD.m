syms s;
zetha = 0.7;
Wn = 0.01;
exp = 2;
PolDes = (s^2 + 2 * zetha * Wn * s + Wn^2) * (s + 10 * Wn * zetha) ^ exp;
vpa(expand(PolDes), 4)