import os
import json
import re

input_file = r"C:\Cursando\Inteligencia_Artificial\Workspace\Lab\Proyecto\Proyecto IA\Preguntas.txt"
output_dir = os.path.dirname(os.path.abspath(__file__))
output_file = os.path.join(output_dir, "converted_dataset.jsonl")

def clean_reasoning(text):
    # Opcional: limpiar etiquetas <think>
    return text.replace("<think>", "").replace("</think>", "").strip()

# Leer el archivo completo
with open(input_file, "r", encoding="utf-8") as f:
    content = f.read()

# El archivo Preguntas.txt contiene múltiples arreglos JSON concatenados (p. ej., ][ o ] \n [).
# Los combinamos en un único arreglo JSON válido reemplazando las uniones por comas.
content_clean = re.sub(r'\]\s*\[', ',', content)
data = json.loads(content_clean)

converted = []

for item in data:
    # Opción A: Solo la pregunta
    instruction = item["pregunta"]
    
    # Opción B (descomentar si se prefiere combinar paciente + pregunta):
    # instruction = f"Paciente: {item['paciente']}\nPregunta: {item['pregunta']}"
    
    response = item["respuesta"]

    # Formato de Chat (Messages)
    message_entry = {
        "messages": [
            {"role": "user", "content": instruction},
            {"role": "assistant", "content": response}
        ]
    }

    # Si quisieras incluir el razonamiento en el futuro:
    # reasoning = clean_reasoning(item.get("razonamiento", ""))
    # if reasoning:
    #     message_entry["messages"][1]["content"] = f"{reasoning}\n\n{response}"

    converted.append(message_entry)

# Guardar como JSONL
with open(output_file, "w", encoding="utf-8") as f:
    for item in converted:
        f.write(json.dumps(item, ensure_ascii=False) + "\n")

print("Dataset convertido correctamente.")