clear; clc; close all;

% ============================
% 1. Cargar imagen
% ============================
I = imread("pumpkin.png");

% Convertir a escala de grises si es necesario
if ndims(I) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end

figure; imshow(Igray); title("Imagen original");

% ============================
% 2. Detección de bordes
% ============================
edges = edge(Igray, 'canny', 0.1);   % 0.1 reduce pérdidas de líneas finas

figure; imshow(edges); title("Bordes detectados (Canny)");

% Limpiar ruido pequeño
edges = bwareaopen(edges, 20);

% ============================
% 3. Obtener trayectorias de los bordes
% ============================
[B, L] = bwboundaries(edges, 'noholes');

figure; imshow(edges); hold on;
title("Contornos encontrados");

for k = 1:length(B)
    plot(B{k}(:,2), B{k}(:,1), 'r', 'LineWidth', 1.5);
end

% ============================
% 4. Guardar coordenadas
% ============================
contornos = cell(length(B),1);

for k = 1:length(B)
    coords = B{k};
    x = coords(:,2);
    y = coords(:,1);
    contornos{k} = [x, y];
end

fprintf("Número de contornos detectados: %d\n", length(contornos));

% ============================
% 5. Redibujar (comprobación)
% ============================
figure; hold on; axis equal; title("Redibujado desde bordes");

for k = 1:length(contornos)
    xy = contornos{k};
    plot(xy(:,1), -xy(:,2), 'k', 'LineWidth', 2);
end
