#include <stm32f767xx.h>
#include <stdio.h>

/// ======================================================
/// ====================== PARÁMETROS ====================
/// ======================================================
#define KY040_CPR_X4     60.0f     // cuenta por vuelta efectivo
#define TS_MS            20        // período de muestreo (ms)
#define PWM_ARR          1000      // resolución PWM

// ====== PID (editable en tiempo real) ======
volatile float Kp = 1.0f;
volatile float Ki = 0.1f;
volatile float Kd = 0.01f;

// señales del PID
volatile float e = 0, e_prev = 0;
volatile float integ = 0;
volatile float deriv = 0;
volatile float u = 0;

// medición
volatile float ang = 0.0f;

/// ======================================================
/// ====================== SysTick ========================
/// ======================================================
void SysTick_Init(void) {
    SysTick->LOAD = 0xFFFFFF;
    SysTick->CTRL = 0x5;
}

void SysTick_Wait(uint32_t n) {
    SysTick->LOAD = n - 1;
    SysTick->VAL = 0;
    while ((SysTick->CTRL & (1<<16)) == 0);
}

void SysTick_Wait1ms(uint32_t delay) {
    for(uint32_t i=0;i<delay;i++){
        SysTick_Wait(16000);
    }
}

/// ======================================================
/// ===================== GPIO + TIMERS ===================
/// ======================================================
static void Config_GPIO(void) {

    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOBEN |
                     RCC_AHB1ENR_GPIOCEN |
                     RCC_AHB1ENR_GPIOAEN;

    // === GPIO TIM9 CH1 (PWM) === ? PE5 ó PB? según tu placa
    // Asumimos PB1 -> AF2 TIM3, pero tú ya tenías PB config
    // Se mantiene tu configuración original:
    GPIOB->MODER |= 0xAAA80;
    GPIOB->AFR[0] |= 0x22221000;
    GPIOB->AFR[1] |= 0x33;

    // === Encoder TIM4 CH1/CH2 en PC6-PC7 AF2 ===
    GPIOC->MODER |= 0xA000;
    GPIOC->AFR[0] |= 0x33000000;
}

void Config_TimerPWM(TIM_TypeDef *TIMx){
    TIMx->ARR = PWM_ARR - 1;
    TIMx->PSC = 16 - 1;      // 1 MHz
    TIMx->EGR = 1;

    TIMx->CCMR1 = 0x6060;   // CH1 y CH2 PWM1
    TIMx->CCMR2 = 0x6060;   // CH3 y CH4 PWM1
    TIMx->CCER  = 0x1111;   // activación de salidas
    TIMx->CR1 = 1;          // enable
}

void Config_TimerEncoder(TIM_TypeDef *TIMx){
    TIMx->CR1  = 0;
    TIMx->SMCR = 0;

    TIMx->CCMR1 = 0;
    TIMx->CCMR1 |= (1<<0) | (1<<8);     // CC1S=01 CC2S=01
    TIMx->CCMR1 |= (3<<4) | (3<<12);    // filtros

    TIMx->CCER = 0;       // polaridad normal
    TIMx->ARR = 0xFFFF;
    TIMx->CNT = 0;

    TIMx->SMCR |= (3<<0); // Modo encoder 3

    TIMx->CR1 |= TIM_CR1_CEN;
}

/// ======================================================
/// ===================== TIMER DE CONTROL ================
/// ======================================================
void Timer3_Init(void){
    RCC->APB1ENR |= RCC_APB1ENR_TIM3EN;

    TIM3->PSC = 16000-1;      // tick cada 1 ms
    TIM3->ARR = TS_MS-1;      // periodo de muestreo
    TIM3->DIER |= TIM_DIER_UIE;
    TIM3->CR1  |= TIM_CR1_CEN;

    NVIC_EnableIRQ(TIM3_IRQn);
}

/// ======================================================
/// ====================== WRAP ANGLE =====================
/// ======================================================
static inline float wrap180(float a){
    while(a > 180.0f) a -= 360.0f;
    while(a < -180.0f) a += 360.0f;
    return a;
}

/// ======================================================
/// ====================== MAIN ===========================
/// ======================================================
int main(void){
    SysTick_Init();
    Config_GPIO();

    // Timers
    RCC->APB2ENR |= RCC_APB2ENR_TIM9EN | RCC_APB2ENR_TIM8EN;
    RCC->APB1ENR |= RCC_APB1ENR_TIM4EN;

    Config_TimerPWM(TIM9);
    Config_TimerEncoder(TIM4);
    Timer3_Init();

    while(1){
        // el control NO VA aquí
        // todo se hace en TIM3_IRQHandler
    }
}

/// ======================================================
/// ====================== PID (ISR) ======================
/// ======================================================
extern "C"{
void TIM3_IRQHandler(void){
    TIM3->SR &= ~TIM_SR_UIF;

    /// ========= 1. Medición del ángulo =========
    int16_t pulse = (int16_t)TIM4->CNT;
    float ang_raw = (pulse / KY040_CPR_X4) * 360.0f;
    ang = wrap180(ang_raw);

    /// ========= 2. PID DISCRETO =========
    float Ts = TS_MS / 1000.0f;

    e = -ang;        // referencia = 0 grados

    integ += e * Ts;
    deriv = (e - e_prev) / Ts;
    e_prev = e;

    u = Kp*e + Ki*integ + Kd*deriv;

    /// ========= 3. Saturación =========
    if (u > PWM_ARR) u = PWM_ARR;
    if (u < 0)       u = 0;

    /// ========= 4. Aplicación al PWM =========
    TIM9->CCR1 = (uint32_t)u;
}
}
