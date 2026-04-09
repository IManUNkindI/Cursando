import numpy as np
import matplotlib.pyplot as plt
from sklearn import datasets, svm, metrics
from sklearn.model_selection import train_test_split
import cv2
import os

def train_classifier():
    """
    Trains a Support Vector Machine (SVM) classifier on the Digits dataset.
    """
    print("Cargando el dataset 'Digits' de Scikit-learn...")
    digits = datasets.load_digits()

    # Flatten the images (8x8 images to 1D arrays of 64 features)
    n_samples = len(digits.images)
    data = digits.images.reshape((n_samples, -1))

    # Split data: 70% train, 30% test
    X_train, X_test, y_train, y_test = train_test_split(
        data, digits.target, test_size=0.3, shuffle=False
    )

    # Create a classifier: a support vector classifier
    print("Entrenando el modelo SVM (Kernel RBF)...")
    clf = svm.SVC(gamma=0.001)

    # Learn the digits on the train subset
    clf.fit(X_train, y_train)

    # Predict the value of the digit on the test subset
    predicted = clf.predict(X_test)

    # Metrics
    print(f"Precisión del modelo: {metrics.accuracy_score(y_test, predicted):.4f}")
    print("\nReporte de Clasificación:\n", metrics.classification_report(y_test, predicted))

    # Visualizing some predictions
    _, axes = plt.subplots(nrows=1, ncols=4, figsize=(10, 3))
    for ax, image, prediction in zip(axes, X_test, predicted):
        ax.set_axis_off()
        image = image.reshape(8, 8)
        ax.imshow(image, cmap=plt.cm.gray_r, interpolation="nearest")
        ax.set_title(f"Pred: {prediction}")
    
    plt.tight_layout()
    plt.savefig("predictions_preview.png")
    print("Vista previa de predicciones guardada como 'predictions_preview.png'")
    
    return clf, digits

def predict_custom_image(clf, image_path):
    """
    Loads a custom image from path, pre-processes it, and predicts its class.
    Note: For the Digits dataset, target image should be 8x8 pixels and grayscale.
    """
    if not os.path.exists(image_path):
        print(f"Error: No se encontró la imagen en {image_path}")
        return

    # Load image in grayscale
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        print("Error al cargar la imagen.")
        return

    # Resize to 8x8 (matching Digits dataset)
    img_resized = cv2.resize(img, (8, 8), interpolation=cv2.INTER_AREA)
    
    # Invert colors if necessary (Digits dataset uses numbers in black on white [0-16 scale])
    # Scikit-learn digits are 0 (white) to 16 (black). Standard images 0 (black) to 255 (white).
    # We normalize to 0-16 scale
    img_normalized = 16 - (img_resized / 255.0 * 16)
    
    # Flatten
    img_flattened = img_normalized.reshape(1, -1)
    
    # Predict
    prediction = clf.predict(img_flattened)
    print(f"Resultado de la predicción para '{image_path}': Clase {prediction[0]}")
    return prediction[0], img_normalized

if __name__ == "__main__":
    clf, digits_data = train_classifier()
    
    # Example instructions for custom images
    print("\n--- Cómo usar con tus propias imágenes ---")
    print("1. Guarda una imagen de un dígito (p.ej. 'test_digit.jpg')")
    print("2. Asegúrate de que el fondo sea claro y el número oscuro.")
    print("3. Llama a: predict_custom_image(clf, 'ruta/de/la/imagen.jpg')")
    
    # plt.show() # Uncomment to see the plot window if running interactively
