% Archivo: brazo_robotico_serial_completo.m
% Interfaz profesional con comunicación serial para dos brazos robóticos
close all;
clear all;
clc;

% -------------------------
% Create main uifigure + layout
% -------------------------
fig = uifigure('Name','Control - Brazo Robótico (2 brazos) + Serial','Position',[100 100 1400 780]);
fig.Color = [0.96 0.97 0.98];

% grid: header + main
gl = uigridlayout(fig,[2,1]);
gl.RowHeight = {60, '1x'};
gl.ColumnWidth = {'1x'};

% --- Header (professional look) ---
hdr = uipanel(gl,'BackgroundColor',[0.13 0.17 0.2],'BorderType','none');
hdr.Layout.Row = 1; hdr.Layout.Column = 1;

% Header content: only title (keeps header compacto)
hdrGrid = uigridlayout(hdr,[1,1]);
hdrGrid.Padding = [12 10 12 10];
titleLabel = uilabel(hdrGrid,'Text','SISTEMA DE CONTROL - BRAZOS ROBÓTICOS + COM3/COM4','FontWeight','bold',...
    'FontSize',18,'HorizontalAlignment','left','FontColor',[1 1 1],'BackgroundColor',hdr.BackgroundColor);
titleLabel.Layout.Row = 1; titleLabel.Layout.Column = 1;

% --- Main panel with left controls + axes on the right ---
mainPanel = uipanel(gl,'BackgroundColor',[1 1 1]);
mainPanel.Layout.Row = 2; mainPanel.Layout.Column = 1;
mainGrid = uigridlayout(mainPanel,[1,2]);
mainGrid.Padding = 8;
mainGrid.ColumnWidth = {280, '1x'};    % left controls width + right flexible axes
mainGrid.RowHeight = {'1x'};

% Left controls panel
controlsPanel = uipanel(mainGrid,'Title','Controles','BackgroundColor',[0.98 0.98 0.99]);
controlsPanel.Layout.Row = 1; controlsPanel.Layout.Column = 1;
controlsGrid = uigridlayout(controlsPanel,[18,1]);
controlsGrid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','1x','fit','fit','fit','fit'};
controlsGrid.Padding = [10 10 10 10];
controlsGrid.BackgroundColor = controlsPanel.BackgroundColor;

% Buttons (visibles)
btnSeq = uibutton(controlsGrid,'Text','▶ Ejecutar Secuencia','ButtonPushedFcn',@(s,e) onBtnSequence(fig), ...
    'FontSize',13,'BackgroundColor',[0.16 0.45 0.78],'FontColor',[1 1 1],'Tooltip','Ejecuta secuencia predefinida de movimientos');
btnSeq.Layout.Row = 1; btnSeq.Layout.Column = 1;

% Label + Dropdown para seleccionar componente (Círculo/Triángulo/Rectángulo)
lblShape = uilabel(controlsGrid,'Text','Componente:','HorizontalAlignment','left','FontSize',12);
lblShape.Layout.Row = 2; lblShape.Layout.Column = 1;

ddlShape = uidropdown(controlsGrid,'Items',{'Ninguno','Circulo','Triangulo','Rectangulo'},...
    'Value','Ninguno','Tooltip','Selecciona componente para la secuencia', ...
    'ValueChangedFcn',@(s,e) onShapeSelected(s,e,fig));
ddlShape.Layout.Row = 3; ddlShape.Layout.Column = 1;

btnKine = uibutton(controlsGrid,'Text','🔁 IK - Click 3D','ButtonPushedFcn',@(s,e) onBtnKinematics(fig), ...
    'FontSize',13,'BackgroundColor',[0.12 0.4 0.7],'FontColor',[1 1 1],'Tooltip','Calcula cinemática inversa para posición clickeada en 3D');
btnKine.Layout.Row = 4; btnKine.Layout.Column = 1;

btnGraphs = uibutton(controlsGrid,'Text','📈 Mostrar Gráficas','ButtonPushedFcn',@(s,e) onBtnAngleGraphs(fig), ...
    'FontSize',13,'BackgroundColor',[0.08 0.33 0.6],'FontColor',[1 1 1],'Tooltip','Muestra gráficas de ángulos y cinemática');
btnGraphs.Layout.Row = 5; btnGraphs.Layout.Column = 1;

% --- NUEVO: Controles para ángulos y comunicación serial ---
sp1 = uilabel(controlsGrid,'Text','--- COMUNICACIÓN SERIAL ---','FontWeight','bold','FontColor',[0.2 0.2 0.5],...
    'HorizontalAlignment','center');
sp1.Layout.Row = 6; sp1.Layout.Column = 1;

lblAngles1 = uilabel(controlsGrid,'Text','Brazo Rojo (COM3):','HorizontalAlignment','left','FontSize',11,'FontWeight','bold');
lblAngles1.Layout.Row = 7; lblAngles1.Layout.Column = 1;

% Campos de texto para ángulos del brazo 1
anglesGrid1 = uigridlayout(controlsGrid,[1,5]);
anglesGrid1.Layout.Row = 8; anglesGrid1.Layout.Column = 1;
anglesGrid1.Padding = [0 0 0 0];
txtQ1 = gobjects(1,5);
for k = 1:5
    txtQ1(k) = uieditfield(anglesGrid1,'numeric','Value',90,'Limits',[0 180],...
        'Tooltip',sprintf('Ángulo joint %d (0-180°)',k),'FontSize',10);
    txtQ1(k).Layout.Row = 1; txtQ1(k).Layout.Column = k;
end

btnSend1 = uibutton(controlsGrid,'Text','📤 Enviar Brazo 1 (COM3)','ButtonPushedFcn',@(s,e) enviarAngulos(1,fig), ...
    'FontSize',11,'BackgroundColor',[0.85 0.18 0.18],'FontColor',[1 1 1]);
btnSend1.Layout.Row = 9; btnSend1.Layout.Column = 1;

lblAngles2 = uilabel(controlsGrid,'Text','Brazo Azul (COM4):','HorizontalAlignment','left','FontSize',11,'FontWeight','bold');
lblAngles2.Layout.Row = 10; lblAngles2.Layout.Column = 1;

% Campos de texto para ángulos del brazo 2
anglesGrid2 = uigridlayout(controlsGrid,[1,5]);
anglesGrid2.Layout.Row = 11; anglesGrid2.Layout.Column = 1;
anglesGrid2.Padding = [0 0 0 0];
txtQ2 = gobjects(1,5);
for k = 1:5
    txtQ2(k) = uieditfield(anglesGrid2,'numeric','Value',90,'Limits',[0 180],...
        'Tooltip',sprintf('Ángulo joint %d (0-180°)',k),'FontSize',10);
    txtQ2(k).Layout.Row = 1; txtQ2(k).Layout.Column = k;
end

btnSend2 = uibutton(controlsGrid,'Text','📤 Enviar Brazo 2 (COM4)','ButtonPushedFcn',@(s,e) enviarAngulos(2,fig), ...
    'FontSize',11,'BackgroundColor',[0.15 0.2 0.85],'FontColor',[1 1 1]);
btnSend2.Layout.Row = 12; btnSend2.Layout.Column = 1;

% Botón para reinicializar puertos seriales
btnReinitSerial = uibutton(controlsGrid,'Text','🔄 Reiniciar Serial','ButtonPushedFcn',@(s,e) inicializarPuertosSeriales(fig), ...
    'FontSize',11,'BackgroundColor',[0.3 0.3 0.3],'FontColor',[1 1 1]);
btnReinitSerial.Layout.Row = 13; btnReinitSerial.Layout.Column = 1;

% Botones existentes
sp2 = uilabel(controlsGrid,'Text',''); sp2.Layout.Row = 14; sp2.Layout.Column = 1;

btnReload = uibutton(controlsGrid,'Text','⟳ Recargar Modelos','ButtonPushedFcn',@(s,e) reloadSTLs(fig), ...
    'FontSize',12,'BackgroundColor',[0.2 0.2 0.2],'FontColor',[1 1 1],'Tooltip','Recarga los modelos 3D STL');
btnReload.Layout.Row = 15; btnReload.Layout.Column = 1;

btnHome = uibutton(controlsGrid,'Text','🏠 Posición Inicial','ButtonPushedFcn',@(s,e) resetHome(fig), ...
    'FontSize',12,'BackgroundColor',[0.2 0.2 0.2],'FontColor',[1 1 1],'Tooltip','Regresa a posición home (90° todas las articulaciones)');
btnHome.Layout.Row = 16; btnHome.Layout.Column = 1;

btnStop = uibutton(controlsGrid,'Text','■ Detener','ButtonPushedFcn',@(s,e) stopTimer(fig), ...
    'FontSize',12,'BackgroundColor',[0.7 0.12 0.12],'FontColor',[1 1 1],'Tooltip','Detiene el timer de actualización de gráficas');
btnStop.Layout.Row = 17; btnStop.Layout.Column = 1;

% filler
lblVersion = uilabel(controlsGrid,'Text','Versión: v2.0 + Serial COM3/COM4','HorizontalAlignment','center');
lblVersion.Layout.Row = 18; lblVersion.Layout.Column = 1;

% Right: axes
axPanel = uipanel(mainGrid,'BackgroundColor',[1 1 1]);
axPanel.Layout.Row = 1; axPanel.Layout.Column = 2;
axGrid = uigridlayout(axPanel,[1,1]); axGrid.Padding = 6;

ax = uiaxes(axGrid,'BackgroundColor',[0.99 0.99 1]);
ax.Layout.Row = 1; ax.Layout.Column = 1;
grid(ax,'on'); view(ax,3); axis(ax,[-0.6 0.6 -0.35 0.35 0 0.55]);
xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z'); ax.DataAspectRatio = [1 1 1];

% Attach click callback to axes (user clicks to set goal)
ax.ButtonDownFcn = @(src,event) onAxesClick(src, event, fig);

% -------------------------
% Internal fixed parameters (no controls)
% -------------------------
handles.ax = ax;
handles.l6 = 0.11;
handles.baseHeight = 0.055;
handles.fps = 120;

% STLs and mesh / visual handles
handles.stlNames = {'LINKBASE.stl','LINK11.STL','LINK22.STL','LINK33.STL','LINK44.STL','LINK55.STL'};
handles.linkSTL = cell(1,6);
handles.linkMeshOffsets = cell(2,6);
for arm=1:2, for k=1:6, handles.linkMeshOffsets{arm,k} = eye(4); end, end
handles.meshCentroid = cell(1,6); handles.meshTop = cell(1,6); handles.meshBottom = cell(1,6); handles.meshJoint = cell(1,6);
handles.jointPointsManual = {[],[-0.011,0.007,-0.018],[-0.005,0,-0.06],[0,0,-0.05],[-0.004,0,-0.048],[-0.005,0,-0.14]};

% drawing placeholders
handles.linkPatches = cell(2,6);
handles.frame_handles = cell(2,6,3);
handles.lightCreated = false;
handles.currentAngles = 90*ones(1,5);
handles.simAnglesArm1 = []; handles.simAnglesArm2 = [];

% goal (set by click)
handles.goalPos = []; handles.goalHandle = [];

% plotting data + timer
handles.plotData.ts = []; handles.plotData.qs = []; handles.plotData.eeA = []; handles.plotData.eeB = [];
handles.plotHandles = struct();
handles.plotTimer = [];

% selected shape (default Ninguno)
handles.selectedShape = 'Ninguno';

% -------------- NUEVO: Puertos seriales --------------
handles.s1 = []; % COM3 - Brazo Rojo
handles.s2 = []; % COM4 - Brazo Azul
handles.lastTrajectory_Brazo2 = []; % Para almacenar trayectoria del brazo 2

% -------------- FIX: initialize baseOffsets BEFORE calling reloadSTLs --------------
handles.baseOffsets = [0 0 0; 0.22 0 0];
% ----------------------------------------------------------------------------------

% Guardar referencias a los campos de texto
handles.txtQ1 = txtQ1;
handles.txtQ2 = txtQ2;

guidata(fig, handles);

% Inicializar puertos seriales
inicializarPuertosSeriales(fig);

% Load STLs and initial draw
reloadSTLs(fig);
actualizarBrazo(fig);

% Prepare hidden figures for plotting/kinematics
createAuxFigures(fig);

% Create and store a timer to update plots while animating
updatePeriod = 0.15;
t = timer('ExecutionMode','fixedSpacing','Period',updatePeriod,'BusyMode','drop',...
    'TimerFcn',@(~,~) plotTimerTick(fig));
handles = guidata(fig); handles.plotTimer = t; guidata(fig, handles);

% Clean-up on close
fig.CloseRequestFcn = @(src,evt) closeMainFigure(src,evt);

%% -------------------------
%% NUEVA FUNCIÓN: Inicializar puertos seriales
%% -------------------------
function inicializarPuertosSeriales(fig)
    handles = guidata(fig);
    
    try
        % Cerrar puertos si estaban abiertos
        if ~isempty(handles.s1) && isvalid(handles.s1)
            fclose(handles.s1);
            delete(handles.s1);
        end
        if ~isempty(handles.s2) && isvalid(handles.s2)
            fclose(handles.s2);
            delete(handles.s2);
        end
        
        % Inicializar COM3 - Brazo Rojo
        handles.s1 = serialport("COM3", 9600);
        configureTerminator(handles.s1, "LF");
        pause(1);
        
        % Inicializar COM4 - Brazo Azul  
        handles.s2 = serialport("COM4", 9600);
        configureTerminator(handles.s2, "LF");
        pause(1);
        
        disp('Puertos seriales inicializados: COM3 y COM4');
        uialert(fig,'Puertos seriales COM3 y COM4 inicializados correctamente.','Comunicación Serial','Icon','success');
        
    catch ME
        warning('No se pudieron inicializar los puertos seriales: %s', ME.message);
        uialert(fig,['Error inicializando puertos seriales: ' ME.message],'Error Serial','Icon','error');
        handles.s1 = [];
        handles.s2 = [];
    end
    
    guidata(fig, handles);
end

%% -------------------------
%% NUEVA FUNCIÓN: Enviar ángulos por serial
%% -------------------------
function enviarAngulos(brazo_id, fig)
    handles = guidata(fig);
    
    if brazo_id == 1
        % Brazo Rojo - COM3
        if isempty(handles.s1) || ~isvalid(handles.s1)
            uialert(fig,'Puerto COM3 no está abierto.','Error Comunicación'); 
            return
        end
        
        % Obtener ángulos actuales del brazo
        if ~isempty(handles.simAnglesArm1)
            Q = handles.simAnglesArm1;
        else
            Q = handles.currentAngles;
        end
        
        % Actualizar campos de texto
        for k = 1:5
            handles.txtQ1(k).Value = Q(k);
        end
        
        % Formatear y enviar mensaje
        msg = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', Q);
        writeline(handles.s1, msg);
        
        uialert(fig,['Ángulos enviados a Brazo 1 (COM3): ' sprintf('%.1f ',Q)],'Envío Exitoso','Icon','success');
        
    else
        % Brazo Azul - COM4
        if isempty(handles.s2) || ~isvalid(handles.s2)
            uialert(fig,'Puerto COM4 no está abierto.','Error Comunicación'); 
            return
        end
        
        % Priorizar enviar trayectoria si existe
        if ~isempty(handles.lastTrajectory_Brazo2)
            Qtr = handles.lastTrajectory_Brazo2;
            for i = 1:size(Qtr,1)
                msg = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', Qtr(i,:));
                writeline(handles.s2, msg);
                pause(0.02); % Pequeña pausa entre puntos
            end
            uialert(fig,sprintf('Trayectoria completa (%d puntos) enviada a Brazo 2 (COM4).',size(Qtr,1)),'Trayectoria Enviada','Icon','success');
        else
            % Enviar ángulos actuales
            if ~isempty(handles.simAnglesArm2)
                Q = handles.simAnglesArm2;
            else
                Q = handles.currentAngles;
            end
            
            % Actualizar campos de texto
            for k = 1:5
                handles.txtQ2(k).Value = Q(k);
            end
            
            msg = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', Q);
            writeline(handles.s2, msg);
            
            uialert(fig,['Ángulos enviados a Brazo 2 (COM4): ' sprintf('%.1f ',Q)],'Envío Exitoso','Icon','success');
        end
    end
    
    guidata(fig, handles);
end

%% -------------------------
%% UI interaction callbacks
%% -------------------------
function onAxesClick(src, ~, fig)
    % set goal position at clicked 3D point (project to z-range)
    handles = guidata(fig);
    cp = src.CurrentPoint; % 2x3
    pt = cp(1,1:3)';
    % clamp within viewing Z-range (>=0)
    pt(3) = max(0, pt(3));
    % store and draw marker
    if isfield(handles,'goalHandle') && ~isempty(handles.goalHandle) && isgraphics(handles.goalHandle)
        delete(handles.goalHandle);
    end
    hold(handles.ax,'on');
    h = plot3(handles.ax, pt(1), pt(2), pt(3), 'ko','MarkerFaceColor',[1 0.84 0],'MarkerSize',10);
    hold(handles.ax,'off');
    handles.goalPos = pt;
    handles.goalHandle = h;
    guidata(fig, handles);
end

function onBtnSequence(fig)
    handles = guidata(fig);
    % start plot timer
    if isfield(handles,'plotTimer') && ~isempty(handles.plotTimer) && isvalid(handles.plotTimer)
        try start(handles.plotTimer); catch; end
    end
    % run the existing sequence (uses internal parameters and selectedShape)
    runSequenceCallback(fig);
end

function onBtnKinematics(fig)
    handles = guidata(fig);
    if isempty(handles.goalPos)
        uialert(fig,'Marque un objetivo haciendo click en la vista 3D antes de calcular la inversa.','Objetivo no definido','Icon','warning');
        return;
    end

    % Create new figure with two panels (left=red, right=blue)
    kinFig = uifigure('Name','Cinemática - Resultados (Rojo / Azul)','Position',[200 200 1000 420]);
    grid = uigridlayout(kinFig,[1,2]);
    grid.ColumnWidth = {'1x','1x'};
    grid.RowHeight = {'1x'};

    % For both arms: compute IK and prepare tables
    arms = {'Rojo','Azul'};
    results = cell(1,2);
    for armIdx = 1:2
        % compute IK using solveIKForTarget (armIdx supported)
        [q_sol, info] = solveIKForTarget(handles.goalPos, armIdx, fig, true);
        current = handles.currentAngles(:);
        if isempty(q_sol)
            q_sol = nan(5,1);
            pos_final = forwardPositionFromAngles_withBase(current, handles.baseOffsets(armIdx,:), handles.baseHeight, handles.l6);
            err = norm(pos_final - handles.goalPos(:));
        else
            pos_final = forwardPositionFromAngles_withBase(q_sol, handles.baseOffsets(armIdx,:), handles.baseHeight, handles.l6);
            err = norm(pos_final - handles.goalPos(:));
        end

        % Prepare table data
        jointIdx = (1:5)';
        current_col = current(:);
        ik_col = q_sol(:);
        tabData = [num2cell(jointIdx), num2cell(current_col), num2cell(ik_col)];

        % Create panel and uitable
        p = uipanel(grid);
        p.Title = sprintf('%s (brazo %d)', arms{armIdx}, armIdx);
        p.Layout.Row = 1; p.Layout.Column = armIdx;
        pGrid = uigridlayout(p,[3,1]);
        pGrid.RowHeight = {'fit','fit','1x'};
        % joint table
        jt = uitable(pGrid,'Data',tabData,'ColumnName',{'Joint','Current (deg)','IK solution (deg)'}, 'ColumnEditable',[false false false]);
        jt.Layout.Row = 1; jt.Layout.Column = 1;
        % EE table (single row)
        eeData = {pos_final(1), pos_final(2), pos_final(3), err*1000}; % pos in m, err in mm
        eet = uitable(pGrid,'Data',eeData,'ColumnName',{'EE_x (m)','EE_y (m)','EE_z (m)','err (mm)'}, 'ColumnEditable',[false false false false]);
        eet.Layout.Row = 2; eet.Layout.Column = 1;

        % Add a small descriptive label
        if isstruct(info)
            lbl = uilabel(pGrid,'Text',sprintf('IK foundExact: %d   bestJ: %.4g', double(isfield(info,'foundExact') && info.foundExact), info.bestJ));
        else
            lbl = uilabel(pGrid,'Text','Info no disponible');
        end
        lbl.Layout.Row = 3; lbl.Layout.Column = 1;

        results{armIdx} = struct('q_sol',q_sol,'pos_final',pos_final,'err',err,'table',jt,'eetable',eet);
    end
end

function onBtnAngleGraphs(fig)
    handles = guidata(fig);
    % show existing angles figure if present
    if isfield(handles.plotHandles,'anglesFig') && isgraphics(handles.plotHandles.anglesFig)
        set(handles.plotHandles.anglesFig,'Visible','on');
    end
    if isfield(handles,'plotTimer') && ~isempty(handles.plotTimer) && isvalid(handles.plotTimer)
        try start(handles.plotTimer); catch; end
    end

    % Now compute velocities via Jacobian for both arms using plotData (if available)
    if ~isfield(handles,'plotData') || isempty(handles.plotData) || isempty(handles.plotData.qs) || isempty(handles.plotData.ts)
        uialert(fig,'No hay datos de trayectoria (plotData). Ejecuta o registra una secuencia primero para calcular velocidades.','Datos insuficientes','Icon','warning');
        return;
    end

    % initialize outputs to safe defaults
    t_mid = []; velA = []; velB = [];

    % compute ee velocities for arm 1 and arm 2
    try
        [t_mid, velA] = computeEEVelocitiesFromTrajectory(handles.plotData.qs, handles.plotData.ts, 1, fig); % velA: Nx3
    catch ME
        warning(['Error calculando velocidades para brazo 1: ' ME.message]);
        t_mid = []; velA = [];
    end
    try
        [~, velB] = computeEEVelocitiesFromTrajectory(handles.plotData.qs, handles.plotData.ts, 2, fig);
    catch ME
        warning(['Error calculando velocidades para brazo 2: ' ME.message]);
        velB = [];
    end

    % Open velocities figure
    velFig = figure('Name','Velocidades (Jacobian) - Rojo / Azul','NumberTitle','off','Position',[250 150 1000 500]);
    if ~isempty(t_mid) && ~isempty(velA)
        subplot(2,1,1);
        plot(t_mid, velA(:,1),'LineWidth',1.2); hold on;
        plot(t_mid, velA(:,2),'LineWidth',1.2); plot(t_mid, velA(:,3),'LineWidth',1.2);
        hold off; grid on;
        legend('v_x','v_y','v_z','Location','best'); title('Brazo Rojo - Velocidad del EE (m/s)'); xlabel('Tiempo (s)'); ylabel('Velocidad (m/s)');
    else
        subplot(2,1,1); text(0.2,0.5,'Datos insuficientes para Brazo Rojo'); axis off;
    end

    if ~isempty(t_mid) && ~isempty(velB)
        subplot(2,1,2);
        plot(t_mid, velB(:,1),'LineWidth',1.2); hold on;
        plot(t_mid, velB(:,2),'LineWidth',1.2); plot(t_mid, velB(:,3),'LineWidth',1.2);
        hold off; grid on;
        legend('v_x','v_y','v_z','Location','best'); title('Brazo Azul - Velocidad del EE (m/s)'); xlabel('Tiempo (s)'); ylabel('Velocidad (m/s)');
    else
        subplot(2,1,2); text(0.2,0.5,'Datos insuficientes para Brazo Azul'); axis off;
    end
end

function stopTimer(fig)
    handles = guidata(fig);
    if isfield(handles,'plotTimer') && ~isempty(handles.plotTimer) && isvalid(handles.plotTimer)
        try stop(handles.plotTimer); catch; end
    end
end

%% -------------------------
%% Aux: create hidden aux figures for plotting
%% -------------------------
function createAuxFigures(fig)
    handles = guidata(fig);
    % Angles
    anglesFig = figure('Name','Ángulos por Eslabón','NumberTitle','off','Visible','off');
    angAx = axes('Parent',anglesFig);
    xlabel(angAx,'Tiempo (s)'); ylabel(angAx,'Ángulo (deg)'); grid(angAx,'on'); hold(angAx,'on');
    % Kinematics
    kinFig = figure('Name','Cinemática Directa / Inversa','NumberTitle','off','Visible','off');
    axDirect = subplot(1,2,1,'Parent',kinFig); grid(axDirect,'on'); title(axDirect,'Cinemática Directa'); view(axDirect,3); axis(axDirect,[-0.6 0.6 -0.35 0.35 0 0.55]); hold(axDirect,'on');
    axInverse = subplot(1,2,2,'Parent',kinFig); grid(axInverse,'on'); title(axInverse,'Cinemática Inversa'); hold(axInverse,'on');
    handles.plotHandles.anglesFig = anglesFig; handles.plotHandles.angAx = angAx;
    handles.plotHandles.kinFig = kinFig; handles.plotHandles.axDirect = axDirect; handles.plotHandles.axInverse = axInverse;
    guidata(fig, handles);
end

%% -------------------------
%% Core visual & robot functions
%% -------------------------
function reloadSTLs(fig)
    handles = guidata(fig);
    names = handles.stlNames;
    for k=1:6
        try
            S = stlread(names{k});
            handles.linkSTL{k} = S;
        catch
            % placeholder small box
            verts = [0 0 0; 0.02 0 0; 0.02 0.02 0; 0 0.02 0; 0 0 0.02; 0.02 0 0.02; 0.02 0.02 0.02; 0 0.02 0.02];
            faces = [1 2 3;1 3 4;5 6 7;5 7 8;1 2 6;1 6 5;2 3 7;2 7 6;3 4 8;3 8 7;4 1 5;4 5 8];
            S.faces = faces; S.vertices = verts;
            handles.linkSTL{k} = S;
        end

        stl = handles.linkSTL{k};
        if isempty(stl)
            handles.meshCentroid{k} = [0 0 0]; handles.meshTop{k} = 0; handles.meshBottom{k} = 0; handles.meshJoint{k} = [0 0 0];
            continue;
        else
            if isfield(stl,'vertices'), v = stl.vertices * 1e-3; else v = stl.Points * 1e-3; end
            if isempty(v)
                handles.meshCentroid{k} = [0 0 0]; handles.meshTop{k} = 0; handles.meshBottom{k} = 0; handles.meshJoint{k} = [0 0 0];
            else
                centroid = mean(v,1); handles.meshCentroid{k} = centroid;
                v_centered = v - centroid; zmax = max(v_centered(:,3)); zmin = min(v_centered(:,3));
                handles.meshTop{k} = zmax; handles.meshBottom{k} = zmin;
                range = zmax - zmin; tol = max(range*0.05,1e-6);
                if k==1, idx = v_centered(:,3) >= (zmax - tol); else idx = v_centered(:,3) <= (zmin + tol); end
                if sum(idx)==0
                    if k==1, idx = (v_centered(:,3) == zmax); else idx = (v_centered(:,3) == zmin); end
                end
                jointPoint = mean(v_centered(idx,:),1);
                if isfield(handles,'jointPointsManual') && ~isempty(handles.jointPointsManual)
                    manual = handles.jointPointsManual{k};
                    if ~isempty(manual), jointPoint = manual(:)'; end
                end
                handles.meshJoint{k} = jointPoint;
            end
        end
    end

    % create/update patches - colors rojo/azul
    colorsArm = {[0.85 0.18 0.18], [0.15 0.2 0.85]};
    alphaVal = 0.95;
    for armIdx = 1:2
        for k = 1:6
            stl = handles.linkSTL{k};
            if isempty(stl), v = zeros(0,3); f = []; else
                if isfield(stl,'vertices'), v = stl.vertices * 1e-3; else v = stl.Points * 1e-3; end
                if isfield(stl,'faces'), f = stl.faces; else f = stl.ConnectivityList; end
            end
            centroid = handles.meshCentroid{k};
            if ~isempty(v), v_centered = v - centroid; else v_centered = v; end

            if isempty(handles.linkPatches{armIdx,k}) || ~isgraphics(handles.linkPatches{armIdx,k})
                try
                    p = patch(handles.ax, 'Faces', f, 'Vertices', v_centered, 'FaceColor', colorsArm{armIdx}, 'EdgeColor', 'none', 'FaceAlpha', alphaVal);
                    set(p,'FaceLighting','gouraud','SpecularStrength',0.2,'AmbientStrength',0.6);
                    handles.linkPatches{armIdx,k} = p;
                catch
                    p = patch(handles.ax, 'Faces', [], 'Vertices', zeros(0,3), 'FaceColor', colorsArm{armIdx}, 'EdgeColor', 'none', 'FaceAlpha', alphaVal);
                    set(p,'FaceLighting','gouraud','SpecularStrength',0.2,'AmbientStrength',0.6);
                    handles.linkPatches{armIdx,k} = p;
                end
            else
                p = handles.linkPatches{armIdx,k};
                try set(p,'Faces',f,'FaceAlpha',alphaVal,'Vertices',v_centered,'FaceLighting','gouraud'); catch, end
            end
        end
    end

    % offsets align
    for armIdx=1:2
        for k=1:6
            jointPoint = handles.meshJoint{k};
            M = Trans(-jointPoint(1), -jointPoint(2), -jointPoint(3));
            handles.linkMeshOffsets{armIdx,k} = M;
        end
        l6 = handles.l6;
        handles.linkMeshOffsets{armIdx,6} = handles.linkMeshOffsets{armIdx,6} * Trans(0,0,-l6);
    end

    guidata(fig, handles);
    actualizarBrazo(fig);
end

function actualizarBrazo(fig)
    handles = guidata(fig);
    ax = handles.ax; l6 = handles.l6; baseHeight = handles.baseHeight;
    fps_user = handles.fps; if isempty(fps