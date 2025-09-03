#include <stm32f767xx.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

/*------------------------------------------------------------
   USART2:
     - PD8 -> TX (AF7)
     - PD9 -> RX (AF7)
   PWM (servos):
     - Servo1: TIM9_CH1  -> PE5 (AF3)
     - Servo2: TIM10_CH1 -> PB8 (AF3)
     - Servo3: TIM11_CH1 -> PB9 (AF3)
     - Servo4: TIM13_CH1 -> PF8 (AF9)
     - Servo5: TIM14_CH1 -> PF9 (AF9)
   Encoders (cuadratura x4):
     - Enc1 (TIM1):  CH1->PA8 (AF1),  CH2->PA9 (AF1)
     - Enc2 (TIM2):  CH1->PA15 (AF1),  CH2->PB3 (AF1)
     - Enc3 (TIM3):  CH1->PB4 (AF2),  CH2->PB5 (AF2)
     - Enc4 (TIM4):  CH1->PB6 (AF2),  CH2->PB7 (AF2)
     - Enc5 (TIM8):  CH1->PC6 (AF3),  CH2->PC7 (AF3)
   ============================================================ */

uint32_t BAUDRATE;

int target1 = 0;
int target2 = 0;
int target3 = 0;
int target4 = 0;
int target5 = 0;

int16_t cnt1 = 0;
int16_t cnt2 = 0;
int16_t cnt3 = 0;
int16_t cnt4 = 0;
int16_t cnt5 = 0;

/* ======================= Parámetros de control ======================= */
#define ANG_TOLERANCIA_DEG   1.0f
#define VMAX_DEGPS           45.0f
#define CONTROL_DT_MS        10
#define SERVO_MIN_US         600
#define SERVO_MAX_US         2500
#define SERVO_PERIOD_US      20000

/* ======================= Escalas de encoders ======================= */
/* KY-040 a x4: ~80 cuentas/vuelta */
#define KY040_CPR_X4         80.0f
/* Encoder 50 PPR a x4: 200 cuentas/vuelta (para el 5to encoder si es 50 PPR) */
#define ENC50_CPR            200.0f

/* ======================= Variables globales ======================= */
volatile uint32_t ms_tick = 0;

float ref1=0, ref2=0, ref3=0, ref4=0, ref5=0;
float cmd1=0,  cmd2=0,  cmd3=0,  cmd4=0,  cmd5=0;
float ang1=0,  ang2=0,  ang3=0,  ang4=0,  ang5=0;
int   sec_home = 0, sec_on = 0;
int txi = 0;
char tx[32];
/// ======================= SysTick ======================= ///
void SysTick_Init(void) {                // Inicialización
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
static inline float wrap360(float a){
    while (a >= 360.0f) a -= 360.0f;
    while (a <    0.0f) a += 360.0f;
    return a;
}
/* ======================= GPIO (PWM + Encoders + USART) ======================= */
static void Config_GPIO(void) {
	/* ---------- PWM ( PE5 (T9-1, AF3), PB8(T10-1, AF3), PB9(T11-1, AF3), PF8(T13-1, AF9), PF9(T14-1, AF9) ) ---------- */
  /* ---------- Encoders (T1_1/2: PA8, PA9 (AF1), T2_1/2: PA15, PB3 (AF1), T3_1/2: PPB4, PB5 (AF2)) ---------- */
	/* ---------- Encoders (T4_1/2: PB6, PB7 (AF2), T8_1/2: PC6, PC7 (AF3) ) ---------- */

	/* Relojes de TIM */
  /* APB2: TIM1, TIM8; APB1: TIM2, TIM3, TIM4, PWM: TIM9/10/11 (APB2), TIM13/14 (APB1) y USART3 */
  RCC->APB1ENR |= RCC_APB1ENR_TIM2EN | RCC_APB1ENR_TIM3EN | RCC_APB1ENR_TIM4EN | RCC_APB1ENR_TIM13EN | RCC_APB1ENR_TIM14EN
								| RCC_APB1ENR_USART3EN;
	
  RCC->APB2ENR |= RCC_APB2ENR_TIM1EN | RCC_APB2ENR_TIM8EN | RCC_APB2ENR_TIM9EN | RCC_APB2ENR_TIM10EN | RCC_APB2ENR_TIM11EN;
	
	/* Habilitar relojes GPIO usados ( A, B, C , D, E, F, H) */
  RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN | RCC_AHB1ENR_GPIOBEN | RCC_AHB1ENR_GPIOCEN 
							  | RCC_AHB1ENR_GPIODEN | RCC_AHB1ENR_GPIOEEN | RCC_AHB1ENR_GPIOFEN ;
	
	GPIOA->MODER |= 0x800A000;
  GPIOA->AFR[1] |= 0x10000011;

  GPIOB->MODER |= 0xAAA80;
  GPIOB->AFR[0] |= 0x22221000;
	GPIOB->AFR[1] |= 0x33;

  GPIOC->MODER |= 0xA000;
  GPIOC->AFR[0] |= 0x33000000;
	
	RCC->APB1ENR |= (0x1<<18);		// USART3 Encendido
	
	GPIOD->MODER |= 0xA0000;			// Alternante PD8 y PD9
	GPIOD->AFR[1] |= 0x77;				// AF7 PD8 y PD9

  GPIOE->MODER |= 0x440800;
  GPIOE->AFR[0] |= 0x300000;

  GPIOF->MODER |= 0xA0000;
  GPIOF->AFR[1] |= 0x99;
	
}

/* ======================= PWM: CH1 (timers 1-canal) ======================= */
void Config_TimerPWM(TIM_TypeDef *TIMx) {
	TIMx->ARR = 20000 - 1;       // 20 ms periodo (50 Hz)
	TIMx->PSC = 16 - 1;          // 1 MHz clock (1 us por unidad)
  TIMx->EGR = 0x1;             // Update Event para aplicar cambios
  TIMx->CCMR1 = 0x6060;        // CH1 y CH2: PWM1
  TIMx->CCMR2 = 0x6060;        // CH3 y CH4: PWM1
  TIMx->CCER = 0x1111;         // Habilita CH1-CH4 salida activa alta
  TIMx->CR1 = 0x1;             // Habilita el contador
}

/* ============== Servo Control ============== */
void Servo_SetAngle(TIM_TypeDef *TIMx, uint8_t canal, uint8_t angulo) {
	if (angulo > 180) angulo = 180;
		uint16_t pulse = 600 + ((uint32_t)angulo * 1900) / 180;
	
		switch (canal) {
      case 1: TIMx->CCR1 = pulse; break;
      case 2: TIMx->CCR2 = pulse; break;
      case 3: TIMx->CCR3 = pulse; break;
      case 4: TIMx->CCR4 = pulse; break;
		}
}

/* ======================= Encoders (modo x4) ======================= */
void Config_TimerEncoder(TIM_TypeDef *TIMx){
    /* Encoder interface on CH1/CH2, x4 */
    TIMx->CR1  = 0;
    TIMx->SMCR = 0;

    /* CC1S=01 (TI1), CC2S=01 (TI2), filtros básicos (IC1F/IC2F=0011) */
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
/* ================ USART3: PD8(TX), PD9(RX) AF7 ================= */
void USART3_Init(uint32_t baud) {
	BAUDRATE = (16000000/baud)+1;
	USART3->BRR |= BAUDRATE;
	USART3->CR1 |= 0xD;				 		// Transmision, recepcion, stop mode, enable USART
	USART3->CR1 |= (0x1<<5);	 		// Interrupcion (recepcion)
	USART3->CR1 &= ~(0x1<<15);		// Over8 = 0
		
	NVIC_SetPriority(USART3_IRQn,2);
	NVIC_EnableIRQ(USART3_IRQn);
}
int USART3_SendChar(int value) { 	//Enviar Caracter
  USART3->TDR = value;
  while(!(USART3->ISR & USART_ISR_TXE));
  return 0;
}
void USART3_SendChain(char str[32]){	//Enviar Cadena
	strncpy(tx,str,30);
	txi = 0;
	for(;txi<strlen(tx);){
		USART3_SendChar(tx[txi++]);
	}
}
void USART3_SendString(const char *s) {
    while(*s) USART3_SendChar(*s++);
}
void USART3_SendFloat(float f) {
    char buffer[32];
    sprintf(buffer, "%.2f", f);
    USART3_SendString(buffer);
}
/* ======================= Main ======================= */
int main(void){
	sec_home = 0;
	
	Config_GPIO();
  SysTick_Init();
  USART3_Init(57600);
	
  /* PWM: configurar solo CH1 en cada timer de servo */
  Config_TimerPWM(TIM9);
  Config_TimerPWM(TIM10);
  Config_TimerPWM(TIM11);
  Config_TimerPWM(TIM13);
  Config_TimerPWM(TIM14);

  /* Encoders (x4) */
  Config_TimerEncoder(TIM1);
  Config_TimerEncoder(TIM2);
  Config_TimerEncoder(TIM3);
  Config_TimerEncoder(TIM4);
  Config_TimerEncoder(TIM8);

  /* Inicializa comandos en 0° */
  cmd1=0; cmd2=0; cmd3=0; cmd4=0; cmd5=0;
	
	while(1){
	//==================== Secuencia ===================//
		while(sec_home == 0){
			// Asignar angulo objetivo:
			target1 = 0;		//0 - 360
			target2 = 30;		//0 - 180
			target3 = 0;		//0 -180
			target4 = 8;		//8 - 172
			target5 = 180;	//140 - 180		
			
			Servo_SetAngle(TIM9, 1, target1); // Servo 1
			Servo_SetAngle(TIM10, 1, target2);	// Servo 2
			Servo_SetAngle(TIM11, 1, target3);	// Servo 3
			Servo_SetAngle(TIM13, 1, target4);	// Servo 4
			Servo_SetAngle(TIM14, 1, target5);	// Servo 5
			sec_home = 1;

			SysTick_Wait1ms(1500); // Pequeño retardo para estabilidad
			
		}	
		cnt1 = (int16_t)TIM2->CNT;
		cnt2 = (int16_t)TIM1->CNT;
		cnt3 = (int16_t)TIM3->CNT;
		cnt4 = (int16_t)TIM4->CNT;
		cnt5 = (int16_t)TIM8->CNT;
		
		// Asignar angulo objetivo:
		target1 = 0;		//0 - 360
		target2 = 90;		//0 - 180
		target3 = 80;		//0 -180
		target4 = 90;		//8 - 172
		target5 = 90;	//140 - 180		
		
		Servo_SetAngle(TIM9, 1, target1); // Servo 1
		Servo_SetAngle(TIM10, 1, target2);	// Servo 2
		Servo_SetAngle(TIM11, 1, target3);	// Servo 3
		Servo_SetAngle(TIM13, 1, target4);	// Servo 4
		Servo_SetAngle(TIM14, 1, target5);	// Servo 5
		
		USART3_SendFloat(target1);
		USART3_SendChar('x');
		USART3_SendFloat(target2);
		USART3_SendChar('x');
		USART3_SendFloat(target3);
		USART3_SendChar('x');
		USART3_SendFloat(target4);
		USART3_SendChar('x');
		USART3_SendFloat(target5);
		USART3_SendChar('\n');
		
				/* Conversión a ángulos */
		ang1 = wrap360((cnt1 / ENC50_CPR) * 360.0f);
		ang2 = wrap360((cnt2 / KY040_CPR_X4) * 360.0f);
		ang3 = wrap360((cnt3 / KY040_CPR_X4) * 360.0f);
		ang4 = wrap360((cnt4 / KY040_CPR_X4) * 360.0f);
    ang5 = wrap360((cnt5 / KY040_CPR_X4)  * 360.0f);
		
	}
}
extern "C"{
	void USART3_IRQHandler(void){
			if(USART3->CR1 == 0x2D){
				while (USART3->ISR & USART_ISR_RXNE){
					USART3->RDR & 0xFF;
				}
			}
	}
}