;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _SetStackGuard: Set the Stack Guard
;
; Operation:
;	Copy the new STACK_GUARD value
;
; Input:
;	w0 = STACK_GUARD
; Return:
;	none
;
; System resources usage:
;	{w0}    	used, not modified

	.section .data
	.global _STACK_GUARD
_STACK_GUARD: .word 1024

    .text
	.global	_SetStackGuard	        ; export
	
_SetStackGuard:
	mov     w0,_STACK_GUARD         ; store new stack guard value

	return
	.end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


