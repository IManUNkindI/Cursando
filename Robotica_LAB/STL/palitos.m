% cd('C:\Users\Andres Felipe\Desktop\Semestre\Robotica TEO\RVC2-copy\RVC2-copy\rvctools')
% startup_rvc

% === Definición de un robot de 5 DOF con articulaciones revolutas ===
% Reemplaza los valores d, a, alpha y qlim por los de tu brazo real


L(1) = Link('d', 0.30, 'a', 0.00, 'alpha',  pi/2, 'qlim', [-pi/2,  pi/2]); % J1
L(2) = Link('d', 0.00, 'a', 0.30, 'alpha',  0.00, 'qlim', [0,  pi/2]);   % J2
L(3) = Link('d', 0.00, 'a', 0.00, 'alpha',  pi/2, 'qlim', [-pi/2,  pi/4]);   % J3
L(4) = Link('d', 0.30, 'a', 0.00, 'alpha',  pi/2, 'qlim', [-pi/2,  pi/2]); % J4
L(5) = Link('d', 0.15, 'a', 0.00, 'alpha',  pi/2, 'qlim', [-pi/2,  pi/2]);   % J5

robot = SerialLink(L, 'name', 'MiBrazo5DOF');

% Configuración inicial (todas las articulaciones a 0)
q0 = zeros(1,5);

% Visualizar el robot
figure;
robot.plot(q0, 'workspace', [-1 1 -1 1 0 1]);
%camzoom(2)  % Aumenta el zoom 2x
title('Brazo de 5 DOF - Configuración inicial');

% Probar sliders integrados
robot.teach;