#include <Arduino.h>

// ---------- Pines puente H ----------
#define IN1 19
#define IN2 18
#define IN3 5
#define IN4 17
#define ENA 23
#define ENB 22

// ---------- Variables motor ----------
const float Max_RPMD = 3150.0;
const float Max_RPMI = 2850.0;

const float r_llantas = 0.041;   // Radio en metros
float Vlineal_C = 12;          // Velocidad lineal en m/s

float RPM = 0.0;
int VD = 0;
int VI = 0;

// ---------- Prototipos ----------
void avanzar(int vd, int vi);

void setup() {
  Serial.begin(9600);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
}

void loop() {

  // --- Conversión de velocidad lineal a RPM ---
  // RPM = (V / (2πr)) * 60
  RPM = (Vlineal_C / (2 * 3.1415 * r_llantas)) * 60.0;

  // --- Conversión de RPM a PWM ---
  VD = (int)(255.0 * (RPM / Max_RPMD));
  VI = (int)(255.0 * (RPM / Max_RPMI));

  // --- Saturación (por seguridad) ---
  VD = constrain(VD, 0, 255);
  VI = constrain(VI, 0, 255);

  Serial.print("PWM Derecho = ");
  Serial.print(VD);
  Serial.print(" | PWM Izquierdo = ");
  Serial.println(VI);

  avanzar(VD, VI);
  delay(100);
}


// ---------- Función de avance ----------
void avanzar(int vd, int vi) {
  analogWrite(ENA, vi);
  analogWrite(ENB, vd);

  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);

  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}