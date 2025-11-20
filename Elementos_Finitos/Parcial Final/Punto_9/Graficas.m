% Leer el archivo CSV
data = readtable('Torque vs Time!.csv');

% Extraer las columnas relevantes (filas 6 a 16)
tiempo = table2array(data(1:11,1));
torque = table2array(data(1:11,2));

% Graficar
figure;
plot(tiempo, torque, 'o-', 'LineWidth', 2);
title('Torque a través del tiempo');
xlabel('Tiempo [s]');
ylabel('Torque [J]');
grid on;
