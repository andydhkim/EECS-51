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


; Interrupt Controller Definitions

; Addresses

INTCtrlrEOI         EQU     0FF22H          ;address of interrupt controller EOI register


; Event Type Definitions

NO_EVENT_VALUE      EQU     0               ;value indicating no event       
KEY_EVENT_VALUE     EQU     1               ;value indicating key pressed event
DATA_EVENT_VALUE    EQU     2               ;value indicating data received event
ERROR_EVENT_VALUE   EQU     3               ;value indicating serial error event

;Laser Operation Definitions

LASER_ON            EQU     1               ;value indicating that laser is on
LASER_OFF           EQU     0               ;value indicating that laser is off

; General Definitions

ASCII_NULL          EQU     0               ;string termination character (<null>)
BYTE_SIZE           EQU     1           	;Number of bytes in a byte.                                  
WORD_SIZE	        EQU		2   			;Number of bytes in a word.