#include <stm32f767xx.h>

// Tolerancia de error en grados
#define ANG_TOLERANCIA 1.0f
// Paso de corrección (cuánto cambia cada ciclo)
#define CORR_PASO 1.0f

/// Variables globales ///
int pot1 = 0; float ang1 = 0;
int pot2 = 0; float ang2 = 0;
int pot3 = 0; float ang3 = 0;
int pot4 = 0; float ang4 = 0;
int pot5 = 0; float ang5 = 0;

int target1 = 0;
int target2 = 0;
int target3 = 0;
int target4 = 0;
int target5 = 0;

int sec_on = 0;
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

/// ======================= Timer (PWM) ======================= ///
void Config_TimerPWM(TIM_TypeDef *TIMx) {
  TIMx->ARR = 20000 - 1;       // 20 ms periodo (50 Hz)
  TIMx->PSC = 16 - 1;          // 1 MHz clock (1 us por unidad)
  TIMx->EGR = 0x1;             // Update Event para aplicar cambios
  TIMx->CCMR1 = 0x6060;        // CH1 y CH2: PWM1
  TIMx->CCMR2 = 0x6060;        // CH3 y CH4: PWM1
  TIMx->CCER = 0x1111;         // Habilita CH1-CH4 salida activa alta
  TIMx->CR1 = 0x1;             // Habilita el contador
}

/// ======================= GPIO & ADC ======================= ///
void Config_GPIO(void) {
  /// Habilitar relojes ///
  RCC->APB1ENR |= (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3);  // TIM2-5
  RCC->APB2ENR |= (1 << 16);                                  // TIM9
  RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN | RCC_AHB1ENR_GPIOBEN | 
                  RCC_AHB1ENR_GPIOEEN | RCC_AHB1ENR_GPIOCEN;
  RCC->APB2ENR |= (0x1 << 8);                                 // ADC1

  // PA0 (TIM2_CH1) // PA1 (TIM5_CH2) // PA6 (TIM3_CH1) // PB6 (TIM4_CH1) // PE5 (TIM9_CH1)
  GPIOA->MODER |= 0x2F0A; 
  GPIOA->AFR[0] |= 0x2000021; 

  GPIOB->MODER |= 0x2000; 
  GPIOB->AFR[0] |= 0x2000000;

  GPIOE->MODER |= 0x800; 
  GPIOE->AFR[0] |= 0x300000;

  // Entradas analógicas: PA4 (IN4), PA5 (IN5), PC0 (IN10), PC1 (IN11), PC2 (IN12)
  GPIOA->MODER |= (3 << (4*2)) | (3 << (5*2)); // PA4, PA5 en modo analógico
  GPIOC->MODER |= (3 << (0*2)) | (3 << (1*2)) | (3 << (2*2)); // PC0, PC1, PC2 analógico

  // Configuración básica del ADC1
  ADC1->CR1 = 0;           // Sin SCAN, 12 bits
  ADC1->CR2 = 0;           // Trigger por software, single conversion
  ADC1->SMPR2 |= (0x7 << 12) | (0x7 << 15); // IN4, IN5  (480 ciclos)
  ADC1->SMPR1 |= (0x7 << 0) | (0x7 << 3) | (0x7 << 6); // IN10, IN11, IN12

  ADC1->CR2 |= ADC_CR2_ADON; // Habilitar ADC
}

/// ======================= Lectura ADC puntual ======================= ///
uint16_t ADC_ReadChannel(uint8_t canal) {
  ADC1->SQR1 = 0;           // 1 conversión
  ADC1->SQR3 = canal;       // Selecciona canal
  ADC1->CR2 |= ADC_CR2_SWSTART; // Inicia conversión
  while (!(ADC1->SR & ADC_SR_EOC)); // Esperar fin
  return (uint16_t)ADC1->DR; // Leer valor
}

/// ======================= Servo control ======================= ///
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

/// ======================= Main ======================= ///
int main(void) {
	sec_on = 0;
  SysTick_Init();
  Config_GPIO();

  Config_TimerPWM(TIM2);
  Config_TimerPWM(TIM3);
  Config_TimerPWM(TIM4);
  Config_TimerPWM(TIM5);
  Config_TimerPWM(TIM9);

  while (1) {
		//==================== Secuencia ===================//
		while(sec_on == 0){
			// Asignar angulo objetivo:
			target1 = 90;		//0 - 360
			target2 = 90;		//0 - 180
			target3 = 90;		//0 -180
			target4 = 90;	//0 - 172
			target5 = 90;		//0 - 180		
			
			Servo_SetAngle(TIM2, 1, target1); // Servo 1
			SysTick_Wait1ms(500);
			Servo_SetAngle(TIM5, 2, target2);	// Servo 2
			SysTick_Wait1ms(500);
			Servo_SetAngle(TIM3, 1, target3);	// Servo 3
			SysTick_Wait1ms(500);
			Servo_SetAngle(TIM4, 1, target4);	// Servo 4
			SysTick_Wait1ms(500);
			Servo_SetAngle(TIM9, 1, target5);	// Servo 5
			sec_on = 1;
			SysTick_Wait1ms(5000); // Pequeño retardo para estabilidad
		}
		//=============== Lectura y correccion ===============//
    pot1 = ADC_ReadChannel(4);   // PA4
		ang1 = 0.0441140667 * (pot1 - 2048) + 90;
			
    pot2 = ADC_ReadChannel(5);   // PA5
		ang2 = 0.0441140667 * (pot2 - 2048) + 90;
			
    pot3 = ADC_ReadChannel(10);  // PC0
		ang3 = 0.0441140667 * (pot3 - 2048) + 90;
			
    pot4 = ADC_ReadChannel(11);  // PC1
		ang4 = 0.0441140667 * (pot4 - 2048) + 90;
			
    pot5 = ADC_ReadChannel(12);  // PC2
		ang5 = 0.0441140667 * (pot5 - 2048) + 90;
		
		 
		
//		// --- Corrección servo 1 ---
//    if (ang1 < target1 - ANG_TOLERANCIA) target1 += CORR_PASO;
//    else if (ang1 > target1 + ANG_TOLERANCIA) target1 -= CORR_PASO;
//    // Limitar
//    if (target1 < 0) target1 = 0;
//    if (target1 > 180) target1 = 180;
//    Servo_SetAngle(TIM2, 1, target1);

//    // --- Corrección servo 2 ---
//    if (ang2 < target2 - ANG_TOLERANCIA) target2 += CORR_PASO;
//    else if (ang2 > target2 + ANG_TOLERANCIA) target2 -= CORR_PASO;
//    if (target2 < 0) target2 = 0;
//    if (target2 > 180) target2 = 180;
//    Servo_SetAngle(TIM5, 2, target2);

//    // --- Corrección servo 3 ---
//    if (ang3 < target3 - ANG_TOLERANCIA) target3 += CORR_PASO;
//    else if (ang3 > target3 + ANG_TOLERANCIA) target3 -= CORR_PASO;
//    if (target3 < 0) target3 = 0;
//    if (target3 > 180) target3 = 180;
//    Servo_SetAngle(TIM3, 1, target3);

//    // --- Corrección servo 4 ---
//    if (ang4 < target4 - ANG_TOLERANCIA) target4 += CORR_PASO;
//    else if (ang4 > target4 + ANG_TOLERANCIA) target4 -= CORR_PASO;
//    if (target4 < 0) target4 = 0;
//    if (target4 > 180) target4 = 180;
//    Servo_SetAngle(TIM4, 1, target4);

//    // --- Corrección servo 5 ---
//    if (ang5 < target5 - ANG_TOLERANCIA) target5 += CORR_PASO;
//    else if (ang5 > target5 + ANG_TOLERANCIA) target5 -= CORR_PASO;
//    if (target5 < 0) target5 = 0;
//    if (target5 > 180) target5 = 180;
//    Servo_SetAngle(TIM9, 1, target5);

	}
}
