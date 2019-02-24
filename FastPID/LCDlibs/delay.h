/* 
 * File:   delay.h
 * Author: Csurleny
 *
 * Created on August 3, 2018, 8:30 AM
 */

#ifndef DELAY_H
#define	DELAY_H

#ifdef	__cplusplus
extern "C" {
#endif

#include "mcc_generated_files/mcc.h"
    
    void delayTimerInit();
    void usDelay(unsigned int us);
    void msDelay(unsigned int ms);


#ifdef	__cplusplus
}
#endif

#endif	/* DELAY_H */

