%% Punto 1
% Datos de la tabla
nodos = [1572, 4877, 13434, 642215, 993629, 1635844, 2278059, 2920274];
elementos = [779, 2617, 7636, 462912, 748349, 1211261, 1674173, 2137085];
deformacion = [0.00038006, 0.00038066, 0.00038108, 0.00038157, 0.00038169, 0.00038160, 0.00038166, 0.00038163];

% Preparar figura
figure;
hold on;

% Gráfica 1: Elementos vs Deformación
scatter(elementos,deformacion,70,'filled','MarkerFaceColor','b');

% Ajuste spline
xq_elem = linspace(min(elementos),max(elementos),200);
yq_elem = spline(elementos,deformacion,xq_elem);
plot(xq_elem,yq_elem,'-b','LineWidth',2);

% Gráfica 2: Nodos vs Deformación
scatter(nodos,deformacion,70,'filled','MarkerFaceColor','r');

% Ajuste spline
xq_nodos = linspace(min(nodos),max(nodos),200);
yq_nodos = spline(nodos,deformacion,xq_nodos);
plot(xq_nodos,yq_nodos,'-r','LineWidth',2);

% Estética
xlabel('Cantidad (Nodos o Elementos)');
ylabel('Deformación (m)');
title('Convergencia: Nodos vs Deformación y Elementos vs Deformación');
legend('Elementos - datos','Elementos - spline',...
       'Nodos - datos','Nodos - spline','Location','best');
grid on;

%% Punto 2

% Datos de la tabla
nodos = [1996, 5671, 8778, 12356, 93321, 105677, 118033, 130389];
elementos = [978, 2752, 4305, 6095, 46989, 53084, 59179, 65274];
deformacion = [0.039028, 0.039348, 0.039321, 0.039481, 0.039464, 0.039476, 0.039469, 0.039473];

% Preparar figura
figure;
hold on;

% Gráfica 1: Elementos vs Deformación
scatter(elementos,deformacion,70,'filled','MarkerFaceColor','b');

% Ajuste spline
xq_elem = linspace(min(elementos),max(elementos),200);
yq_elem = spline(elementos,deformacion,xq_elem);
plot(xq_elem,yq_elem,'-b','LineWidth',2);

% Gráfica 2: Nodos vs Deformación
scatter(nodos,deformacion,70,'filled','MarkerFaceColor','r');

% Ajuste spline
xq_nodos = linspace(min(nodos),max(nodos),200);
yq_nodos = spline(nodos,deformacion,xq_nodos);
plot(xq_nodos,yq_nodos,'-r','LineWidth',2);

% Estética
xlabel('Cantidad (Nodos o Elementos)');
ylabel('Deformación (m)');
title('Convergencia: Nodos vs Deformación y Elementos vs Deformación');
legend('Elementos - datos','Elementos - spline',...
       'Nodos - datos','Nodos - spline','Location','best');
grid on;

%% Punto 4

% Datos de la tabla
nodos = [1360, 2920, 3811, 80787, 1910130, 1990917, 2071704, 2152491];
elementos = [157, 357, 475, 15996, 451462, 467458, 483454, 499450];
deformacion = [0.028913, 0.029336, 0.029235, 0.029453, 0.029544, 0.029450, 0.029547, 0.029448];

% Preparar figura
figure;
hold on;

% Gráfica 1: Elementos vs Deformación
scatter(elementos,deformacion,70,'filled','MarkerFaceColor','b');

% Ajuste spline
xq_elem = linspace(min(elementos),max(elementos),200);
yq_elem = spline(elementos,deformacion,xq_elem);
plot(xq_elem,yq_elem,'-b','LineWidth',2);

% Gráfica 2: Nodos vs Deformación
scatter(nodos,deformacion,70,'filled','MarkerFaceColor','r');

% Ajuste spline
xq_nodos = linspace(min(nodos),max(nodos),200);
yq_nodos = spline(nodos,deformacion,xq_nodos);
plot(xq_nodos,yq_nodos,'-r','LineWidth',2);

% Estética
xlabel('Cantidad (Nodos o Elementos)');
ylabel('Deformación (m)');
title('Convergencia: Nodos vs Deformación y Elementos vs Deformación');
legend('Elementos - datos','Elementos - spline',...
       'Nodos - datos','Nodos - spline','Location','best');
grid on;