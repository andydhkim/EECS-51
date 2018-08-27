;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  InitPP.INC                                ;
;                       Initialize Parallel I/O Function                     ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Initialize Parallel I/O Function
; program, (InitPP.ASM).
;
; Revision History:
;   11/09/16    Dong Hyun Kim       initial revision


; 82C55A Chip Definitions

; Addresses
PPCtrlREg		EQU     183H          ;address of 82C55A control register

; Control Register Values
PPCtrlRegInit 	EQU     10000000b     ;Mode 0, all ports output
									  ;1-------  Set mode flag
									  ;-00-----  Select mode 0 for Group A
									  ;---0----  Use Port A for output
									  ;----0---  Use Port C (upper) for output
									  ;-----0--  Select mode 0 for Group B
									  ;------0-  Use Port B for output
									  ;-------0  Use Port C (lower) for output