#include <stm32f767xx.h>
#include "SisTick.h"
#include "LCD_Comm_Write.h"
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
   ADC (potenciometros):
     - Adc1 (ADC1):  PA4
     - Adc2 (ADC1):  PA5
     - Adc3 (ADC1):  PC0
     - Adc4 (ADC1):  PC1
     - Adc5 (ADC1):  PC2
   ============================================================ */

uint32_t BAUDRATE;

float target1 = 0;
float target2 = 0;
float target3 = 0;
float target4 = 0;
float target5 = 0;

int pot1 = 0;
int pot2 = 0;
int pot3 = 0;
int pot4 = 0;
int pot5 = 0;

int bandera = 0;
/* ======================= Comandos LCD ======================= */
char clean = 0x01;                // 0b00000001 Limpieza LCD
char home = 0x02;                 // 0b00000010 Modo home LCD
char set = 0x38;    	            // 0b00111100 Define: BUS as 8 bits, LCD 2 lines, Caracter 5x8
char LCD_ON = 0x0C;               // 0b00001100 Display ON, cursor OFF, Blink OFF
char LCD_Mode = 0x06;             // 0b00000110 Cursor increment, NO blink display
char LCD_pos = 0;                 // Count position cursor
char LINE1 = (0x80 + LCD_pos);    // 0b10000000 Position 0:0 Display
char LINE2 = (0xC0 + LCD_pos);    // 0b11000000 Position 1:0 Display
char txt[64];
int aux[10];


/* ======================= Par metros de control ======================= */
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
/* ======================= GPIO (PWM + Encoders + USART) ======================= */
static void Config_GPIO(void) {
	/* ---------- PWM ( PE5 (T9-1, AF3), PB8(T10-1, AF3), PB9(T11-1, AF3), PF8(T13-1, AF9), PF9(T14-1, AF9) ) ---------- */
  /* ---------- Entradas analógicas, PA4 (IN4), PA5 (IN5), PC0 (IN10), PC1 (IN11), PC2 (IN12) ---------- */

	/* Relojes de TIM */
  /* APB2: TIM1, TIM8; APB1: TIM2, TIM3, TIM4, PWM: TIM9/10/11 (APB2), TIM13/14 (APB1) y USART3 */
  RCC->APB1ENR |= RCC_APB1ENR_TIM2EN | RCC_APB1ENR_TIM3EN | RCC_APB1ENR_TIM4EN | RCC_APB1ENR_TIM13EN | RCC_APB1ENR_TIM14EN
								| RCC_APB1ENR_USART3EN;
	
  RCC->APB2ENR |= RCC_APB2ENR_TIM1EN | RCC_APB2ENR_TIM8EN | RCC_APB2ENR_TIM9EN | RCC_APB2ENR_TIM10EN | RCC_APB2ENR_TIM11EN;
	
	/* Habilitar relojes GPIO usados ( A, B, C , D, E, F, H) */
  RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN | RCC_AHB1ENR_GPIOBEN | RCC_AHB1ENR_GPIOCEN 
							  | RCC_AHB1ENR_GPIODEN | RCC_AHB1ENR_GPIOEEN | RCC_AHB1ENR_GPIOFEN 
								| RCC_AHB1ENR_GPIOGEN;
	
	RCC->APB2ENR |= (0x1 << 8);                                 // ADC1
	
	GPIOG->MODER |= 0x55555;
	GPIOG->OTYPER |= 0x0000;
	GPIOG->OSPEEDR |= 0xAAAAAAAA;
	GPIOG->PUPDR |= 0x00000000;
	
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

  // Configuración básica del ADC1
	GPIOA->MODER |= (3 << (4*2)) | (3 << (5*2)); // PA4, PA5 en modo analógico
  GPIOC->MODER |= (3 << (0*2)) | (3 << (1*2)) | (3 << (2*2)); // PC0, PC1, PC2 analógico
	
  ADC1->CR1 = 0;           // Sin SCAN, 12 bits
  ADC1->CR2 = 0;           // Trigger por software, single conversion
  ADC1->SMPR2 |= (0x7 << 12) | (0x7 << 15); // IN4, IN5  (480 ciclos)
  ADC1->SMPR1 |= (0x7 << 0) | (0x7 << 3) | (0x7 << 6); // IN10, IN11, IN12

  ADC1->CR2 |= ADC_CR2_ADON; // Habilitar ADC
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
/// ======================= Lectura ADC puntual ======================= ///
uint16_t ADC_ReadChannel(uint8_t canal) {
		ADC1->SQR1 = 0;           // 1 conversión
		ADC1->SQR3 = canal;       // Selecciona canal
		ADC1->CR2 |= ADC_CR2_SWSTART; // Inicia conversión
		while (!(ADC1->SR & ADC_SR_EOC)); // Esperar fin
		return (uint16_t)ADC1->DR; // Leer valor
}
static inline float wrap360(float a){
    while (a >= 360.0f) a -= 360.0f;
    while (a <    0.0f) a += 360.0f;
    return a;
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
/* ======================= Int to LCD ======================= */
void SetTxt(){
	
	txt[0] = '1';
	txt[1] = ':';
	
	aux[5] = (int)(ang1/100)%10;
	txt[2] = '0' + aux[5];
	aux[4] = (int)(ang1/10)%10;
	txt[3] = '0' + aux[4];
	aux[3] = (int)(ang1/1)%10;
	txt[4] = '0' + aux[3];
	txt[5] = '.';
	aux[2] =  (int)(ang1/0.1)%10;
	txt[6] = '0' + aux[2];
	aux[1] =  (int)(ang1/0.01)%10;
	txt[7] = '0' + aux[1];

	txt[8] = ' ';
	txt[9] = '2';
	txt[10] = ':';
	
	aux[5] = (int)(ang2/100)%10;
	txt[11] = '0' + aux[5];
	aux[4] = (int)(ang2/10)%10;
	txt[12] = '0' + aux[4];
	aux[3] = (int)(ang2/1)%10;
	txt[13] = '0' + aux[3];
	txt[14] = '.';
	aux[2] =  (int)(ang2/0.1)%10;
	txt[15] = '0' + aux[2];
	aux[1] =  (int)(ang2/0.01)%10;
	txt[16] = '0' + aux[1];
	
	txt[17] = ' ';
	txt[18] = '3';
	txt[19] = ':';
	
	aux[5] = (int)(ang3/100)%10;
	txt[20] = '0' + aux[5];
	aux[4] = (int)(ang3/10)%10;
	txt[21] = '0' + aux[4];
	aux[3] = (int)(ang3/1)%10;
	txt[22] = '0' + aux[3];
	txt[23] = '.';
	aux[2] =  (int)(ang3/0.1)%10;
	txt[24] = '0' + aux[2];
	aux[1] =  (int)(ang3/0.01)%10;
	txt[25] = '0' + aux[1];
	
	txt[26] = ' ';
	txt[27] = '4';
	txt[28] = ':';
	
	aux[5] = (int)(ang2/100)%10;
	txt[29] = '0' + aux[5];
	aux[4] = (int)(ang2/10)%10;
	txt[30] = '0' + aux[4];
	aux[3] = (int)(ang2/1)%10;
	txt[31] = '0' + aux[3];
	txt[32] = '.';
	aux[2] =  (int)(ang2/0.1)%10;
	txt[33] = '0' + aux[2];
	aux[1] =  (int)(ang2/0.01)%10;
	txt[34] = '0' + aux[1];
	
	txt[35] = ' ';
	txt[36] = '5';
	txt[37] = ':';
	
	aux[5] = (int)(ang5/100)%10;
	txt[38] = '0' + aux[5];
	aux[4] = (int)(ang5/10)%10;
	txt[39] = '0' + aux[4];
	aux[3] = (int)(ang5/1)%10;
	txt[40] = '0' + aux[3];
	txt[41] = '.';
	aux[2] =  (int)(ang5/0.1)%10;
	txt[42] = '0' + aux[2];
	aux[1] =  (int)(ang5/0.01)%10;
	txt[43] = '0' + aux[1];
	
}
/* ======================= Main ======================= */
int main(void){
	sec_home = 1;
	
	Config_GPIO();
  SysTick_Init();
  USART3_Init(57600);
	
  /* PWM: configurar solo CH1 en cada timer de servo */
  Config_TimerPWM(TIM9);
  Config_TimerPWM(TIM10);
  Config_TimerPWM(TIM11);
  Config_TimerPWM(TIM13);
  Config_TimerPWM(TIM14);

  /* Inicializa comandos en 0  */
  cmd1=0; cmd2=0; cmd3=0; cmd4=0; cmd5=0;
	
	while(1){
	//==================== Secuencia ===================//
		while(sec_home == 0){
			char txt[50] = "Set Home...            Marranito";
			LCD_COM(clean);
			LCD_COM(home);
			LCD_COM(set);
			LCD_COM(LCD_ON);
			LCD_COM(LCD_Mode);
			LCD_COM(LINE1);
			for(int j = 0; j <= 15; j++){
				LCD_W(txt[j]);
			}
			LCD_COM(LINE2);
			for(int j = 16; j <= 32; j++){
				LCD_W(txt[j]);
			}
			
			// Asignar angulo objetivo:
			target1 = 45;		//0 - 90
			target2 = 90;		//0 - 180
			target3 = 90;		//0 - 180
			target4 = 82;		//8 - 172
			target5 = 90;		//0 - 180		
			
			Servo_SetAngle(TIM9, 1, target1); // Servo 1
			Servo_SetAngle(TIM10, 1, target2);	// Servo 2
			Servo_SetAngle(TIM11, 1, target3);	// Servo 3
			Servo_SetAngle(TIM13, 1, target4);	// Servo 4
			Servo_SetAngle(TIM14, 1, target5);	// Servo 5
			sec_home = 1;

			SysTick_Wait1ms(1000); // Peque retardo para estabilidad
		}	
		
		SetTxt();
		
		LCD_COM(LINE1);
		for(int j = 0; j <= 15; j++){
			if(txt[j] == 0){
				LCD_W(' ');
			}else{
				LCD_W(txt[j]);
			}
		}
		LCD_COM(LINE2);
		for(int j = 16; j <= 32; j++){
			if(txt[j] == 0){
				LCD_W(' ');
			}else{
				LCD_W(txt[j]);
			}
		}
		
		// Asignar angulo objetivo:
		target1 = 90;			//0 - 90
		target2 = 60;			//0 - 180
		target3 = 30;			//0 - 180
		target4 = 90;			//8 - 172
		target5 = 180;			//0 - 180	
	
		
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
		
				/* Conversion angulos */
		pot1 = ADC_ReadChannel(4);   // PA4
		ang1 = ((float)pot1 / 4096) * 180.0;
		
		pot2 = ADC_ReadChannel(5);   // PA5
		ang2 = ((float)pot2 / 4096) * 180.0;
		
		pot3 = ADC_ReadChannel(10);  // PC0
		ang3 = ((float)pot3 / 4096) * 180.0;
		
		pot4 = ADC_ReadChannel(11);  // PC1
		ang4 = ((float)pot4 / 4096) * 180.0;
		
		pot5 = ADC_ReadChannel(12);  // PC2
    ang5 = ((float)pot5 / 4096) * 180.0;
		
		SysTick_Wait1ms(1000);
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