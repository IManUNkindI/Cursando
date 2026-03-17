import cv2
import numpy as np
import os
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.mixture import GaussianMixture

def procesar_imagen(nombre_imagen, base_path="."):
    path = os.path.join(base_path, nombre_imagen)
    if not os.path.exists(path):
        print(f"Error: No se encontró la imagen {nombre_imagen}")
        return None

    # Leer imagen
    img = cv2.imread(path)
    if img is None:
        print(f"Error: No se pudo cargar la imagen {nombre_imagen}")
        return None

    # Obtener dimensiones
    alto, ancho = img.shape[:2]

    # 1. Convertir a RGB (OpenCV lee en BGR por defecto)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # 2. Convertir a CIELab
    img_lab = cv2.cvtColor(img, cv2.COLOR_BGR2Lab)

    # 3. Normalizar datos de color (0-1)
    # RGB: 0-255 -> 0-1
    img_rgb_norm = img_rgb.astype(np.float32) / 255.0
    
    # Lab: L [0, 100], a [-127, 127], b [-127, 127]
    # Usaremos la normalización estándar de OpenCV para 8 bits que escala convenientemente
    img_lab_norm = img_lab.astype(np.float32) / 255.0

    # 4. Definir coordenadas espaciales normalizadas (0-1)
    x = np.linspace(0, 1, ancho)
    y = np.linspace(0, 1, alto)
    xv, yv = np.meshgrid(x, y)
    
    # Expandir dimensiones para que coincidan con la imagen [alto, ancho, 1]
    xv = xv[:, :, np.newaxis]
    yv = yv[:, :, np.newaxis]

    # 5. Definir vector de características por píxel [color + coordenadas]
    # Combinamos RGB + Lab + XY
    # El usuario pide [color + coordenadas], usaremos RGB y Lab como opciones
    
    # Vector RGB + XY
    features_rgb_xy = np.concatenate((img_rgb_norm, xv, yv), axis=2)
    # Reshape a (alto*ancho, 5) -> cada fila es un píxel: [R, G, B, X, Y]
    vector_rgb_xy = features_rgb_xy.reshape(-1, 5)

    # Vector Lab + XY
    features_lab_xy = np.concatenate((img_lab_norm, xv, yv), axis=2)
    # Reshape a (alto*ancho, 5) -> cada fila es un píxel: [L, a, b, X, Y]
    vector_lab_xy = features_lab_xy.reshape(-1, 5)

    print(f"Imagen {nombre_imagen} procesada:")
    print(f"  Shape vector RGB+XY: {vector_rgb_xy.shape}")
    print(f"  Shape vector Lab+XY: {vector_lab_xy.shape}")
    
    return {
        "rgb_xy": vector_rgb_xy,
        "lab_xy": vector_lab_xy,
        "img_rgb": img_rgb,
        "original_shape": (alto, ancho)
    }

def segmentar_imagen(features, n_clusters, metodo='kmeans'):
    if metodo == 'kmeans':
        model = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    elif metodo == 'gmm':
        model = GaussianMixture(n_components=n_clusters, random_state=42)
    else:
        raise ValueError("Metodo no soportado. Usa 'kmeans' o 'gmm'.")
    
    labels = model.fit_predict(features)
    return labels

def posprocesar_mascara(labels, shape):
    mask = labels.reshape(shape)
    # Ejemplo de posprocesamiento: Apertura morfológica para quitar ruido
    kernel = np.ones((5, 5), np.uint8)
    
    processed_mask = np.zeros_like(mask)
    for i in range(np.max(mask) + 1):
        binary_mask = (mask == i).astype(np.uint8)
        opening = cv2.morphologyEx(binary_mask, cv2.MORPH_OPEN, kernel)
        closing = cv2.morphologyEx(opening, cv2.MORPH_CLOSE, kernel)
        processed_mask[closing == 1] = i
        
    return processed_mask

def visualizar_resultados(img_original, labels, n_clusters, titulo, save_path=None):
    alto, ancho = img_original.shape[:2]
    mask = labels.reshape(alto, ancho)
    
    # Crear una imagen segmentada usando colores promedio de cada cluster
    img_segmented = np.zeros_like(img_original)
    for i in range(n_clusters):
        pixels = img_original[mask == i]
        if len(pixels) > 0:
            color_medio = np.mean(pixels, axis=0)
            img_segmented[mask == i] = color_medio.astype(np.uint8)

    plt.figure(figsize=(12, 4))
    plt.subplot(1, 3, 1)
    plt.imshow(img_original)
    plt.title("Original")
    plt.axis('off')

    plt.subplot(1, 3, 2)
    plt.imshow(mask, cmap='viridis')
    plt.title(f"Máscara (k={n_clusters})")
    plt.axis('off')

    plt.subplot(1, 3, 3)
    plt.imshow(img_segmented)
    plt.title(f"Segmentada ({titulo})")
    plt.axis('off')

    if save_path:
        plt.savefig(save_path)
        plt.close()
    else:
        plt.show()

import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from PIL import Image, ImageTk

class SegmentationApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Segmentación de Imágenes - IA")
        self.root.geometry("1000x700")

        # Variables de estado
        self.path_imagen = None
        self.res_procesamiento = None
        self.labels_segmentacion = None

        # Configuración de estilo
        self.setup_ui()

    def setup_ui(self):
        # Panel lateral de controles
        panel_controles = tk.Frame(self.root, width=250, bg="#f0f0f0", padx=10, pady=10)
        panel_controles.pack(side="left", fill="y")

        tk.Label(panel_controles, text="Configuración", font=("Arial", 14, "bold"), bg="#f0f0f0").pack(pady=10)

        # Botón cargar
        tk.Button(panel_controles, text="Cargar Imagen", command=self.cargar_imagen, bg="#4CAF50", fg="white", font=("Arial", 10, "bold")).pack(fill="x", pady=5)

        self.lbl_archivo = tk.Label(panel_controles, text="Ninguna imagen cargada", wraplength=200, bg="#f0f0f0", font=("Arial", 8))
        self.lbl_archivo.pack(pady=5)

        # Parámetro K
        tk.Label(panel_controles, text="Número de Clusters (k):", bg="#f0f0f0").pack(pady=(10, 0))
        self.val_k = tk.IntVar(value=3)
        tk.Spinbox(panel_controles, from_=2, to=10, textvariable=self.val_k).pack(fill="x")

        # Método
        tk.Label(panel_controles, text="Método:", bg="#f0f0f0").pack(pady=(10, 0))
        self.metodo_var = tk.StringVar(value="kmeans")
        ttk.Combobox(panel_controles, textvariable=self.metodo_var, values=["kmeans", "gmm"], state="readonly").pack(fill="x")

        # Botón segmentar
        self.btn_segmentar = tk.Button(panel_controles, text="Segmentar", command=self.ejecutar_segmentacion, bg="#2196F3", fg="white", font=("Arial", 10, "bold"), state="disabled")
        self.btn_segmentar.pack(fill="x", pady=20)

        # Panel principal de visualización
        self.canvas_area = tk.Frame(self.root, bg="white")
        self.canvas_area.pack(side="right", fill="both", expand=True)

        self.lbl_original = tk.Label(self.canvas_area, text="Imagen Original", bg="white")
        self.lbl_original.grid(row=0, column=0, padx=10, pady=10)
        
        self.lbl_resultado = tk.Label(self.canvas_area, text="Resultado de Segmentación", bg="white")
        self.lbl_resultado.grid(row=0, column=1, padx=10, pady=10)

        self.panel_img_orig = tk.Label(self.canvas_area, bg="#e0e0e0", width=400, height=400)
        self.panel_img_orig.grid(row=1, column=0, padx=10, pady=10)

        self.panel_img_res = tk.Label(self.canvas_area, bg="#e0e0e0", width=400, height=400)
        self.panel_img_res.grid(row=1, column=1, padx=10, pady=10)

    def cargar_imagen(self):
        file_path = filedialog.askopenfilename(filetypes=[("Imágenes", "*.jpg *.jpeg *.png")])
        if file_path:
            self.path_imagen = file_path
            self.lbl_archivo.config(text=os.path.basename(file_path))
            
            # Procesar imagen inmediatamente para tener los features listos
            self.res_procesamiento = procesar_imagen(os.path.basename(file_path), os.path.dirname(file_path))
            
            if self.res_procesamiento:
                # Mostrar preview original
                img = Image.open(file_path)
                img.thumbnail((400, 400))
                img_tk = ImageTk.PhotoImage(img)
                self.panel_img_orig.config(image=img_tk)
                self.panel_img_orig.image = img_tk
                self.btn_segmentar.config(state="normal")
            else:
                messagebox.showerror("Error", "No se pudo cargar la imagen")

    def ejecutar_segmentacion(self):
        if not self.res_procesamiento:
            return

        k = self.val_k.get()
        metodo = self.metodo_var.get()
        features = self.res_procesamiento["lab_xy"]
        shape = self.res_procesamiento["original_shape"]
        img_rgb = self.res_procesamiento["img_rgb"]

        self.root.config(cursor="watch")
        self.root.update()

        try:
            # Ejecutar segmentación
            labels = segmentar_imagen(features, k, metodo=metodo)
            labels_proc = posprocesar_mascara(labels, shape)

            # Generar imagen de visualización
            out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "resultados")
            if not os.path.exists(out_dir):
                os.makedirs(out_dir)

            nombre_base = os.path.splitext(os.path.basename(self.path_imagen))[0]
            filename = f"{nombre_base}_{metodo}_k{k}.png"
            save_path = os.path.join(out_dir, filename)

            # Usar la función existente para visualizar y guardar
            # Pero modificada para obtener el array segmentado
            mask = labels_proc.reshape(shape)
            img_segmented = np.zeros_like(img_rgb)
            for i in range(k):
                pixels = img_rgb[mask == i]
                if len(pixels) > 0:
                    color_medio = np.mean(pixels, axis=0)
                    img_segmented[mask == i] = color_medio.astype(np.uint8)

            # Guardar resultado
            cv2.imwrite(save_path, cv2.cvtColor(img_segmented, cv2.COLOR_RGB2BGR))

            # Mostrar resultado en UI
            img_pil = Image.fromarray(img_segmented)
            img_pil.thumbnail((400, 400))
            img_tk = ImageTk.PhotoImage(img_pil)
            self.panel_img_res.config(image=img_tk)
            self.panel_img_res.image = img_tk

            messagebox.showinfo("Éxito", f"Segmentación completada.\nGuardado en: {save_path}")

        except Exception as e:
            messagebox.showerror("Error", f"Ocurrió un error: {str(e)}")
        finally:
            self.root.config(cursor="")

if __name__ == "__main__":
    root = tk.Tk()
    app = SegmentationApp(root)
    root.mainloop()
