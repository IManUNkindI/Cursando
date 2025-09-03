README — Instalación del Robotics Toolbox (Peter Corke) en MATLAB 2025

1️⃣ Descargar el Toolbox
- Descargar la carpeta "RVC 2nd edition: RTB10+MVTB4" desde el MATLAB Drive de Peter Corke o desde GitHub. Link: https://petercorke.com/toolboxes/robotics-toolbox/?utm_source=chatgpt.com

- Guardar la carpeta en tu PC, por ejemplo:
  C:\Users\pinzo\Documents\UMNG\ROBOTICA\toolbox MATLAB\RVC2-copy\RVC2-copy\

2️⃣ Agregar al Path de MATLAB
1. Abrir MATLAB.
2. Ir a Home → Set Path → Add with Subfolders.
3. Seleccionar la carpeta rvctools dentro de la ruta descargada.
4. Guardar cambios (Save).

3️⃣ Ejecutar el script de inicio
En la consola de MATLAB, escribir:
cd('C:\Users\pinzo\Documents\UMNG\ROBOTICA\toolbox MATLAB\RVC2-copy\RVC2-copy\rvctools')
startup_rvc

4️⃣ Verificar instalación
En la consola de MATLAB, probar:
mdl_puma560           % Carga el modelo Puma 560
p560.plot([0 0 0 0 0 0])  % Dibuja el robot

Si ves un modelo 3D del robot, la instalación está correcta.

5️⃣ (Opcional) Cargar automáticamente al abrir MATLAB
- Crear o editar el archivo startup.m en tu carpeta de MATLAB.
- Agregar:
run('C:\Users\pinzo\Documents\UMNG\ROBOTICA\toolbox MATLAB\RVC2-copy\RVC2-copy\rvctools\startup_rvc.m')

- Guardar el archivo. Ahora el toolbox se cargará siempre.
