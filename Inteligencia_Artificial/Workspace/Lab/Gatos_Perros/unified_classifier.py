import os
import sys
import tkinter as tk
from tkinter import filedialog, Label
from PIL import Image, ImageTk

# 1. Configuración de entorno y supresión de logs de TensorFlow
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# Configurar codificación para consola Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
from tensorflow.keras.preprocessing import image
import numpy as np

# 2. Lógica de Clasificación
def load_model():
    """Carga el modelo MobileNetV2 pre-entrenado."""
    print("Cargando modelo MobileNetV2...")
    model = MobileNetV2(weights='imagenet')
    print("Modelo cargado exitosamente.")
    return model

def classify_image(img_path, model):
    """Clasifica una imagen y determina si es un perro o un gato."""
    result = {
        'is_animal': False,
        'label': 'Objeto Desconocido',
        'probability': 0.0,
        'type': None
    }
    
    try:
        # Cargar y preprocesar la imagen
        img = image.load_img(img_path, target_size=(224, 224))
        x = image.img_to_array(img)
        x = np.expand_dims(x, axis=0)
        x = preprocess_input(x)

        # Realizar predicción
        preds = model.predict(x, verbose=0)
        decoded_preds = decode_predictions(preds, top=3)[0]

        # Palabras clave para ImageNet
        dog_keywords = ['dog', 'terrier', 'retriever', 'spaniel', 'hound', 'poodle', 'collie', 'sheepdog', 'bulldog', 'dalmatian', 'beagle', 'pug', 'chihuahua', 'husky', 'schnauzer']
        cat_keywords = ['cat', 'tabby', 'tiger', 'siamese', 'persian', 'egyptian', 'lynx', 'leopard', 'lion', 'kit', 'feline']

        found_animal = False
        
        for i, (id, label, prob) in enumerate(decoded_preds):
            label_lower = label.lower()
            
            if not found_animal:
                if any(k in label_lower for k in dog_keywords):
                    result['is_animal'] = True
                    result['label'] = label
                    result['probability'] = float(prob)
                    result['type'] = 'Perro'
                    found_animal = True
                elif any(k in label_lower for k in cat_keywords):
                    result['is_animal'] = True
                    result['label'] = label
                    result['probability'] = float(prob)
                    result['type'] = 'Gato'
                    found_animal = True
                
    except Exception as e:
        print(f"Error al procesar la imagen {img_path}: {e}")
        return None

    return result

# 3. Interfaz Gráfica (GUI)
class ClassifierApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Clasificador de Perros y Gatos")
        self.root.geometry("600x820")
        self.root.configure(bg='#f5f5f5')

        self.model = None
        self.panel = None

        # Elementos de la interfaz
        self.title_label = Label(root, text="Clasificador IA", font=("Segoe UI", 28, "bold"), bg='#f5f5f5', fg='#333')
        self.title_label.pack(pady=10)

        self.btn = tk.Button(root, text="Cargar Imagen", command=self.select_image, 
                            font=("Segoe UI", 14, "bold"), bg="#4CAF50", fg="white", 
                            padx=30, pady=12, relief="flat", cursor="hand2")
        self.btn.pack(pady=5)

        self.img_container = tk.Frame(root, bg='#e0e0e0', width=400, height=400)
        self.img_container.pack_propagate(False)
        self.img_container.pack(pady=10)

        self.img_label = Label(self.img_container, bg='#e0e0e0')
        self.img_label.pack(expand=True, fill="both")
        self.img_label.config(text="Vista previa de imagen", font=("Segoe UI", 12))

        self.result_label = Label(root, text="", font=("Segoe UI", 18, "bold"), bg='#f5f5f5')
        self.result_label.pack(pady=10)

        self.status_label = Label(root, text="Iniciando...", font=("Segoe UI", 10), bg='#f5f5f5', fg='#888')
        self.status_label.pack(side="bottom", fill="x", pady=5)

        # Cargar el modelo al iniciar
        self.root.after(100, self.load_ai_model)

    def load_ai_model(self):
        self.status_label.config(text="Cargando modelo neuronal... (puede tardar unos segundos)")
        self.root.update()
        try:
            self.model = load_model()
            self.status_label.config(text="Modelo cargado. Listo.")
        except Exception as e:
            self.status_label.config(text=f"Error al cargar modelo: {e}")

    def select_image(self):
        if self.model is None:
            return

        path = filedialog.askopenfilename(
            title="Seleccionar una imagen",
            filetypes=[("Imágenes", "*.jpg *.jpeg *.png *.bmp")]
        )

        if path:
            # Mostrar miniatura con mejor redimensionamiento
            img = Image.open(path)
            
            # Calcular dimensiones manteniendo el aspecto
            preview_size = (390, 390)
            img.thumbnail(preview_size, Image.Resampling.LANCZOS)
            img_tk = ImageTk.PhotoImage(img)

            self.img_label.configure(image=img_tk, text="")
            self.img_label.image = img_tk

            self.status_label.config(text="Clasificando...")
            self.root.update()
            
            result = classify_image(path, self.model)
            
            if result:
                if result['is_animal']:
                    text = f"¡Es un {result['type']}!\nRaza: {result['label']}\nConfianza: {result['probability']*100:.2f}%"
                    self.result_label.config(text=text, fg="#2E7D32")
                else:
                    self.result_label.config(text="Objeto Desconocido", fg="#C62828")
            else:
                self.result_label.config(text="Error en la clasificación", fg="#C62828")
                
            self.status_label.config(text="Listo.")

if __name__ == '__main__':
    root = tk.Tk()
    app = ClassifierApp(root)
    root.mainloop()
