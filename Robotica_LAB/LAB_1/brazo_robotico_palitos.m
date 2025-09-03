function brazo_robotico_gui_var
    % Ventana principal
    fig = uifigure('Name','Brazo Robótico 6 GDL','Position',[100 100 900 640]);

    % Panel de sliders
    panel = uipanel(fig,'Position',[10 10 220 620],'Title','Controles');

    % Ejes de dibujo
    ax = uiaxes(fig,'Position',[240 10 650 620]);
    grid(ax,"on");
    axis(ax,[-0.35 0.35 -0.35 0.35 0 0.45]); % [X Y Z] límites en m
    xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z');
    view(ax,3);
    ax.DataAspectRatio = [1 1 1];

    % Sliders para 5 articulaciones con límites [-90, 90]
    sliders = gobjects(1,5);
    for i=1:5
        uilabel(panel,'Position',[20 560-(i-1)*110 180 20],...
            'Text',sprintf('Articulación %d',i));
        sliders(i) = uislider(panel,...
            'Position',[20 540-(i-1)*110 180 3],...
            'Limits',[-90 90], 'Value',0,...
            'ValueChangingFcn',@(s,evt) actualizar(),...   % respuesta más fluida
            'ValueChangedFcn',@(s,~) actualizar());
        % Valor numérico
        uilabel(panel,'Position',[20 515-(i-1)*110 180 20],...
            'Tag',sprintf('lbl%d',i), 'Text','0.0°');
    end

    % --- Utilidades de rotación/traslación ---
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

    % --- Dibujo de triada en un frame T ---
    function dibujarTriada(ax,T,s)
        o = T(1:3,4); R = T(1:3,1:3);
        hold(ax,'on');
        quiver3(ax,o(1),o(2),o(3), R(1,1)*s, R(2,1)*s, R(3,1)*s, 0, 'LineWidth',1.2); % x
        quiver3(ax,o(1),o(2),o(3), R(1,2)*s, R(2,2)*s, R(3,2)*s, 0, 'LineWidth',1.2); % y
        quiver3(ax,o(1),o(2),o(3), R(1,3)*s, R(2,3)*s, R(3,3)*s, 0, 'LineWidth',1.2); % z
        hold(ax,'off');
    end

    % --- Actualización del dibujo ---
    function actualizar
        % ángulos en rad y refrescar etiquetas
        q = zeros(1,5);
        for j=1:5
            q(j) = sliders(j).Value*pi/180;
            lbl = findobj(panel,'Tag',sprintf('lbl%d',j));
            if ~isempty(lbl), lbl.Text = sprintf('%.1f°', sliders(j).Value); end
        end

        % guardar vista/límites
        vView = ax.View; xL=ax.XLim; yL=ax.YLim; zL=ax.ZLim;

        % Cadena cinemática (T = R * Trans), unidades en metros:
        % 0-1: rotación Z, luego desplazamiento (10, 0, 95.8) mm
        T01 = Rz(q(1)) * Trans(10e-3, 0, 95.8e-3);
        % 1-2: rotación Y, luego desplazamiento (0, 84.85, 84.85) mm
        T12 = Rx(q(2)) * Trans(0, 84.85e-3, 84.85e-3);
        % 2-3: rotación Y, luego desplazamiento (0, -6.36, 88) mm
        T23 = Rx(q(3)) * Trans(0, -6.36e-3, 88e-3);
        % 3-4: rotación X, luego desplazamiento (0, 14, 27.5) mm
        T34 = Rz(q(4)) * Trans(0, 14e-3, 27.5e-3);
        % 4-5: rotación Y, luego desplazamiento (-14, 0, 37) mm
        T45 = Rx(q(5)) * Trans(-14e-3, 0, 37e-3);

        % Transformaciones acumuladas
        T0 = eye(4);
        A1 = T01;
        A2 = A1*T12;
        A3 = A2*T23;
        A4 = A3*T34;
        A5 = A4*T45;

        % Posiciones
        P = [[0;0;0], A1(1:3,4), A2(1:3,4), A3(1:3,4), A4(1:3,4), A5(1:3,4)];

        % Redibujar
        cla(ax);
        plot3(ax, P(1,:), P(2,:), P(3,:), '-o', 'LineWidth',2, 'MarkerSize',6);
        grid(ax,'on'); xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'Z');
        hold(ax,'on');
        % Triadas (para ver orientación de cada junta)
        s = 0.03; % tamaño de eje local (m)
        dibujarTriada(ax, T0, s);
        dibujarTriada(ax, A1, s);
        dibujarTriada(ax, A2, s);
        dibujarTriada(ax, A3, s);
        dibujarTriada(ax, A4, s);
        dibujarTriada(ax, A5, s);
        hold(ax,'off');

        % restaurar vista/límites
        ax.View = vView; ax.XLim = xL; ax.YLim = yL; ax.ZLim = zL;
    end

    actualizar(); % primer dibujo
end
