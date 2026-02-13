import cv2
import numpy as np
import os
import tkinter as tk

"""
Generación de anaglifo 3D método Dubois
con ajuste automático al tamaño de pantalla
"""

# ==============================
# 1. Obtener resolución de pantalla
# ==============================

root = tk.Tk()
screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()
root.destroy()

# Margen de seguridad (evita que toque los bordes)
margin = 100

max_width = screen_width - margin
max_height = screen_height - margin

# ==============================
# 2. Cargar imágenes
# ==============================

script_dir = os.path.dirname(os.path.abspath(__file__))

img_left = cv2.imread(os.path.join(script_dir, "Izq.jpg"))
img_right = cv2.imread(os.path.join(script_dir, "Der.jpg"))

if img_left is None or img_right is None:
    raise ValueError("Error cargando imágenes")

# ==============================
# 3. Igualar tamaño entre imágenes
# ==============================

h = min(img_left.shape[0], img_right.shape[0])
w = min(img_left.shape[1], img_right.shape[1])

img_left = cv2.resize(img_left, (w, h), interpolation=cv2.INTER_AREA)
img_right = cv2.resize(img_right, (w, h), interpolation=cv2.INTER_AREA)

# ==============================
# 4. Convertir a RGB float32
# ==============================

img_left = cv2.cvtColor(img_left, cv2.COLOR_BGR2RGB).astype(np.float32)
img_right = cv2.cvtColor(img_right, cv2.COLOR_BGR2RGB).astype(np.float32)

# ==============================
# 5. Matrices Dubois
# ==============================

M_left = np.array([
    [0.456, 0.500, 0.176],
    [-0.040, -0.038, -0.016],
    [-0.015, -0.021, -0.005]
], dtype=np.float32)

M_right = np.array([
    [-0.043, -0.088, -0.002],
    [0.378, 0.734, -0.018],
    [-0.072, -0.113, 1.226]
], dtype=np.float32)

# ==============================
# 6. Aplicar transformación
# ==============================

left_transformed = img_left @ M_left.T
right_transformed = img_right @ M_right.T

anaglyph = left_transformed + right_transformed

anaglyph = np.clip(anaglyph, 0, 255).astype(np.uint8)

anaglyph = cv2.cvtColor(anaglyph, cv2.COLOR_RGB2BGR)

# ==============================
# 7. Redimensionar a pantalla
# ==============================

h, w = anaglyph.shape[:2]

scale_w = max_width / w
scale_h = max_height / h

scale = min(scale_w, scale_h, 1.0)  # nunca agrandar, solo reducir

new_w = int(w * scale)
new_h = int(h * scale)

anaglyph_resized = cv2.resize(anaglyph, (new_w, new_h), interpolation=cv2.INTER_AREA)

# ==============================
# 8. Guardar resultado
# ==============================

output_path = os.path.join(script_dir, "anaglifo_dubois.png")
cv2.imwrite(output_path, anaglyph_resized)

print("Imagen guardada en:", output_path)
print(f"Resolución final: {new_w} x {new_h}")

# ==============================
# 9. Mostrar centrado
# ==============================

cv2.namedWindow("Anaglifo 3D", cv2.WINDOW_AUTOSIZE)
cv2.imshow("Anaglifo 3D", anaglyph_resized)

cv2.waitKey(0)
cv2.destroyAllWindows()
