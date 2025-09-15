function brazo_robotico_gui_var
    % === Configuración inicial ===
    puerto = "COM3";
    baud   = 57600;
    s = []; % objeto serial (se abre desde el botón)
    
    % Configuración de offsets y rangos
    rango_min = [0 , 0  , 0  , 8  , 0  ];   
    rango_max = [90, 180, 180, 172, 180];   
    valores_iniciales = [0, 0, 0, 8, 0];     

    % Ventana principal
    fig = uifigure('Name','Brazo Robótico 6 GDL','Position',[100 100 950 640]);

    % Panel de sliders
    panel = uipanel(fig,'Position',[10 100 220 530],'Title','Ángulos actuales');

    % Panel de control
    ctrlPanel = uipanel(fig,'Position',[10 10 220 80],'Title','Control');

    % Botón abrir puerto
    btnOpenPort = uibutton(ctrlPanel,'Text','Abrir Puerto',...
        'Position',[10 10 90 30],'ButtonPushedFcn',@abrirPuerto);

    % Botón cerrar puerto
    btnClosePort = uibutton(ctrlPanel,'Text','Cerrar Puerto',...
        'Position',[120 10 90 30],'ButtonPushedFcn',@cerrarPuerto);

    % Ejes de dibujo
    ax = uiaxes(fig,'Position',[240 10 700 620]);
    grid(ax,"on");
    axis(ax,[-0.35 0.35 -0.35 0.35 0 0.45]);
    xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z');
    view(ax,3);
    ax.DataAspectRatio = [1 1 1];

    % Sliders (solo lectura)
    sliders = gobjects(1,5);
    for i = 1:5
        uilabel(panel,'Position',[20 510-(i-1)*100 180 20],...
            'Text',sprintf('Articulación %d',i));
    
        sliders(i) = uislider(panel,...
            'Position',[20 490-(i-1)*100 180 3],...
            'Limits',[rango_min(i) rango_max(i)], ...
            'Value', valores_iniciales(i), ...
            'MajorTicks', linspace(rango_min(i), rango_max(i), 7), ...
            'MinorTicks', linspace(rango_min(i), rango_max(i), 13));
    
        sliders(i).Enable = 'off';
    
        uilabel(panel,'Position',[20 465-(i-1)*100 180 20],...
            'Tag',sprintf('lbl%d',i),...
            'Text',sprintf('%.2f°', valores_iniciales(i)));
    end

    % --- Cargar STL ---
    linkSTL{1} = stlread('link1.stl');  
    linkSTL{2} = stlread('link2.stl');
    linkSTL{3} = stlread('link3.stl');
    linkSTL{4} = stlread('link4.stl');
    linkSTL{5} = stlread('link5.stl');

    % Crear patches persistentes
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

    % --- Funciones de matrices homogéneas ---
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

    % --- Actualizar simulación ---
    function actualizar(q_deg)
        % Actualizar sliders y etiquetas
        for j=1:5
            sliders(j).Value = q_deg(j);
            lbl = findobj(panel,'Tag',sprintf('lbl%d',j));
            if ~isempty(lbl)
                lbl.Text = sprintf('%.2f°', q_deg(j));
            end
        end

        % Convertir a radianes
        q = q_deg * pi/180;

        % Cinemática directa acumulada X->Y, Y->Z, Z->X.
        T01 = Rz(q(1)) * Trans(-13.92e-3, -4e-3, 105.28e-3);
        T12 = Ry(q(2)) * Trans(-120e-3, 0, 0);
        T23 = Ry(q(3)) * Trans(-9.61e-3, 12.68e-3, -93.48e-3);
        T34 = Rx(q(4)) * Trans(8.2e-3, 20.01e-3, -71.96e-3);
        T45 = Ry(q(5)) * Trans(49.59e-3, 25.96e-3, 16e-3);

        A1 = T01; A2 = A1*T12; A3 = A2*T23; A4 = A3*T34; A5 = A4*T45;
        T_all = {A1,A2,A3,A4,A5};

        % Actualizar vértices de cada STL
        for j=1:5
            v = linkSTL{j}.Points * 1e-3;
            v_h = [v, ones(size(v,1),1)] * T_all{j}';
            patches(j).Vertices = v_h(:,1:3);
        end

        drawnow limitrate
    end

    % --- Timer (se inicia al abrir puerto) ---
    t = timer('ExecutionMode','fixedRate','Period',0.15,... % ~6 Hz
              'TimerFcn',@(~,~) leerSerial);

    function leerSerial
        if ~isempty(s) && isvalid(s) && s.NumBytesAvailable > 0
            linea = readline(s); 
            try
                datos = str2double(split(strtrim(linea),'x'));
                datos = datos(~isnan(datos));   % quitar vacíos
                if numel(datos) == 5
                    q_corr = datos(:)'; % aplicar offset
                    actualizar(q_corr);
                end
            catch
                % ignorar errores de parseo
            end
        end
    end

    % --- Abrir puerto ---
    function abrirPuerto(~,~)
        if isempty(s) || ~isvalid(s)
            try
                s = serialport(puerto, baud);
                flush(s,"input");
                start(t);
                uialert(fig,'Puerto abierto correctamente.','Info');
            catch ME
                uialert(fig,sprintf('Error al abrir puerto: %s',ME.message),'Error');
            end
        else
            uialert(fig,'El puerto ya está abierto.','Info');
        end
    end

    % --- Cerrar puerto ---
    function cerrarPuerto(~,~)
        stop(t);
        if ~isempty(s) && isvalid(s)
            delete(s);
            s = [];
            uialert(fig,'Puerto cerrado correctamente.','Info');
        else
            uialert(fig,'El puerto ya estaba cerrado.','Info');
        end
    end

    % Inicial
    actualizar(valores_iniciales);
end
