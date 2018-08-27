;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Display.INC                                ;
;                               Display Functions                          	 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Display Program (Display.asm).
;
; Revision History:


; Definitions
BUF_LENGTH      EQU     8           ;length of the buffer containing code segment
LED_LENGTH      EQU     8           ;number of digits that can be displayed on 
                                    ;   the LED display
ASCII_NULL      EQU     0H          ;string termination character (<null>)

; Addresses
OFFSETAD        EQU     0000H       ;address of leftmost digit of LED display