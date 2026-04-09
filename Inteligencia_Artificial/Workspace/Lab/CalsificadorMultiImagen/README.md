# Clasificador de Imágenes Multiclase en Python

Este proyecto implementa un clasificador de imágenes multiclase utilizando una **Máquina de Vectores de Soporte (SVM)** con un kernel RBF (Radial Basis Function). Es una solución robusta y eficiente para clasificación de imágenes pequeñas en CPU.

## ¿Cómo funciona?

### 1. El Dataset: Digits
Utilizamos el dataset `digits` de la librería `scikit-learn`. Este dataset contiene imágenes de 8x8 píxeles de dígitos manuscritos del 0 al 9.
- **Entrada:** Imágenes de 8x8 (64 píxeles).
- **Salida:** Una de las 10 posibles clases (0-9).

### 2. Preprocesamiento de Datos
Para que un algoritmo de Machine Learning tradicional (como SVM) pueda procesar imágenes, estas deben convertirse en un formato que el modelo entienda:
- **Aplanamiento (Flattening):** Convertimos la matriz de 8x8 píxeles en un vector unidimensional de 64 valores. Cada valor representa la intensidad de un píxel.
- **Normalización:** Las intensidades de píxeles se ajustan a un rango específico para mejorar la velocidad y precisión del entrenamiento.

### 3. El Modelo: SVM (Support Vector Machine)
La clasificación multiclase se logra mediante una técnica llamada **"One-vs-Rest" (Uno contra el Resto)** o **"One-vs-One"**. 

#### Teoría del Modelo:
- **SVM:** Intenta encontrar el hiperplano que mejor separa las clases en un espacio de características. 
- **Kernel RBF:** Permite que el modelo maneje fronteras de decisión no lineales, proyectando los datos a una dimensión superior donde sí sean separables.
- **Función de Decisión:** El modelo asigna a la imagen la clase con la mayor puntuación de confianza.

### 4. Evaluación
El modelo se evalúa dividiendo el dataset en dos partes:
- **Entrenamiento (70%):** Para ajustar los parámetros del modelo.
- **Prueba (30%):** Para verificar qué tan bien generaliza el modelo con datos que nunca ha visto.

Se genera un **Reporte de Clasificación** que incluye:
- **Precision:** Qué tan exacto es el modelo al predecir una clase.
- **Recall:** Qué tanto de la clase real pudo capturar el modelo.
- **F1-Score:** El balance entre Precision y Recall.

## Requisitos
- Python 3.x
- NumPy
- Matplotlib
- Scikit-learn
- OpenCV (opcional para predecir imágenes externas)

Instalación:
```bash
pip install numpy matplotlib scikit-learn opencv-python
```

## Ejecución

### 1. Versión de Consola (Entrenamiento y Prueba)
Ejecuta el script principal para entrenar el modelo y ver métricas:
```bash
python main.py
```

### 2. Versión con Interfaz Gráfica (GUI)
Para una experiencia interactiva donde puedas cargar tus propias imágenes:
```bash
python gui.py
```
- Haz clic en **"Cargar Imagen"**.
- Selecciona un archivo de imagen (`.jpg`, `.png`).
- El modelo procesará la imagen y mostrará el dígito identificado en pantalla.

Al terminar, se generará un archivo `predictions_preview.png` con ejemplos de las predicciones realizadas por el modelo.
