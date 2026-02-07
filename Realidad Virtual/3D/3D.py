import cv2
import numpy as np

import os

# Cargar imágenes
script_dir = os.path.dirname(os.path.abspath(__file__))
img_left_path = os.path.join(script_dir, "Izq.jpg")
img_right_path = os.path.join(script_dir, "Der.jpg")

img_left = cv2.imread(img_left_path)
img_right = cv2.imread(img_right_path)

# Verificación básica
if img_left is None or img_right is None:
    raise ValueError("No se pudieron cargar las imágenes")

# Redimensionar imágenes si son muy grandes
def resize_if_needed(img, max_width=550):
    height, width = img.shape[:2]
    if width > max_width:
        scaling_factor = max_width / width
        new_height = int(height * scaling_factor)
        return cv2.resize(img, (max_width, new_height), interpolation=cv2.INTER_AREA)
    return img

img_left = resize_if_needed(img_left)
img_right = resize_if_needed(img_right)

# Convertir de BGR (OpenCV) a RGB
img_left = cv2.cvtColor(img_left, cv2.COLOR_BGR2RGB)
img_right = cv2.cvtColor(img_right, cv2.COLOR_BGR2RGB)

# Separar canales
R_left, G_left, B_left = cv2.split(img_left)
R_right, G_right, B_right = cv2.split(img_right)

# --- Supresión de componentes ---
# Imagen izquierda: eliminar ROJO
R_left[:] = 0

# Imagen derecha: eliminar VERDE y AZUL (amarillo y azul)
G_right[:] = 0
B_right[:] = 0

# Reconstruir imágenes filtradas
left_filtered = cv2.merge((R_left, G_left, B_left))
right_filtered = cv2.merge((R_right, G_right, B_right))

# Combinar ambas imágenes (suma saturada)
anaglyph = cv2.add(left_filtered, right_filtered)

# Guardar resultado
anaglyph_bgr = cv2.cvtColor(anaglyph, cv2.COLOR_RGB2BGR)
cv2.imwrite("anaglifo_3d.png", anaglyph_bgr)

# Mostrar resultado
cv2.imshow("Anaglifo 3D", anaglyph_bgr)
cv2.waitKey(0)
cv2.destroyAllWindows()
