/* 
 * File:   pid.h
 * Author: Csurleny
 *
 * Created on August 6, 2018, 11:21 AM
 */

#ifndef PID_H
#define	PID_H

#ifdef	__cplusplus
extern "C" {
#endif

#define FLOATING        -1                      /* using floating type */
#define FRACTIONAL       1                      /* using fractional type */
#ifndef DATA_TYPE                       /* [ */
#define DATA_TYPE       FRACTIONAL              /* default */
#endif  /* ] */
    
#ifndef fractional                      /* [ */

#if     DATA_TYPE==FLOATING             /* [ */
typedef double          fractional;
#else   /* ] */
typedef int             fractional;
#endif /* ] */

#endif

#define Q15(X) \
((X < 0.0) ? (int)(32768*(X) - 0.5) : (int)(32767*(X) + 0.5)) 

extern fractional PID(fractional* coeffVector, fractional* errorVector, fractional* outputVector);
extern void CoeffCalc(fractional kp, fractional ki, fractional kd, fractional* coeffVector );

#ifdef	__cplusplus
}
#endif

#endif	/* PID_H */

