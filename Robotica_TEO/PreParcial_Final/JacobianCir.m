clear; clc; close all;

% --- 1. DEFINICIÓN DE PARÁMETROS ---
% Valores arbitrarios para las longitudes (puedes cambiarlos)
L5 = [10, 0, 10, 10]; 
L  = [0, 5]; 

% --- 2. DEFINICIÓN DEL ROBOT (Toolbox) ---
% Copia exacta de tu definición
R5(1) = Link('revolute',  'd', L5(1), 'a', 0, 'alpha', 0, 'offset', pi);
R5(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', pi/2, 'offset', L(2), 'qlim', [0 25]);
R5(3) = Link('revolute',  'd', 0, 'a', 0, 'alpha', pi/2, 'offset', pi/2);
R5(4) = Link('revolute',  'd', L5(4)+L5(3), 'a', 0, 'alpha', 0, 'offset', 0);
R5(5) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L(2), 'qlim', [0 25]);

Rob5r = SerialLink(R5, 'name', 'PARIN');

% --- 3. CÁLCULO SIMBÓLICO ---
% Ahora tenemos 5 variables articulares
syms q1 q2 q3 q4 q5 real 

% Calculamos la Cinemática Directa Simbólica
MTH = simplify(Parin_fkin([q1 q2 q3 q4 q5], L5, L));
PosVector = simplify(MTH(1:3,4));

% Jacobiano (3x5 porque controlamos X, Y, Z con 5 motores)
J_sym = jacobian(PosVector, [q1 q2 q3 q4 q5]);

% --- 4. CONFIGURACIÓN INICIAL ---
% q2 y q5 son prismáticas (distancia), las otras son ángulos (radianes)
qin = [0, 5, 0, 0, 5]'; 

Rob5r.plot(qin');
hold on
view(3); % Vista 3D

% Velocidad del bucle (más pequeño = más suave)
step = 0.5; 

% --- 5. BUCLE DE MOVIMIENTO (CÍRCULO EN EL ESPACIO) ---
% Primero evaluamos numéricamente la posición inicial
MTH_inicial = double(subs(MTH, [q1 q2 q3 q4 q5], qin'));
pos_inicial = MTH_inicial(1:3, 4);

% Parámetros del círculo
radio = 5;           % Radio del círculo (reducido para mayor seguridad)
centro = pos_inicial'; % Centro en la posición inicial (convertido a vector fila)
num_puntos = 100;     % Número de puntos para el círculo completo

% Generar puntos del círculo en el plano XY (usando valores numéricos)
theta_circle = linspace(0, 2*pi, num_puntos);
x_circle = centro(1) + radio * cos(theta_circle);
y_circle = centro(2) + radio * sin(theta_circle);
z_circle = centro(3) * ones(size(theta_circle)); % Mantener Z constante

% Graficar el círculo de referencia (ahora con datos numéricos)
plot3(x_circle, y_circle, z_circle, 'b--', 'LineWidth', 1);

fprintf('Iniciando trayectoria circular...\n');
fprintf('Centro del círculo: [%.2f, %.2f, %.2f]\n', centro);
fprintf('Radio: %.2f\n', radio);

% Bucle principal para seguir la trayectoria circular
for i = 1:num_puntos
    % Posición deseada en el siguiente punto del círculo
    pos_deseada = [x_circle(i); y_circle(i); z_circle(i)];
    
    % Posición actual (evaluar la MTH actual)
    MTH_actual = double(subs(MTH, [q1 q2 q3 q4 q5], qin'));
    pos_actual = MTH_actual(1:3, 4);
    
    % Error de posición
    error = pos_deseada - pos_actual;
    
    % Control proporcional (ganancia para suavizar el movimiento)
    Kp = 0.3; % Reducida para mayor suavidad
    V = Kp * error;
    
    % Limitar la velocidad máxima para evitar movimientos bruscos
    vel_max = 0.8;
    if norm(V) > vel_max
        V = V / norm(V) * vel_max;
    end
    
    % Evaluación numérica del Jacobiano
    J_num = eval(subs(J_sym, [q1 q2 q3 q4 q5], qin'));
    
    % Cinemática Inversa Diferencial (Pseudo-inversa)
    Thetadot = pinv(J_num) * V;
    
    % Actualizar configuración articular
    qin = qin + Thetadot;
    
    % Graficar
    Rob5r.animate(qin');
    plot3(pos_actual(1), pos_actual(2), pos_actual(3), 'r.', 'MarkerSize', 10);
    drawnow;
    
    % Pequeña pausa para visualización
    pause(0.05);
end

disp('Trayectoria circular finalizada.');

% Mostrar información final
MTH_final = double(subs(MTH, [q1 q2 q3 q4 q5], qin'));
fprintf('Posición final: [%.2f, %.2f, %.2f]\n', MTH_final(1,4), MTH_final(2,4), MTH_final(3,4));

% --- FUNCIONES AUXILIARES ---

function MTH = Parin_fkin(q, L5, L)
    % Mapeo estricto de tus Link Parameters a Matrices DH
    
    % Link 1 (Revolute): d=L5(1), offset=pi
    T1 = MiDH(q(1) + pi, L5(1), 0, 0);
    
    % Link 2 (Prismatic): theta=-pi/2, alpha=pi/2, offset=L(2)
    % En prismatica, la variable 'q' se suma a 'd'
    T2 = MiDH(-pi/2, q(2) + L(2), 0, pi/2);
    
    % Link 3 (Revolute): d=0, alpha=pi/2, offset=pi/2
    T3 = MiDH(q(3) + pi/2, 0, 0, pi/2);
    
    % Link 4 (Revolute): d=L5(4)+L5(3), alpha=0
    T4 = MiDH(q(4), L5(4)+L5(3), 0, 0);
    
    % Link 5 (Prismatic): theta=-pi/2, alpha=-pi/2, offset=L(2)
    T5 = MiDH(-pi/2, q(5) + L(2), 0, -pi/2);
    
    MTH = T1 * T2 * T3 * T4 * T5;
end

function T = MiDH(theta, d, a, alpha)
    T = [cos(theta) -sin(theta)*cos(alpha) sin(theta)*sin(alpha) a*cos(theta);
         sin(theta) cos(theta)*cos(alpha) -cos(theta)*sin(alpha) a*sin(theta);
         0          sin(alpha)            cos(alpha)            d;
         0          0                     0                     1];
end