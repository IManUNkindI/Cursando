import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image, ImageTk
import os
import cv2
import numpy as np
from main import train_classifier, predict_custom_image

class ClassifierGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("AI Visual Classifier - Multi-Class")
        self.root.geometry("700x500")
        self.root.configure(bg="#2d2d2d")  # Modern dark background
        
        # Load and train the model immediately
        self.clf, _ = train_classifier()
        
        self.setup_ui()

    def setup_ui(self):
        # Header
        header = tk.Label(self.root, text="Clasificador de Imágenes AI", 
                         font=("Helvetica", 20, "bold"), bg="#2d2d2d", fg="#ffffff", pady=20)
        header.pack()

        # Main Container
        self.main_frame = tk.Frame(self.root, bg="#2d2d2d")
        self.main_frame.pack(expand=True, fill="both", padx=20, pady=10)

        # Left Panel (Images Preview)
        self.preview_frame = tk.Frame(self.main_frame, bg="#2d2d2d")
        self.preview_frame.pack(side="left", padx=10)

        # Original Preview
        original_title = tk.Label(self.preview_frame, text="Original:", bg="#2d2d2d", fg="#888888")
        original_title.pack()
        self.preview_canvas = tk.Frame(self.preview_frame, bg="#3d3d3d", width=250, height=250, 
                                     highlightthickness=2, highlightbackground="#555555")
        self.preview_canvas.pack(pady=5)
        self.preview_canvas.pack_propagate(False)
        self.img_label = tk.Label(self.preview_canvas, text="Vista Previa", bg="#3d3d3d", fg="#888888")
        self.img_label.pack(expand=True)

        # Filtered 8x8 Preview
        filtered_title = tk.Label(self.preview_frame, text="Filtro AI (8x8):", bg="#2d2d2d", fg="#888888")
        filtered_title.pack(pady=(15, 0))
        self.filtered_canvas = tk.Frame(self.preview_frame, bg="#3d3d3d", width=120, height=120, 
                                     highlightthickness=2, highlightbackground="#4a90e2")
        self.filtered_canvas.pack(pady=5)
        self.filtered_canvas.pack_propagate(False)
        self.img_8x8_label = tk.Label(self.filtered_canvas, text="8x8", bg="#3d3d3d", fg="#888888")
        self.img_8x8_label.pack(expand=True)

        # Right Panel (Instructions & Results)
        self.info_frame = tk.Frame(self.main_frame, bg="#2d2d2d")
        self.info_frame.pack(side="right", expand=True, fill="both")

        self.btn_load = tk.Button(self.info_frame, text="Cargar Imagen", command=self.load_image,
                                 font=("Helvetica", 12), bg="#4a90e2", fg="white", 
                                 padx=20, pady=10, borderwidth=0, cursor="hand2")
        self.btn_load.pack(pady=20)

        self.result_title = tk.Label(self.info_frame, text="Resultado:", 
                                    font=("Helvetica", 14), bg="#2d2d2d", fg="#aaaaaa")
        self.result_title.pack()

        self.result_label = tk.Label(self.info_frame, text="Esperando...", 
                                    font=("Helvetica", 24, "bold"), bg="#2d2d2d", fg="#4a90e2")
        self.result_label.pack(pady=10)

        # Status Bar
        self.status = tk.Label(self.root, text="Modelo cargado y listo (Dataset: Digits 0-9)", 
                              bd=1, relief=tk.SUNKEN, anchor=tk.W, bg="#1e1e1e", fg="#666666", padx=10)
        self.status.pack(side="bottom", fill="x")

    def load_image(self):
        file_path = filedialog.askopenfilename(
            filetypes=[("Imágenes", "*.jpg *.jpeg *.png *.bmp")]
        )
        if file_path:
            self.display_image(file_path)
            self.predict(file_path)

    def display_image(self, path):
        img = Image.open(path)
        img.thumbnail((280, 280))  # Resize for preview
        img_tk = ImageTk.PhotoImage(img)
        self.img_label.configure(image=img_tk, text="")
        self.img_label.image = img_tk  # Keep a reference

    def predict(self, path):
        try:
            # Reusing the prediction logic from main.py
            prediction, img_8x8 = predict_custom_image(self.clf, path)
            
            # Show filtered 8x8 image in GUI (upscaled for visibility)
            # Normalize img_8x8 (0-16) back to 0-255 for display
            img_vis = (16 - img_8x8) / 16 * 255
            img_vis = img_vis.astype(np.uint8)
            img_pil = Image.fromarray(img_vis)
            img_pil = img_pil.resize((100, 100), Image.NEAREST) # Nearest to see pixels
            img_tk_filtered = ImageTk.PhotoImage(img_pil)
            self.img_8x8_label.configure(image=img_tk_filtered, text="")
            self.img_8x8_label.image = img_tk_filtered

            # Show results
            self.result_label.configure(text=f"Dígito {prediction}", fg="#2ecc71")
            self.status.configure(text=f"Identificado: {prediction}")
        except Exception as e:
            messagebox.showerror("Error", f"No se pudo procesar la imagen:\n{str(e)}")
            self.result_label.configure(text="Error", fg="#e74c3c")

if __name__ == "__main__":
    root = tk.Tk()
    app = ClassifierGUI(root)
    root.mainloop()
