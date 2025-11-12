function brazo_robotico_gui_doble_shapes
% Doble GUI 5GDL adaptado: elimina casillas de puntos y permite dibujar
% figuras (cuadro, triángulo, círculo) con el efector final del BRAZO 2
% Conserva botones Abrir/Cerrar puerto y añade Guardar/Enviar ángulos por
% separado: Brazo1 -> COM3, Brazo2 -> COM4 (baud 57600).

% --- Configuración inicial ---
puerto1 = "COM3";
puerto2 = "COM4";
baud    = 57600;
s1 = []; s2 = []; % objetos serial

% --- Handles compartidos brazo 1 ---
txtQ1  = gobjects(1,5);
txtQ1_init = gobjects(1,5); % Campos para ángulos iniciales
txtQ1_pre = gobjects(1,5); % Campos para ángulos pre-secuencia
patches1 = gobjects(1,5);
linkSTL1 = cell(1,5);

% --- Handles compartidos brazo 2 ---
txtQ2  = gobjects(1,5);
txtQ2_init = gobjects(1,5); % Campos para ángulos iniciales
txtQ2_pre = gobjects(1,5); % Campos para ángulos pre-secuencia
patches2 = gobjects(1,5);
linkSTL2 = cell(1,5);

ax = [];
valores_iniciales = [0, 90, 90, 90, 90];

% === Ventana principal ===
fig = uifigure('Name','Doble Brazo Robótico 5 GDL - Figuras (Jacobiano)','WindowState', 'maximized');

% === Ejes 3D ===
ax = uiaxes(fig,'Position',[500 10 820 620]);
grid(ax,"on"); axis(ax,[-0.2 0.8 -0.3 0.3 0 0.45]);
xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z'); view(ax,3);
ax.DataAspectRatio = [1 1 1];
light(ax); lighting(ax,'gouraud');

% === Base común ===
baseSTL = stlread('Base.stl');
v_base = baseSTL.Points * 1e-3;
patch(ax, 'Faces', baseSTL.ConnectivityList, 'Vertices', v_base,...
      'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 1.0);

% === Segunda base (desplazada en X) ===
offset_base = 0.6; % mismo desplazamiento usado para el segundo brazo
v_base2 = v_base + [offset_base 0 0];
patch(ax, 'Faces', baseSTL.ConnectivityList, 'Vertices', v_base2,...
      'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 1.0);

% === Colores para los brazos ===
colors1 = {[0.8 0.1 0.1],[0.1 0.8 0.1],[0.1 0.1 0.8],[0.8 0.8 0.1],[0.5 0.5 0.5]};
colors2 = {[0.9 0.5 0.2],[0.2 0.7 0.9],[0.7 0.2 0.7],[0.3 0.8 0.3],[0.2 0.2 0.2]};

% === Cargar STL brazo 1 ===
for j = 1:5
    linkSTL1{j} = stlread(sprintf('link%d.stl', j));
    v = linkSTL1{j}.Points * 1e-3;
    patches1(j) = patch(ax,'Faces',linkSTL1{j}.ConnectivityList,...
        'Vertices',v,'FaceColor',colors1{j},'EdgeColor','none','FaceAlpha',0.9);
end

% === Cargar STL brazo 2 (último eslabón diferente) ===
for j = 1:4
    linkSTL2{j} = stlread(sprintf('link%d.stl', j));
end
linkSTL2{5} = stlread('link5_alt.stl'); % versión distinta
for j = 1:5
    v = linkSTL2{j}.Points * 1e-3;
    patches2(j) = patch(ax,'Faces',linkSTL2{j}.ConnectivityList,...
        'Vertices',v,'FaceColor',colors2{j},'EdgeColor','none','FaceAlpha',0.9);
end

% === Funciones de transformación homogénea ===
Rx = @(q)[1 0 0 0; 0 cos(q) -sin(q) 0; 0 sin(q) cos(q) 0; 0 0 0 1];
Ry = @(q)[cos(q) 0 sin(q) 0; 0 1 0 0; -sin(q) 0 cos(q) 0; 0 0 0 1];
Rz = @(q)[cos(q) -sin(q) 0 0; sin(q) cos(q) 0 0; 0 0 1 0; 0 0 0 1];
Trans = @(x,y,z)[1 0 0 x; 0 1 0 y; 0 0 1 z; 0 0 0 1];

% === Función genérica de actualización CORREGIDA ===
function [EEpos] = actualizar(q_deg, patches, linkSTL, offsetX, txtQ)
    q = q_deg * pi/180;
    
    % CORRECCIÓN: Aplicar offset_base correctamente en la primera transformación
    % Brazo 1: offsetX = 0, Brazo 2: offsetX = offset_base
    T01 = Trans(offsetX, 0, 0) * Rz(q(1)) * Trans(0, -20e-3, 105.28e-3);
    T12 = Ry(q(2)) * Trans(-120e-3, 0, 0);
    T23 = Ry(q(3)) * Trans(-5.3e-3, 7.5e-3, -89.75e-3);
    T34 = Rz(q(4)) * Trans(5e-3, 14e-3, -65.5e-3);
    T45 = Ry(q(5)) * Trans(38e-3, 25.9e-3, 14e-3);

    A1 = T01; 
    A2 = A1*T12; 
    A3 = A2*T23; 
    A4 = A3*T34; 
    A5 = A4*T45;
    T_all = {A1,A2,A3,A4,A5};

    for j=1:5
        v = linkSTL{j}.Points * 1e-3;
        v_h = [v, ones(size(v,1),1)] * T_all{j}';
        patches(j).Vertices = v_h(:,1:3);
    end

    % Posición del efector final (origen del último eslabón)
    EE = T_all{5};
    EEpos = EE(1:3,4)';

    % Actualizar campos
    for j=1:5
        if isvalid(txtQ(j)), txtQ(j).Value = q_deg(j); end
    end
    drawnow limitrate
end

% === Funciones de puerto ===
function abrirPuerto1(~,~)
    s1 = abrirPuerto(fig, s1, puerto1, baud);
end
function cerrarPuerto1(~,~)
    s1 = cerrarPuerto(fig, s1);
end
function abrirPuerto2(~,~)
    s2 = abrirPuerto(fig, s2, puerto2, baud);
end
function cerrarPuerto2(~,~)
    s2 = cerrarPuerto(fig, s2);
end

% === Crear paneles GUI con nuevos controles ===
crearPaneles(fig);

    function crearPaneles(fig)
        % Brazo 1 - controles expandidos
        panel1 = uipanel(fig,'Position',[5 470 500 270],'Title','Brazo 1 (COM3)');
        
        % Panel de configuración de ángulos
        panelConfig1 = uipanel(panel1,'Position',[5 125 490 120],'Title','Configuración de Ángulos');
        uilabel(panelConfig1,'Text','Inicial:','Position',[5 50 40 20]);
        uilabel(panelConfig1,'Text','Pre-Sec:','Position',[5 20 50 20]);
        
        for i=1:5
            uilabel(panelConfig1,'Text',sprintf('q%d',i),'Position',[75+(i-1)*55 75 40 22]);
            txtQ1_init(i) = uieditfield(panelConfig1,'numeric','Position',[65+(i-1)*55 50 40 22],...
                                      'Value',valores_iniciales(i));
            txtQ1_pre(i) = uieditfield(panelConfig1,'numeric','Position',[65+(i-1)*55 20 40 22],...
                                     'Value',valores_iniciales(i));
        end
        
        uibutton(panelConfig1,'Text','Aplicar Init','Position',[350 50 100 25],...
                'ButtonPushedFcn',@(~,~)aplicarAngulosIniciales(1));
        uibutton(panelConfig1,'Text','Aplicar Pre','Position',[350 20 100 25],...
                'ButtonPushedFcn',@(~,~)aplicarAngulosPreSecuencia(1));

        panelCtrl1 = uipanel(panel1,'Position',[5 65 490 60],'Title','Puerto y Acciones');
        uibutton(panelCtrl1,'Text','Abrir','Position',[5 5 80 30],'ButtonPushedFcn',@abrirPuerto1);
        uibutton(panelCtrl1,'Text','Cerrar','Position',[90 5 80 30],'ButtonPushedFcn',@cerrarPuerto1);
        uibutton(panelCtrl1,'Text','Guardar Ángulos','Position',[175 5 120 30],'ButtonPushedFcn',@(~,~)guardarAngulos(1));
        uibutton(panelCtrl1,'Text','Enviar Ángulos','Position',[300 5 120 30],'ButtonPushedFcn',@(~,~)enviarAngulos(1));

        panelAng1 = uipanel(panel1,'Position',[5 5 490 60],'Title','Ángulos actuales (°)');
        for i=1:5
            txtQ1(i) = uieditfield(panelAng1,'numeric','Position',[20+(i-1)*55 10 40 22],...
                                  'Editable','off','Value',valores_iniciales(i));
        end

        % Brazo 2 - controles expandidos
        panel2 = uipanel(fig,'Position',[5 195 500 270],'Title','Brazo 2 (COM4)');
        
        % Panel de configuración de ángulos
        panelConfig2 = uipanel(panel2,'Position',[5 125 490 120],'Title','Configuración de Ángulos');
        uilabel(panelConfig2,'Text','Inicial:','Position',[5 50 40 20]);
        uilabel(panelConfig2,'Text','Pre-Sec:','Position',[5 20 50 20]);
        
        for i=1:5
            uilabel(panelConfig2,'Text',sprintf('q%d',i),'Position',[75+(i-1)*55 75 40 22]);
            txtQ2_init(i) = uieditfield(panelConfig2,'numeric','Position',[65+(i-1)*55 50 40 22],...
                                      'Value',valores_iniciales(i));
            txtQ2_pre(i) = uieditfield(panelConfig2,'numeric','Position',[65+(i-1)*55 20 40 22],...
                                     'Value',valores_iniciales(i));
        end
        
        uibutton(panelConfig2,'Text','Aplicar Init','Position',[350 50 100 25],...
                'ButtonPushedFcn',@(~,~)aplicarAngulosIniciales(2));
        uibutton(panelConfig2,'Text','Aplicar Pre','Position',[350 20 100 25],...
                'ButtonPushedFcn',@(~,~)aplicarAngulosPreSecuencia(2));

        panelCtrl2 = uipanel(panel2,'Position',[5 65 490 60],'Title','Puerto y Figuras');
        uibutton(panelCtrl2,'Text','Abrir','Position',[5 5 80 30],'ButtonPushedFcn',@abrirPuerto2);
        uibutton(panelCtrl2,'Text','Cerrar','Position',[90 5 80 30],'ButtonPushedFcn',@cerrarPuerto2);

        % Botones de figuras
        uibutton(panelCtrl2,'Text','■','Position',[175 5 30 30], 'ButtonPushedFcn',@(~,~)dibujarFigura('cuadro'));
        uibutton(panelCtrl2,'Text','►','Position',[210 5 30 30], 'ButtonPushedFcn',@(~,~)dibujarFigura('triangulo'));
        uibutton(panelCtrl2,'Text','○','Position',[245 5 30 30], 'ButtonPushedFcn',@(~,~)dibujarFigura('circulo'));
        panelAng2 = uipanel(panel2,'Position',[5 5 490 60],'Title','Ángulos actuales (°)');
        for i=1:5
            txtQ2(i) = uieditfield(panelAng2,'numeric','Position',[20+(i-1)*55 10 40 22],...
                                  'Editable','off','Value',valores_iniciales(i));
        end
    end

% === Función para aplicar ángulos iniciales ===
function aplicarAngulosIniciales(brazo_id)
    if brazo_id == 1
        q_init = zeros(1,5);
        for k=1:5
            q_init(k) = txtQ1_init(k).Value;
        end
        actualizar(q_init, patches1, linkSTL1, 0, txtQ1);
        uialert(fig,'Ángulos iniciales aplicados al Brazo 1','Info');
    else
        q_init = zeros(1,5);
        for k=1:5
            q_init(k) = txtQ2_init(k).Value;
        end
        actualizar(q_init, patches2, linkSTL2, offset_base, txtQ2);
        uialert(fig,'Ángulos iniciales aplicados al Brazo 2','Info');
    end
end

% === Función para aplicar ángulos pre-secuencia ===
function aplicarAngulosPreSecuencia(brazo_id)
    if brazo_id == 1
        q_pre = zeros(1,5);
        for k=1:5
            q_pre(k) = txtQ1_pre(k).Value;
        end
        actualizar(q_pre, patches1, linkSTL1, 0, txtQ1);
        uialert(fig,'Ángulos pre-secuencia aplicados al Brazo 1','Info');
    else
        q_pre = zeros(1,5);
        for k=1:5
            q_pre(k) = txtQ2_pre(k).Value;
        end
        actualizar(q_pre, patches2, linkSTL2, offset_base, txtQ2);
        uialert(fig,'Ángulos pre-secuencia aplicados al Brazo 2','Info');
    end
end

% === Función para movimiento suave entre configuraciones ===
function movimientoSuave(brazo_id, q_inicial, q_final, duracion)
    N = 50; % número de pasos
    for i=1:N
        t = i/N;
        % Interpolación cúbica para movimiento suave
        q_interp = q_inicial + (q_final - q_inicial) * (3*t^2 - 2*t^3);
        
        if brazo_id == 1
            actualizar(q_interp, patches1, linkSTL1, 0, txtQ1);
            if ~isempty(s1) && isvalid(s1)
                msg1 = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', q_interp);
                writeline(s1, msg1);
            end
        else
            actualizar(q_interp, patches2, linkSTL2, offset_base, txtQ2);
            if ~isempty(s2) && isvalid(s2)
                msg2 = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', q_interp);
                writeline(s2, msg2);
            end
        end
        pause(duracion/N);
    end
end

% === FK y Jacobiano CORREGIDO para el brazo 2 ===
function [pos, J] = FK_and_Jacobian(Qdeg, offsetX)
    Q = Qdeg*pi/180;
    
    % CORRECCIÓN: Aplicar offset_base en la primera transformación
    T01 = Trans(offsetX, 0, 0) * Rz(Q(1)) * Trans(0, -20e-3, 105.28e-3);
    T12 = Ry(Q(2)) * Trans(-120e-3, 0, 0);
    T23 = Ry(Q(3)) * Trans(-5.3e-3, 7.5e-3, -89.75e-3);
    T34 = Rz(Q(4)) * Trans(5e-3, 14e-3, -65.5e-3);
    T45 = Ry(Q(5)) * Trans(38e-3, 25.9e-3, 14e-3);
    
    A5 = T01 * T12 * T23 * T34 * T45;
    pos = A5(1:3,4)';
    
    eps_q = 1e-6;
    J = zeros(3,5);
    for k=1:5
        Qp = Q; Qp(k) = Qp(k) + eps_q;
        
        T01p = Trans(offsetX, 0, 0) * Rz(Qp(1)) * Trans(0, -20e-3, 105.28e-3);
        T12p = Ry(Qp(2)) * Trans(-120e-3, 0, 0);
        T23p = Ry(Qp(3)) * Trans(-5.3e-3, 7.5e-3, -89.75e-3);
        T34p = Rz(Qp(4)) * Trans(5e-3, 14e-3, -65.5e-3);
        T45p = Ry(Qp(5)) * Trans(38e-3, 25.9e-3, 14e-3);
        
        A5p = T01p * T12p * T23p * T34p * T45p;
        pos_p = A5p(1:3,4);
        J(:,k) = (pos_p - A5(1:3,4)) / eps_q;
    end
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function dibujarFigura(tipo)
    % === Obtener configuraciones pre-secuencia e iniciales ===
    q1_pre = zeros(1,5); 
    q2_pre = zeros(1,5);
    q1_init = zeros(1,5);
    q2_init = zeros(1,5);
    q1_actual = zeros(1,5);
    q2_actual = zeros(1,5);
    
    for k=1:5
        q1_pre(k) = txtQ1_pre(k).Value;
        q2_pre(k) = txtQ2_pre(k).Value;
        q1_init(k) = txtQ1_init(k).Value;
        q2_init(k) = txtQ2_init(k).Value;
        q1_actual(k) = txtQ1(k).Value;  % Posición actual del brazo 1
        q2_actual(k) = txtQ2(k).Value;  % Posición actual del brazo 2
    end

    %% === FASE 0: Movimiento AMBOS brazos a posición pre-secuencia ===
    uialert(fig,'Moviendo ambos brazos a posición pre-secuencia...','Info');
    
    % Brazo 1: movimiento a pre-secuencia
    movimientoSuave(1, q1_actual, q1_pre, 2.0);
    
    % Brazo 2: movimiento a pre-secuencia  
    movimientoSuave(2, q2_actual, q2_pre, 2.0);
    
    % Pequeña pausa para asegurar la posición
    pause(0.5);

    %% === FASE 1: Movimiento del Brazo 1 a posición de observación ===
    uialert(fig,'Moviendo Brazo 1 a posición de observación...','Info');
    
    % Obtener posición actual del efector del brazo 2 (después de moverse a pre-secuencia)
    EE2 = actualizar(q2_pre, patches2, linkSTL2, offset_base, txtQ2);

    % Definir figura y altura del Brazo 1
    scale = 0.06; % 60 mm
    switch tipo
        case 'cuadro'
            pts = [ -scale -scale;  scale -scale;  scale scale;  -scale scale; -scale -scale];
            z_offset_brazo1 = 0.025; % +25 mm
        case 'triangulo'
            pts = [ -scale -scale;  scale -scale;  0 scale; -scale -scale];
            z_offset_brazo1 = -0.015; % -15 mm
        case 'circulo'
            theta = linspace(0,2*pi,200)';
            pts = [cos(theta)*scale, sin(theta)*scale];
            z_offset_brazo1 = 0.010; % +10 mm
        otherwise
            return
    end

    target1 = [EE2(1), EE2(2), EE2(3) + z_offset_brazo1];
    q1_sol = IK_numeric(q1_pre, target1, 0, 60, 1e-4, 0.01, 2);

    % Movimiento suave a posición de observación (desde pre-secuencia)
    movimientoSuave(1, q1_pre, q1_sol, 2.0);

    %% === FASE 2: Movimiento del Brazo 2 para dibujar figura ===
    uialert(fig,'Brazo 2 dibujando figura...','Info');
    
    Z2 = EE2(3);
    path2 = [EE2(1) + pts(:,1), EE2(2) + pts(:,2), repmat(Z2, size(pts,1),1)];

    % Calcular longitud total y tiempo
    d = sqrt(sum(diff(path2).^2,2));
    total_length = sum(d);
    vel_lineal = 0.02; % 20 mm/s
    t_total2 = total_length / vel_lineal;
    N2 = 200;

    % Interpolación paramétrica
    s = [0; cumsum(d)] / total_length;
    s_uniforme = linspace(0,1,N2);
    x_interp = interp1(s, path2(:,1), s_uniforme);
    y_interp = interp1(s, path2(:,2), s_uniforme);
    z_interp = interp1(s, path2(:,3), s_uniforme);

    q2_current = q2_pre; % Empezar desde pre-secuencia
    Q_traj2 = zeros(N2,5);
    for i=1:N2
        target2 = [x_interp(i), y_interp(i), z_interp(i)];
        q2_current = IK_numeric(q2_current, target2, offset_base, 40, 1e-4, 0.01, 2);
        actualizar(q2_current, patches2, linkSTL2, offset_base, txtQ2);
        Q_traj2(i,:) = q2_current;

        if ~isempty(s2) && isvalid(s2)
            msg2 = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', q2_current);
            writeline(s2, msg2);
        end
        pause(t_total2/N2);
    end

    % Guardar trayectorias
    assignin('base','lastPose_Brazo1',q1_sol);
    assignin('base','lastTrajectory_Brazo2',Q_traj2);

    %% === FASE 3: Retorno suave a posición home ===
    uialert(fig,'Retornando a posición home...','Info');
    
    % Brazo 2 retorna a posición home desde la última posición de dibujo
    movimientoSuave(2, q2_current, q2_init, 3.0);
    
    % Brazo 1 retorna a posición home desde posición de observación
    movimientoSuave(1, q1_sol, q1_init, 3.0);

    uialert(fig, sprintf(['Secuencia completada.\n' ...
        'Figura "%s" dibujada.\n' ...
        'Ambos brazos retornaron a posición home.'], tipo), 'Info');
end

% -------------------------------------------------------------------------
function q_sol = IK_numeric(q_init, target, offsetX, max_iter, tol_cart, lambda, maxstep_deg)
    q = q_init;
    for iter = 1:max_iter
        [x, J] = FK_and_Jacobian(q, offsetX);
        e = (target - x)';
        if norm(e) < tol_cart
            break;
        end
        Jp = J' * ((J*J' + lambda*eye(3)) \ eye(3));
        dq = (Jp * e)';
        dq_deg = dq * (180/pi);
        dq_deg = max(min(dq_deg, maxstep_deg), -maxstep_deg);
        q = q + dq_deg;
    end
    q_sol = q;
end

% ... (resto de funciones guardarAngulos, enviarAngulos, abrirPuerto, cerrarPuerto se mantienen igual)

function guardarAngulos(brazo_id)
    if brazo_id == 1
        Q = zeros(1,5); for k=1:5, Q(k)=txtQ1(k).Value; end
        filename = fullfile(pwd, sprintf('angulos_brazo1_%s.mat',datestr(now,'yyyymmdd_HHMMSS')));
        save(filename,'Q');
        uialert(fig,sprintf('Ángulos guardados en %s',filename),'Info');
    else
        if evalin('base','exist(''lastTrajectory_Brazo2'',''var'')')
            Qtr = evalin('base','lastTrajectory_Brazo2');
            filename = fullfile(pwd, sprintf('trayectoria_brazo2_%s.mat',datestr(now,'yyyymmdd_HHMMSS')));
            save(filename,'Qtr');
            uialert(fig,sprintf('Trayectoria guardada en %s',filename),'Info');
        else
            Q = zeros(1,5); for k=1:5, Q(k)=txtQ2(k).Value; end
            filename = fullfile(pwd, sprintf('angulos_brazo2_%s.mat',datestr(now,'yyyymmdd_HHMMSS')));
            save(filename,'Q');
            uialert(fig,sprintf('Ángulos guardados en %s',filename),'Info');
        end
    end
end

function enviarAngulos(brazo_id)
    if brazo_id == 1
        if isempty(s1) || ~isvalid(s1)
            uialert(fig,'Puerto COM3 no está abierto.','Error'); return
        end
        Q = zeros(1,5); for k=1:5, Q(k)=txtQ1(k).Value; end
        msg = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', Q);
        writeline(s1, msg);
        uialert(fig,'Ángulos enviados a Brazo 1 (COM3).','Info');
    else
        if isempty(s2) || ~isvalid(s2)
            uialert(fig,'Puerto COM4 no está abierto.','Error'); return
        end
        if evalin('base','exist(''lastTrajectory_Brazo2'',''var'')')
            Qtr = evalin('base','lastTrajectory_Brazo2');
            for i=1:size(Qtr,1)
                msg = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', Qtr(i,:));
                writeline(s2,msg);
                pause(0.02);
            end
            uialert(fig,'Trayectoria enviada a Brazo 2 (COM4).','Info');
        else
            Q = zeros(1,5); for k=1:5, Q(k)=txtQ2(k).Value; end
            msg = sprintf('%.3f,%.3f,%.3f,%.3f,%.3f\n', Q);
            writeline(s2, msg);
            uialert(fig,'Ángulos enviados a Brazo 2 (COM4).','Info');
        end
    end
end

function s = abrirPuerto(fig, s, puerto, baud)
    if isempty(s) || ~isvalid(s)
        try
            s = serialport(puerto, baud);
            configureCallback(s,"off");
            uialert(fig,['Puerto ' puerto ' abierto.'],'Info');
        catch ME
            uialert(fig,['Error al abrir ' puerto ': ' ME.message],'Error');
        end
    else
        uialert(fig,'Ya está abierto.','Info');
    end
end

function s = cerrarPuerto(fig, s)
    if ~isempty(s) && isvalid(s)
        delete(s); s = [];
        uialert(fig,'Puerto cerrado.','Info');
    else
        uialert(fig,'El puerto ya estaba cerrado.','Info');
    end
end

% === Inicialización visual ===
actualizar(valores_iniciales,patches1,linkSTL1,0,txtQ1);
actualizar(valores_iniciales,patches2,linkSTL2,offset_base,txtQ2);

end