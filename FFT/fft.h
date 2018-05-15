/* 
 * File:   fft.h
 * Author: Csurleny
 *
 * Created on May 12, 2018, 11:35 AM
 */

#ifndef FFT_H
#define	FFT_H

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
#endif  /* ] */

#ifndef fractcomplex                    /* [ */
typedef struct {
  fractional real;
  fractional imag;
} fractcomplex;
#endif  /* ] fractcomplex */

#endif  /* ] fractional */

#define Q15(X) \
   ((X < 0.0) ? (int)(32768*(X) - 0.5) : (int)(32767*(X) + 0.5)) 

#define FFT_BLOCK_LENGTH	256     /* = Number of frequency points in the FFT */
#define LOG2_BLOCK_LENGTH 	8	/* = Number of "Butterfly" Stages in FFT processing */
#define SAMPLING_RATE		10000	/* = Rate at which input signal was sampled */
                                        /* SAMPLING_RATE is used to calculate the frequency*/
                                        /* of the largest element in the FFT output vector*/


extern fractcomplex* BitReverseComplex (        /* Bit Reverse Ordering */
                                        /* (complex) */
   int log2N,                           /* log2(N), N is vector length */
   fractcomplex* srcCV                  /* ptr to source complex vector */
                                        /* MUST be N modulo aligned */

                                        /* srcCV returned */
);

extern fractcomplex* FFTComplexIP (     /* Fast Fourier Transform */
                                        /* (complex, in-place) */
   int log2N,                           /* log2(N), N-point transform */
   fractcomplex* srcCV,                 /* ptr to source complex vector */
                                        /* with time samples */
                                        /* in natural order */
   fractcomplex* twidFactors,           /* base address of twiddle factors */
                                        /* either in X data or program memory */
                                        /* if in X data memory, it points at */
                                        /* WN(0).real */
                                        /* if in program memory, base is the */
                                        /* offset from program page boundary */
                                        /* to address where factors located */
                                        /* (inline assembly psvoffset ()) */
   int factPage                         /* if in X data memory, set to */
                                        /* defined value COEFFS_IN_DATA */
                                        /* if in program memory, page number */
                                        /* where factors are located */
                                        /* (inline assembly psvpage ()) */

                                        /* srcCV returned */
                                        /* with frequency components */
                                        /* in bit reverse order */
                                        /* and scaled by 1/(1<<log2N) */
);

extern fractional* SquareMagnitudeCplx ( /* Squared-Magnitude of complex  */
   int numelems,                        /* source vector, srcV, of length */
   fractcomplex* srcV,                  /* numelems, is stored in the     */
   fractional* dstV                     /* destination vector dstV        */
                                        /* dstV may be located in X or Y  */
                                        /* data space, while srcV is in Y */
                                        /* data space                     */
                                        /* Address of dstV is returned    */
                                        /* Function is typically, called  */
                                        /* after performing the FFTComplex*/
                                        /* operation                      */
);


#ifdef	__cplusplus
}
#endif

#endif	/* FFT_H */

