import tkinter as tk
from tkinter import ttk, messagebox
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import math

# =============================================================================
# LÓGICA DE LA RED NEURAL (IMPLEMENTACIÓN DESDE CERO)
# =============================================================================

def sigmoid(z):
    """Función de activación Sigmoide."""
    return 1 / (1 + np.exp(-z))

def sigmoid_derivative(z):
    """Derivada de la función Sigmoide."""
    s = sigmoid(z)
    return s * (1 - s)

class Layer:
    """Representa una capa en la red neuronal."""
    def __init__(self, input_size, neurons_count, layer_name="Layer"):
        self.name = layer_name
        # Inicialización de pesos y sesgos (pequeños valores aleatorios)
        self.weights = np.random.randn(neurons_count, input_size) * 0.1
        self.biases = np.random.randn(neurons_count, 1) * 0.1
        
        # Almacenamiento para visualización y backprop
        self.z = None      # Entrada lineal: z = W*a_prev + b
        self.a = None      # Activación: a = sigmoid(z)
        self.a_prev = None # Activación de la capa anterior
        self.delta = None  # Error local (gradiente local)
        self.dW = None     # Gradiente de pesos
        self.db = None     # Gradiente de sesgos

    def forward(self, a_prev):
        """Paso hacia adelante de la capa."""
        self.a_prev = a_prev
        self.z = np.dot(self.weights, a_prev) + self.biases
        self.a = sigmoid(self.z)
        return self.a

class NeuralNetwork:
    """Red Neuronal Completa."""
    def __init__(self, layer_sizes, lr=0.1):
        self.layers = []
        self.lr = lr
        for i in range(len(layer_sizes) - 1):
            name = f"Hidden {i+1}" if i < len(layer_sizes) - 2 else "Output"
            self.layers.append(Layer(layer_sizes[i], layer_sizes[i+1], name))
        
        self.history_loss = []

    def forward(self, x):
        """Forward propagation completa."""
        out = x
        for layer in self.layers:
            out = layer.forward(out)
        return out

    def backward(self, x, y):
        """Backpropagation paso a paso."""
        # Supone que el forward ya se ejecutó
        # 1. Error en la capa de salida
        output_layer = self.layers[-1]
        # Derivada de la pérdida (MSE: 0.5 * (y - a)^2) respecto a activacion: (a - y)
        error_signal = (output_layer.a - y)
        output_layer.delta = error_signal * sigmoid_derivative(output_layer.z)
        
        # 2. Propagar error hacia atrás por las capas ocultas
        for i in reversed(range(len(self.layers) - 1)):
            current_layer = self.layers[i]
            next_layer = self.layers[i+1]
            current_layer.delta = np.dot(next_layer.weights.T, next_layer.delta) * sigmoid_derivative(current_layer.z)

    def update_weights(self):
        """Actualizar pesos usando los deltas calculados."""
        for layer in self.layers:
            # Gradients
            layer.dW = np.dot(layer.delta, layer.a_prev.T)
            layer.db = np.copy(layer.delta)
            
            # Actualización
            layer.weights -= self.lr * layer.dW
            layer.biases -= self.lr * layer.db

# =============================================================================
# DATASET (DÍGITOS 5x5: 0-9)
# =============================================================================

def flatten(matrix):
    return np.array(matrix).reshape(25, 1)

DATASET = [
    {"x": flatten([[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,1]]), "y": np.array([[1,0,0,0,0,0,0,0,0,0]]).T}, # 0
    {"x": flatten([[0,0,1,0,0],[0,1,1,0,0],[1,0,1,0,0],[0,0,1,0,0],[1,1,1,1,1]]), "y": np.array([[0,1,0,0,0,0,0,0,0,0]]).T}, # 1
    {"x": flatten([[1,1,1,1,1],[0,0,0,0,1],[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,1]]), "y": np.array([[0,0,1,0,0,0,0,0,0,0]]).T}, # 2
    {"x": flatten([[1,1,1,1,1],[0,0,0,0,1],[0,1,1,1,1],[0,0,0,0,1],[1,1,1,1,1]]), "y": np.array([[0,0,0,1,0,0,0,0,0,0]]).T}, # 3
    {"x": flatten([[1,0,0,1,0],[1,0,0,1,0],[1,1,1,1,1],[0,0,0,1,0],[0,0,0,1,0]]), "y": np.array([[0,0,0,0,1,0,0,0,0,0]]).T}, # 4
    {"x": flatten([[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,1],[0,0,0,0,1],[1,1,1,1,1]]), "y": np.array([[0,0,0,0,0,1,0,0,0,0]]).T}, # 5
    {"x": flatten([[1,1,1,1,1],[1,0,0,0,0],[1,1,1,1,1],[1,0,0,0,1],[1,1,1,1,1]]), "y": np.array([[0,0,0,0,0,0,1,0,0,0]]).T}, # 6
    {"x": flatten([[1,1,1,1,1],[0,0,0,0,1],[0,0,0,1,0],[0,0,1,0,0],[0,1,0,0,0]]), "y": np.array([[0,0,0,0,0,0,0,1,0,0]]).T}, # 7
    {"x": flatten([[1,1,1,1,1],[1,0,0,0,1],[1,1,1,1,1],[1,0,0,0,1],[1,1,1,1,1]]), "y": np.array([[0,0,0,0,0,0,0,0,1,0]]).T}, # 8
    {"x": flatten([[1,1,1,1,1],[1,0,0,0,1],[1,1,1,1,1],[0,0,0,0,1],[1,1,1,1,1]]), "y": np.array([[0,0,0,0,0,0,0,0,0,1]]).T}, # 9
]

# =============================================================================
# INTERFAZ GRÁFICA (TKINTER)
# =============================================================================

class App:
    def __init__(self, root):
        self.root = root
        self.root.title("Simulador Backpropagation - Paso a Paso")
        self.root.geometry("1200x900") 
        try:
            self.root.state('zoomed') # Maximizar ventana en Windows
        except:
            pass
        
        # Estado del simulador
        self.nn_arch = [25, 3, 3, 10]
        self.nn = None
        self.lr = 0.5
        self.epochs = 500
        self.current_example_idx = 0
        self.is_forward_done = False
        self.is_backward_done = False
        self.epoch_count = 0
        
        self.setup_ui()
        self.initialize_network()

    def setup_ui(self):
        # Panel de Controles (EMPACADO PRIMERO ARRIBA para asegurar visibilidad)
        control_panel = ttk.LabelFrame(self.root, text="Controles", padding="10")
        control_panel.pack(side=tk.TOP, fill=tk.X, padx=10, pady=5)
        
        ttk.Label(control_panel, text="LR:").pack(side=tk.LEFT)
        self.lr_entry = ttk.Entry(control_panel, width=5)
        self.lr_entry.insert(0, "0.5")
        self.lr_entry.pack(side=tk.LEFT, padx=5)
        
        ttk.Label(control_panel, text="Epochs:").pack(side=tk.LEFT)
        self.epochs_entry = ttk.Entry(control_panel, width=6)
        self.epochs_entry.insert(0, "500")
        self.epochs_entry.pack(side=tk.LEFT, padx=5)

        ttk.Button(control_panel, text="Inicializar Red", command=self.initialize_network).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_panel, text="Paso Forward", command=self.step_forward).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_panel, text="Paso Backward", command=self.step_backward).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_panel, text="Actualizar Pesos", command=self.step_update).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_panel, text="Entrenar 1 Epoch", command=self.train_epoch).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_panel, text="Entrenar Completo", command=self.train_full).pack(side=tk.LEFT, padx=5)
        
        self.status_label = ttk.Label(control_panel, text="Estado: Red Inicializada", font=("Arial", 9, "bold"))
        self.status_label.pack(side=tk.RIGHT)

        # Frame Principal (Ocupa el resto)
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Panel Izquierdo (Grafo de la Red)
        left_panel = ttk.LabelFrame(main_frame, text="Visualización de la Red", padding="10")
        left_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        self.canvas = tk.Canvas(left_panel, bg="white", highlightthickness=1, highlightbackground="#cccccc")
        self.canvas.pack(fill=tk.BOTH, expand=True)

        # Panel Derecho (Matemáticas y Gráfica)
        right_panel = ttk.Frame(main_frame, padding="5")
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH)

        # Gráfica de Error
        self.fig, self.ax = plt.subplots(figsize=(4, 2.5), dpi=100) # Más compacta
        self.ax.set_title("Error vs Epochs")
        self.ax.set_xlabel("Epoch")
        self.ax.set_ylabel("MSE")
        self.plot_canvas = FigureCanvasTkAgg(self.fig, master=right_panel)
        self.plot_canvas.get_tk_widget().pack()

        # Panel de Dibujo interactivo (MOVIDO ARRIBA para asegurar visibilidad)
        draw_panel = ttk.LabelFrame(right_panel, text="Dibujar Patrón (5x5)", padding="5")
        draw_panel.pack(fill=tk.X, pady=5)
        
        self.draw_grid_frame = ttk.Frame(draw_panel)
        self.draw_grid_frame.pack()
        
        self.draw_state = np.zeros((5, 5))
        self.grid_buttons = []
        for r in range(5):
            row_btns = []
            for c in range(5):
                btn = tk.Button(self.draw_grid_frame, width=2, height=1, bg="white", 
                               command=lambda r=r, c=c: self.toggle_pixel(r, c))
                btn.grid(row=r, column=c, padx=1, pady=1)
                row_btns.append(btn)
            self.grid_buttons.append(row_btns)
            
        btn_frame = ttk.Frame(draw_panel)
        btn_frame.pack(fill=tk.X, pady=2)
        ttk.Button(btn_frame, text="Predecir Dibujo", command=self.predict_drawing).pack(side=tk.LEFT, padx=5, expand=True)
        ttk.Button(btn_frame, text="Borrar Lienzo", command=self.clear_drawing).pack(side=tk.LEFT, padx=5, expand=True)
        
        # Selección de etiqueta para aprendizaje
        learn_frame = ttk.Frame(draw_panel)
        learn_frame.pack(fill=tk.X, pady=2)
        ttk.Label(learn_frame, text="Es el número:").pack(side=tk.LEFT, padx=5)
        self.label_combo = ttk.Combobox(learn_frame, values=[str(i) for i in range(10)], width=3, state="readonly")
        self.label_combo.current(0)
        self.label_combo.pack(side=tk.LEFT, padx=5)
        ttk.Button(learn_frame, text="Aprender este dibujo", command=self.add_to_dataset).pack(side=tk.LEFT, padx=5, expand=True)

        # Panel Matemático (Al final porque puede scrollar)
        math_panel = ttk.LabelFrame(right_panel, text="Panel Matemático", padding="5")
        math_panel.pack(fill=tk.BOTH, expand=True, pady=5)
        
        self.math_text = tk.Text(math_panel, height=8, width=50, font=("Consolas", 9))
        self.math_text.pack(fill=tk.BOTH, expand=True)
        
    def initialize_network(self):
        try:
            self.lr = float(self.lr_entry.get())
            # Arquitectura Actualizada: 25 entrada, 2 capas ocultas de 3, 10 de salida
            self.nn_arch = [25, 3, 3, 10]
            self.nn = NeuralNetwork(self.nn_arch, lr=self.lr)
            self.nn.history_loss = []
            self.epoch_count = 0
            self.current_example_idx = 0
            self.is_forward_done = False
            self.is_backward_done = False
            self.update_canvas()
            self.update_plot()
            self.math_text.delete(1.0, tk.END)
            self.math_text.insert(tk.END, f"Red Inicializada.\nArquitectura: {self.nn_arch}\nSigmoide activada.\nDataset de 10 dígitos (5x5) cargado.")
            self.status_label.config(text="Estado: Red Inicializada")
        except ValueError:
            messagebox.showerror("Error", "Ingrese valores numéricos válidos.")

    def update_canvas(self, custom_input=None):
        self.canvas.delete("all")
        w = self.canvas.winfo_width()
        h = self.canvas.winfo_height()
        if w < 100: w = 850
        if h < 100: h = 600

        layer_sizes = self.nn_arch
        layer_x = np.linspace(60, w - 60, len(layer_sizes))
        
        neuron_radius = 10 if max(layer_sizes) > 10 else 15
        
        # Dibujar conexiones primero con optimización visual
        for i in range(len(layer_sizes) - 1):
            curr_y = np.linspace(40, h - 40, layer_sizes[i])
            next_y = np.linspace(40, h - 40, layer_sizes[i+1])
            
            for j in range(layer_sizes[i]):
                for k in range(layer_sizes[i+1]):
                    weight_val = self.nn.layers[i].weights[k, j]
                    # Solo dibujar si el peso tiene alguna magnitud o para unos pocos para no saturar
                    color = "#3498db" if weight_val > 0 else "#e74c3c"
                    alpha_val = min(1.0, abs(weight_val) * 2)
                    thickness = min(3, max(1, abs(weight_val) * 5))
                    
                    self.canvas.create_line(layer_x[i], curr_y[j], layer_x[i+1], next_y[k], fill=color, width=thickness)
                    
                    # Mostrar valor del peso solo en capas pequeñas (ocultas)
                    if layer_sizes[i] < 5 and layer_sizes[i+1] < 11:
                        mx, my = (layer_x[i] + layer_x[i+1]) / 2, (curr_y[j] + next_y[k]) / 2
                        self.canvas.create_text(mx, my, text=f"{weight_val:.2f}", font=("Arial", 7), fill="#555555")

        # Dibujar neuronas
        for i in range(len(layer_sizes)):
            layer_y = np.linspace(40, h - 40, layer_sizes[i])
            for j in range(layer_sizes[i]):
                x, y = layer_x[i], layer_y[j]
                
                if i == 0:
                    if custom_input is not None:
                        val = custom_input[j, 0]
                    else:
                        val = DATASET[self.current_example_idx]["x"][j, 0]
                else:
                    val = self.nn.layers[i-1].a[j, 0] if self.nn.layers[i-1].a is not None else 0
                
                intensity = int(val * 255)
                color = f"#{intensity:02x}{intensity:02x}{intensity:02x}"
                outline = "orange" if val > 0.5 else "black"
                
                self.canvas.create_oval(x-neuron_radius, y-neuron_radius, x+neuron_radius, y+neuron_radius, fill=color, outline=outline, width=1)
                
                # Etiquetas de valor (solo si caben)
                if layer_sizes[i] < 15:
                    self.canvas.create_text(x + (25 if i < 3 else -25), y, text=f"{val:.2f}", font=("Arial", 7, "bold"))
                elif j % 5 == 0: # Para la entrada de 25, mostrar algunos
                    self.canvas.create_text(x - 20, y, text=f"in[{j}]", font=("Arial", 6), fill="gray")

    def write_math(self, text):
        self.math_text.insert(tk.END, text + "\n")
        self.math_text.see(tk.END)

    def toggle_pixel(self, r, c):
        self.draw_state[r, c] = 1 if self.draw_state[r, c] == 0 else 0
        color = "black" if self.draw_state[r, c] == 1 else "white"
        self.grid_buttons[r][c].config(bg=color)

    def clear_drawing(self):
        self.draw_state = np.zeros((5, 5))
        for r in range(5):
            for c in range(5):
                self.grid_buttons[r][c].config(bg="white")
        self.math_text.delete(1.0, tk.END)
        self.math_text.insert(tk.END, "Lienzo borrado. Dibuje un nuevo patrón.")

    def predict_drawing(self):
        x = self.draw_state.reshape(25, 1)
        # Usar la red actual para predecir
        out = self.nn.forward(x)
        prediction = np.argmax(out)
        confidence = out[prediction, 0]
        
        self.math_text.delete(1.0, tk.END)
        self.write_math("--- PREDICCIÓN DE DIBUJO ---")
        self.write_math(f"Entrada 5x5 detectada.")
        self.write_math(f"Salidas de la red (activaciones):")
        for i in range(len(out)):
            self.write_math(f"  [{i}]: {out[i, 0]:.4f}")
        
        self.write_math(f"\nRESULTADO: Es probable que sea un '{prediction}'")
        self.write_math(f"Confianza: {confidence*100:.2f}%")
        
        # Actualizar el canvas para mostrar cómo tu dibujo activa la red
        self.update_canvas(custom_input=x)
        self.status_label.config(text=f"Predicción: {prediction} ({confidence*100:.1f}%)")

    def add_to_dataset(self):
        target_digit = int(self.label_combo.get())
        x_new = self.draw_state.reshape(25, 1)
        
        # Crear vector one-hot para la etiqueta
        y_new = np.zeros((10, 1))
        y_new[target_digit, 0] = 1.0
        
        # Agregar al dataset global
        DATASET.append({"x": x_new, "y": y_new})
        
        self.math_text.delete(1.0, tk.END)
        self.write_math(f"--- DATO AGREGADO ---")
        self.write_math(f"El patrón actual ha sido etiquetado como '{target_digit}'")
        self.write_math(f"Dataset: {len(DATASET)} ejemplos.")
        self.write_math(f"\nUsa 'Entrenar 1 Epoch' para aprenderlo.")
        self.status_label.config(text=f"Dato añadido ({len(DATASET)})")

    def step_forward(self):
        example = DATASET[self.current_example_idx]
        x, y = example["x"], example["y"]
        self.math_text.delete(1.0, tk.END)
        self.write_math(f"--- FORWARD PASS (Ejemplo {self.current_example_idx}) ---")
        
        current_input = x
        for i, layer in enumerate(self.nn.layers):
            self.write_math(f"Capa: {layer.name}")
            prev_a = current_input
            current_input = layer.forward(current_input)
            
            # Mostrar ejemplo de cálculo para la primera neurona de la capa
            self.write_math(f"  z[0] = Σ(w*a_prev) + b")
            val_z = layer.z[0, 0]
            val_a = layer.a[0, 0]
            self.write_math(f"  z[0] = {val_z:.4f}")
            self.write_math(f"  a[0] = σ({val_z:.4f}) = {val_a:.4f}")
        
        mse = 0.5 * np.sum((current_input - y)**2)
        self.write_math(f"\nSalida Obtenida: {current_input.flatten()}")
        self.write_math(f"Salida Deseada: {y.flatten()}")
        self.write_math(f"Error (MSE): {mse:.6f}")
        
        self.is_forward_done = True
        self.is_backward_done = False
        self.update_canvas()
        self.status_label.config(text="Estado: Forward Completado")

    def step_backward(self):
        if not self.is_forward_done:
            messagebox.showwarning("Aviso", "Ejecute Forward primero.")
            return
        
        self.write_math("\n--- BACKPROPAGATION ---")
        example = DATASET[self.current_example_idx]
        y = example["y"]
        
        self.nn.backward(example["x"], y)
        
        # Mostrar cálculos para la capa de salida
        out_layer = self.nn.layers[-1]
        self.write_math(f"Capa Salida: {out_layer.name}")
        self.write_math(f"  δ_out = (a - y) * σ'(z)")
        self.write_math(f"  δ[0] = ({out_layer.a[0,0]:.3f} - {y[0,0]:.3f}) * {sigmoid_derivative(out_layer.z[0,0]):.3f}")
        self.write_math(f"  δ[0] = {out_layer.delta[0,0]:.4f}")
        
        # Mostrar para una capa oculta
        h_layer = self.nn.layers[1]
        self.write_math(f"\nCapa Oculta: {h_layer.name}")
        self.write_math(f"  δ_h = (W_next_T * δ_next) * σ'(z)")
        self.write_math(f"  δ_h[0] = {h_layer.delta[0,0]:.4f}")

        self.is_backward_done = True
        self.status_label.config(text="Estado: Backprop Completado")

    def step_update(self):
        if not self.is_backward_done:
            messagebox.showwarning("Aviso", "Ejecute Backprop primero.")
            return
        
        self.write_math("\n--- ACTUALIZACIÓN DE PESOS ---")
        self.write_math(f"Learning Rate (η) = {self.nn.lr}")
        
        # Guardar un ejemplo de peso antes
        layer = self.nn.layers[0]
        old_w = layer.weights[0, 0]
        
        self.nn.update_weights()
        
        new_w = layer.weights[0, 0]
        grad = layer.dW[0, 0]
        self.write_math(f"Ejemplo W[0,0] (Capa 0):")
        self.write_math(f"  ΔW = η * δ * a_prev = {self.nn.lr} * {grad/layer.a_prev[0,0] if layer.a_prev[0,0]!=0 else 0:.4f} * ... = {self.nn.lr * grad:.6f}")
        self.write_math(f"  W_nuevo = {old_w:.4f} - {self.nn.lr * grad:.4f} = {new_w:.4f}")

        self.is_forward_done = False
        self.is_backward_done = False
        self.update_canvas()
        
        # Pasar al siguiente ejemplo circularmente
        self.current_example_idx = (self.current_example_idx + 1) % len(DATASET)
        self.status_label.config(text=f"Estado: Pesos Actualizados. Siguiente: Ejemplo {self.current_example_idx}")

    def train_epoch(self):
        total_error = 0
        for example in DATASET:
            x, y = example["x"], example["y"]
            pred = self.nn.forward(x)
            total_error += 0.5 * np.sum((pred - y)**2)
            self.nn.backward(x, y)
            self.nn.update_weights()
        
        avg_error = total_error / len(DATASET)
        self.nn.history_loss.append(avg_error)
        self.epoch_count += 1
        self.update_plot()
        self.update_canvas()
        self.status_label.config(text=f"Epoch {self.epoch_count} - Error: {avg_error:.6f}")

    def train_full(self):
        try:
            self.epochs = int(self.epochs_entry.get())
            for _ in range(self.epochs):
                total_error = 0
                for example in DATASET:
                    x, y = example["x"], example["y"]
                    pred = self.nn.forward(x)
                    total_error += 0.5 * np.sum((pred - y)**2)
                    self.nn.backward(x, y)
                    self.nn.update_weights()
                avg_error = total_error / len(DATASET)
                self.nn.history_loss.append(avg_error)
                self.epoch_count += 1
            
            self.update_plot()
            self.update_canvas()
            self.status_label.config(text=f"Entrenamiento Finalizado ({self.epoch_count} epochs)")
            messagebox.showinfo("Éxito", f"Entrenamiento completado.\nError final: {avg_error:.6f}")
        except ValueError:
            messagebox.showerror("Error", "Ingrese un número de epochs válido.")

    def update_plot(self):
        self.ax.clear()
        self.ax.set_title("Curva de Error (MSE)")
        self.ax.set_xlabel("Epoch")
        self.ax.set_ylabel("MSE")
        self.ax.plot(self.nn.history_loss, color="blue")
        self.plot_canvas.draw()

if __name__ == "__main__":
    root = tk.Tk()
    # Prevenir que la red no se dibuje al inicio por falta de tamaño del canvas
    root.update()
    app = App(root)
    root.mainloop()
