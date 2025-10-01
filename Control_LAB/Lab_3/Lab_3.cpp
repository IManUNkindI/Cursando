#include <stm32f767xx.h>
#include <stdio.h>

int PULSOS_POR_REV = 400;  // con cuadratura (4 * 50)
int TS_MS = 20;    // periodo de muestreo en ms
float RPM = 0.0;     // variable global con la velocidad en RPM
int cnt = 0;
int reset = 0;
int max_rpm = 1500;
int pot;
int arr = 1000;

int16_t pulse = 0;
/* KY-040 a x4: ~80 cuentas/vuelta */
#define KY040_CPR_X4         60.0f
float ang = 0;

/// ======================= SysTick ======================= ///
void SysTick_Init(void) {                // Inicializaci n
	SysTick->LOAD = 0xFFFFFF;
  SysTick->CTRL = 0x0000005;
}
void SysTick_Wait(uint32_t n) {           // Ciclo
  SysTick->LOAD = n - 1;
  SysTick->VAL = 0;
  while ((SysTick->CTRL & 0x00010000) == 0);
}
void SysTick_Wait1ms(uint32_t delay) {    // ms
  for (uint32_t i = 0; i < delay; i++) {
      SysTick_Wait(16000);
  }
}
/* ======================= PWM: CH1 (timers 1-canal) ======================= */
void Config_TimerPWM(TIM_TypeDef *TIMx) {
	TIMx->ARR = arr - 1;       // 20 ms periodo (50 Hz)
	TIMx->PSC = 16 - 1;          // 1 MHz clock (1 us por unidad)
  TIMx->EGR = 0x1;             // Update Event para aplicar cambios
  TIMx->CCMR1 = 0x6060;        // CH1 y CH2: PWM1
  TIMx->CCMR2 = 0x6060;        // CH3 y CH4: PWM1
  TIMx->CCER = 0x1111;         // Habilita CH1-CH4 salida activa alta
  TIMx->CR1 = 0x1;             // Habilita el contador
}
static void Config_GPIO(void) {
	/* ---------- Encoder (T8_1/2: PC6, PC7 (AF3) ) ---------- */
	/* Relojes de TIM */
  /* APB2: TIM8
		 APB1: TIM3*/
	/* ---------- ADC (PA4) ---------- */
	RCC->APB2ENR |= (0x1 << 8);
	RCC->APB1ENR |= RCC_APB1ENR_TIM3EN | RCC_APB1ENR_TIM4EN;
  RCC->APB2ENR |= RCC_APB2ENR_TIM8EN | RCC_APB2ENR_TIM9EN;
	
	/* Habilitar relojes GPIO usados (C, A, E, B) */
  RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN | RCC_AHB1ENR_GPIOAEN | RCC_AHB1ENR_GPIOEEN |
									RCC_AHB1ENR_GPIOBEN;

	GPIOB->MODER |= 0xAAA80;
  GPIOB->AFR[0] |= 0x22221000;
	GPIOB->AFR[1] |= 0x33;
	
  GPIOC->MODER |= 0xA000;
  GPIOC->AFR[0] |= 0x33000000;
	
	GPIOE->MODER |= 0x440800;
  GPIOE->AFR[0] |= 0x300000;
	
	  // Configuracion basica del ADC1
	GPIOA->MODER |= 3 << (5*2); // PA5 en modo analogico
	
  ADC1->CR1 = 0;           // Sin SCAN, 12 bits
  ADC1->CR2 = 0;           // Trigger por software, single conversion
  ADC1->SMPR2 |= (0x7 << 12) | (0x7 << 15); // IN4, IN5  (480 ciclos)
  ADC1->SMPR1 |= (0x7 << 0) | (0x7 << 3) | (0x7 << 6); // IN10, IN11, IN12

  ADC1->CR2 |= ADC_CR2_ADON; // Habilitar ADC
}
/// ======================= Lectura ADC puntual ======================= ///
uint16_t ADC_ReadChannel(uint8_t canal) {
		ADC1->SQR1 = 0;           // 1 conversi n
		ADC1->SQR3 = canal;       // Selecciona canal
		ADC1->CR2 |= ADC_CR2_SWSTART; // Inicia conversi n
		while (!(ADC1->SR & ADC_SR_EOC)); // Esperar fin
		return (uint16_t)ADC1->DR; // Leer valor
}
/* ======================= Encoder (modo x4) ======================= */
void Config_TimerEncoder(TIM_TypeDef *TIMx){
    /* Encoder interface on CH1/CH2, x4 */
    TIMx->CR1  = 0;
    TIMx->SMCR = 0;

    /* CC1S=01 (TI1), CC2S=01 (TI2), filtros b sicos (IC1F/IC2F=0011) */
    TIMx->CCMR1 = 0;
    TIMx->CCMR1 |= (1U<<0) | (1U<<8);           /* CC1S/CC2S */
    TIMx->CCMR1 |= (3U<<4) | (3U<<12);          /* filtros */

    TIMx->CCER  = 0;                            /* polaridad normal */
    TIMx->ARR   = 0xFFFF;
    TIMx->CNT   = 0;

    /* SMS=011 -> Encoder mode 3 (contador con TI1 y TI2) */
    TIMx->SMCR |= (3U<<0);

    TIMx->CR1  |= TIM_CR1_CEN;
}
/* ===================== CONFIGURACION TIMER DE 10ms ===================== */
void Timer3_Init(void) {
		// Reloj a 16 MHz
    TIM3->PSC = 16000-1;     // 
    TIM3->ARR = TS_MS-1;       // ms
    TIM3->DIER |= TIM_DIER_UIE;
    TIM3->CR1 |= TIM_CR1_CEN;

    NVIC_EnableIRQ(TIM3_IRQn);
}
/* ===================== CONFIGURACION DEL DAC ===================== */
void DAC_Init(void) {
    // Habilitar reloj del DAC
    RCC->APB1ENR |= RCC_APB1ENR_DACEN;

    // Configurar PA4 como anal gico
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
    GPIOA->MODER |= (3U << (4*2));  // PA4 en modo anal gico

    // Configurar DAC channel 1
    DAC->CR |= DAC_CR_EN1;     // habilitar canal 1
}

/* ===================== ACTUALIZAR SALIDA DAC ===================== */
void DAC_SetOutput(float rpm) {
    if (rpm < 0) rpm = 0;
    if (rpm > max_rpm) rpm = max_rpm;  // saturar
	
    // Escalar a 12 bits
    float dac_val = ((rpm / max_rpm) * 4096);

    DAC->DHR12R1 = dac_val;   // escribir en canal 1
}
static inline float wrap360(float a){
    while (a >= 360.0f) a -= 360.0f;
    while (a <    0.0f) a += 360.0f;
    return a;
}
int main(void) {
	Config_GPIO();
	SysTick_Init();
	DAC_Init();
	Config_TimerEncoder(TIM8);
	Config_TimerEncoder(TIM4);
	Timer3_Init();
	Config_TimerPWM(TIM9);
	
    while (1) {
			cnt = TIM8->CNT;
			pulse = (int16_t)TIM4->CNT;
			pot = ADC_ReadChannel(5);   // PA5
			ang = wrap360(((pulse / KY040_CPR_X4) * 360.0f) + 180.0f);
			int ccr = (ang * arr) / 360.0f;
			TIM9->CCR1 = ccr;
    }
}
extern "C"{
	void TIM3_IRQHandler(void) {
		TIM3->SR &= ~TIM_SR_UIF;

    int delta = TIM8->CNT;   // pulsos en este periodo
    TIM8->CNT = 0;           // reset contador

    float revs = (float)delta / PULSOS_POR_REV;
    RPM = revs * (60000.0f / TS_MS);
		
		DAC_SetOutput(RPM);
	}
}