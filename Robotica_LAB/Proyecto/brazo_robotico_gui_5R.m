function brazo_robotico_gui_xyz
    % === Configuración inicial ===
    puerto = "COM3";
    baud   = 57600;
    s = []; % objeto serial
    valores_iniciales = [45, 90, 90, 90, 90];     

    % === Ventana principal ===
    fig = uifigure('Name','Brazo Robótico 5 GDL','Position',[100 100 1000 640]);

    % === Paneles de coordenadas ===
    crearPaneles(fig);

    % === Ejes de dibujo ===
    ax = uiaxes(fig,'Position',[260 10 720 620]);
    grid(ax,"on"); axis(ax,[-0.35 0.35 -0.35 0.35 0 0.45]);
    xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z'); view(ax,3);
    ax.DataAspectRatio = [1 1 1];
    light(ax); lighting(ax,'gouraud');

    % === Cargar STL ===
    baseSTL = stlread('Base.stl');
    v_base = baseSTL.Points * 1e-3;
    patch(ax, 'Faces', baseSTL.ConnectivityList, 'Vertices', v_base,...
          'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 1.0);

    linkSTL = cell(1,5);
    patches = gobjects(1,5);
    colors = {[0.8 0.1 0.1],[0.1 0.8 0.1],[0.1 0.1 0.8],[0.8 0.8 0.1],[0.5 0.5 0.5]};
    for j = 1:5
        linkSTL{j} = stlread(sprintf('link%d.stl', j));
        v = linkSTL{j}.Points * 1e-3;
        patches(j) = patch(ax,'Faces',linkSTL{j}.ConnectivityList,...
            'Vertices',v,'FaceColor',colors{j},'EdgeColor','none','FaceAlpha',0.9);
    end

    % === Transformaciones homogéneas ===
    Rx = @(q)[1 0 0 0; 0 cos(q) -sin(q) 0; 0 sin(q) cos(q) 0; 0 0 0 1];
    Ry = @(q)[cos(q) 0 sin(q) 0; 0 1 0 0; -sin(q) 0 cos(q) 0; 0 0 0 1];
    Rz = @(q)[cos(q) -sin(q) 0 0; sin(q) cos(q) 0 0; 0 0 1 0; 0 0 0 1];
    Trans = @(x,y,z)[1 0 0 x; 0 1 0 y; 0 0 1 z; 0 0 0 1];

    % === Actualización de visualización ===
    function actualizar(q_deg)
        q = q_deg * pi/180;
        % Cinemática directa definida por usuario
        T01 = Rz(q(1)) * Trans(-13.92e-3, -4e-3, 105.28e-3);
        T12 = Ry(q(2)) * Trans(-120e-3, 0, 0);
        T23 = Ry(q(3)) * Trans(-5.3e-3, 7.5e-3, -89.75e-3);
        T34 = Rz(q(4)) * Trans(5e-3, 14e-3, -65.5e-3);
        T45 = Ry(q(5)) * Trans(38e-3, 25.9e-3, 14e-3);

        A1 = T01; A2 = A1*T12; A3 = A2*T23; A4 = A3*T34; A5 = A4*T45;
        T_all = {A1,A2,A3,A4,A5};

        % Actualizar STL
        for j=1:5
            v = linkSTL{j}.Points * 1e-3;
            v_h = [v, ones(size(v,1),1)] * T_all{j}';
            patches(j).Vertices = v_h(:,1:3);
        end

        % Ejes locales
        delete(findall(ax, 'Tag', 'eje_local'));
        L_eje = 0.05;
        for j=1:5
            T = T_all{j};
            O = T(1:3,4); R = T(1:3,1:3);
            X = O + R(:,1)*L_eje; Y = O + R(:,2)*L_eje; Z = O + R(:,3)*L_eje;
            line(ax,[O(1) X(1)],[O(2) X(2)],[O(3) X(3)],'Color','r','Tag','eje_local');
            line(ax,[O(1) Y(1)],[O(2) Y(2)],[O(3) Y(3)],'Color','g','Tag','eje_local');
            line(ax,[O(1) Z(1)],[O(2) Z(2)],[O(3) Z(3)],'Color','b','Tag','eje_local');
        end

        % Actualizar campos
        for j = 1:5
            txtQ(j).Value = q_deg(j);
        end
        drawnow limitrate
    end

    % === Puerto serie ===
    function abrirPuerto(~,~)
        if isempty(s) || ~isvalid(s)
            try
                s = serialport(puerto, baud);
                uialert(fig,'Puerto abierto correctamente.','Info');
            catch ME
                uialert(fig,sprintf('Error al abrir puerto: %s',ME.message),'Error');
            end
        else
            uialert(fig,'El puerto ya está abierto.','Info');
        end
    end

    function cerrarPuerto(~,~)
        if ~isempty(s) && isvalid(s)
            delete(s); s = [];
            uialert(fig,'Puerto cerrado correctamente.','Info');
        else
            uialert(fig,'El puerto ya estaba cerrado.','Info');
        end
    end

    % === Movimiento entre puntos ===
    function moverEntrePuntos(~,~)
        Pi = [ str2double(get(txtXi, 'String')), ...
        str2double(get(txtYi, 'String')), ...
        str2double(get(txtZi, 'String')) ] / 1000;

        Pf = [ str2double(get(txtXf, 'String')), ...
        str2double(get(txtYf, 'String')), ...
        str2double(get(txtZf, 'String')) ] / 1000;



        q_i = cinematica_inversa_5GDL(Pi(1), Pi(2), Pi(3));
        q_f = cinematica_inversa_5GDL(Pf(1), Pf(2), Pf(3));

        N = 25;
        q_tray = zeros(N,5);
        for k=1:5
            q_tray(:,k) = linspace(q_i(k), q_f(k), N);
        end

        for n=1:N
            q = q_tray(n,:);
            actualizar(q);
            if ~isempty(s) && isvalid(s)
                msg = sprintf('%.3fx%.3fx%.3fx%.3fx%.3f\n', q);
                writeline(s, msg);
            end
            pause(0.05);
        end

        if ~isempty(s) && isvalid(s)
            uialert(fig,'Movimiento completado y datos enviados.','Info');
        else
            uialert(fig,'Movimiento completado (sin conexión serial).','Advertencia');
        end
    end

    % === Crear paneles ===
    function crearPaneles(fig)
        panelInicio = uipanel(fig,'Position',[10 460 230 150],'Title','Punto Inicial (mm)');
        uilabel(panelInicio,'Text','X:','Position',[20 90 20 22]);
        txtXi = uieditfield(panelInicio,'numeric','Position',[50 90 120 22],'Value',0);
        uilabel(panelInicio,'Text','Y:','Position',[20 60 20 22]);
        txtYi = uieditfield(panelInicio,'numeric','Position',[50 60 120 22],'Value',0);
        uilabel(panelInicio,'Text','Z:','Position',[20 30 20 22]);
        txtZi = uieditfield(panelInicio,'numeric','Position',[50 30 120 22],'Value',0);

        panelFinal = uipanel(fig,'Position',[10 310 230 150],'Title','Punto Final (mm)');
        uilabel(panelFinal,'Text','X:','Position',[20 90 20 22]);
        txtXf = uieditfield(panelFinal,'numeric','Position',[50 90 120 22],'Value',0);
        uilabel(panelFinal,'Text','Y:','Position',[20 60 20 22]);
        txtYf = uieditfield(panelFinal,'numeric','Position',[50 60 120 22],'Value',0);
        uilabel(panelFinal,'Text','Z:','Position',[20 30 20 22]);
        txtZf = uieditfield(panelFinal,'numeric','Position',[50 30 120 22],'Value',0);

        ctrlPanel = uipanel(fig,'Position',[10 240 230 65],'Title','Control');
        uibutton(ctrlPanel,'Text','Abrir Puerto','Position',[15 10 90 30],'ButtonPushedFcn',@abrirPuerto);
        uibutton(ctrlPanel,'Text','Cerrar Puerto','Position',[120 10 90 30],'ButtonPushedFcn',@cerrarPuerto);

        panelAng = uipanel(fig,'Position',[10 70 230 160],'Title','Ángulos de articulación (°)');
        labels = {'q1','q2','q3','q4','q5'};
        txtQ = gobjects(1,5);
        for i=1:5
            uilabel(panelAng,'Text',labels{i},'Position',[20 125 - (i-1)*25 30 22]);
            txtQ(i) = uieditfield(panelAng,'numeric','Position',[60 125 - (i-1)*25 120 22],'Editable','off','Value',valores_iniciales(i));
        end

        uibutton(fig,'Text','Mover entre puntos','Position',[40 25 160 35],'ButtonPushedFcn',@moverEntrePuntos);
    end

    % === Inicializar ===
    actualizar(valores_iniciales);
end

%% ---- Cinemática inversa SIN Peter Corke ----
function Q = cinematica_inversa_5GDL(Px, Py, Pz)
    L = [105.28e-3 120e-3 155.25e-3];
    q1 = atan2(Py, Px);
    r = sqrt(Px^2 + Py^2);
    s = Pz - L(1);
    D = (r^2 + s^2 - L(2)^2 - L(3)^2)/(2*L(2)*L(3));
    q3 = atan2(-sqrt(1-D^2), D);
    q2 = atan2(s, r) - atan2(L(3)*sin(q3), L(2)+L(3)*cos(q3));
    q4 = 0; q5 = 0;  % simplificación sin orientación final
    Q = rad2deg([q1 q2 q3 q4 q5]);
end
