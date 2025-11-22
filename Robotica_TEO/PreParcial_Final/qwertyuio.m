L5 = [10, 0, 10, 10]; 
L  = [0, 5]; 

% --- 2. DEFINICIÓN DEL ROBOT (Toolbox) ---
% Copia exacta de tu definición
R5(1) = Link('revolute',  'd', L5(1), 'a', 0, 'alpha', 0, 'offset', pi);
R5(2) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', -pi/2, 'offset', L(2), 'qlim', [0 25]);
R5(3) = Link('prismatic', 'theta', -pi/2, 'a', 0, 'alpha', pi/2, 'offset', L(2), 'qlim', [0 25]);
R5(4) = Link('revolute',  'd', 0, 'a', L5(4)+L5(3), 'alpha', pi/2, 'offset', pi/2);
R5(5) = Link('revolute',  'd', 0, 'a', 10, 'alpha', pi/2, 'offset', 0);
Rob5r = SerialLink(R5, 'name', 'PARIN');

home = [0 0 0 0 0];

figure(2)
Rob5r.plot(home)
zlim([-10 40])
Rob5r.teach(home)
hold on