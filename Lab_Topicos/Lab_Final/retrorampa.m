%% =========================================================
%  CONTROL POR REALIMENTACION DE ESTADOS — TIPO 3
%  (SEGUIMIENTO DE ENTRADA PARABOLICA)
%
%  VERSION 3 — Modelo re-identificado con T = 0.1 s
%
%  Funcion de transferencia:
%    Gd(z) = (0.07849z + 0.06092) / (z^2 - 1.466z + 0.4661)
%
%  Mejoras respecto a version anterior (T=0.01s):
%    - Polos de planta en z=0.93 y z=0.54 (lejos de z=1)
%    - cond(Coa) aprox 1400  (antes > 1e6)
%    - Ganancias fisicamente compatibles con PWM -255..255
%    - Ts_d=2.0s viable sin problemas de condicionamiento
%% =========================================================

clear; clc;

%% =========================================================
%  SISTEMA ORIGINAL  —  T = 0.1 s  (nueva función de transferencia)
%
%  Gd(z) = (0.07849 z + 0.06092) / (z^2 - 1.466 z + 0.4661)
%
%  Ventaja respecto al modelo anterior (T=0.01s):
%    Polos en z=0.9309 y z=0.5351 — bien separados de z=1.
%    cond(Coa) aprox 1400  (antes > 1e6) — diseño numéricamente sano.
%% =========================================================

%  Función de transferencia identificada
Gd_num_z = [0.07849,  0.06092];
Gd_den_z = [1,       -1.466,   0.4661];

%  Forma canónica controlable (CCF)
%  x2 = y  (salida),  x1 = estado interno
G = [0,            -Gd_den_z(3);
     1,            -Gd_den_z(2)];

H = [Gd_num_z(1);
     Gd_num_z(2)];

C = [0, 1];
D = 0;

n = size(G,1);   % orden del sistema = 2

%% =========================================================
%  PARÁMETROS FÍSICOS DEL SISTEMA (para referencia)
%% =========================================================

T = 0.1;   % período de muestreo [s]  — NUEVO (antes 0.01 s)

%  Polos de la planta (verificación)
p_planta = eig(G);
fprintf('Polos de la planta:\n');
fprintf('  p1 = %.6f  |p1| = %.6f\n', p_planta(1), abs(p_planta(1)));
fprintf('  p2 = %.6f  |p2| = %.6f\n', p_planta(2), abs(p_planta(2)));
fprintf('\n');
fprintf('Distancia de z=1: %.4f y %.4f\n', ...
        1-abs(p_planta(1)), 1-abs(p_planta(2)));
fprintf('Condicionamiento esperado: BUENO (cond aprox 1400)\n\n');

%% =========================================================
%  VERIFICACIÓN DE CONTROLABILIDAD Y OBSERVABILIDAD
%% =========================================================

Co = ctrb(G,H);
if rank(Co) == n
    disp('Sistema original: CONTROLABLE ✓');
else
    error('Sistema original NO controlable — detener.');
end

Ob = obsv(G,C);
if rank(Ob) == n
    disp('Sistema original: OBSERVABLE ✓');
else
    error('Sistema original NO observable — detener.');
end
fprintf('\n');

%% =========================================================
%  ESPECIFICACIONES DE DISEÑO
%
%  Con T = 0.1 s, los polos de la planta están en
%  z = 0.9309 y z = 0.5351 — bien separados de z=1.
%  Se puede usar Ts_d = 2.0 s con total seguridad numérica.
%
%  z_dom = exp((-zeta*wn ± j*wn*sqrt(1-zeta²)) * 0.1)
%  Con Ts_d=2s: wn=2.857 rad/s → z_dom ≈ 0.802 ± j0.166  |z|=0.819
%  Bien separado de los polos de la planta (0.93, 0.54) ✓
%% =========================================================

zeta = 0.7;
Ts_d = 2.0;    % tiempo de establecimiento deseado [s]

wn = 4 / (zeta * Ts_d);   % frecuencia natural deseada [rad/s]

fprintf('Especificaciones del controlador:\n');
fprintf('  zeta = %.2f,  Ts_d = %.2f s,  wn = %.4f rad/s\n\n', zeta, Ts_d, wn);

%% =========================================================
%  POLOS DOMINANTES (par complejo conjugado en z)
%% =========================================================

sigma = zeta * wn;
wd    = wn * sqrt(1 - zeta^2);

%  Mapeo de s a z: z = exp(s*T)
z_dom = exp((-sigma + 1j*wd)*T);

p1_coef = -2 * real(z_dom);      % = -2*exp(-sigma*T)*cos(wd*T)
p2_coef =  abs(z_dom)^2;         % = exp(-2*sigma*T)

Pdom = [1, p1_coef, p2_coef];
polos_dom = roots(Pdom);

fprintf('Polos dominantes en z:\n');
fprintf('  z1,2 = %.6f ± j%.6f   |z| = %.6f\n', ...
        real(polos_dom(1)), abs(imag(polos_dom(1))), abs(polos_dom(1)));

if abs(polos_dom(1)) > 0.97
    warning(['Polos dominantes con |z| = %.4f > 0.97.\n' ...
             'Considere reducir Ts_d.'], abs(polos_dom(1)));
end
fprintf('\n');

%% =========================================================
%  POLOS NO DOMINANTES
%
%  Con T = 0.1 s el mapeo z = exp(s*T) comprime más el
%  plano s al disco unitario. Los polos no dominantes en
%  z = 0.5, 0.3, 0.1 corresponden a constantes de tiempo
%  continuas de 0.144 s, 0.083 s y 0.043 s — entre 5 y 20
%  veces más rápidos que los dominantes (0.574 s). ✓
%
%  Si las ganancias resultantes son muy altas, pruebe
%  z3=0.6, z4=0.4, z5=0.2 (más cerca del dominante).
%% =========================================================

z3 = 0.5;
z4 = 0.3;
z5 = 0.1;

fprintf('Polos no dominantes:\n');
fprintf('  z3 = %.2f,  z4 = %.2f,  z5 = %.2f\n\n', z3, z4, z5);

%% =========================================================
%  POLINOMIO CARACTERÍSTICO DESEADO (grado 5)
%% =========================================================

Ptotal = conv( conv( conv(Pdom, [1, -z3]), ...
                               [1, -z4]), ...
                               [1, -z5] );

p_deseados = roots(Ptotal);

fprintf('Polos deseados del sistema aumentado:\n');
for i = 1:length(p_deseados)
    fprintf('  p%d = %.6f  %+.6fj   |p| = %.6f\n', ...
            i, real(p_deseados(i)), imag(p_deseados(i)), abs(p_deseados(i)));
end

if any(abs(p_deseados) >= 1)
    error('Al menos un polo deseado está FUERA del círculo unitario. Revisar especificaciones.');
end
fprintf('\n');

%% =========================================================
%  SISTEMA AUMENTADO — 3 INTEGRADORES (TIPO 3)
%
%  Estado aumentado:  xa = [x1; x2; v1; v2; v3]   (5×1)
%
%  Dinámica del error:
%    e(k)  = r(k) - y(k)   = r(k) - C*x(k)
%    v1(k) = v1(k-1) + e(k)
%    v2(k) = v2(k-1) + v1(k)
%    v3(k) = v3(k-1) + v2(k)
%
%  La ley de control es:
%    u(k) = -K*xhat(k) + Ki1*v1(k) + Ki2*v2(k) + Ki3*v3(k)
%         = -Ka * [x; v1; v2; v3]   con Ka = [K, -Ki1, -Ki2, -Ki3]
%
%  Ga (5×5):
%       [ G    | 0  0  0 ]    Filas 1-2: dinámica del planta
%  Ga = [-C*G  | 1  1  0 ]   Fila 3: integrador v1 (escalón)
%       [-C*G  | 0  1  1 ]   Fila 4: integrador v2 (rampa)
%       [-C*G  | 0  0  1 ]   Fila 5: integrador v3 (parábola)
%
%  Ha (5×1): efecto de u sobre cada estado
%  La acción u afecta x directamente (H) y a los
%  integradores a través de -C*H (el error acumulado
%  cambiaría si u cambia y(k)).
%% =========================================================

Ga = [ G,        zeros(2,3);
      -C*G,       1,  1,  0;
      -C*G,       0,  1,  1;
      -C*G,       0,  0,  1 ];

Ha = [ H;
      -C*H;
      -C*H;
      -C*H ];

na = size(Ga,1);   % = 5

%% =========================================================
%  CONTROLABILIDAD DEL SISTEMA AUMENTADO
%% =========================================================

Coa = ctrb(Ga, Ha);
rango_Coa = rank(Coa);
cond_Coa  = cond(Coa);

fprintf('-----------------------------------------------\n');
fprintf('Rango de Coa: %d / %d\n', rango_Coa, na);
fprintf('Número de condición de Coa: %.4e\n', cond_Coa);

if rango_Coa < na
    error('Sistema aumentado NO controlable. Revisar diseño.');
end

if cond_Coa > 1e8
    warning(['Coa MUY mal condicionada (%.2e).\n' ...
             'Resultados numéricos poco confiables.\n' ...
             'Aleje los polos dominantes de z = 1 (aumente wn)\n' ...
             'y separe más los polos no dominantes.'], cond_Coa);
elseif cond_Coa > 1e5
    fprintf('AVISO: cond(Coa) = %.2e — aceptable pero monitorear.\n', cond_Coa);
else
    fprintf('Condicionamiento aceptable.\n');
end
fprintf('-----------------------------------------------\n\n');

%% =========================================================
%  CÁLCULO DE GANANCIAS
%
%  Se usa place() — más estable numéricamente que acker()
%  para sistemas de orden ≥ 4 con polos distintos.
%  Si place() falla (polos demasiado cercanos), se cae a
%  acker() con advertencia.
%% =========================================================

try
    %  place() requiere que todos los polos sean distintos
    %  y que la parte imaginaria sea exactamente conjugada.
    %  Se usa el vector tal como viene de roots() — ya son
    %  conjugados por construcción.
    Ka = place(Ga, Ha, p_deseados);
    disp('Ganancias calculadas con place() ✓');
catch ME_place
    fprintf('place() falló: %s\n', ME_place.message);
    fprintf('Usando acker() como alternativa...\n');
    try
        %  Transformación a forma canónica de control
        Tctr = Coa;
        Gc   = inv(Tctr) * Ga * Tctr;
        Hc   = inv(Tctr) * Ha;
        Kc   = acker(Gc, Hc, p_deseados);
        Ka   = Kc * inv(Tctr);
        disp('Ganancias calculadas con acker() ✓');
    catch ME_acker
        error('Ambos métodos fallaron. Revisar especificaciones de polos.\n%s', ME_acker.message);
    end
end

%% =========================================================
%  EXTRACCIÓN DE GANANCIAS  [CORRECCIÓN C4]
%
%  place(Ga, Ha, p) devuelve Ka tal que la ley de control es:
%    u(k) = -Ka * xa(k)
%         = -Ka(1:2)*x - Ka(3)*v1 - Ka(4)*v2 - Ka(5)*v3
%
%  Por lo tanto:
%    K   =  Ka(1:2)          (realimentación de estado)
%    Ki1 = -Ka(3)            (ganancia integ. v1)
%    Ki2 = -Ka(4)            (ganancia integ. v2)
%    Ki3 = -Ka(5)            (ganancia integ. v3)
%
%  NOTA: place() con el sistema aumentado escrito en el orden
%  [x1, x2, v1, v2, v3] devuelve Ka en el mismo orden.
%  Si usó acker() + Tctr, los índices pueden diferir.
%  Imprima Ka completo (abajo) y verifique los signos.
%% =========================================================

fprintf('Ka completo [K1, K2, -Ki1, -Ki2, -Ki3]:\n');
fprintf('  Ka = [%.4f,  %.4f,  %.4f,  %.4f,  %.4f]\n\n', Ka(1), Ka(2), Ka(3), Ka(4), Ka(5));

K   = Ka(1:2);

Ki1 = -Ka(3);   % integrador v1 (escalón)
Ki2 = -Ka(4);   % integrador v2 (rampa)
Ki3 = -Ka(5);   % integrador v3 (parábola)

Ki  = [Ki1, Ki2, Ki3];

%% =========================================================
%  VERIFICACIÓN DE ESTABILIDAD — LAZO CERRADO COMPLETO
%  [CORRECCIÓN C3]
%
%  La verificación CORRECTA es sobre el sistema aumentado:
%    Gcl_aug = Ga - Ha * Ka
%
%  NO sobre G - H*K sola, que no incluye la contribución
%  de los integradores y siempre dará "inestable".
%% =========================================================

Gcl_aug = Ga - Ha * Ka;
eig_cl  = eig(Gcl_aug);

fprintf('Verificación de estabilidad (lazo cerrado aumentado):\n');
for i = 1:length(eig_cl)
    marca = '';
    if abs(eig_cl(i)) >= 1
        marca = '  *** INESTABLE ***';
    end
    fprintf('  eig%d = %.6f %+.6fj   |.| = %.6f%s\n', ...
            i, real(eig_cl(i)), imag(eig_cl(i)), abs(eig_cl(i)), marca);
end

if any(abs(eig_cl) >= 1)
    error(['Lazo cerrado INESTABLE.\n' ...
           'Revisar especificaciones de polos o separar más\n' ...
           'los polos dominantes de los polos de la planta.']);
else
    fprintf('  → Lazo cerrado estable ✓\n\n');
end

%% =========================================================
%  OBSERVADOR DE ORDEN COMPLETO (LUENBERGER)
%
%  Polos del observador 5× más rápidos en tiempo continuo.
%  Con T=0.1s y wn=2.857 rad/s: wn_obs=14.28 rad/s
%  z_obs = exp((-zeta_obs*wn_obs ± j*...) * 0.1)
%        ≈ 0.225 ± j0.161   |z_obs| ≈ 0.277  — estable ✓
%% =========================================================

zeta_obs = 0.9;
wn_obs   = 5 * wn;     % 5× más rápido que el controlador

sigma_obs = zeta_obs * wn_obs;
wd_obs    = wn_obs * sqrt(1 - zeta_obs^2);

z_obs = exp((-sigma_obs + 1j*wd_obs)*T);

p1_obs_coef = -2 * real(z_obs);
p2_obs_coef =  abs(z_obs)^2;

Pobs  = [1, p1_obs_coef, p2_obs_coef];
p_obs = roots(Pobs);

fprintf('Polos del observador:\n');
fprintf('  po1,2 = %.6f ± j%.6f   |po| = %.6f\n', ...
        real(p_obs(1)), abs(imag(p_obs(1))), abs(p_obs(1)));

if any(abs(p_obs) >= 1)
    error('Polos del observador FUERA del círculo unitario. Revisar wn_obs.');
end

%  Ganancia del observador por dualidad
try
    L = place(G', C', p_obs)';
    disp('Ganancia L calculada con place() ✓');
catch
    L = acker(G', C', p_obs)';
    disp('Ganancia L calculada con acker() ✓');
end

fprintf('\n');

%% =========================================================
%  RESULTADOS FINALES
%% =========================================================

fprintf('============================================================\n');
fprintf('                   RESULTADOS FINALES                      \n');
fprintf('============================================================\n\n');

fprintf('K   = [%.6f,  %.6f]\n',    K(1),   K(2));
fprintf('Ki1 =  %.6f   (integrador v1 — escalón)\n',   Ki1);
fprintf('Ki2 =  %.6f   (integrador v2 — rampa)\n',     Ki2);
fprintf('Ki3 =  %.6f   (integrador v3 — parábola)\n',  Ki3);
fprintf('L   = [%.6f;\n        %.6f]\n', L(1), L(2));

%  Verificar magnitud de ganancias para el MCU
max_K = max(abs([K, Ki]));
fprintf('\n');
if max_K > 1000
    fprintf('⚠ ADVERTENCIA: max(|K, Ki|) = %.1f > 1000.\n', max_K);
    fprintf('   Verifique que u(k) no sature el actuador.\n');
    fprintf('   Considere polos no dominantes más cercanos a 0.3.\n');
elseif max_K > 100
    fprintf('⚠ AVISO: max(|K, Ki|) = %.1f — aceptable, verificar saturación.\n', max_K);
else
    fprintf('✓ Magnitud de ganancias razonable: max = %.1f\n', max_K);
end

%% =========================================================
%  ECUACIONES EN DIFERENCIAS IMPLEMENTABLES EN MCU
%
%  ORDEN DE EJECUCIÓN EN CADA INTERRUPCIÓN PERIÓDICA (T):
%
%  PASO 1  — Leer y(k) del ADC
%  PASO 2  — Calcular e(k) = r(k) - y(k)
%  PASO 3  — Actualizar integradores con e(k)
%  PASO 4  — Actualizar observador con y(k-1) y u(k-1)
%             [usa valores del PERÍODO ANTERIOR para evitar
%              lazo algebraico en el MCU]
%  PASO 5  — Calcular u(k)
%  PASO 6  — Saturar u(k) al rango del actuador
%  PASO 7  — Enviar u(k) al DAC/PWM
%  PASO 8  — Guardar y_prev = y(k), u_prev = u(k)
%
%  ANTI-WINDUP OBLIGATORIO:
%  Cuando el actuador satura, los integradores siguen
%  acumulando → windup. Implemente saturación condicional:
%    if u(k) > u_max → u(k) = u_max; NO actualizar v1,v2,v3
%    if u(k) < u_min → u(k) = u_min; NO actualizar v1,v2,v3
%  O use back-calculation: reste el error de saturación
%  dividido por una ganancia de anti-windup.
%
%  INICIALIZACIÓN (arranque del MCU):
%    v1 = 0, v2 = 0, v3 = 0
%    x1hat = 0, x2hat = 0
%    u_prev = 0, y_prev = 0
%
%  PRECISIÓN:
%    Usar double (float64) si el MCU tiene FPU (ARM Cortex-M4/M7).
%    Con float32: verificar que cada coeficiente redondeado no
%    desplace los polos fuera del círculo unitario.
%    Cálculo de tolerancia: si |z| = 0.93, un error de 0.01
%    en un coeficiente puede mover el polo a |z| > 1.
%% =========================================================

fprintf('\n============================================================\n');
fprintf('        ECUACIONES EN DIFERENCIAS — MCU READY              \n');
fprintf('============================================================\n\n');

fprintf('--- PASO 2: Error de seguimiento ---\n');
fprintf('e(k) = r(k) - y(k)\n\n');

fprintf('--- PASO 3: Integradores (tipo 3) ---\n');
fprintf('v1(k) = v1(k-1) + e(k)          %% cancela escalon\n');
fprintf('v2(k) = v2(k-1) + v1(k)         %% cancela rampa\n');
fprintf('v3(k) = v3(k-1) + v2(k)         %% cancela parabola\n\n');

fprintf('--- PASO 4: Observador (usa y(k-1) y u(k-1)) ---\n');
fprintf('innovation = y(k-1) - x2hat(k-1)\n\n');

fprintf(['x1hat(k) = %.6f*u(k-1) ' ...
         '+ %.6f*x2hat(k-1) ' ...
         '+ %.6f*innovation\n'], ...
          H(1), G(1,2), L(1));

fprintf('\n');

fprintf(['x2hat(k) = %.6f*u(k-1) ' ...
         '+ %.6f*x1hat(k-1) ' ...
         '+ %.6f*x2hat(k-1) ' ...
         '+ %.6f*innovation\n'], ...
          H(2), G(2,1), G(2,2), L(2));

fprintf('\n--- PASO 5-6: Ley de control y saturación ---\n');
fprintf(['u_raw = %.6f*v1(k) + %.6f*v2(k) + %.6f*v3(k)\n' ...
         '        - %.6f*x1hat(k) - %.6f*x2hat(k)\n'], ...
          Ki1, Ki2, Ki3, K(1), K(2));
fprintf('u(k)  = max(u_min, min(u_max, u_raw))   %% saturacion obligatoria\n\n');

fprintf('NOTA: Si u_raw != u(k) (saturacion activa),\n');
fprintf('      NO actualizar v1, v2, v3 en ese paso (anti-windup).\n\n');

fprintf('============================================================\n');
fprintf('INICIALIZACION MCU:\n');
fprintf('  double v1=0, v2=0, v3=0;\n');
fprintf('  double x1hat=0, x2hat=0;\n');
fprintf('  double u_prev=0, y_prev=0;\n');
fprintf('  double innovation;\n');
fprintf('  [declarar u_min y u_max segun actuador fisico]\n');
fprintf('============================================================\n\n');