;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   INT2.INC                                 ;
;                            INT2 Handler Functions                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the INT2 Handler Functions program, 
; (INT2.ASM).
;
; Revision History:
;   11/17/16    Dong Hyun Kim       initial revision


; INT2 Definitions

; Addresses
INT2Ctrl        EQU     0FF3CH          ;address of INT2 Control Register

; Control Register Values
INT2CtrlVal     EQU     00011H          ;value to write to INT2 Control Register
                                        ;00000000000-----  reserved
                                        ;-----------1----  level triggering mode
                                        ;------------0---  enable interrupts
                                        ;-------------001  set to max priority level

; Interrupt Vectors
INT2Vec         EQU     14              ;interrupt vector for INT2


; Interrupt Controller Definitions

; Register Values
INT2EOI         EQU     0000EH          ;INT2 EOI command