function cuadroef3 
[pde_fig,ax]=pdeinit;
pdetool('appl_cb',1);
set(ax,'DataAspectRatio',[85 165 1]);
set(ax,'PlotBoxAspectRatio',[1 1 1]);
set(ax,'XLim',[-10 90]);
set(ax,'YLim',[-10 170]);
set(ax,'XTickMode','auto');
set(ax,'YTickMode','auto');
pdetool('gridon','on');

% ===== GEOMETRÍA =====
% Rectángulo principal
pdepoly([0 0 82 82], [0 160 160 0], 'P1');

pdepoly([0 33.5 33.5 0], [7.4 7.4 152.6 152.6], 'C1');
pdepoly([48.5 82 82 48.5], [7.4 7.4 152.6 152.6], 'C2');
pdepoly([0 38.5 38.5 0], [12.4 12.4 147.6 147.6], 'C3');
pdepoly([43.5 82 82 43.5], [12.4 12.4 147.6 147.6], 'C4');

pdeellip(33.5,12.4,5,5,0,'E1');
pdeellip(33.5,147.6,5,5,0,'E2');
pdeellip(48.5,12.4,5,5,0,'E3');
pdeellip(48.5,147.6,5,5,0,'E4');

% Dominio final = rectángulo - cuadrado
set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1 - C1 - C2 - C3 - C4 - E1 - E2 - E3 - E4');

% Boundary conditions:
pdetool('changemode',0)
pdesetbd(5,'dir',1,'1','0')
pdesetbd(4,'dir',1,'1','0')
pdesetbd(3,'dir',1,'1','0')
pdesetbd(2,'dir',1,'1','0')
pdesetbd(1,'dir',1,'1','0')

% Mesh generation:
setappdata(pde_fig,'Hgrad',1.3);
setappdata(pde_fig,'refinemethod','regular');
setappdata(pde_fig,'jiggle',char('on','mean',''));
setappdata(pde_fig,'MesherVersion','preR2013a');
 
pdetool('initmesh');
pdetool('refine')

% PDE coefficients:
pdeseteq(1,'1.0','0.0','10.0','1.0','0:10','0.0','0.0','[0 100]')
 
setappdata(pde_fig,'currparam',['1.0 ';'0.0 ';'10.0';'1.0 '])
 
% Solve parameters:
setappdata(pde_fig,'solveparam',...
char('0','4608','10','pdeadworst','0.5','longest','0','1E-4','','fixed','Inf'))
 
% Plotflags and user data strings:
setappdata(pde_fig,'plotflags',[1 1 1 1 1 1 1 1 0 0 0 1 1 0 0 0 0 1]);
setappdata(pde_fig,'colstring','');
setappdata(pde_fig,'arrowstring','');
setappdata(pde_fig,'deformstring','');
setappdata(pde_fig,'heightstring','');
end
clc;
cuadroef3()

% Obtener datos de malla
sp= size(p);
%NUMERO  DE  NODOS
nodos=sp(2);
 
% NUMERO DE DIMENSIONES
dimensiones = 2;
 
st = size(t);
 
% NUMERO DE ELEMENTOS
elementos = st(2);
 
% NUMERO DE GRADOS DE LIBERTAD
ngrad = dimensiones * nodos;
 
% GRAFICACIÓN DE MALLA 
figure(1)
pdemesh(p,e,t)
hold on
% MATRIZ DE COORDENADAS NODALES
Mcoorde = p';
% GRAFICACIÓN DE NODOS
plot(Mcoorde(:,1), Mcoorde(:,2), '.k')
title('Malla con nodos')
axis([-10 90 -10 170]); % Límites ajustados

% MATRIZ DE CONECTIVIDAD
tt = t';
Mconectividad = tt(:,1:3);
 
% MATRIZ DE GRADOS DE LIBERTAD DOF
Mdof = zeros(elementos,6);
 
for i = 1:elementos
    Mdof(i,1) = 2*Mconectividad(i,1)-1; 
    Mdof(i,2) = 2*Mconectividad(i,1);  
    Mdof(i,3) = 2*Mconectividad(i,2)-1;  
    Mdof(i,4) = 2*Mconectividad(i,2);  
    Mdof(i,5) = 2*Mconectividad(i,3)-1;  
    Mdof(i,6) = 2*Mconectividad(i,3); 
end
 
% MATRIZ DE PROPIEDADES
Eyoung = (2*10^11)/(1000^2);
Vpoison = 0.3;
Tespesor = 12;
 
KK = zeros(ngrad);
 
D = (Eyoung/(1- (Vpoison^2))) * [1 Vpoison 0; Vpoison 1 0; 0 0 (1-Vpoison)/2];
 
% MATRIZ KK 
for i = 1:elementos
    % Coordenadas de los nodos del elemento
    x1 = Mcoorde(Mconectividad(i,1),1); y1 = Mcoorde(Mconectividad(i,1),2);
    x2 = Mcoorde(Mconectividad(i,2),1); y2 = Mcoorde(Mconectividad(i,2),2);
    x3 = Mcoorde(Mconectividad(i,3),1); y3 = Mcoorde(Mconectividad(i,3),2);
    
    bi = y2 - y3; % yj-yk
    bj = y3 - y1; % yk-yi
    bk = y1 - y2; % yi-yj
 
    ci = x3 - x2; % xk-xj
    cj = x1 - x3; % xi-xk
    ck = x2 - x1; % xj-xi
 
    dosA = x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2);
    
    if abs(dosA) < 1e-10
        warning('Elemento %d tiene área muy pequeña o cero', i);
        continue;
    end
 
    Bb = [bi 0 bj 0 bk 0; 0 ci 0 cj 0 ck; ci bi cj bj ck bk];
    B = (1/dosA) * Bb;
    Btras = B';
 
    Ke = Btras * D * B * Tespesor * (dosA/2);
 
    % Grados de libertad del elemento
    dofs = Mdof(i,:);
    
    % Ensamblar en matriz global
    for row = 1:6
        for col = 1:6
            KK(dofs(row), dofs(col)) = KK(dofs(row), dofs(col)) + Ke(row, col);
        end
    end
end
 
% BUSQUEDA DE NODOS DE BORDES PARA APLICACION DE FUERZAS EN TENSION
posicionborde = find(abs(Mcoorde(:,2) - 160) < 1e-6);
posicionbordeinicial = find(abs(Mcoorde(:,2) - 0) < 1e-6);
 
numnodosfuerza = length(posicionborde);
 
% CALCULO DE FUERZA NODAL POR APLICAR
Fnodal = (50e3*9.806)/numnodosfuerza;
 
FF = zeros(ngrad,1);
gradosliberxf = (2.*posicionborde)-1;
 
for i = 1:numnodosfuerza
    FF(gradosliberxf(i)) = FF(gradosliberxf(i)) + Fnodal;    
end
 
gradosliberx0 = (2.*posicionbordeinicial)-1;
 
% CORRESPONDE TODOS LOS U QUE TIENEN DESPLAZAMIENTO CERO
gradoslibereliminar = gradosliberx0;
uelimi = length(gradoslibereliminar);
 
Ugradosliber = ones(ngrad,1);
for i = 1:uelimi
    Ugradosliber(gradoslibereliminar(i)) = 0;
end
 
tamanoredu = sum(Ugradosliber);
desco = find(Ugradosliber);
KKREDU = zeros(tamanoredu);
 
for i = 1:tamanoredu
    for j = 1:tamanoredu
        KKREDU(i,j) = KK(desco(i), desco(j));  
    end
end
 
FFREDU = zeros(tamanoredu,1);
for i = 1:tamanoredu
    FFREDU(i,1) = FF(desco(i));  
end

% Resolver el sistema
Usol = KKREDU \ FFREDU;
 
UTOTAL = zeros(ngrad,1);
for i = 1:tamanoredu
    UTOTAL(desco(i),1) = Usol(i);  
end
 
DEFORMACIONTOTAL = zeros(elementos,3);
ESFUERZOTOTAL = zeros(elementos,3);
 
% Función auxiliar para calcular centroide
centroid = @(points) mean(points, 1);
 
for i = 1:elementos
    % Coordenadas de los nodos del elemento
    x1 = Mcoorde(Mconectividad(i,1),1); y1 = Mcoorde(Mconectividad(i,1),2);
    x2 = Mcoorde(Mconectividad(i,2),1); y2 = Mcoorde(Mconectividad(i,2),2);
    x3 = Mcoorde(Mconectividad(i,3),1); y3 = Mcoorde(Mconectividad(i,3),2);
    
    bi = y2 - y3;
    bj = y3 - y1;
    bk = y1 - y2;
 
    ci = x3 - x2;
    cj = x1 - x3;
    ck = x2 - x1;
 
    dosA = x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2);
    
    if abs(dosA) < 1e-10
        continue;
    end
 
    Bb = [bi 0 bj 0 bk 0; 0 ci 0 cj 0 ck; ci bi cj bj ck bk];
    Belemental = (1/dosA) * Bb;
 
    Uelemental = zeros(6,1);
    for j = 1:6
        Uelemental(j,1) = UTOTAL(Mdof(i,j));
    end
 
    deformacionelemental = Belemental * Uelemental;
    DEFORMACIONTOTAL(i,:) = deformacionelemental';
 
    esfuerzoelemental = D * deformacionelemental;
    ESFUERZOTOTAL(i,:) = esfuerzoelemental';
end

% Calcular centroides
centro = zeros(elementos, 2);
for c = 1:elementos
    puntos = [Mcoorde(Mconectividad(c,1),1), Mcoorde(Mconectividad(c,1),2); 
              Mcoorde(Mconectividad(c,2),1), Mcoorde(Mconectividad(c,2),2); 
              Mcoorde(Mconectividad(c,3),1), Mcoorde(Mconectividad(c,3),2)];
    centro(c,:) = centroid(puntos);
end

% Visualización de resultados
visualizar_resultados(2, ESFUERZOTOTAL(:,1), centro, 'Esfuerzo en X');
visualizar_resultados(3, ESFUERZOTOTAL(:,2), centro, 'Esfuerzo en Y');
visualizar_resultados(4, ESFUERZOTOTAL(:,3), centro, 'Esfuerzo en XY');
visualizar_resultados(5, DEFORMACIONTOTAL(:,1), centro, 'Deformación en X');
visualizar_resultados(6, abs(DEFORMACIONTOTAL(:,2)), centro, 'Deformación en Y');
visualizar_resultados(7, DEFORMACIONTOTAL(:,3), centro, 'Deformación en XY');

% Visualizar números de elementos
figure(8)
pdemesh(p,e,t)
hold on
for c = 1:elementos
    text(centro(c,1), centro(c,2), num2str(c), 'FontSize', 8, 'HorizontalAlignment', 'center');
end
title('Números de Elementos');
axis([-10 90 -10 170]); % Límites ajustados


% Función auxiliar para visualización
function visualizar_resultados(fig_num, datos, centro, titulo)
    datos_norm = datos / (max(abs(datos)) + eps);
    
    figure(fig_num);
    pdemesh(evalin('base', 'p'), evalin('base', 'e'), evalin('base', 't'));
    hold on;
    
    colors = jet(5);
    limites = [0, 0.2, 0.4, 0.6, 0.8, 1];
    
    for c = 1:size(centro, 1)
        valor = datos_norm(c);
        
        if valor <= limites(2)
            color_idx = 1;
        elseif valor <= limites(3)
            color_idx = 2;
        elseif valor <= limites(4)
            color_idx = 3;
        elseif valor <= limites(5)
            color_idx = 4;
        else
            color_idx = 5;
        end
        
        plot(centro(c,1), centro(c,2), '.', 'MarkerSize', 15, 'Color', colors(color_idx,:));
    end
    
    colorbar;
    colormap(jet);
    caxis([0 0.1]);
    title(titulo);
    % axis([-10 90 -10 170]);
end