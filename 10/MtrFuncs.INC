;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   MTRFUNCS                                 ;
;                      Motor Unit Main File Helper Functions                 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains definitions for the motor unit main file helper function
; program (MtrFuncs.ASM). 
;
; Revision History:
;   12/08/16    Dong Hyun Kim       initial revision


; Status Update Message Definitions

;Message Position Definitions
SPEED_POS           EQU     0               ;index of the UpdataStsBuf where
                                            ;   the SPEED_CHAR will be written to
SPEED_VAL           EQU     1               ;index of the UpdateStsBuf where
                                            ;   the upper byte of the value of
                                            ;   the speed, in hex, will be 
                                            ;   written to
DIR_POS             EQU     4               ;index of the UpdateStsBuf where 
                                            ;   the DIR_CHAR will be written to
DIR_VAL             EQU     3               ;index of the UpdataStsBuf where
                                            ;   the current direction of movement
                                            ;   setting will be written to. It 
                                            ;   is one less than the DIR_POS since
                                            ;   there are two leading zeros that
                                            ;   we must get rid of.
LASER_POS           EQU     3               ;index of the UpdateStsBuf where the
                                            ;   laser status character will be
                                            ;   written to


;Message Character Definitions
SPEED_CHAR          EQU     'S'             ;character indicating that the next
                                            ;   two characters, in hex, will be
                                            ;   the current speed of the RoboTrike
DIR_CHAR            EQU     'D'             ;character indicating that the next
                                            ;   three digits, in decimal, will
                                            ;   be the current direction of 
                                            ;   movement of the RoboTrike
LASER_ON_CHAR       EQU     'F'             ;character indicating that the laser
                                            ;   is currently on
LASER_OFF_CHAR      EQU     'O'             ;character indicating that the laser
                                            ;   is currently off




; Motor Unit Error Definitions

MOTOR_OK            EQU     0               ;value indicating no motor unit error
MOTOR_FAILURE       EQU     1               ;value indicating a motor unit error


; General Definitions
UP_STS_LENGTH		EQU		9				;the length of the buffer that will		
											;	contain the status update message
											;	that will be output to the serial
											;	channel