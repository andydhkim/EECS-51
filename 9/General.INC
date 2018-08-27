;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   General                                  ;
;                           General Routine Functions                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the general definitions that will be utilized in the motor
; and remote unit of the RoboTrike.
;
; Revision History:
;   12/02/16    Dong Hyun Kim       initial revision



; Interrupt Controller Addresses

INTCtrlrEOI         EQU     0FF22H          ;address of interrupt controller EOI register


; Event Type Definitions

NO_EVENT_TYPE       EQU     0               ;value indicating no event      
KEY_EVENT_TYPE      EQU     1               ;value indicating key pressed event
DATA_EVENT_TYPE     EQU     2               ;value indicating data received event
ERROR_EVENT_TYPE    EQU     3               ;value indicating serial error event

; Event Value Definitions

STRING_OUTPUT_ERROR EQU     32              ;one of the values regarding serial
                                            ;   errors, displayed when there is
                                            ;   a string output error
DATA_OVERFLOW_ERROR EQU     34              ;one of the values regarding serial
                                            ;   errors, dispalyed when there is
                                            ;   too much data to display

; Laser Operation Definitions

LASER_ON            EQU     1               ;value indicating that laser is on
LASER_OFF           EQU     0               ;value indicating that laser is off


; Critical Error Definitions

SYSTEM_OK           EQU     0               ;value indicating no critical error
SYSTEM_FAILURE      EQU     1               ;value indicating a critical error


; Basic Definitions

ASCII_NULL          EQU     0               ;string termination character (<null>)
CARRIAGE_RETURN     EQU     13              ;carriage return character, used to
                                            ;   end a message output to the 
                                            ;   serial channel
                                            
BYTE_SIZE           EQU     1           	;Number of bytes in a byte                        
WORD_SIZE	        EQU		2   			;Number of bytes in a word


BUF_LENGTH          EQU     16              ;length of the buffer, in bytes, that  
                                            ;   will contain the characters that 
                                            ;   will be displayed in the LED display.
                                            ;   Different from LED_LENGTH since
                                            ;   each character has a segment 
                                            ;   pattern that has WORD_SIZE bytes
LED_LENGTH          EQU     8               ;number of digits that can be displayed  
                                            ;   on the LED display.
SER_ERR_LENGTH		EQU		9				;length of buffer that will contain
											;	the error message that will be
											;	output whenever there is a serial
											;	error
											
ERROR_DELAY         EQU     65000           ;number of times a NO_EVENT will be
                                            ;   called in the SerialErrorEvent
                                            ;   so that the error message is
                                            ;   displayed for a longer period
                                            ;   of time
											