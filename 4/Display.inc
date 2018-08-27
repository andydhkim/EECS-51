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


; Definitions
LED_LENGTH      EQU     8           ;number of digits that can be displayed on 
                                    ;   the LED display. Also refers to the 
                                    ;   amount of characters (in words) that are
                                    ;   included in the MuxBuffer
BUF_LENGTH      EQU     16          ;length of the buffer, in bytes, that will 
                                    ;   contain the characters that will be 
                                    ;   displayed in the LED display. Used to 
                                    ;   denote how many bytes are in MuxBuffer
                                    ;   and DisBuffer.                                 
ASCII_NULL      EQU     0           ;string termination character (<null>)
BYTES_PER_WORD  EQU     2           ;value designating the amount of bytes per
                                    ;   word. Used to go through the MuxBuffer
                                    ;   since it is a word array.

; Addresses
LowCharAddr     EQU     0000H       ;address of first segment of the LED digit
                                    ;   display, used for low byte of the 
                                    ;   word character
HighCharAddr    EQU     0008H       ;address of segment of the LED digit display
                                    ;   that will be used for the high byte of
                                    ;   the word character