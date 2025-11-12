#include <stm32f767xx.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

volatile char rx_buffer[64];
volatile uint8_t rx_index = 0;
volatile uint8_t rx_ready = 0;


void SysTick_Init(void)	{					// Inicializacion
	SysTick->LOAD =0xFFFFFF;
	SysTick->CTRL =0x0000005;
}
void SysTick_Wait(uint32_t n)	{			// Ciclo
	SysTick->LOAD = n-1;
	SysTick->VAL =0;
	while((SysTick->CTRL&0x00010000)==0);
}
void SysTick_Wait1s(uint32_t delay){ // S
	for(uint32_t i=0; i<delay ; i++){
	SysTick_Wait(16000000);
	}
}
void SysTick_Wait1ms(uint32_t delay){ // mS
	for(uint32_t i=0; i<delay ; i++){
	SysTick_Wait(16000);
	}
}
void SysTick_Wait1us(uint32_t delay){ // uS
	for(uint32_t i=0; i<delay ; i++){
		SysTick_Wait(16);
	}
}
void LCD_COM(char com){
//RS-PG8, Enable-PG9, DATA PG0 (LSB)- PG7 (MSB)
	SysTick_Init();
	
	GPIOG->ODR = com;
	GPIOG->ODR &= ~(1UL <<8); //RS=0
	GPIOG->ODR |= (1UL << 9); //Enable 1
	SysTick_Wait1us(2000);
	GPIOG->ODR &= ~(1UL <<9); //Enable 0
}
void LCD_W(char write){
//RS-PG8, Enable-PG9, DATA PG0 (LSB)- PG7 (MSB)
	SysTick_Init();

	GPIOG->ODR = write;
	GPIOG->ODR |= (1UL <<8); //RS=1 PARA ENVIAR DATOS (CARACTER)
	GPIOG->ODR |= (1UL << 9); //Enable 1
	SysTick_Wait1us(10);
	GPIOG->ODR &= ~(1UL <<9); //Enable 0
}

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

int dealyl = 3;
int reco = 0;
int bandera = 0;
int mult = 0;
/* ======================= Comandos LCD ======================= */
char clean = 0x01;                // 0b00000001 Limpieza LCD
char home = 0x02;                 // 0b00000010 Modo home LCD
char set = 0x38;    	            // 0b00111100 Define: BUS as 8 bits, LCD 2 lines, Caracter 5x8
char LCD_ON = 0x0C;               // 0b00001100 Display ON, cursor OFF, Blink OFF
char LCD_Mode = 0x06;             // 0b00000110 Cursor increment, NO blink display
char LCD_pos = 0;                 // Count position cursor
char LINE1 = (0x80 + LCD_pos);    // 0b10000000 Position 0:0 Display
char LINE2 = (0xC0 + LCD_pos);    // 0b11000000 Position 1:0 Display
char txt1[32], txt2[32];
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
float vec1[11], vec2[11], vec3[11], vec4[11], vec5[11];
float prom1, prom2, prom3, prom4, prom5;
int   sec_home = 0, sec_on = 0;
int txi = 0;
char tx[32];
/* ======================= GPIO (PWM + Encoders + USART) ======================= */
static void Config_GPIO(void) {
	/* ---------- PWM ( PE5 (T9-1, AF3), PB8(T10-1, AF3), PB9(T11-1, AF3), PF8(T13-1, AF9), PF9(T14-1, AF9) ) ---------- */
  /* ---------- Entradas anal gicas, PA4 (IN4), PA5 (IN5), PC0 (IN10), PC1 (IN11), PC2 (IN12) ---------- */

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

  // Configuraci n b sica del ADC1
	GPIOA->MODER |= (3 << (4*2)) | (3 << (5*2)); // PA4, PA5 en modo anal gico
  GPIOC->MODER |= (3 << (0*2)) | (3 << (1*2)) | (3 << (2*2)); // PC0, PC1, PC2 anal gico
	
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
		ADC1->SQR1 = 0;           // 1 conversi n
		ADC1->SQR3 = canal;       // Selecciona canal
		ADC1->CR2 |= ADC_CR2_SWSTART; // Inicia conversi n
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
	for(int q=0; q<=32; q++){
		txt1[q] = 0;
		txt2[q] = 0;
	}
	txt1[0-(reco/dealyl)] = '1';
	txt1[1-(reco/dealyl)] = ':';
	
	aux[5] = (int)(prom1/100)%10;
	txt1[2-(reco/dealyl)] = '0' + aux[5];
	aux[4] = (int)(prom1/10)%10;
	txt1[3-(reco/dealyl)] = '0' + aux[4];
	aux[3] = (int)(prom1/1)%10;
	txt1[4-(reco/dealyl)] = '0' + aux[3];
	txt1[5-(reco/dealyl)] = '.';
	aux[2] =  (int)(prom1/0.1)%10;
	txt1[6-(reco/dealyl)] = '0' + aux[2];
	aux[1] =  (int)(prom1/0.01)%10;
	txt1[7-(reco/dealyl)] = '0' + aux[1];

	txt1[9-(reco/dealyl)] = '2';
	txt1[10-(reco/dealyl)] = ':';
	
	aux[5] = (int)(prom2/100)%10;
	txt1[11-(reco/dealyl)] = '0' + aux[5];
	aux[4] = (int)(prom2/10)%10;
	txt1[12-(reco/dealyl)] = '0' + aux[4];
	aux[3] = (int)(prom2/1)%10;
	txt1[13-(reco/dealyl)] = '0' + aux[3];
	txt1[14-(reco/dealyl)] = '.';
	aux[2] =  (int)(prom2/0.1)%10;
	txt1[15-(reco/dealyl)] = '0' + aux[2];
	aux[1] =  (int)(prom2/0.01)%10;
	txt1[16-(reco/dealyl)] = '0' + aux[1];
	
	txt1[18-(reco/dealyl)] = '3';
	txt1[19-(reco/dealyl)] = ':';
	
	aux[5] = (int)(prom3/100)%10;
	txt1[20-(reco/dealyl)] = '0' + aux[5];
	aux[4] = (int)(prom3/10)%10;
	txt1[21-(reco/dealyl)] = '0' + aux[4];
	aux[3] = (int)(prom3/1)%10;
	txt1[22-(reco/dealyl)] = '0' + aux[3];
	txt1[23-(reco/dealyl)] = '.';
	aux[2] =  (int)(prom3/0.1)%10;
	txt1[24-(reco/dealyl)] = '0' + aux[2];
	aux[1] =  (int)(prom3/0.01)%10;
	txt1[25-(reco/dealyl)] = '0' + aux[1];
	
	txt2[0-(reco/dealyl)] = '4';
	txt2[1-(reco/dealyl)] = ':';
	
	aux[5] = (int)(prom4/100)%10;
	txt2[2-(reco/dealyl)] = '0' + aux[5];
	aux[4] = (int)(prom4/10)%10;
	txt2[3-(reco/dealyl)] = '0' + aux[4];
	aux[3] = (int)(prom4/1)%10;
	txt2[4-(reco/dealyl)] = '0' + aux[3];
	txt2[5-(reco/dealyl)] = '.';
	aux[2] =  (int)(prom4/0.1)%10;
	txt2[6-(reco/dealyl)] = '0' + aux[2];
	aux[1] =  (int)(prom4/0.01)%10;
	txt2[7-(reco/dealyl)] = '0' + aux[1];
	
	txt2[9-(reco/dealyl)] = '5';
	txt2[10-(reco/dealyl)] = ':';
	
	aux[5] = (int)(prom5/100)%10;
	txt2[11-(reco/dealyl)] = '0' + aux[5];
	aux[4] = (int)(prom5/10)%10;
	txt2[12-(reco/dealyl)] = '0' + aux[4];
	aux[3] = (int)(prom5/1)%10;
	txt2[13-(reco/dealyl)] = '0' + aux[3];
	txt2[14-(reco/dealyl)] = '.';
	aux[2] =  (int)(prom5/0.1)%10;
	txt2[15-(reco/dealyl)] = '0' + aux[2];
	aux[1] =  (int)(prom5/0.01)%10;
	txt2[16-(reco/dealyl)] = '0' + aux[1];
	
	if(prom1 != 0){
		reco += 1;
	}
	if(reco == 12*dealyl){
		reco = 0;
	}
}
/* ======================= Almacenar vector para promedio ======================= */
void vector1(){
	for(int h=0; h<= 9; h++){
		if(vec1[h] != 0){
		}else{
			vec1[h] = ang1;
			h = 9;
		}
	}
	if(vec1[9] != 0){
		for(int p=0; p<=9; p++){
			prom1 += vec1[p];
		}
		prom1 = prom1/10;
		for(int o=0; o<=9; o++){
			vec1[o] = vec1[o+1];
		}
	}
}
void vector2(){
	for(int h=0; h<= 9; h++){
		if(vec2[h] != 0){
		}else{
			vec2[h] = ang2;
			h = 9;
		}
	}
	if(vec2[9] != 0){
		for(int p=0; p<=9; p++){
			prom2 += vec2[p];
		}
		prom2 = prom2/10;
		for(int o=0; o<=9; o++){
			vec2[o] = vec2[o+1];
		}
	}
}
void vector3(){
	for(int h=0; h<= 9; h++){
		if(vec3[h] != 0){
		}else{
			vec3[h] = ang3;
			h = 9;
		}
	}
	if(vec3[9] != 0){
		for(int p=0; p<=9; p++){
			prom3 += vec3[p];
		}
		prom3 = prom3/10;
		for(int o=0; o<=9; o++){
			vec3[o] = vec3[o+1];
		}
	}
}
void vector4(){
	for(int h=0; h<= 9; h++){
		if(vec4[h] != 0){
		}else{
			vec4[h] = ang4;
			h = 9;
		}
	}
	if(vec4[9] != 0){
		for(int p=0; p<=9; p++){
			prom4 += vec4[p];
		}
		prom4 = prom4/10;
		for(int o=0; o<=9; o++){
			vec4[o] = vec4[o+1];
		}
	}
}
void vector5(){
	for(int h=0; h<= 9; h++){
		if(vec5[h] != 0){
		}else{
			vec5[h] = ang5;
			h = 9;
		}
	}
	if(vec5[9] != 0){
		for(int p=0; p<=10; p++){
			prom5 += vec5[p];
		}
		prom5 = prom5/10;
		for(int o=0; o<=9; o++){
			vec5[o] = vec5[o+1];
		}
	}
}
/* ======================= Main ======================= */
int main(void){
	sec_home = 0;
	
	Config_GPIO();
  SysTick_Init();
  USART3_Init(9600);
	
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
			target1 = 90;
			target2 = 90;
			target3 = 90;
			target4 = 90;
			target5 = 90;
			sec_home = 1;
			Servo_SetAngle(TIM9, 1, target1); // Servo 1
			Servo_SetAngle(TIM10, 1, target2);	// Servo 2
			Servo_SetAngle(TIM11, 1, target3);	// Servo 3
			Servo_SetAngle(TIM13, 1, target4);	// Servo 4
			Servo_SetAngle(TIM14, 1, target5);	// Servo 5
			SysTick_Wait1ms(5000);
		}
		SetTxt();
		
		LCD_COM(LINE1);
		for(int j = 0; j <= 15; j++){
			if(txt1[j] == 0){
				LCD_W(' ');
			}else{
				LCD_W(txt1[j]);
			}
		}
		LCD_COM(LINE2);
		for(int j = 0; j <= 15; j++){
			if(txt2[j] == 0){
				LCD_W(' ');
			}else{
				LCD_W(txt2[j]);
			}
		}
		
		Servo_SetAngle(TIM9, 1, target1); // Servo 1
		Servo_SetAngle(TIM10, 1, target2);	// Servo 2
		Servo_SetAngle(TIM11, 1, target3);	// Servo 3
		Servo_SetAngle(TIM13, 1, target4);	// Servo 4
		Servo_SetAngle(TIM14, 1, target5);	// Servo 5
		
		int N = 2; // n mero arbitrario, por ejemplo cada 5
		mult = bandera % N;
		
				/* Conversion angulos */
		pot1 = ADC_ReadChannel(4);   // PA4
		ang1 = -30.00f + ((float)pot1 / 4096.0f) * 210.0f;
		vector1();
		
		pot2 = ADC_ReadChannel(5);   // PA5
		ang2 = -30.00f + ((float)pot2 / 4096.0f) * 210.0f;
		vector2();
		
		pot3 = ADC_ReadChannel(10);  // PC0
		ang3 = -30.00f + ((float)pot3 / 4096.0f) * 210.0f;
		vector3();
		
		pot4 = ADC_ReadChannel(11);  // PC1
		ang4 = -30.00f + ((float)pot4 / 4096.0f) * 210.0f;
		vector4();
		
		pot5 = ADC_ReadChannel(12);  // PC2
    ang5 = -25.00f + ((float)pot5 / 4096.0f) * 205.0f;
		vector5();
		
		SysTick_Wait1ms(500);
	}
}
extern "C"{
	extern "C" {
void USART3_IRQHandler(void) {
    if (USART3->ISR & USART_ISR_RXNE) {
        char c = USART3->RDR & 0xFF;
        static char num_buf[15];
        static uint8_t num_index = 0;
        static float temp_values[5];
        static uint8_t current_value = 0;
        static uint8_t frame_started = 0;  // Bandera de inicio de trama

        if (c == '$') {
            // Inicio de trama - resetear todo
            frame_started = 1;
            current_value = 0;
            num_index = 0;
            return;
        }

        if (!frame_started) {
            return;  // Ignorar hasta recibir '$'
        }

        if (c == '*') {
            // Fin de trama - procesar
            if (num_index > 0 && current_value < 5) {
                num_buf[num_index] = '\0';
                temp_values[current_value++] = atof(num_buf);
                num_index = 0;
            }
            
            // Verificar que tenemos exactamente 5 valores
            if (current_value == 5) {
                target1 = fminf(fmaxf(temp_values[0], 0.0f), 180.0f);
                target2 = fminf(fmaxf(temp_values[1], 0.0f), 180.0f);
                target3 = fminf(fmaxf(temp_values[2], 0.0f), 180.0f);
                target4 = fminf(fmaxf(temp_values[3], 0.0f), 180.0f);
                target5 = fminf(fmaxf(temp_values[4], 0.0f), 180.0f);
                
                // Aplicar transformaciones si son necesarias
                target4 = 180.0f - target4;
                target5 = 180.0f - target5;
            }
            
            // Resetear para siguiente trama
            frame_started = 0;
            current_value = 0;
            num_index = 0;
            return;
        }

        if (c == ',') {
            // Separador entre valores
            if (num_index > 0 && current_value < 5) {
                num_buf[num_index] = '\0';
                temp_values[current_value++] = atof(num_buf);
                num_index = 0;
            }
            return;
        }

        // Acumular caracteres numéricos
        if ((c >= '0' && c <= '9') || c == '.' || c == '-') {
            if (num_index < sizeof(num_buf) - 1) {
                num_buf[num_index++] = c;
            }
        }
        // Ignorar otros caracteres (incluyendo \n, \r)
    }
}
}

}
