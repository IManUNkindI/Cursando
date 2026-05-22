import snap7
from snap7.util import get_real, set_real
from snap7.type import Areas

import psycopg2

import tkinter as tk
from tkinter import ttk

from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

from collections import deque
from datetime import datetime

import threading
import time

# =========================================================
# CONFIGURACIÓN PLC
# =========================================================

PLC_IP = "192.168.0.1"
RACK = 0
SLOT = 1

# =========================================================
# DIRECCIONES PLC
# =========================================================

MD34 = 34
MD38 = 38
MD42 = 42

# =========================================================
# CONFIGURACIÓN BASE DE DATOS
# =========================================================

DB_HOST = "localhost"
DB_NAME = "factoryio"
DB_USER = "postgres"
DB_PASSWORD = "1943"
DB_PORT = 5432

# =========================================================
# VARIABLES GLOBALES
# =========================================================

running = True

plc = snap7.client.Client()

conn = None
cursor = None

max_points = 100

x_data = deque(maxlen=max_points)
y1_data = deque(maxlen=max_points)
y2_data = deque(maxlen=max_points)

start_time = time.time()

# =========================================================
# INTERFAZ PRINCIPAL
# =========================================================

root = tk.Tk()

root.title("SCADA PLC Siemens")
root.geometry("1200x850")

style = ttk.Style()
style.theme_use("clam")

# =========================================================
# FRAME SUPERIOR
# =========================================================

top_frame = ttk.Frame(root)
top_frame.pack(
    side=tk.TOP,
    fill=tk.X,
    padx=10,
    pady=10
)

# =========================================================
# ESTADOS
# =========================================================

plc_status = tk.Label(
    top_frame,
    text="PLC DESCONECTADO",
    bg="red",
    fg="white",
    font=("Arial", 12, "bold"),
    width=20,
    pady=5
)

plc_status.pack(
    side=tk.LEFT,
    padx=10
)

db_status = tk.Label(
    top_frame,
    text="DB DESCONECTADA",
    bg="red",
    fg="white",
    font=("Arial", 12, "bold"),
    width=20,
    pady=5
)

db_status.pack(
    side=tk.LEFT,
    padx=10
)

# =========================================================
# VARIABLES
# =========================================================

md34_label = ttk.Label(
    top_frame,
    text="MD34: 0.00",
    font=("Arial", 14)
)

md34_label.pack(
    side=tk.LEFT,
    padx=20
)

md38_label = ttk.Label(
    top_frame,
    text="MD38: 0.00",
    font=("Arial", 14)
)

md38_label.pack(
    side=tk.LEFT,
    padx=20
)

# =========================================================
# FRAME CONTROL
# =========================================================

control_frame = ttk.LabelFrame(
    root,
    text="Control PLC"
)

control_frame.pack(
    fill=tk.X,
    padx=10,
    pady=10
)

slider_label = ttk.Label(
    control_frame,
    text="Control MD42",
    font=("Arial", 14)
)

slider_label.pack(pady=5)

slider_value_label = ttk.Label(
    control_frame,
    text="0.00",
    font=("Arial", 12)
)

slider_value_label.pack()

slider = tk.Scale(
    control_frame,
    from_=0,
    to=100,
    orient=tk.HORIZONTAL,
    length=700,
    resolution=0.1
)

slider.pack(pady=10)

# =========================================================
# FRAME GRÁFICA
# =========================================================

graph_frame = ttk.LabelFrame(
    root,
    text="Monitoreo en Tiempo Real"
)

graph_frame.pack(
    fill=tk.BOTH,
    expand=True,
    padx=10,
    pady=10
)

# =========================================================
# FIGURA MATPLOTLIB
# =========================================================

fig = Figure(
    figsize=(10, 5),
    dpi=100
)

ax = fig.add_subplot(111)

line1, = ax.plot([], [], linewidth=2, label="MD34")
line2, = ax.plot([], [], linewidth=2, label="MD38")

ax.set_title("Variables PLC")
ax.set_xlabel("Tiempo (s)")
ax.set_ylabel("Valor")

ax.grid(True)
ax.legend()

canvas = FigureCanvasTkAgg(
    fig,
    master=graph_frame
)

canvas.get_tk_widget().pack(
    fill=tk.BOTH,
    expand=True,
    padx=10,
    pady=(0, 10)
)

# =========================================================
# CONSOLA LOGS
# =========================================================

log_container = ttk.LabelFrame(
    root,
    text="Consola del Sistema"
)

log_container.pack(
    fill=tk.BOTH,
    expand=False,
    padx=10,
    pady=10
)

# =========================================================
# FRAME INTERNO LOGS
# =========================================================

log_inner_frame = tk.Frame(
    log_container,
    bg="#1e1e1e"
)

log_inner_frame.pack(
    fill=tk.BOTH,
    expand=True
)

# =========================================================
# SCROLLBAR
# =========================================================

log_scrollbar = ttk.Scrollbar(
    log_inner_frame
)

log_scrollbar.pack(
    side=tk.RIGHT,
    fill=tk.Y
)

# =========================================================
# TEXT LOGS
# =========================================================

log_text = tk.Text(
    log_inner_frame,
    height=12,
    bg="#1e1e1e",
    fg="#00ff88",
    insertbackground="white",
    font=("Consolas", 10),
    yscrollcommand=log_scrollbar.set,
    wrap=tk.WORD,
    borderwidth=0,
    padx=10,
    pady=10
)

log_text.pack(
    side=tk.LEFT,
    fill=tk.BOTH,
    expand=True
)

log_scrollbar.config(
    command=log_text.yview
)

# =========================================================
# COLORES LOGS
# =========================================================

log_text.tag_config(
    "INFO",
    foreground="#00ff88"
)

log_text.tag_config(
    "ERROR",
    foreground="#ff5555"
)

log_text.tag_config(
    "WARNING",
    foreground="#ffaa00"
)

log_text.tag_config(
    "SUCCESS",
    foreground="#00ffff"
)

# =========================================================
# FUNCIÓN LOG
# =========================================================

def log(message, level="INFO"):

    timestamp = datetime.now().strftime("%H:%M:%S")

    text = f"[{timestamp}] [{level}] {message}\n"

    print(text)

    log_text.insert(
        tk.END,
        text,
        level
    )

    log_text.see(tk.END)

    log_text.update_idletasks()

# =========================================================
# ESCRIBIR MD42
# =========================================================

def write_md42(value):

    if not plc.get_connected():
        return

    data = bytearray(4)

    set_real(
        data,
        0,
        float(value)
    )

    plc.write_area(
        Areas.MK,
        0,
        MD42,
        data
    )

# =========================================================
# CALLBACK SLIDER
# =========================================================

def slider_changed(value):

    value = float(value)

    slider_value_label.config(
        text=f"{value:.2f}"
    )

    try:

        write_md42(value)

    except Exception as e:

        log(
            f"Error escribiendo MD42: {e}",
            "ERROR"
        )

slider.config(
    command=slider_changed
)

# =========================================================
# ACTUALIZAR GUI
# =========================================================

def update_gui(md34, md38):

    md34_label.config(
        text=f"MD34: {md34:.2f}"
    )

    md38_label.config(
        text=f"MD38: {md38:.2f}"
    )

    current_time = time.time() - start_time

    x_data.append(current_time)
    y1_data.append(md34)
    y2_data.append(md38)

    line1.set_data(x_data, y1_data)
    line2.set_data(x_data, y2_data)

    ax.relim()
    ax.autoscale_view()

    canvas.draw()

# =========================================================
# ADQUISICIÓN
# =========================================================

def acquisition_loop():

    global running

    while running:

        try:

            data = plc.read_area(
                Areas.MK,
                0,
                MD34,
                8
            )

            md34 = get_real(data, 0)
            md38 = get_real(data, 4)

            # =========================================
            # INSERTAR EN DB
            # =========================================

            cursor.execute("""
                INSERT INTO datos_plc
                (timestamp, md34, md38)
                VALUES (%s, %s, %s)
            """, (
                datetime.now(),
                md34,
                md38
            ))

            conn.commit()

            # =========================================
            # ACTUALIZAR GUI
            # =========================================

            root.after(
                0,
                update_gui,
                md34,
                md38
            )

            time.sleep(0.1)

        except Exception as e:

            log(
                f"Error adquisición: {e}",
                "ERROR"
            )

            time.sleep(1)

# =========================================================
# INICIALIZAR SISTEMA
# =========================================================

def initialize_system():

    global conn
    global cursor

    try:

        # =========================================
        # PLC
        # =========================================

        log("Conectando al PLC...")

        plc.connect(
            PLC_IP,
            RACK,
            SLOT
        )

        if plc.get_connected():

            plc_status.config(
                text="PLC CONECTADO",
                bg="green"
            )

            log(
                "PLC conectado",
                "SUCCESS"
            )

        else:

            log(
                "No se pudo conectar PLC",
                "ERROR"
            )

            return

        # =========================================
        # POSTGRESQL
        # =========================================

        log("Conectando PostgreSQL...")

        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT
        )

        cursor = conn.cursor()

        db_status.config(
            text="DB CONECTADA",
            bg="green"
        )

        log(
            "Base de datos conectada",
            "SUCCESS"
        )

        # =========================================
        # TABLA
        # =========================================

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS datos_plc (
            id SERIAL PRIMARY KEY,
            timestamp TIMESTAMP,
            md34 REAL,
            md38 REAL
        )
        """)

        conn.commit()

        log(
            "Tabla verificada",
            "SUCCESS"
        )

        # =========================================
        # HILO ADQUISICIÓN
        # =========================================

        log(
            "Iniciando adquisición...",
            "INFO"
        )

        thread = threading.Thread(
            target=acquisition_loop,
            daemon=True
        )

        thread.start()

    except Exception as e:

        log(
            f"ERROR INICIALIZACIÓN: {e}",
            "ERROR"
        )

# =========================================================
# CERRAR APLICACIÓN
# =========================================================

def on_closing():

    global running

    running = False

    log(
        "Cerrando aplicación...",
        "WARNING"
    )

    try:

        plc.disconnect()

        log(
            "PLC desconectado",
            "INFO"
        )

    except:
        pass

    try:

        cursor.close()
        conn.close()

        log(
            "Base de datos cerrada",
            "INFO"
        )

    except:
        pass

    root.destroy()

root.protocol(
    "WM_DELETE_WINDOW",
    on_closing
)

# =========================================================
# INICIALIZAR EN SEGUNDO PLANO
# =========================================================

threading.Thread(
    target=initialize_system,
    daemon=True
).start()

# =========================================================
# EJECUTAR GUI
# =========================================================

root.mainloop()
