;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  KEYPAD.INC                                ;
;                               Keypad Routines                              ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Keypad Program (Keypad.asm).
;
; Revision History:
;    11/02/16   Dong Hyun Kim           initial revision

; Definitions
KEY_VALUE_MASKER    EQU     00001111b   ;used to mask the high nibble of key value,
                                        ;   which are not used in any function

NO_KEY_PRESS        EQU     00001111b   ;value when no keys are pressed
KEY_EVENT_VALUE     EQU     00000000b   ;value that indicates a key pressed event

DECIMAL_DIGIT       EQU     4           ;the number of bits in the upper nibble
                                        ;   of Key Value. if we shift CurrentRow
                                        ;   left by DECIMAL_DIGIT, we can put
                                        ;   CurrentRow in the tens digit of the
                                        ;   Key Value.
NUM_ROWS            EQU     4           ;the number of rows on the keypad. since 
                                        ;   it is a power of 2, we can MOD NUM_ROWS
                                        ;   by using AND NUM_ROWS - 1. 
FIRST_ROW_INDEX     EQU     0           ;the offset from the first row of the keypad
                                        ;   to the first row (that is, 0)
                                        
DEBOUNCE_TIME       EQU     50          ;time (in ms) that the key must be actually
                                        ;   pressed down in order for the program to 
                                        ;   fully debounce the input signal and 
                                        ;   consider the key to be pressed down 
AUTOREPEAT_TIME     EQU     500         ;time (in ms) that each EnqueueEvent will
                                        ;   be called if a key is pressed and held 
                                        ;   down
END_DEBOUNCE_TIME   EQU     0           ;the minimum value of DebounceCnt. When
                                        ;   this value is reached, the EnqueueEvent
                                        ;   is called                                        
                                      
                                        

; Addresses
FIRST_ROW_ADDR      EQU     80H         ;address of the very top row of the keypad
