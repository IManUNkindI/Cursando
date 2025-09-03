function interfaz_pieza
    % Ventana principal
    fig = uifigure('Name','Definir Pieza','Position',[100 100 500 600]);

    % ================== Panel dimensiones placa ==================
    uilabel(fig,'Position',[20 570 200 22],'Text','Dimensiones de la placa:');
    uilabel(fig,'Position',[20 540 50 22],'Text','Ancho:');
    anchoField = uieditfield(fig,'numeric','Position',[80 540 100 22]);
    uilabel(fig,'Position',[200 540 50 22],'Text','Alto:');
    altoField = uieditfield(fig,'numeric','Position',[250 540 100 22]);

    % ================== Número de agujeros ==================
    uilabel(fig,'Position',[20 500 200 22],'Text','Cantidad de agujeros:');
    numHolesDrop = uidropdown(fig,'Items',{'0','1','2','3','4','5'}, ...
        'Position',[180 500 80 22],'Value','0');

    % ================== Refinamiento de la malla ==================
    uilabel(fig,'Position',[20 460 200 22],'Text','Refinamiento de la malla:');
    meshSlider = uislider(fig, ...
        'Position',[180 470 200 3], ...
        'Limits',[1 3], ...                      % valores de 1 a 3
        'MajorTicks',[1 2 3], ...                % posiciones discretas
        'MajorTickLabels',{'Gruesa','Media','Fina'}, ...
        'Value',2);                              % valor inicial en "Media"

    % ================== Panel agujeros ==================
    holePanel = uipanel(fig,'Title','Parámetros de agujeros', ...
        'Position',[20 140 460 280]);

    holeParams = cell(1,5);
    for i = 1:5
        w = uieditfield(holePanel,'numeric','Position',[80 220-(i-1)*50 60 22], ...
            'Enable','off'); 
        h = uieditfield(holePanel,'numeric','Position',[160 220-(i-1)*50 60 22], ...
            'Enable','off');
        x = uieditfield(holePanel,'numeric','Position',[240 220-(i-1)*50 60 22], ...
            'Enable','off');
        y = uieditfield(holePanel,'numeric','Position',[320 220-(i-1)*50 60 22], ...
            'Enable','off');

        uilabel(holePanel,'Text',['Agujero ' num2str(i)],'Position',[10 220-(i-1)*50 70 15]);
        uilabel(holePanel,'Text','Ancho','Position',[80 240-(i-1)*50 50 15]);
        uilabel(holePanel,'Text','Alto','Position',[160 240-(i-1)*50 50 15]);
        uilabel(holePanel,'Text','X','Position',[240 240-(i-1)*50 20 15]);
        uilabel(holePanel,'Text','Y','Position',[320 240-(i-1)*50 20 15]);

        holeParams{i} = struct('w',w,'h',h,'x',x,'y',y);
    end

    % ================== Botón guardar ==================
    guardarBtn = uibutton(fig,'Text','Guardar Valores','Position',[150 100 200 30], ...
        'ButtonPushedFcn',@(src,event)guardarValores());

    % ================== Botón ejecutar cuadroef (deshabilitado al inicio) ==================
    ejecutarBtn = uibutton(fig,'Text','Ejecutar PDETool','Position',[150 60 200 30], ...
        'Enable','off', ...
        'ButtonPushedFcn',@(src,event)cuadroef());

    % ================== Callback cambio de dropdown ==================
    numHolesDrop.ValueChangedFcn = @(src,event) actualizarCampos();

    % ================== Funciones internas ==================
    function actualizarCampos()
        n = str2double(numHolesDrop.Value);
        for j = 1:5
            if j <= n
                holeParams{j}.w.Enable  = 'on';
                holeParams{j}.h.Enable  = 'on';
                holeParams{j}.x.Enable  = 'on';
                holeParams{j}.y.Enable  = 'on';
            else
                holeParams{j}.w.Value   = 0; holeParams{j}.w.Enable='off';
                holeParams{j}.h.Value   = 0; holeParams{j}.h.Enable='off';
                holeParams{j}.x.Value   = 0; holeParams{j}.x.Enable='off';
                holeParams{j}.y.Value   = 0; holeParams{j}.y.Enable='off';
            end
        end
    end

    function guardarValores()
        % Dimensiones placa
        datosPlaca.ancho = anchoField.Value;
        datosPlaca.alto  = altoField.Value;

        % Inicializar arreglo de agujeros vacío
        datosPlaca.agujeros = struct('ancho',{},'alto',{},'x',{},'y',{});

        % Guardar agujeros activos
        n = str2double(numHolesDrop.Value);
        assignin('base','numAgujeros', n);
        for j = 1:n
            params = holeParams{j};
            datosPlaca.agujeros(end+1) = struct( ...
                'ancho',params.w.Value, ...
                'alto', params.h.Value, ...
                'x',    params.x.Value, ...
                'y',    params.y.Value);
        end

        % Guardar refinamiento de malla (1=gruesa, 2=media, 3=fina)
        datosPlaca.refinamientoMalla = round(meshSlider.Value);

        % Guardar en workspace
        assignin('base','datosPlaca',datosPlaca);

        % Mensaje y habilitar botón de cuadroef
        uialert(fig,'Valores guardados en variable "datosPlaca" del workspace.','Éxito');
        ejecutarBtn.Enable = 'on'; 
    end
end
function cuadroef()
global datosPlaca
global numAgujeros

refinamiento = datosPlaca.refinamientoMalla;

ancho = datosPlaca.ancho;
alto = datosPlaca.alto;

switch numAgujeros
    case 0
        x1 = 0; x2 = 0; x3 = 0; x4 = 0; x5 = 0;
        y1 = 0; y2 = 0; y3 = 0; y4 = 0; y5 = 0;
        ax1 = 0; ax2 = 0; ax3 = 0; ax4 = 0; ax5 = 0;
        ay1 = 0; ay2 = 0; ay3 = 0; ay4 = 0; ay5 = 0;
    case 1
        x1 = datosPlaca.agujeros(1).x;
        x2 = 0; x3 = 0; x4 = 0; x5 = 0;
        
        y1 = datosPlaca.agujeros(1).y;
        y2 = 0; y3 = 0; y4 = 0; y5 = 0;

        ax1 = datosPlaca.agujeros(1).ancho;
        ax2 = 0; ax3 = 0; ax4 = 0; ax5 = 0;

        ay1 = datosPlaca.agujeros(1).alto;
        ay2 = 0; ay3 = 0; ay4 = 0; ay5 = 0;
    case 2
        x1 = datosPlaca.agujeros(1).x;
        x2 = datosPlaca.agujeros(2).x;
        x3 = 0; x4 = 0; x5 = 0;

        y1 = datosPlaca.agujeros(1).y;
        y2 = datosPlaca.agujeros(2).y;
        y3 = 0; y4 = 0; y5 = 0;

        ax1 = datosPlaca.agujeros(1).ancho;
        ax2 = datosPlaca.agujeros(2).ancho;
        ax3 = 0; ax4 = 0; ax5 = 0;

        ay1 = datosPlaca.agujeros(1).alto;
        ay2 = datosPlaca.agujeros(2).alto;
        ay3 = 0; ay4 = 0; ay5 = 0;
    case 3
        x1 = datosPlaca.agujeros(1).x;
        x2 = datosPlaca.agujeros(2).x;
        x3 = datosPlaca.agujeros(3).x;
        x4 = 0; x5 = 0;

        y1 = datosPlaca.agujeros(1).y;
        y2 = datosPlaca.agujeros(2).y;
        y3 = datosPlaca.agujeros(3).y;
        y4 = 0; y5 = 0;

        ax1 = datosPlaca.agujeros(1).ancho;
        ax2 = datosPlaca.agujeros(2).ancho;
        ax3 = datosPlaca.agujeros(3).ancho;
        ax4 = 0; ax5 = 0;
        
        ay1 = datosPlaca.agujeros(1).alto;
        ay2 = datosPlaca.agujeros(2).alto;
        ay3 = datosPlaca.agujeros(3).alto;
        ay4 = 0; ay5 = 0;
    case 4
        x1 = datosPlaca.agujeros(1).x;
        x2 = datosPlaca.agujeros(2).x;
        x3 = datosPlaca.agujeros(3).x;
        x4 = datosPlaca.agujeros(4).x;
        x5 = 0;

        y1 = datosPlaca.agujeros(1).y;
        y2 = datosPlaca.agujeros(2).y;
        y3 = datosPlaca.agujeros(3).y;
        y4 = datosPlaca.agujeros(4).y;
        y5 = 0;

        ax1 = datosPlaca.agujeros(1).ancho;
        ax2 = datosPlaca.agujeros(2).ancho;
        ax3 = datosPlaca.agujeros(3).ancho;
        ax4 = datosPlaca.agujeros(4).ancho;
        ax5 = 0;
        
        ay1 = datosPlaca.agujeros(1).alto;
        ay2 = datosPlaca.agujeros(2).alto;
        ay3 = datosPlaca.agujeros(3).alto;
        ay4 = datosPlaca.agujeros(4).alto;
        ay5 = 0;
    case 5
        x1 = datosPlaca.agujeros(1).x;
        x2 = datosPlaca.agujeros(2).x;
        x3 = datosPlaca.agujeros(3).x;
        x4 = datosPlaca.agujeros(4).x;
        x5 = datosPlaca.agujeros(5).x;


        y1 = datosPlaca.agujeros(1).y;
        y2 = datosPlaca.agujeros(2).y;
        y3 = datosPlaca.agujeros(3).y;
        y4 = datosPlaca.agujeros(4).y;
        y5 = datosPlaca.agujeros(5).y;

        ax1 = datosPlaca.agujeros(1).ancho;
        ax2 = datosPlaca.agujeros(2).ancho;
        ax3 = datosPlaca.agujeros(3).ancho;
        ax4 = datosPlaca.agujeros(4).ancho;
        ax5 = datosPlaca.agujeros(5).ancho;
        
        ay1 = datosPlaca.agujeros(1).alto;
        ay2 = datosPlaca.agujeros(2).alto;
        ay3 = datosPlaca.agujeros(3).alto;
        ay4 = datosPlaca.agujeros(4).alto;
        ay5 = datosPlaca.agujeros(5).alto;
end

[pde_fig,ax]=pdeinit;
pdetool('appl_cb',1); 
set(ax,'DataAspectRatio',[220.60439560439556 142.72500000000002 1]); 
set(ax,'PlotBoxAspectRatio',[1 1 1]); 
set(ax,'XLim',[-10 ancho+10]); 
set(ax,'YLim',[-10 alto+10]); 
set(ax,'XTickMode','auto'); 
set(ax,'YTickMode','auto'); 
pdetool('gridon','on'); 

% Geometry description: 
pdepoly([0, 0, ancho, ancho],[0, alto, alto, 0],'P1');

switch numAgujeros
    case 0
        set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1')
    case 1
        pdeellip(x1, y1, ax1, ay1, 0, 'E1');
        set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1-E1')
    case 2
        pdeellip(x1, y1, ax1, ay1, 0, 'E1');
        pdeellip(x2, y2, ax2, ay2, 0, 'E2');
        set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1-E1-E2')
    case 3
        pdeellip(x1, y1, ax1, ay1, 0, 'E1');
        pdeellip(x2, y2, ax2, ay2, 0, 'E2');
        pdeellip(x3, y3, ax3, ay3, 0, 'E3');
        set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1-E1-E2-E3')
    case 4
        pdeellip(x1, y1, ax1, ay1, 0, 'E1');
        pdeellip(x2, y2, ax2, ay2, 0, 'E2');
        pdeellip(x3, y3, ax3, ay3, 0, 'E3');
        pdeellip(x4, y4, ax4, ay4, 0, 'E4');
        set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1-E1-E2-E3-E4')
    case 5
        pdeellip(x1, y1, ax1, ay1, 0, 'E1');
        pdeellip(x2, y2, ax2, ay2, 0, 'E2');
        pdeellip(x3, y3, ax3, ay3, 0, 'E3');
        pdeellip(x4, y4, ax4, ay4, 0, 'E4');
        pdeellip(x5, y5, ax5, ay5, 0, 'E5');
        set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1-E1-E2-E3-E4-E5')
end
 
% Boundary conditions: 
pdetool('changemode',0) 
%pdesetbd(5,'dir',1,'1','0') 
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
switch refinamiento
    case 1
        pdetool('refine') 
    case 2
        pdetool('refine')
        pdetool('refine')
    case 3
        pdetool('refine')
        pdetool('refine')
        pdetool('refine')
end

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

h = findobj(get(pde_fig,'Children'),'flat','Tag','PDEMeshMenu');
p = get(findobj(get(h,'Children'),'flat','Tag','PDEInitMesh'),'UserData');
e = get(findobj(get(h,'Children'),'flat','Tag','PDERefine'),'UserData');
t = get(findobj(get(h,'Children'),'flat','Tag','PDEMeshParam'),'UserData');

assignin('base','p',p);
assignin('base','e',e);
assignin('base','t',t);

analisis()

end 
function analisis

global p;
global e;
global t;
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
posicionborde = find(abs(Mcoorde(:,1) - 762) < 1e-6);
posicionbordeinicial = find(abs(Mcoorde(:,1) - 0) < 1e-6);
 
numnodosfuerza = length(posicionborde);
 
% CALCULO DE FUERZA NODAL POR APLICAR
Fnodal = (50*381)/numnodosfuerza;
 
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
    caxis([0 1]);
    title(titulo);
end
end

global numAgujeros;
global datosPlaca;
global p;
global e;
global t;

interfaz_pieza()
