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
;   10/21/16    Dong Hyun Kim       initial revision
;   12/01/16    Dong Hyun Kim       added new definitions to make compatible 
;                                   with 14-segment display
                     

; Addresses
LowCharAddr     EQU     0000H       ;address of first segment of the LED digit
                                    ;   display, used for low byte of the 
                                    ;   word character
HighCharAddr    EQU     0008H       ;address of segment of the LED digit display
                                    ;   that will be used for the high byte of
                                    ;   the word character