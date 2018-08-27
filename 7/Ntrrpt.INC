;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Intrrpt.INC                                ;
;                         Interrupt Handler Functions                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Interrupt Handler Functions program, 
; (Intrrpt.ASM).
;
; Revision History:
;   10/27/16    Dong Hyun Kim       initial revision
;   11/02/16    Dong Hyun Kim       added VECTOR_SIZE


; Interrupt Controller Definitions

; Addresses
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
NonSpecEOI      EQU     08000H          ;Non-specific EOI command

; General Definitions
FIRST_RESERVED_VEC	    EQU	    1       ;reserve vectors 1-3
LAST_RESERVED_VEC	    EQU	    3
VECTOR_SIZE             EQU     4       ;size of each interrupt vector