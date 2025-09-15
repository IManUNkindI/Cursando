function brazo_robotico_gui_urdf
    % === Configuración inicial ===
    puerto = "COM3";
    baud   = 57600;
    s = []; % objeto serial (se abre desde el botón)

    % Configuración de rangos
    rango_min = [0 , 0  , 0  , 8  , 0  ];   
    rango_max = [90, 180, 180, 172, 180];   
    valores_iniciales = [0, 0, 0, 8, 0];     

    % === Ventana principal ===
    fig = uifigure('Name','Brazo Robótico (URDF)','Position',[100 100 950 640]);

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

    % === Sliders (solo lectura) ===
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

    % === Cargar URDF ===
    robot = importrobot('Robot.urdf'); % <-- aquí va el URDF exportado de SolidWorks
    showdetails(robot);                   % muestra info en consola
    config = homeConfiguration(robot);    % configuración inicial

    % Dibujar robot inicial
    show(robot,config,'Parent',ax);

    % === Función para actualizar el robot ===
    function actualizar(q_deg)
        % Actualizar sliders y etiquetas
        for j=1:5
            sliders(j).Value = q_deg(j);
            lbl = findobj(panel,'Tag',sprintf('lbl%d',j));
            if ~isempty(lbl)
                lbl.Text = sprintf('%.2f°', q_deg(j));
            end
        end

        % Actualizar config del robot
        for j=1:5
            config(j).JointPosition = deg2rad(q_deg(j));
        end

        % Mostrar robot con nueva configuración
        show(robot,config,'Parent',ax,'PreservePlot',false);
        drawnow limitrate
    end

    % === Timer (se inicia al abrir puerto) ===
    t = timer('ExecutionMode','fixedRate','Period',0.15,... % ~6 Hz
              'TimerFcn',@(~,~) leerSerial);

    function leerSerial
        if ~isempty(s) && isvalid(s) && s.NumBytesAvailable > 0
            linea = readline(s); 
            try
                datos = str2double(split(strtrim(linea),'x'));
                datos = datos(~isnan(datos));   % quitar vacíos
                if numel(datos) == 5
                    q_corr = datos(:)'; % valores en grados
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
