	NAME	MOTOR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Motor                                   ;
;                           Motor Routines Function                          ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file contains seven public functions and five private tables
;			   that will be used for the RoboTrike DC motors and laser. It can 
;			   initialize the variables that will be used within the file, set
;			   the motor speed and direction of movement, get the speed and direction
;			   of movement, turn the laser on/off, or get the current laser status.
;			   It also includes an event handler that activates the DC motors
;			   through pulse width modulation. The tables are used to set the 
;			   appropriate bits on Port B and find the pulse width of the motors.
;
; Table of Contents (Functions):
;	InitMotor:			Initializes the shared variables to be used in the file.
;   SetMotorSpeed:		Sets RoboTrike's speed and direction.
;	GetMotorSpeed:		Returns current speed setting in AX.
;	GetMotorDirection:	Returns current direction of movement setting in AX.
;	SetLaser:			Indicates whether to turn laser on or off.
;	GetLaser:			Returns status of laser in AX.
;	MotorEventHandler:	Event handler that activates the DC motors and laser 
;						through pulse width modulation.
;
; Table of Contents (Stub Functions):
;   SetRelTurretAngle:  Set angle of turret relative to current position.
;   SetTurretAngle:     Set absolute angle of turret.
;
; Table of Contents (Tables):
;	ForceXTable:		The magnitude of the forces in the x direction.
;	ForceYTable:		The magnitude of the forces in the y direction.
;	MotorOff:			Bits on Port B of 8255A so motors will be off.
;	MotorFon:			Bits on Port B of 8255A so motors will be on and forwards.
;	MotorROn:			Bits on Port B of 8255A so motors will be on and reverse.
;
; Revision History:
;   11/06/16    Dong Hyun Kim       wrote pseudo code
;   11/09/16    Dong Hyun Kim       initial revision
;   11/11/16    Dong Hyun Kim       debugged code and fixed accordingly
;   11/11/16    Dong Hyun Kim       updated comments



; local include files
$INCLUDE(Motor.INC)			;contains definitions and addresses for motor routines
$INCLUDE(General.INC)       ;add general definitions



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

		

;external function declarations
        EXTRN   Sin_Table:WORD			;sin value table for MIN_ANGLE to MAX_ANGLE
		EXTRN	Cos_Table:WORD			;cos value table for MIN_ANGLE to MAX_ANGLE
		
		

; InitMotor
;
; Description:			This function initialize the shared variables in the 
;						data segment for the motors routine that will be used in 
;                       other functions.
;
; Operation:			The function will go through each variable in the data
;						segment and initialize them appropripriately to a certain
;						value.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		Arr_Counter (BX) - Counter for data segment arrays.
; Shared Variables:		PulseWidths	(DS) - Array containing the pulse width
;										   for all three wheels (W).
;						MotorDir	(DS) - Array containing the direction for
;										   each of the three wheels (W).
;						DriveSpeed  (DS) - Current speed setting for RoboTrike. 
;										   Between MIN_SPEED and MAX_SPEED 
;										   inclusively (W).
;						DriveAngle  (DS) - Current direction of movement setting 
;										   for RoboTrike. Between MIN_ANGLE and
;										   MAX_ANGLE inclusively (W).
;						LaserStatus (DS) - Value indicating if laser is on/off (W).
;                       PW_Count    (DS) - Counter for pulse width modulation (W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	BX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision
;                       11/11/16    Dong Hyun Kim       debugged and fixed code

InitMotor		PROC		NEAR
				PUBLIC 		InitMotor
				
InitMotorInit:								;initialization
		MOV		BX, 0						;initialize Arr_Counter(BX) so the 
											;	loop can start at the first
                                            ;   element of arrays
		;JMP	SingleValueInit				;now, initialize single value variables

SingleValueInit:							;initialization for single value 
											;	variables in the data segment        
        MOV		DriveSpeed, 0		        ;RoboTrike is not moving, so initialize
											;	DriveSpeed to MIN_SPEED
		MOV		DriveAngle, 0		        ;RoboTrike moves straight ahead, so 
											;	set DriveAngle to MIN_ANGLE
		MOV 	LaserStatus, LASER_OFF		;laser is off, so set LaserStatus to
											;	LASER_OFF
        MOV     PW_Count, 0                 ;pulse width modulation is not 
                                            ;   happening, so set to OFF_PULSE
		;JMP	ArrayInitLoop				;now, initialize arrays
		
ArrayInitLoop:								;initialization for arrays in the 
											;	data segment
		CMP		BX, NUM_MOTORS				;check if the arrays have been completely
											;	initialized
		JE		EndInitMotor				;if so, we are done
		;JNE	ArrayInit				

ArrayInit:									;initialize the elements in the array
		MOV		PulseWidths[BX], OFF_PULSE	;RoboTrike wheels are not moving, so
											;	initialize elements in PulseWidths
											;	to OFF_PULSE
		MOV		MotorDir[BX], MOV_FOR		;set initial direction of wheels to
											;	forward, although wheels are not
											;	moving
		INC		BX							;check the next element
		JMP		ArrayInitLoop				;go through the entire array 
		
EndInitMotor:								;end the function
		RET
		
InitMotor		ENDP



; SetMotorSpeed
;
; Description:			The function sets the speed and angle at which the RoboTrike
;						is to run. The first argument (speed) is passed in AX and
;						indicates the absolute speed. If speed is equal to KEEP_SPEED,
;						the current speed will not change - otherwise, it will be
;						used to update DriveSpeed. The second argument (angle) is 
;						passed in BX and is the signed angle of movement in degrees.
;						If angle is equal to KEEP_ANGLE, the current angle of 
;						movement will not change - otherwise, it will be used to
;						update DriveAngle after the value of angle is normalized.
;						The pulse widths of all the DC motors are calculated using
;                       the dot product rule relating speed, force and velocity.
;                       Once all pulse widths are turned into positive values, 
;                       they are stored in the array PulseWidths. The direction 
;                       of motion of all three motors are also determined and the 
;                       appropriate bits will be stored in the array MotorDir.
;
; Operation:			The function starts off by checking if speed and angle is
;						equal to KEEP_SPEED and KEEP_ANGLE, respectively. If so,
;						their respective values are not updated. If they are not,
;						the speed is updated by simply copying its value to DriveSpeed.
;						The angle is updated into DriveAngle after being normalized
;						through a modulo operation that makes the angle fall between
;						MIN_ANGLE and MAX_ANGLE. 
;                       The function then moves on to calculate the pulse widths 
;                       of each motor by utilizing the formula: Pulse Width = 
;                       Force(F) dot speed = Fx*speed*cos(angle) + Fy*speed*sin(angle). 
;                       The forces in the x and y directions are found through 
;                       the private lookup tables, and the sine and cosine values 
;                       are found through the provided public lookup table.
;						The calculations are done utilizing fixed point arithmetic
;                       involving the Q0.15 form. As such, the speed is shifted 
;                       right by Q015_FORM byte to be converted into Q0.15 form.
;                       Each time two values are multiplied, the value is truncated
;                       into the upper word since we only care about the Q0.15
;                       value. The unaltered value of each pulse width will be the
;                       size of a nibble and stored in the CH register.
;                       Once the calculations are over, the sign of each pulse
;						width is determined. If positive, a bit for forward movement
;                       is set and stored in MotorDir. If negative, a bit is set
;                       for reverse movement, stored in MotorDir, and the pulse
;                       width is negated. Once this is all over, the pulse width
;                       values (which are now positive) are put into PulseWidths.
;
; Arguments:			Speed (AX) - Absolute speed at which RoboTrike is to run.
;						Angle (BX) - Signed angle at which RoboTrike is to move
;									 in degrees.
; Return Value:			None.
;
; Local Variables:		PW_Speed	(AX) - Speed in Q0.15 form, used for pulse
;										   width calculations.
;						ArrTab_Cntr (BX) - Counter to go through the private tables 
;										   and arrays in data segment.
;						Angle_Offset(SI) - Index to go through cosine and sine
;										   lookup tables.
; Shared Variables:		PulseWidths	(DS) - Array containing the pulse width
;										   or all three wheels (W).
;						MotorDir	(DS) - Array containing the direction for
;										   each of the three wheels (W).
;						DriveSpeed  (DS) - Current speed setting for RoboTrike. 
;										   Between MIN_SPEED and MAX_SPEED 
;										   inclusively (R/W).
;						DriveAngle  (DS) - Current direction of movement setting 
;										   for RoboTrike. Between MIN_ANGLE and
;										   MAX_ANGLE inclusively (R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;

; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, BX, CX, DX, SI, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision
;                       11/11/16    Dong Hyun Kim       debugged and fixed code

SetMotorSpeed	PROC		NEAR
				PUBLIC 		SetMotorSpeed

CheckSpeed:									;compare value of speed with KEEP_SPEED
		CMP		AX, KEEP_SPEED				;check if value of speed is equal to
											;	that of KEEP_SPEED
		JE		CheckAngle					;if it is, keep the current speed
											;	and check the value of angle instead
		;JNE	StoreSpeed					;if not, update DriveSpeed
		
StoreSpeed:									;store appropriate value in data segment
		MOV 	DriveSpeed, AX				;update the current speed into DriveSpeed
		;JMP	CheckAngle					;now, check the value of angle
		
CheckAngle:									;compare value of angle with KEEP_ANGLE
		CMP		BX, KEEP_ANGLE				;check if value of angle is equal to
											;	that of KEEP_ANGLE
		JE		PulseWidthsInit				;if it is, prepare to set the appropriate
											;	pulse widths to the motors
		;JNE	NormalizeAngle				;if not, update DriveAngle
		
NormalizeAngle:							    ;perform modulo operation so angle is
											;	between MIN_ANGLE and MAX_ANGLE
		MOV		AX, BX						;store angle in the accumulator to 
											;	use the IDIV command
		MOV		BX, 360     				;store FULL_ANGLE in BX to use the 
											;	IDIV command
		CWD									;extend the sign bit of the angle for
											;	signed division, converting 
                                            ;   the angle to a double word to allow
                                            ;   IDIV to store the remainder in
                                            ;   the DX register
		IDIV	BX							;perform a signed division of the 
											;	current angle to get a remainder
											;	in the DX register. Since the sign
											;	of the remainder is always the 
											;	same as the sign of the dividend
											;	for the IDIV command, we must check
											;	if the remainder is positive or 
											;	negative before storing the value
											;	in DX to DriveAngle.
		CMP     DX, 0       				;check if the remainder in DX is 
											;	positive or negative
		JGE		StoreAngle					;if positive, store the angle because
											;	DX already contains the angle 
											; 	we need
		;JL 	MakeAnglePositive			;if negative, make the value in DX 
											;	positive

MakeAnglePositive:							;make the value of the angle in DX
											;	positive
		ADD		DX, 360     				;add FULL_ANGLE to the negative result
											;	 in DX to make it positive 
		;JMP	StoreAngle
		
StoreAngle:									;store appropriate value in data segment
		MOV 	DriveAngle, DX				;update the normalized angle in DriveAngle
		;JMP	PulseWidthsInit				
		
PulseWidthsInit:							;preparation for the pulse width 
											;	calculation for each motor
		MOV 	BX, DriveAngle				;put value of DriveAngle into BX
											;	to fine sine and cosine values
		SHL		BX, 1       				;convert the value of DriveAngle into
											;	a word index to go through the 
											;	tables correctly
		MOV 	SI, BX						;put the word offset into SI for 
											;	proper indexing
		MOV 	BX, 0						;initialize count variable so the 
											;	loop can start at first elements
											;	of each array and table
		;JMP	PulseWidthsCalcLoop				

PulseWidthsCalcLoop:						;go through each motor and set the
											;	appropriate pulse width
		CMP		BX, NUM_MOTORS				;check if the pulse widths have been
											;	set for every motor
		JE		EndSetMotorSpeed			;if so, we are done
		;JNE	PulseWidthsCalc	
		
PulseWidthsCalc:							;calculate pulse width for each motor
        SHL     BX, 1                       ;covert the value of ArrTab_Cntr into
                                            ;   a wordindex to go through word 
                                            ;   tables correctly
		MOV		AX, DriveSpeed				;obtain value of DriveSpeed into the 
											;	accumulator for IMUL command
		SHR		AX, Q015_Form				;set P_Speed (AX) to the Q0.15 form
											;	so that speed can be utilized in 
											;	the pulse width calulations
		IMUL 	CS:ForceXTable[BX]			;multiply Fx with P_Speed
		MOV		AX, DX						;since we are performing Q0.15 arithmetic,
											;	we only care about the upper half
											;	of the result. We store this value
											;	in the accumulator for further 
                                            ;   calculations involving IMUL
		IMUL	CS:Cos_Table[SI]			;multiply Fx * P_Speed with Cos(Angle)
											;	to obtain final value for x direction
		MOV 	CX, DX						;as above, store the relevant values 
											;	so we can add with the final value 
											;	for y direction
		MOV		AX, DriveSpeed				;obtain value of DriveSpeed into the 
											;	accumulator for IMUL command
		SHR		AX, Q015_Form				;set P_Speed (AX) to the Q0.15 form
											;	so that speed can be utilized in 
											;	the pulse width calulations
		IMUL	CS:ForceYTable[BX]			;multiply Fy with P_Speed
		MOV 	AX, DX						;as mentioned above, we only store
											;	the upper half of the result
		IMUL	CS:Sin_Table[SI]			;multiply Fy * P_Speed with Sin(Angle)
											;	to obtain final value for y direction
		ADD		CX, DX						;add the relevant value for y direction
											;	with the relevant value for x 
											;	direction
		SHL		CX, Redundant_Sign			;since we performed multiplication
                                            ;   two times with Q0.15 values, we
                                            ;   will have additional sign bits.
                                            ;   Shifting to the left will remove
                                            ;   these redundant sign bits
        SHR     BX, 1                       ;restore the ArrTab_Cntr back to byte
                                            ;   index
		;JMP	CheckPulseSign				

CheckPulseSign:								;see if the pulse width is positive
											;	or negative
		CMP     CH, 0       				;check if the pulse width is positive
		JGE		PulsePositive				;if so, set direction as forwards
		;JL 	PulseNegative
		
PulseNegative:								;negate pulse width and set motor
											;	direction backwards
		NEG		CH							;make pulse width positive for easier
											;	operation at MotorEventHandler
		MOV 	MotorDir[BX], MOV_REV		;set the motor direction as reverse
		JMP		StorePulseWidth				;now, store pulse width

PulsePositive:								;set motor direction forwards
		MOV 	MotorDir[BX], MOV_FOR		;set the motor direction as forwards
		;JMP 	StorePulseWidth				

StorePulseWidth:							;store pulse width in the data segment
		MOV 	PulseWidths[BX], CH 		;store the positive pulse width into the 
											;	appropriate location of PulseWidths
		INC 	BX							;continue the loop by going through 
		JMP 	PulseWidthsCalcLoop			;	all of the motors

EndSetMotorSpeed:							;end the function
		RET 																	
				
SetMotorSpeed	ENDP



; GetMotorSpeed
;
; Description:			The function returns the current speed setting for the
;						RoboTrike in AX. A speed of MAX_SPEED indicates maximum
;						speed and a value of MIN_SPEED indiactes the RoboTrike
;						is stopped. 
;
; Operation:			The function simply moves a copy of the shared variable 
;						DriveSpeed into the AX register.
;
; Arguments:			None.
; Return Value:			Speed (AX) - Current speed setting for RoboTrike. Between
;									 MIN_SPEED and MAX_SPEED inclusively.
;
; Local Variables:		None.
; Shared Variables:		DriveSpeed (DS) - Current speed setting for RoboTrike. 
;										  Between MIN_SPEED and MAX_SPEED 
;										  inclusively (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision

GetMotorSpeed	PROC		NEAR
				PUBLIC 		GetMotorSpeed

 		MOV		AX, DriveSpeed				;obtain the current speed setting  
											;	and store it in AX
 		
		RET									;now, we are done				
				
GetMotorSpeed	ENDP



; GetMotorDirection
;
; Description:			The function returns the current direction of movement
;						setting for the RoboTrike as an angle in degrees in AX.
;						An angle of MIN_ANGLE indicates straight ahead relative
;						to the RoboTrike orientation and angles are measured 
;						clockwise. 
;
; Operation:			This function simply moves a copy of the shared variable
;						DriveAngle into the AX register. 
;
; Arguments:			None.
; Return Value:			Angle (AX) - Current direction of movement setting for 
;									 RoboTrike. Between MIN_ANGLE and MAX_ANGLE
;									 inclusively, in degrees.
;
; Local Variables:		None.
; Shared Variables:		DriveAngle (DS) - Current direction of movement setting 
;										  for RoboTrike. Between MIN_ANGLE and
;										  MAX_ANGLE inclusively (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision

GetMotorDirection	PROC		NEAR
					PUBLIC 		GetMotorDirection

 		MOV		AX, DriveAngle				;obtain the current movement setting 
											;	and store it in AX

		RET									;now, we are done					
					
GetMotorDirection	ENDP



; SetLaser
;
; Description:			The function is passed a single argument (onoff) in AX
;						that indicates whether to turn the RoboTrike laser on
;						or off. The LASER_OFF value turns the laser off, and 
;						any other value turns it on.
;
; Operation:			This function simply moves a copy of onoff into LaserStatus, 
;						a shared variable in the data segment.
;
; Arguments:			onoff 		(AX) - Value to determine on/off of laser.
;                                          LASER_OFF indicates the laser is off,
;                                          any other values indicate that it is 
;                                          on.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		LaserStatus (DS) - Value indicating if laser is on/off (W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision

SetLaser		PROC		NEAR
				PUBLIC 		SetLaser

		MOV		LaserStatus, AX				;set the value of LaserStatus as 
											;	passed down from AX.
										
		RET									;now, we are done.				
				
SetLaser		ENDP



; GetLaser
;
; Description:			The function returns the status of the RoboTrike laser 
;						in AX. The LASER_OFF value indicates the laser is off
;						and any other value indicates the laser is on.
;
; Operation:			This function simply moves a copy of the shared variable
;						LaserStatus into the AX register. 
;
; Arguments:			None.
; Return Value:			Laser_Onoff (AX) - Value to determine on/off of laser.
;                                          LASER_OFF indicates the laser is off,
;                                          any other values indicate that it is 
;                                          on.
;
; Local Variables:		None.
; Shared Variables:		LaserStatus (DS) - Value indicating if laser is on/off (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision

GetLaser		PROC		NEAR
				PUBLIC 		GetLaser

 		MOV		AX, LaserStatus				;obtain the current laser setting 
											;	and store it in AX

		RET									;now, we are done				
				
GetLaser		ENDP



; MotorEventHandler
;
; Description:			The function will use pulse width modulation to activate
;                       the DC motors on the RoboTrike, and turn the laser on/off
;                       as necessary. The function will go through PulseWidths
;                       to activate the DC motor for a designated amount of time,
;                       and check MotorDir to determine the direction of movement.
;                       It expects to be called every quarter millisecond,
;                       and there will be no pushing and popping of registers since
;                       this function does not directly send an EOI.
;
; Operation:			The function starts off by determining whether or not
;                       the DC motor should be activated. If the counter PW_Count
;                       is greater than or equal to the pulse width, the motor
;                       will be turned off. If not, the motor will be turned on,
;                       after the direction is checked by looking through the
;                       values within MotorDir. The appropriate bits are set by
;                       looking up values in the private lookup tables. The laser
;                       is then turned on or off depending on the value of 
;                       LaserStatus. A non zero value will turn the laser on,
;                       and a zero value will turn it off. Once the appropriate
;                       bits are set, the message is output to Port B of 8255A
;                       and the motors are activated. The, PW_Count is incremented
;                       to prepare for the next duty cycle.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		ByteOuput   (AL) - The message that will be output to
;                                          Port B of the 8255A.
;                       ArrTab_Cntr (BX) - Counter to go through the private tables 
;										   and arrays in data segment.
;                       PW_Count    (CL) - Counter to determine how long a motor
;                                          is to be activated.
; Shared Variables:		PulseWidths	(DS) - Array containing the pulse width
;										    or all three wheels (R).
;						MotorDir	(DS) - Array containing the direction for
;										   each of the three wheels (R).  
;                       LaserStatus (DS) - Value indicating if laser is on/off (R).
;						PW_Count	(DS) - Counter utilized for pulse width 
;										   modulation (R,W).
; Global Variables:		None.
;
; Input:				None.
; Output:				Movement of motors on the RoboTrike.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, BX, CX, DX, flags.
; Limitations:			Resolution of pulse width must be 2^n bits.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/06/16    Dong Hyun Kim       wrote pseudo code
;						11/09/16	Dong Hyun Kim		initial revision
;                       11/11/16    Dong Hyun Kim       debugged and fixed code

MotorEventHandler	PROC		NEAR
                    PUBLIC 		MotorEventHandler

MotorEventHandlerInit:                      ;initialization
        XOR     AX, AX                      ;initialize accumulator that will be
                                            ;   used to output bits into Port B
        MOV     BX, 0                       ;intialize counter so that it will
                                            ;   start from the first motor
        MOV     CL, PW_Count                ;store PW_Count in a register to use
                                            ;   the INC command later
        ;JMP    ControlMotorLoop                
        
ControlMotorLoop:                           ;go through each motor and determine
                                            ;   whether it should be turned on
                                            ;   or off
        CMP     BX, NUM_MOTORS              ;check if we have gone through all
                                            ;   the motors
        JE      ControlLaser                ;if so, set/reset the laser 
        ;JNE    CheckMotorMovement 

CheckMotorMovement:                         ;determine if the motor be activated
        CMP     CL, PulseWidths[BX]         ;check if PW_Count is greater than 
                                            ;   or equal to the pulse width
        JAE     TurnMotorOff                ;if so, turn the motor off
        ;JB     CheckMotorDirection         ;if not, turn the motor on   

CheckMotorDirection:                        ;determine which direction the motor
                                            ;   should move in
        CMP     MotorDir[BX], MOV_REV       ;check if the motor should move backwards
        JE      TurnMotorROn                ;if so, turn the motor on and backwards
        ;JNE    TurnMotorFOn             

TurnMotorFOn:                               ;if not, turn the motor on and forwards
        OR      AL, CS:MotorFOn[BX]         ;set the appropriate bits so that 
                                            ;   the motor of the specific wheel
                                            ;   is turned on and moving forwards
        JMP     UpdateMotorCounter          ;now, check the next motor
        
TurnMotorROn:                               ;turn the motor on and backwards
        OR      AL, CS:MotorROn[BX]         ;set the appropriate bits so that
                                            ;   the motor of the specific wheel
                                            ;   is turned on and moving backwards
        JMP     UpdateMotorCounter          ;now, check the next motor
        
TurnMotorOff:                               ;turn the motor off, disregarding
                                            ;   the current direction
        OR      AL, CS:MotorOff[BX]         ;set the appropriate bits so that
                                            ;   the motor of the specific wheel
                                            ;   is turned off
        ;JMP     UpdateMotorCounter          
                                            
UpdateMotorCounter:                         ;increment the counter for motor 
        INC     BX                          ;increment ArrTab_Cntr to go to
                                            ;   next motor
        JMP     ControlMotorLoop            ;loop again until all motors are done
                                            ;   with pulse width modulation
        
ControlLaser:                               ;determine whether or not the laser
                                            ;   should be turned on or off
        CMP     LaserStatus, LASER_OFF      ;check if laser should be off
        JE      TurnLaserOff                ;if so, turn it off
        ;JNE    TurnLaserOn                 ;if not, turn the laser on
        
TurnLaserOn:                                
        OR      AL, TURN_ON_L               ;set the appropriate bits so that 
                                            ;   the laser will be turned on
        JMP     OutputMotorLaser               
        
TurnLaserOff:                              
        OR      AL, TURN_OFF_L              ;add the appropriate bits so that
                                            ;   the laser will be turned off
        ;JMP    OutputMotorLaser            

OutputMotorLaser:                           ;output the appropriate bits to the
                                            ;   PORT_B_ADDR
        MOV     DX, PORT_B_ADDR             ;store the appropriate address in 
                                            ;   DX to output to parallel I/O
                                            ;   port B of 8255A
        OUT     DX, AL                      ;output the set bits AL to the address
                                            ;   which will activate the motor
                                            ;   in the correct direction, along
                                            ;   with the laser                                           
        ;JMP    UpdatePulseCounter
        
UpdatePulseCounter:                         ;update the pulse width counter         
        INC     CL                          ;increment PW_Count to compare with
                                            ;   pulse width
        AND     CL, PW_RESOLUTION - 1       ;perform a modulo operation on PW_Count 
                                            ;   so that it will wrap around correctly
                                            ;   and pulse width modulation will
                                            ;   be utilized again
        MOV     PW_Count, CL                ;put the count value back to the 
                                            ;   data segment for the next duty
                                            ;   cycle
        ;JMP    EndMotorEventHandler
        
EndMotorEventHandler:                       ;end the function
        RET                      
                
MotorEventHandler	ENDP



SetRelTurretAngle   PROC		NEAR
                    PUBLIC 		SetRelTurretAngle
                    
;this is a dummy function added to pass the MotorTest (in the main loop) correctly
        
        RET

SetRelTurretAngle   ENDP                    
                    
                    

SetTurretAngle      PROC		NEAR
                    PUBLIC 		SetTurretAngle
                    
;this is a dummy function added to pass the MotorTest (in the main loop) correctly                    
        
        RET
        
SetTurretAngle      ENDP        



; ForceXTable
;
; Description:			This is the table including the magnitude of the forces
;						in the x direction for all the motors of the RoboTrike.
;                       It is put in the Q0.15 form to carry out fixed point
;                       arithmetic.
;
; Author:				Dong Hyun Kim
; Last Modified:		11/09/16

ForceXTable		LABEL		WORD

		DW		07FFFH				; Motor 0's force in x direction
		DW		0C000H				; Motor 1's force in x direction
		DW		0C000H				; Motor 2's force in x direction
		

	
; ForceYTable
;
; Description:			This is the table including the magnitude of the forces
;						in the y direction for all the motors of the RoboTrike.
;                       It is put in the Q0.15 form to carry out fixed point
;                       arithmetic.
;
; Author:				Dong Hyun Kim
; Last Modified:		11/09/16

ForceYTable		LABEL		WORD

		DW		00000H				; Motor 0's force in y direction
		DW		09127H				; Motor 1's force in y direction
		DW		06ED9H				; Motor 2's force in y direction

		

; MotorOff
;
; Description:			This is the table that contains the bit diagram of the
;                       values that will be output to Port B of the 8255A to 
;                       turn each motor off.
;
; Notes:				Technically the motors will be set to move forwards, but
;						they will be off so this is not an issue.
;
; Author:				Dong Hyun Kim
; Last Modified:		11/09/16

MotorOff		LABEL		BYTE

		DB		00000000b			; Motor 0 set off
		DB		00000000b			; Motor 1 set off
		DB		00000000b			; Motor 2 set off
		
		
		
; MotorFOn
;
; Description:			This is the table that contains the bit diagram of the
;                       values that will be output to Port B of the 8255A to
;                       turn each motor on and make it move forwards.
;
; Author:				Dong Hyun Kim
; Last Modified:		11/09/16

MotorFon		LABEL		BYTE

		DB		00000010b			; Motor 0 direction set to forward and on
		DB		00001000b			; Motor 1 direction set to forward and on
		DB		00100000b			; Motor 2 direction set to forward and on
		


; MotorROn
;
; Description:			This is the table that contains the bit diagram of the
;                       values that will be output to Port B of the 8255A. It
;                       will turn the motor on and make it move backwards.
;
; Author:				Dong Hyun Kim
; Last Modified:		11/09/16

MotorROn		LABEL		BYTE

		DB		00000011b			; Motor 0 direction set to backwards and on
		DB		00001100b			; Motor 1 direction set to backwards and on
		DB		00110000b			; Motor 2 direction set to backwards and on
				
		
		
CODE	ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

PulseWidths		DB		NUM_MOTORS	DUP (?)		;Array containing the pulse width
												;	for each of the three wheels.
												;	The values will always be positive,
												;	as the direction will be 
												;	determined through MotorDir.
MotorDir		DB		NUM_MOTORS	DUP (?)		;Array containing the direction
												;	for each of the three wheels.
												;	A MOV_FOR value indicates 
												;	moving forward, while a MOV_REV
												;	value indicates moving backwards.
DriveSpeed		DW		?						;Current speed setting for RoboTrike.
												;	Between MIN_SPEED and MAX_SPEED 
												;	inclusively.
DriveAngle 		DW		?						;Current direction of movement 
												;	setting for RoboTrike. Between
												;	MIN_ANGLE and MAX_ANGLE inclusively.
LaserStatus		DW		?						;Value indicated if laser is on/off. 
												;	The	LASER_OFF value indicates
												;	the laser is off, while any 
												;	other values indicates that it
												;	is on.
PW_Count        DB      ?                       ;The counter that ensures pulse
                                                ;   width modulation happens for
                                                ;   each motor. The motor is 
                                                ;   turned on if PW_Count is 
                                                ;   less than the pulse width.
											
DATA    ENDS

END