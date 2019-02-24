#include "delay.h"

void delayTimerInit(){
    T1CON = 0x0000;
}

void usDelay(unsigned int us){
    TMR1 = 0;
    PR1 = us*15; 
    IFS0bits.T1IF = 0; 
    T1CONbits.TON = 1;
    while (!IFS0bits.T1IF); 
    T1CONbits.TON = 0;
}

void msDelay(unsigned int ms){
    unsigned int i;
    for(i =0; i < 2*ms; ++i)
        usDelay(500);
}
