#include <stm32f767xx.h>
#include <stdio.h>

int PULSOS_POR_REV = 400;  // con cuadratura (4 * 50)
int TS_MS = 20;    // periodo de muestreo en ms
float RPM = 0.0;     // variable global con la velocidad en RPM
int cnt = 0;
int reset = 0;
int max_rpm = 300;

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
static void Config_GPIO(void) {
	/* ---------- Encoder (T8_1/2: PC6, PC7 (AF3) ) ---------- */
	/* Relojes de TIM */
  /* APB2: TIM8
		 APB1: TIM3*/
	
	RCC->APB1ENR |= RCC_APB1ENR_TIM3EN;
  RCC->APB2ENR |= RCC_APB2ENR_TIM8EN;
	
	/* Habilitar relojes GPIO usados (C) */
  RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;

  GPIOC->MODER |= 0xA000;
  GPIOC->AFR[0] |= 0x33000000;
	
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
/* ===================== CONFIGURACIÓN TIMER DE 10ms ===================== */
void Timer3_Init(void) {
		// Reloj a 16 MHz
    TIM3->PSC = 16000-1;     // 
    TIM3->ARR = TS_MS-1;       // ms
    TIM3->DIER |= TIM_DIER_UIE;
    TIM3->CR1 |= TIM_CR1_CEN;

    NVIC_EnableIRQ(TIM3_IRQn);
}
/* ===================== CONFIGURACIÓN DEL DAC ===================== */
void DAC_Init(void) {
    // Habilitar reloj del DAC
    RCC->APB1ENR |= RCC_APB1ENR_DACEN;

    // Configurar PA4 como analógico
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
    GPIOA->MODER |= (3U << (4*2));  // PA4 en modo analógico

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
int main(void) {
	Config_GPIO();
	SysTick_Init();
	DAC_Init();
	Config_TimerEncoder(TIM8);
	Timer3_Init();
	
    while (1) {
			cnt = TIM8->CNT;
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