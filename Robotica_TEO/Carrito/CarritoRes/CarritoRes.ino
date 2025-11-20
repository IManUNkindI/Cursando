#include <Arduino.h>

// ========================= CONFIGURACIÓN DE PINES ==============================
#define IN1 19
#define IN2 18
#define IN3 5
#define IN4 17
#define ENA 23     // PWM izquierdo
#define ENB 22     // PWM derecho

// ========================= PARÁMETROS DEL MOTOR ===============================
const float Max_RPMD = 2900.0;
const float Max_RPMI = 3040.0;
unsigned long tiempoInicioMotores = 0;

const float r_llantas = 0.041;  // Radio de llanta (m)
float Vlineal_C = 12;         // Velocidad lineal deseada (m/s)

float RPM = 0.0;
int VD = 0;
int VI = 0;

// ========================= CONFIGURACIÓN PWM (LEDC ESP32) ======================
const int PWM_FREQ = 10000;
const int PWM_RESOLUTION = 12;
const int PWM_MAX = (1 << PWM_RESOLUTION) - 1;

const int CH_A = 0;
const int CH_B = 1;

// ---------- Pin IR ----------
#define IR_ANALOG_PIN 36   // VP en ESP32
const int UMBRAL_IR = 1500;
int valorAnteriorIR = 4095;
bool motoresEncendidos = false;
unsigned long tiempoUltimoCambioIR = 0;
const unsigned long TIEMPO_REBOTE_IR = 500;

// ========================= PROTOTIPOS ==========================================
void avanzar(int vd, int vi);
void detenerMotores();

// ============================= SETUP ============================================
void setup() {
  Serial.begin(115200);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  ledcSetup(CH_A, PWM_FREQ, PWM_RESOLUTION);
  ledcSetup(CH_B, PWM_FREQ, PWM_RESOLUTION);

  ledcAttachPin(ENA, CH_A);
  ledcAttachPin(ENB, CH_B);

  Serial.println("Sistema inicializado con PWM LEDC (ESP32).");
}

// ============================== LOOP ============================================
void loop() {
  int valorIR = analogRead(IR_ANALOG_PIN);
  unsigned long tiempoActual = millis();

  // Detección de cambio con rebote
  if (valorIR < UMBRAL_IR && valorAnteriorIR >= UMBRAL_IR &&
      (tiempoActual - tiempoUltimoCambioIR) > TIEMPO_REBOTE_IR) {
    motoresEncendidos = !motoresEncendidos;
    tiempoUltimoCambioIR = tiempoActual;

    if (motoresEncendidos) {
      tiempoInicioMotores = tiempoActual;  // Guardar tiempo de arranque
    }

    Serial.print("Motores ");
    Serial.println(motoresEncendidos ? "ENCENDIDOS" : "APAGADOS");
  }

  valorAnteriorIR = valorIR;

  // Apagado automático después de 6 segundos
  if (motoresEncendidos && (tiempoActual - tiempoInicioMotores >= 5000)) {
    motoresEncendidos = false;
    detenerMotores();
    Serial.println("Motores apagados automáticamente tras 6 segundos.");
  }

  if (motoresEncendidos) {
    RPM = (Vlineal_C / (2 * 3.1415 * r_llantas)) * 60.0;
    VD = (int)(PWM_MAX * (RPM / Max_RPMD));
    VI = (int)(PWM_MAX * (RPM / Max_RPMI));

    VD = constrain(VD, 0, PWM_MAX);
    VI = constrain(VI, 0, PWM_MAX);

    Serial.print("PWM Derecho = ");
    Serial.print(VD);
    Serial.print(" | PWM Izquierdo = ");
    Serial.println(VI);

    avanzar(VD, VI);
  } else {
    detenerMotores();
  }

  //delay(100);
}

// ========================== FUNCIÓN DE AVANCE ==================================
void avanzar(int vd, int vi) {
  ledcWrite(CH_A, vi);
  ledcWrite(CH_B, vd);

  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

// ========================== FUNCIÓN DE DETENER =================================
void detenerMotores() {
  ledcWrite(CH_A, 0);
  ledcWrite(CH_B, 0);

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}