function brazo_robotico_gui_xyz
    % === Configuración inicial ===
    puerto = "COM3";
    baud   = 57600;
    s = []; % objeto serial

    % Configuración inicial de articulaciones
    valores_iniciales = [45, 90, 90, 90, 90];     

    % Ventana principal
    fig = uifigure('Name','Brazo Robótico 6 GDL','Position',[100 100 950 640]);

    % Panel de control cartesiano
    panelXYZ = uipanel(fig,'Position',[10 380 220 250],'Title','Coordenadas Deseadas (mm)');

    % Campos de texto para X, Y, Z
    uilabel(panelXYZ,'Text','X:','Position',[20 170 20 22]);
    txtX = uieditfield(panelXYZ,'numeric','Position',[50 170 100 22],'Value',0);

    uilabel(panelXYZ,'Text','Y:','Position',[20 120 20 22]);
    txtY = uieditfield(panelXYZ,'numeric','Position',[50 120 100 22],'Value',0);

    uilabel(panelXYZ,'Text','Z:','Position',[20 70 20 22]);
    txtZ = uieditfield(panelXYZ,'numeric','Position',[50 70 100 22],'Value',100);

    % Botón para enviar coordenadas
    btnSend = uibutton(panelXYZ,'Text','Enviar coordenadas',...
        'Position',[40 20 140 30],'ButtonPushedFcn',@enviarCoordenadas);

    % Panel de conexión
    ctrlPanel = uipanel(fig,'Position',[10 290 220 80],'Title','Control');

    % Botones abrir/cerrar puerto
    btnOpenPort = uibutton(ctrlPanel,'Text','Abrir Puerto',...
        'Position',[10 10 90 30],'ButtonPushedFcn',@abrirPuerto);

    btnClosePort = uibutton(ctrlPanel,'Text','Cerrar Puerto',...
        'Position',[120 10 90 30],'ButtonPushedFcn',@cerrarPuerto);

    % Ejes de dibujo
    ax = uiaxes(fig,'Position',[240 10 700 620]);
    grid(ax,"on");
    axis(ax,[-0.35 0.35 -0.35 0.35 0 0.45]);
    xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z');
    view(ax,3);
    ax.DataAspectRatio = [1 1 1];

    % --- Cargar STL base fija ---
    baseSTL = stlread('Base.stl');
    v_base = baseSTL.Points * 1e-3;
    patch(ax, 'Faces', baseSTL.ConnectivityList, ...
          'Vertices', v_base, ...
          'FaceColor', [0.4 0.4 0.4], ...
          'EdgeColor', 'none', ...
          'FaceAlpha', 1.0);

    % --- Cargar STL de eslabones ---
    linkSTL{1} = stlread('link1.stl');  
    linkSTL{2} = stlread('link2.stl');
    linkSTL{3} = stlread('link3.stl');
    linkSTL{4} = stlread('link4.stl');
    linkSTL{5} = stlread('link5.stl');

    patches = gobjects(1,5);
    colors = {[0.8 0.1 0.1],[0.1 0.8 0.1],[0.1 0.1 0.8],[0.8 0.8 0.1],[0.5 0.5 0.5]};
    for j = 1:5
        v = linkSTL{j}.Points * 1e-3;
        patches(j) = patch(ax,'Faces',linkSTL{j}.ConnectivityList,...
                              'Vertices',v,...
                              'FaceColor',colors{j},...
                              'EdgeColor','none','FaceAlpha',0.9);
    end
    light(ax); lighting(ax,'gouraud');

    % === Transformaciones homogéneas ===
    function T = Rx(q), cq=cos(q); sq=sin(q);
        T = [1 0 0 0; 0 cq -sq 0; 0 sq cq 0; 0 0 0 1];
    end
    function T = Ry(q), cq=cos(q); sq=sin(q);
        T = [cq 0 sq 0; 0 1 0 0; -sq 0 cq 0; 0 0 0 1];
    end
    function T = Rz(q), cq=cos(q); sq=sin(q);
        T = [cq -sq 0 0; sq cq 0 0; 0 0 1 0; 0 0 0 1];
    end
    function T = Trans(x,y,z)
        T = [1 0 0 x; 0 1 0 y; 0 0 1 z; 0 0 0 1];
    end

    % === Actualizar visualización ===
    function actualizar(q_deg)
        q = q_deg * pi/180;
        T01 = Rz(q(1)) * Trans(-13.92e-3, -4e-3, 105.28e-3);
        T12 = Ry(q(2)) * Trans(-120e-3, 0, 0);
        T23 = Ry(q(3)) * Trans(-5.3e-3, 7.5e-3, -89.75e-3);
        T34 = Rz(q(4)) * Trans(5e-3, 14e-3, -65.5e-3);
        T45 = Ry(q(5)) * Trans(38e-3, 25.9e-3, 14e-3);

        A1 = T01; A2 = A1*T12; A3 = A2*T23; A4 = A3*T34; A5 = A4*T45;
        T_all = {A1,A2,A3,A4,A5};

        for j=1:5
            v = linkSTL{j}.Points * 1e-3;
            v_h = [v, ones(size(v,1),1)] * T_all{j}';
            patches(j).Vertices = v_h(:,1:3);
        end
        drawnow limitrate
    end

    % === Abrir puerto ===
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

    % === Cerrar puerto ===
    function cerrarPuerto(~,~)
        if ~isempty(s) && isvalid(s)
            delete(s);
            s = [];
            uialert(fig,'Puerto cerrado correctamente.','Info');
        else
            uialert(fig,'El puerto ya estaba cerrado.','Info');
        end
    end

    % === Enviar coordenadas ===
    function enviarCoordenadas(~,~)
        xd = txtX.Value / 1000; % convertir mm -> m
        yd = txtY.Value / 1000;
        zd = txtZ.Value / 1000;

        % --- CINEMÁTICA INVERSA SIMPLIFICADA (placeholder) ---
        % Sustituir por el modelo real de tu robot
        q = valores_iniciales; 
        q(1) = atan2(yd, xd) * 180/pi;  
        q(2) = 90 - (zd * 1000 / 5);    
        q(3) = 90; q(4) = 90; q(5) = 90;

        % --- Actualizar visualización ---
        actualizar(q);

        % --- Enviar por serial ---
        if ~isempty(s) && isvalid(s)
            msg = sprintf('%.2f,%.2f,%.2f,%.2f,%.2f\n', q);
            writeline(s, msg);
            uialert(fig, sprintf('Ángulos enviados:\n%s', msg), 'Enviado');
        else
            uialert(fig, 'Puerto no abierto.', 'Advertencia');
        end
    end

    % Inicializar
    actualizar(valores_iniciales);
end
