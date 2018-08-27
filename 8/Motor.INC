;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Motor.INC                                 ;
;                           Motor Routines Functions                     	 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Motor Routines Program (Motor.asm).
;
; Revision History:
;   11/07/16    Dong Hyun Kim       initial revision
;   11/09/16    Dong Hyun Kim       added additional definitions


; Addresses
PORT_B_ADDR     EQU     181H        ;address of parallel I/O port B  


; Definitions

; Speed Definitions
KEEP_SPEED		EQU		65535		;speed that indicates current speed should
									;	not be changed
MAX_SPEED		EQU		65534		;maximum speed of the RoboTrike
MIN_SPEED		EQU		0			;mimimum speed of the RoboTrike. Indicates 
									;	that the RoboTrike has stopped.

; Angle Definitions                                 
KEEP_ANGLE		EQU		-32768		;angle that indicates current direction of
									;	travel should not be changed.
MAX_ANGLE		EQU		359			;maximum angle (clockwise) of movement 
									;	relative to the RoboTrike orientation
MIN_ANGLE		EQU		0			;angle indicating movement straight ahead 
									;	relative to the RoboTrike orientation
FULL_ANGLE		EQU		360			;value used when performing modulo operation
									;	on the angle

; Direction Definitions                                    
MOV_FOR			EQU		0			;value that indicates motor is moving forward
MOV_REV			EQU		1			;value that indicates motor is moving backwards


; Pulse Width Definitions									
OFF_PULSE		EQU		0			;pulse width in which wheels do not move
PW_RESOLUTION   EQU     128         ;resolution of the pulse width in bits


; Laser Definitions
OFF_LASER		EQU		0			 ;value incidating the laser is off
TURN_ON_L       EQU     10000000b    ;value used to turn laser on
TURN_OFF_L      EQU     00000000b    ;value used to turn laser off


; General Definitions
NUM_MOTORS		EQU		3			;number of motors on the RoboTrike
Q015_Form		EQU		1			;number of bits to shift right to half the 
									;	value of speed so we can convert it to
									;	Q0.15 form
Word_Conv		EQU		1			;number of bits to shift left to convert DriveAngle 
									;	from a byte to a word, allowing the user
									;	to index through the cosine and sign 
									;	lookup tables correctly
Redundant_Sign	EQU		2			;the number of bits to shit left to remove 
									;	the redundant sign bits of pulse width
									;	after performing fixed point arithmetic
									
ChkPosAngle		EQU		8000H		;used to check if angle is positive or negative
                                    ;   after IDIV command
ChkPosPulse		EQU		0080H		;used to check if pulse width is positive or    
                                    ;   negative after fixed point arithmetic