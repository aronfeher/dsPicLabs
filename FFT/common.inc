    .nolist
    .include	"xc.inc"
    .list
    
; Operational modes for fractional computation:
    .equ    SATA_ON,1<<7                    ; AccA sat. enabled
    .equ    SATB_ON,1<<6                    ; AccB sat. enabled
    .equ    SATDW_ON,1<<5                   ; data write sat. enabled
    .equ    ACCSAT_ON,1<<4                  ; Accs sat. 9.31 enabled
    .equ    FRACT_SET,SATA_ON|SATB_ON|SATDW_ON|ACCSAT_ON    ; set mask

    .equ    RND_OFF,~(1<<1)                 ; convergent rnd. enabled
    .equ    IF_OFF,~(1<<0)                  ; multiply fractional enabled
    .equ    FRACT_RESET,RND_OFF&IF_OFF      ; reset mask

    .equ    FRACT_MODE,FRACT_SET&FRACT_RESET        ; fractional mask

    .ifdef  TOOLVERS                        ; [
    .equ    FRACT_MODE,FRACT_MODE&0x3ff     ; get rid of leading (sign)
					    ; bits so that the mask can
					    ; be used as a Slit10
    .endif  ; ]

; Operational modes for Program Space Visibility.
    .equ    PSV_ON,1<<2                     ; program space visible in
					    ; data space
; Prepare CORCON for fractional computation.
    .macro  fractsetup      wx              ; [
    mov     #FRACT_MODE,\wx
    mov     \wx,CORCON
    .endm   ; ]

; Prepare CORCON for Program Space Visibility access.
    .macro  psvaccess       wx              ; [
    mov     CORCON,\wx
    ior     #PSV_ON,\wx
    mov     \wx,CORCON
    .endm   ; ]


