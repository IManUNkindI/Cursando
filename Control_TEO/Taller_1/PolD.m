syms s;
zetha = 1.2;
Wn = 0.344;
exp = 3;
PolDes = (s^2 + 2 * zetha * Wn * s + Wn^2) * (s + 10 * Wn * zetha) ^ exp;
vpa(expand(PolDes), 4)