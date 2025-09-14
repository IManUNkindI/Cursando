#include <stm32f767xx.h>

#ifndef SisTick_H
#define SisTick_H

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
#endif