import os
import json

input_file = r"C:\Cursando\Inteligencia_Artificial\Workspace\Lab\Fine_Tuning\Cognitive-Neuroscience.json"
output_dir = os.path.dirname(os.path.abspath(__file__))
output_file = os.path.join(output_dir, "converted_dataset.jsonl")

def clean_reasoning(text):
    # Opcional: limpiar etiquetas <think>
    return text.replace("<think>", "").replace("</think>", "").strip()

with open(input_file, "r", encoding="utf-8") as f:
    data = json.load(f)

converted = []

for item in data:
    instruction = item["pregunta"]
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