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
            'ValueChangingFcn',@(s,evt) actualizar(),...
            'ValueChangedFcn',@(s,~) actualizar());
        uilabel(panel,'Position',[20 515-(i-1)*110 180 20],...
            'Tag',sprintf('lbl%d',i), 'Text','0.0°');
    end

    % --- Cargar STL de cada eslabón (debes poner tus archivos aquí) ---
    % Escala en metros si tu STL está en mm (ej: *1e-3)
    linkSTL{1} = stlread('link1.stl');  
    linkSTL{2} = stlread('link2.stl');
    linkSTL{3} = stlread('link3.stl');
    linkSTL{4} = stlread('link4.stl');
    linkSTL{5} = stlread('link5.stl');

    % --- Utilidades ---
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

    % --- Función para dibujar un STL en una pose T ---
    function dibujarSTL(ax,stl,T,color)
        v = stl.Points*1e-3;   % pasar a metros si viene en mm
        f = stl.ConnectivityList;
        % aplicar transformación homogénea
        v_h = [v, ones(size(v,1),1)] * T';  
        patch(ax,'Faces',f,'Vertices',v_h(:,1:3),...
              'FaceColor',color,'EdgeColor','none','FaceAlpha',0.9);
    end

    % --- Actualización del dibujo ---
    function actualizar
        q = zeros(1,5);
        for j=1:5
            q(j) = sliders(j).Value*pi/180;
            lbl = findobj(panel,'Tag',sprintf('lbl%d',j));
            if ~isempty(lbl), lbl.Text = sprintf('%.1f°', sliders(j).Value); end
        end

        vView = ax.View; xL=ax.XLim; yL=ax.YLim; zL=ax.ZLim;

        % Cinemática (como ya lo tenías)
        T01 = Rz(q(1)) * Trans(13.92e-3, 4e-3, 96.28e-3);
        T12 = Ry(q(2)) * Trans(91.93e-3, 0, 77.13e-3);
        T23 = Ry(q(3)) * Trans(89.75e-3, 7.5e-3, -5.3e-3);
        T34 = Rx(q(4)) * Trans(65.5e-3, -14e-3, 5e-3);
        T45 = Ry(q(5)) * Trans(38e-3, -25.9e-3, -14e-3);

        A1 = T01;
        A2 = A1*T12;
        A3 = A2*T23;
        A4 = A3*T34;
        A5 = A4*T45;

        cla(ax);
        hold(ax,'on');
        light(ax); lighting(ax,'gouraud');
        % Dibujar STL de cada eslabón
        dibujarSTL(ax,linkSTL{1},A1,[0.8 0.1 0.1]);
        dibujarSTL(ax,linkSTL{2},A2,[0.1 0.8 0.1]);
        dibujarSTL(ax,linkSTL{3},A3,[0.1 0.1 0.8]);
        dibujarSTL(ax,linkSTL{4},A4,[0.8 0.8 0.1]);
        dibujarSTL(ax,linkSTL{5},A5,[0.5 0.5 0.5]);

        hold(ax,'off');
        ax.View = vView; ax.XLim = xL; ax.YLim = yL; ax.ZLim = zL;
    end

    actualizar();
end
