import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
from tensorflow.keras.preprocessing import image
import numpy as np
import sys
import os

def classify_image(img_path):
    if not os.path.exists(img_path):
        print(f"Error: El archivo {img_path} no existe.")
        return

    # Cargar el modelo MobileNetV2 pre-entrenado
    print("Cargando modelo...")
    model = MobileNetV2(weights='imagenet')

    # Cargar y pre-procesar la imagen
    # MobileNetV2 espera imágenes de 224x224
    img = image.load_img(img_path, target_size=(224, 224))
    x = image.img_to_array(img)
    x = np.expand_dims(x, axis=0) # Agregar dimensión de batch
    x = preprocess_input(x)

    # Realizar predicción
    print("Analizando imagen...")
    preds = model.predict(x)
    
    # Decodificar predicciones para mostrar qué cree el modelo que es (Top 3)
    decoded_preds = decode_predictions(preds, top=3)[0]
    print("\nTop 3 predicciones generales:")
    for i, (id, label, prob) in enumerate(decoded_preds):
        print(f"{i+1}. {label}: {prob*100:.2f}%")

    # Lógica específica para Gato vs Perro usando índices de ImageNet
    # Dogs: 151-268
    # Cats: 281-285 (Gatos domésticos)
    # Nota: Estos índices son estándar para ImageNet 1k classes
    
    predictions_vec = preds[0]
    
    dog_prob = np.sum(predictions_vec[151:269]) # Indices 151 a 268 (slice es exclusivo al final)
    cat_prob = np.sum(predictions_vec[281:286]) # Indices 281 a 285
    
    print("\n--- Resultado Gato vs Perro ---")
    print(f"Probabilidad de Perro: {dog_prob*100:.2f}%")
    print(f"Probabilidad de Gato:  {cat_prob*100:.2f}%")
    
    threshold = 0.25 # Umbral de confianza
    
    if dog_prob > cat_prob and dog_prob > threshold:
        print(">> ES UN PERRO 🐶")
    elif cat_prob > dog_prob and cat_prob > threshold:
        print(">> ES UN GATO 🐱")
    else:
        print(">> No estoy seguro si es un perro o un gato (o es otra cosa).")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python classifier.py <ruta_de_la_imagen>")
    else:
        classify_image(sys.argv[1])
