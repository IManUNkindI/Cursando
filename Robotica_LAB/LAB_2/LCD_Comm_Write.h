#include <stm32f767xx.h>
#include "SisTick.h"

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