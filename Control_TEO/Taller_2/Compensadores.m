clc
clear all
syms s

%% === DEFINICIÓN DEL SISTEMA Y POLINOMIO DESEADO ===

% Función de transferencia original
f = (3.333*s^2)/(s^4 +182.89*s^2 +2616); 

% Añadir un integrador (tipo de entrada)
f1 = f * (1/s)^2;  

% Parámetros deseados
zitad = 0.7;   % Amortiguamiento deseado
wnd   = 5.714;    % Frecuencia natural deseada

% Polinomio característico deseado
polinomio_deseado = (s^2 + 2*zitad*wnd*s + wnd^2);

% Cálculo de raíces
raices = double(solve(polinomio_deseado == 0, s));

% Selección de la raíz con parte imaginaria positiva
S_n = raices(imag(raices) > 0);

disp('S_n (raíz deseada con Im > 0):');
disp(vpa(S_n, 6));  % Mostrar con decimales

%% === EVALUACIÓN DEL SISTEMA EN S_n Y CÁLCULO DE ÁNGULO ===

% Evaluar la función en S_n
F1_eval = double(subs(f1, s, S_n));

disp('F1(S_n) evaluado:');
disp(F1_eval);

% Obtener partes real e imaginaria
parte_real = real(F1_eval);
parte_imag = imag(F1_eval);

% Módulos para atan
abs_real = abs(parte_real);
abs_imag = abs(parte_imag);

% Ángulo base (en radianes)
angulo_base = atan(abs_imag / abs_real);

% Determinar cuadrante y ajustar ángulo
if parte_real > 0 && parte_imag > 0
    cuadrante = 1;
    angulo_final = rad2deg(angulo_base);
elseif parte_real < 0 && parte_imag > 0
    cuadrante = 2;
    angulo_final = 180 - rad2deg(angulo_base);
elseif parte_real < 0 && parte_imag < 0
    cuadrante = 3;
    angulo_final = 180 + rad2deg(angulo_base);
elseif parte_real > 0 && parte_imag < 0
    cuadrante = 4;
    angulo_final = 360 - rad2deg(angulo_base);
else
    cuadrante = 0; % Eje real o imaginario
    angulo_final = NaN;
end

% Mostrar cuadrante y ángulo final
disp(['El polo está en el cuadrante: ', num2str(cuadrante)]);
disp(['Ángulo desde el eje real positivo hasta el polo: ', num2str(angulo_final), ' grados']);

%% === TIPO DE COMPENSADOR Y CÁLCULO DE ANGULO NECESARIO ===

% Solicitar tipo de compensador
tipo = input('Ingrese el tipo de compensador ("adelanto"): ', 's');
disp('--- CÁLCULO DE ANGULO A ADELANTAR-ATRASAR ---');
% Ángulo en el que existe LGR
K = 0;
angulo_LGR = 180 * (2*K + 1); 

% Cálculo de ángulo necesario según el tipo
if strcmpi(tipo, 'adelanto')
    angulo_necesario = angulo_LGR - angulo_final;
    operacion = 'sumar';
elseif strcmpi(tipo, 'atraso')
    angulo_necesario = angulo_final - angulo_LGR;
    operacion = 'restar';
else
    error('Tipo de compensador no reconocido. Use "adelanto" o "atraso".');
end

% Mostrar resultados
disp(['Tipo de compensador seleccionado: ', tipo]);
disp(['Ángulo actual del polo evaluado: ', num2str(angulo_final), ' grados']);
disp(['Ángulo en el que existe LGR, seleccionado: ', num2str(angulo_LGR), ' grados']);
disp(['Se debe ', operacion, ' un ángulo de: ', num2str(angulo_necesario), ' grados']);

%% === CÁLCULO DE φ, φ/2, α, β, Y MAGNITUD DEL POLO ===
disp('--- CÁLCULO DE φ, φ/2, α, β, Y MAGNITUD DEL POLO ---');
% Paso 1: Calcular φ y φ/2
% Determinar número mínimo de compensadores necesarios
n = 1;
while abs(angulo_necesario / n) > 60
    n = n + 1;
end

% Calcular phi por compensador
phi = abs(angulo_necesario) / n;

% Mostrar cantidad de compensadores y valor de phi
disp(['Cantidad de compensadores necesarios: ', num2str(n)]);
disp(['Ángulo manejado por cada compensador (phi): ', num2str(phi), ' grados']);

phi_medios = phi / 2;


disp(['Ángulo phi/2: ', num2str(phi_medios), ' grados']);

% Paso 2: Calcular ángulo α (alpha) del polo deseado S_n (segundo cuadrante)
parte_real_sn = real(S_n);
parte_imag_sn = imag(S_n);

angulo_base_sn = atan(abs(parte_imag_sn) / abs(parte_real_sn)); 
alpha = 180 - rad2deg(angulo_base_sn); 

disp(['Ángulo alpha del polo deseado S_n: ', num2str(alpha), ' grados']);

% Paso 3: Calcular β = α / 2
beta = alpha / 2;
disp(['Ángulo Beta (alpha/2): ', num2str(beta), ' grados']);

% Paso 4: Calcular la magnitud del polo deseado
m = sqrt(parte_real_sn^2 + parte_imag_sn^2);

disp(['Distancia diagonal del polo deseado al origen (m): ', num2str(m)]);
%%
% === Cálculo de ángulos internos del triángulo entre polo deseado, polo y cero del compensador ===

% Ángulo 1: 180 - alpha
angulo1 = 180 - alpha;

% Ángulo 2: beta - phi/2
angulo2 = beta - phi_medios;

% Ángulo 3: 180 - (ángulo1 + ángulo2)
angulo3 = 180 - (angulo1 + angulo2);

% Mostrar resultados
disp('--- Ángulos internos del triángulo1 (en grados) ---');
disp(['Ángulo entre S_n y el polo del compensador (180 - alpha): ', num2str(angulo1)]);
disp(['Ángulo entre S_n y el cero del compensador (beta - phi/2): ', num2str(angulo2)]);
disp(['Ángulo opuesto a S_n (complemento): ', num2str(angulo3)]);
% === Calcular nuevos ángulos para x2 ===
angulo1_x2 = 180 - alpha;
angulo2_x2 = beta + phi_medios;
angulo3_x2 = 180 - (angulo1_x2 + angulo2_x2);
disp('--- Ángulos internos del triángulo2 (en grados) ---');
disp(['Ángulo entre S_n y el polo del compensador (180 - alpha): ', num2str(angulo1_x2)]);
disp(['Ángulo entre S_n y el cero del compensador (beta + phi/2): ', num2str(angulo2_x2)]);
disp(['Ángulo opuesto a S_n (complemento): ', num2str(angulo3_x2)]);
%%
% === Aplicar ley de senos para calcular x1 ===

% Convertir a radianes para usar en funciones trigonométricas
angulo2_rad = deg2rad(angulo2);
angulo3_rad = deg2rad(angulo3);

% x1: distancia desde S_n al polo del compensador
x1 = m * sin(angulo2_rad) / sin(angulo3_rad);


% Convertir a radianes
angulo2_x2_rad = deg2rad(angulo2_x2);
angulo3_x2_rad = deg2rad(angulo3_x2);

% x2: distancia desde S_n al cero del compensador
x2 = m * sin(angulo2_x2_rad) / sin(angulo3_x2_rad);
% Mostrar resultado
disp('--- Distancia al polo y al cero ---');
disp(['Distancia x1: ', num2str(x1)]);
disp(['Distancia x2: ', num2str(x2)]);

%% Revisar la opción seleccionada en la variable 'tipo' y ajustar el polinomio
if strcmpi(tipo, 'adelanto')
    % En adelanto, x1 es la distancia al polo y x2 es la distancia al cero
    x_n_1 = x1;  % Distancia al polo
    x_n_2 = x2;  % Distancia al cero
elseif strcmpi(tipo, 'atraso')
    % En atraso, x1 es la distancia al cero y x2 es la distancia al polo
    x_n_1 = x2;  % Distancia al cero
    x_n_2 = x1;  % Distancia al polo
else
    error('Tipo de compensador no reconocido. Use "adelanto" o "atraso".');
end

% Mostrar el polinomio del compensador
polinomio_compensador = sprintf('k*((s + %.2f)/(s + %.2f))', x_n_1, x_n_2);

disp(['Polinomio del compensador: ', polinomio_compensador]);
%% Calcular el valor de K
% Primero, obtenemos el polinomio del compensador sin la constante K
compensador = ((s + x_n_1)^n) / ((s + x_n_2)^n);  % Polinomio del compensador sin K

% Multiplicamos f1(s) por el compensador
funcion_compensada = f1 * compensador;

% Evaluamos la multiplicación usando el valor de S_n
resultado = double(subs(funcion_compensada, s, S_n));
% Cambiar formato a notación científica
format short e;  % Cambia a formato de notación científica

% Mostrar el resultado en notación científica
disp('numero para encontrar K (en notación científica):');
disp(resultado);  % Esto mostrará el resultado en notación científica
%% Descomponer el número en parte real e imaginaria
parte_real_resultado = real(resultado);  % Extraer parte real
parte_imag_resultado = imag(resultado);  % Extraer parte imaginaria

% Mostrar las partes real e imaginaria
disp(['Parte real: ', num2str(parte_real_resultado)]);
disp(['Parte imaginaria: ', num2str(parte_imag_resultado)]);

%% Resolver la ecuación para K: (parte_real*k)^2 + (parte_imag)^2 = 1
% Resolviendo para k
syms k;
ecuacion = (parte_real_resultado * k)^2 + (parte_imag_resultado*k)^2 == 1;

% Resolver la ecuación
sol_k = solve(ecuacion, k);

% Convertir soluciones simbólicas a valores numéricos
sol_k_num = double(sol_k);

% Seleccionar la solución positiva
sol_k_pos = sol_k_num(sol_k_num > 0);

% Mostrar la solución positiva
disp(['Valor de K (positivo): ', num2str(sol_k_pos)]);

%% Mostrar el polinomio del compensador con K
disp('Polinomio del compensador con K:');

% Multiplicar el polinomio por K
polinomio_compensador_con_K = [num2str(sol_k_pos), '*', polinomio_compensador];

% Mostrar el polinomio final
disp(polinomio_compensador_con_K);