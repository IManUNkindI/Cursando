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
% Nota: Pasamos las longitudes como constantes directas para simplificar el 'subs'
MTH = simplify(Parin_fkin([q1 q2 q3 q4 q5], L5, L));
PosVector = simplify(MTH(1:3,4)); % Posición X, Y, Z si es un robot planar o 2D es (1:2,3) 

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

% --- 5. BUCLES DE MOVIMIENTO (CUADRADO EN EL ESPACIO) ---
% Usamos pinv() porque el Jacobiano no es cuadrado

% Lado 1: Movimiento en X positivo
fprintf('Moviendo X+ ...\n');
for i=1:1:20
    % Velocidad deseada [Vx; Vy; Vz]
    V = [step; 0; 0]; 
    
    % Evaluación numérica del Jacobiano
    J_num = eval(subs(J_sym, [q1 q2 q3 q4 q5], qin'));
    
    % Cinematica Inversa Diferencial (Pseudo-inversa)
    Thetadot = pinv(J_num) * V; 
    
    qin = qin + Thetadot;
    
    % Graficar
    Rob5r.animate(qin'); % animate es más suave que plot
    MTH_num = double(subs(MTH, [q1 q2 q3 q4 q5], qin')); 
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end

% Lado 2: Movimiento en Y positivo
fprintf('Moviendo Y+ ...\n');
for i=1:1:20
    V = [0; step; 0];
    J_num = eval(subs(J_sym, [q1 q2 q3 q4 q5], qin'));
    Thetadot = pinv(J_num) * V;
    qin = qin + Thetadot;
    
    Rob5r.animate(qin');
    MTH_num = double(subs(MTH, [q1 q2 q3 q4 q5], qin'));
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end

% Lado 3: Movimiento en X negativo
fprintf('Moviendo X- ...\n');
for i=1:1:20
    V = [-step; 0; 0];
    J_num = eval(subs(J_sym, [q1 q2 q3 q4 q5], qin'));
    Thetadot = pinv(J_num) * V;
    qin = qin + Thetadot;
    
    Rob5r.animate(qin');
    MTH_num = double(subs(MTH, [q1 q2 q3 q4 q5], qin'));
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end

% Lado 4: Movimiento en Y negativo
fprintf('Moviendo Y- ...\n');
for i=1:1:20
    V = [0; -step; 0];
    J_num = eval(subs(J_sym, [q1 q2 q3 q4 q5], qin'));
    Thetadot = pinv(J_num) * V;
    qin = qin + Thetadot;
    
    Rob5r.animate(qin');
    MTH_num = double(subs(MTH, [q1 q2 q3 q4 q5], qin'));
    plot3(MTH_num(1,4), MTH_num(2,4), MTH_num(3,4), 'r.');
    drawnow;
end

disp('Trayectoria finalizada.');


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