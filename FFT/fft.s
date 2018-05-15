    .nolist
    .include "common.inc"
    .list
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _FFTComplexIP: Complex (in-place) DIF FFT.
;
; Operation:
;	F(k) = 1/N*sum_n (f(n)*WN(kn)), WN(kn) = exp[-(j*2*pi*k*n)/N],
;
; n in {0, 1,... , N-1}, and
; k in {0, 1,... , N-1}, with N = 2^m.
;
; Input:
;	w0 = number stages in FFT (log2N)
;	w1 = ptr to complex source vector (srcCV)
;	w2 = ptr to complex twiddle factors (twidFactors)
;	w3 = COEFFS_IN_DATA, or memory program page with twiddle factors.
; Return:
;	w0 = ptr to source vector (srcCV)
;
; System resources usage:
;	{w0..w7}	used, not restored
;	{w8..w14}	saved, used, restored
;	 AccuA		used, not restored
;	 AccuB		used, not restored
;	 CORCON		saved, used, restored
;	 PSVPAG		saved, used, restored (if factors in P memory)
;
; DO and REPEAT instruction usage.
;	2 level DO intruction
;	1 REPEAT intruction

    .equ	COEFFS_IN_DATA,0xFF00
    .global	_FFTComplexIP	; export
_FFTComplexIP:

;............................................................................
; Save working registers.
    push.d	w8				; {w8,w9} to TOS
    push.d	w10				; {w10,w11} to TOS
    push.d	w12				; {w12,w13} to TOS
    push	w14             ; w14 to TOS

;............................................................................
; Prepare CORCON for fractional computation.
    push	CORCON
    fractsetup	w7

;............................................................................

; Prepare DSRPAG or PSVPAG for possible access of data
; located in program memory
.ifdef __dsPIC33E
    push	DSRPAG
.else
    push	PSVPAG
.endif

    push	w1				    ; save return value (srcCV)

    mov		w15,w14             ; save SP

    mov		#COEFFS_IN_DATA,w7	; w7 = COEFFS_IN_DATA
    cp		w7,w3				; w7 - w3
    bra		z,_noPSV            ; if w3 = COEFFS_IN_DATA

.ifndef __dsPIC33E  
    psvaccess	w7              ; enable PSV bit in CORCON
    mov		w3,PSVPAG               ; load PSVPAG with program
	                            ; space page offset
.else
	; twiddles in flash
    movpag	w3,DSRPAG            ; set DSRPAG to PSV page
; check if sufficient space is available in stack
; condition (SP + TABLE SIZE + STACK_GUARD) < SPLIM
    mov		SPLIM,w4             ; load stack pointer limit
    mov		_STACK_GUARD,w13     ; stack guard space for interrupts etc ...
				; NOTE: THIS IS USER-DEFINABLE
    mov		#__YDATA_BASE,w5

    mov		#0x1,w9				; to be shifted...
    sl		w9,w0,w9			    ; w9 = N (1<<log2N)
    sl		w9,w9                ; TABLE_SIZE in bytes

    add		w9,w15,w10           ; SP + TABLE_SIZE
    bra		c,_runFromFlash
    sub		w10,w5,w10           ; SP + TABLE_SIZE - __YDATA_BASE
    bra		geu,_runFromFlash

    add		w9,w13,w9            ; add _STACK_GUARD
    bra		c,_runFromFlash
    add		w9,w15,w9            ; add SP
    bra		c,_runFromFlash

    sub		w9,w4,w13            ; Check against SPLIM
    bra		ltu,_copyToStack

;...............................................................................	
; RUN FROM FLASH
;...............................................................................	
_runFromFlash:
; not enough stack space, run from flash

; FFT proper.
    mov		#0x1,w9				; to be shifted...
    sl		w9,w0,w9			; w9 = N (1<<log2N)
    mov		#0x1,w3				; initialize twidds offset,
						; also used as num butterflies
    mov		w2,w8				; w8-> WN(0) (real part)

; Preform all k stages, k = 1:log2N.
; NOTE: for first stage, 1 butterfly per twiddle factor (w3 = 1)
; and N/2 groups  (w9 = N/2) for factors WN(0), WN(1), ..., WN(N/2-1).
    mov		w0,w13				; w13= num stages
					    ; w0 available for reuse
_doStagePSV:

; Perform all butterflies in each stage, grouped per twiddle factor.

; Update counter for groups.
    lsr		w9,w9				; w9 = N/(2^k)
    sl		w9,#2,w12			; w12= lower offset
					    ; nGrps+sizeof(fractcomplex)
					    ; *2 bytes per element

; Set pointers to upper "leg" of butterfly:
    mov		w1,w10				; w10-> srcCV (upper leg)

; Perform all the butterflies in each stage.
    dec		w3,w4				; w4 = butterflies per group
    do		w4,_endBfliesPSV		; {	; do 2^(k-1) butterflies
    nop
; Set pointer to lower "leg" of butterfly.
    add		w12,w10,w11			; w11-> srcCV + lower offset
					    ; (lower leg)
; Prepare offset for twiddle factors.
    sl		w3,#2,w0			; oTwidd*sizeof(fractcomplex)
					    ; *2 bytes per element

; Perform each group of butterflies, one for each twiddle factor.
    dec		w9,w4				; w4 = nGrps-1
    do		w4,_endGroupPSV		; {	; do (nGrps-1)+1 times
					    ; no more nested do's...
    nop

; Butterfly proper.
    clr		a,[w8]+=2,w6,[w10]+=2,w4	; a  = 0 (for dual fetch only)
					    ; w6 = Wr
					    ; pTwidd-> Wi
					    ; w4 = Ar
					    ; pUpper-> Ai (=Ci)

    push	DSRPAG
    movpag	#0x0001, DSRPAG

    nop
    sub		w4,[w11++],w4			; w4 = Ar - Br
					    ; pLower-> Bi (=Di)


    pop		DSRPAG

    mpy		w4*w6,a,[w8]-=2,w7,[w10]-=2,w5	; a  = (Ar - Br)*Wr
					    ; w7 = Wi
					    ; pTwidd-> Wr
					    ; w5 = Ai
					    ; pUpper-> Ar (=Cr)
; Update twiddle pointer.
    add		w0,w8,w8			; pTwidd-> for next group

    mpy	    	w4*w7,b				; b  = (Ar - Br)*Wi

    push	DSRPAG
    movpag	#0x0001, DSRPAG
    nop


    sub		w5,[w11--],w5			; w5 = Ai - Bi
					    ; pLower-> Br (=Dr)
    msc		w5*w7,a,[w11]+=2,w7		; a  = (Ar - Br)*Wr
					    ;    - (Ai - Bi)*Wi = Dr
					    ; w7 = Br
					    ; pLower-> Bi (=Di)
    mac		w5*w6,b,[w11]-=2,w5		; b  = (Ar - Br)*Wi
					    ;    + (Ai - Bi)*Wr = Di
					    ; w5 = Bi
					    ; pLower-> Br (=Dr)
    sac.r	a,#1,[w11++]			; save 1/2*Dr
					    ; pLower-> Bi (=Di)
    sac.r	b,#1,[w11++]			; save 1/2*Di
					    ; pLower-> Br (next)
    lac		[w10++],a			; a  = Ar
					    ; pUpper-> Ai (=Ci)
    lac		[w10--],b			; b  = Ai
					    ; pUpper-> Cr


    pop		DSRPAG

    add	    	w7,a				; a  = Ar + Br
    add		w5,b				; b  = Ai + Bi
    sac.r	a,#1,[w10++]			; save 1/2*Cr
					    ; pUpper-> Ci
_endGroupPSV:
    sac.r	b,#1,[w10++]			; save 1/2*Ci
						; pUpper-> Ar (next)
; }

    add		w12,w10,w10			; w10-> upper leg (next set)
_endBfliesPSV:
    mov		w2,w8				; rewind twiddle pointer
; }

; Update offset to factors.
    sl		w3,w3				; oTwidd *= 2

; Find out whether to perform another stage...
    dec		w13,w13				; w13= log2N - k -1
    bra		gt,_doStagePSV			; if W13 > 0, do next stage
_endStagesPSV:					; else, no more stages...
    bra		_completedFFT

;...............................................................................
; STACK SPACE AVAILABLE
;...............................................................................
_copyToStack:	
    mov		#0x1,w9			; to be shifted...
    sl		w9,w0,w9			; w9 = N (1<<log2N)

; Save twiddle table pointer
    mov		w15,w8			; w8-> WN(0) (real part)
; Copy entire twiddle table to stack
    dec		w9,w13           ; repeat count
    repeat	w13              ; set repeat count
    mov		[w2++],[w15++]   ; copy from PSV to stack

    mov		w8,w2            ; restore w2
	
.endif

_noPSV:
.ifdef __dsPIC33E
    movpag	#0x0001, DSRPAG
.endif
	
;............................................................................

	; FFT proper.
    mov		#0x1,w9				; to be shifted...
    sl		w9,w0,w9			; w9 = N (1<<log2N)
    mov		#0x1,w3				; initialize twidds offset,
					    ; also used as num butterflies
    mov		w2,w8				; w8-> WN(0) (real part)

; Preform all k stages, k = 1:log2N.
; NOTE: for first stage, 1 butterfly per twiddle factor (w3 = 1)
; and N/2 groups  (w9 = N/2) for factors WN(0), WN(1), ..., WN(N/2-1).
    mov		w0,w13				; w13= num stages
			    ; w0 available for reuse
_doStage:

; Perform all butterflies in each stage, grouped per twiddle factor.

; Update counter for groups.
    lsr		w9,w9				; w9 = N/(2^k)
    sl		w9,#2,w12			; w12= lower offset
	                        ; nGrps+sizeof(fractcomplex)
                            ; *2 bytes per element

; Set pointers to upper "leg" of butterfly:
    mov		w1,w10				; w10-> srcCV (upper leg)

; Perform all the butterflies in each stage.
    dec		w3,w4				; w4 = butterflies per group
    do		w4,_endBflies		; {	; do 2^(k-1) butterflies
.ifdef __dsPIC33E
    nop
.endif
    ; Set pointer to lower "leg" of butterfly.
    add		w12,w10,w11			; w11-> srcCV + lower offset
					    ; (lower leg)
    ; Prepare offset for twiddle factors.
    sl		w3,#2,w0			; oTwidd*sizeof(fractcomplex)
					    ; *2 bytes per element

    ; Perform each group of butterflies, one for each twiddle factor.
    dec		w9,w4				; w4 = nGrps-1
    do		w4,_endGroup		; {	; do (nGrps-1)+1 times
	    				    ; no more nested do's...
.ifdef YMEM_ERRATA
    nop
.endif
    ; Butterfly proper.
    clr		a,[w8]+=2,w6,[w10]+=2,w4	; a  = 0 (for dual fetch only)
					    ; w6 = Wr
					    ; pTwidd-> Wi
					    ; w4 = Ar
					    ; pUpper-> Ai (=Ci)

    sub		w4,[w11++],w4			; w4 = Ar - Br
					    ; pLower-> Bi (=Di)

    mpy		w4*w6,a,[w8]-=2,w7,[w10]-=2,w5	; a  = (Ar - Br)*Wr
					    ; w7 = Wi
					    ; pTwidd-> Wr
					    ; w5 = Ai
					    ; pUpper-> Ar (=Cr)
; Update twiddle pointer.
    add		w0,w8,w8			; pTwidd-> for next group

    mpy		w4*w7,b				; b  = (Ar - Br)*Wi

    sub		w5,[w11--],w5			; w5 = Ai - Bi
					    ; pLower-> Br (=Dr)
    msc		w5*w7,a,[w11]+=2,w7		; a  = (Ar - Br)*Wr
					    ;    - (Ai - Bi)*Wi = Dr
					    ; w7 = Br
					    ; pLower-> Bi (=Di)
    mac		w5*w6,b,[w11]-=2,w5		; b  = (Ar - Br)*Wi
					    ;    + (Ai - Bi)*Wr = Di
					    ; w5 = Bi
					    ; pLower-> Br (=Dr)
    sac.r	a,#1,[w11++]			; save 1/2*Dr
					    ; pLower-> Bi (=Di)
    sac.r	b,#1,[w11++]			; save 1/2*Di
					    ; pLower-> Br (next)
    lac		[w10++],a			; a  = Ar
					    ; pUpper-> Ai (=Ci)
    lac		[w10--],b			; b  = Ai
					    ; pUpper-> Cr

    add		w7,a				; a  = Ar + Br
    add		w5,b				; b  = Ai + Bi
    sac.r	a,#1,[w10++]			; save 1/2*Cr
					    ; pUpper-> Ci
_endGroup:
    sac.r	b,#1,[w10++]			; save 1/2*Ci
						; pUpper-> Ar (next)
; }

    add		w12,w10,w10			; w10-> upper leg (next set)
_endBflies:
    mov		w2,w8				; rewind twiddle pointer
; }

; Update offset to factors.
    sl		w3,w3				; oTwidd *= 2

; Find out whether to perform another stage...
    dec		w13,w13				; w13= log2N - k -1
    bra		gt,_doStage			; if W13 > 0, do next stage
_endStages:					; else, no more stages...
;............................................................................
_completedFFT:
    mov		w14,w15         ; restore SP
    pop		w0              ; restore return value

;............................................................................

; Restore PSVPAG and CORCON.
.ifdef __dsPIC33E
    pop		DSRPAG
.else
    pop		PSVPAG
.endif
    pop		CORCON

;............................................................................

; Restore working registers.
    pop		w14             ; w14 from TOS
    pop.d	w12				; {w12,w13} from TOS
    pop.d	w10				; {w10,w11} from TOS
    pop.d	w8				; {w8,w9} from TOS


    
    return
    .end
