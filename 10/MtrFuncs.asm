    NAME    MTRFUNCS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   MTRFUNCS                                 ;
;                      Motor Unit Main File Helper Functions                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file contains five public functions and one private table
;              that will be used for the motor unit main file of the RoboTrike.
;              The first function can initialize all of the necessary components 
;              of the motor unit. The remaining four functions act as helper
;              functions for the main file, carrying out the appropriate action
;              for each event type. 
;              
;
; Table of Contents (Functions):
;   InitMotorMainLoop:	Initializes the necessary components of the motor unit.
;	UpdateStatus:		Outputs a status update message to the serial channel.
;	SerialErrorEvent:	Outputs the correct serial error message to serial channel.
;	ParseErrorEvent:	Outputs the correct parsing error message to serial channel.
;	NoEvent:			Does nothing and returns.
;
; Revision History:
;   12/08/16    Dong Hyun Kim       initial revision



; local include files
$INCLUDE(General.INC)       ;contains general definitions
$INCLUDE(MtrFuncs.INC)		;contains definitions for motor unit helper functions



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

        
;external function declarations
        EXTRN   InitSerial:NEAR             ;initialize the serial routine variables
		EXTRN	InitParser:NEAR				;initialize the parsing variables
		EXTRN	InitMotor:NEAR				;initialize the motor variables
		EXTRN	InitCS:NEAR					;initialize the 80188 chip selects
		EXTRN	InitPP:NEAR					;initialize the parallel port of the 16C450
        EXTRN   InitEventQueue:NEAR         ;initialize EventQueue
        EXTRN   ClrIRQVectors:NEAR          ;clear (initialize) interrupt vector table
        EXTRN   InitTimer2:NEAR             ;initialize the Timer 2 Interrupt
        EXTRN   InstallTimer2Handler:NEAR   ;install the Timer 2 Handler
        EXTRN   InitINT2:NEAR               ;initialize the INT2 Interrupt        
        EXTRN   InstallINT2Handler:NEAR     ;install the INT 2 Handler
        EXTRN   SetCriticalError:NEAR       ;appropriately set the critical error
                                            ;   flag    
        EXTRN   SerialPutString:NEAR        ;output a string to the serial channel
        EXTRN   Hex2String:NEAR             ;convert a unsigned number to Hex
        EXTRN   Dec2String:NEAR             ;convert a signed number to decimal
		EXTRN	GetLaser:NEAR				;obtain current laser setting
		EXTRN	GetMotorSpeed:NEAR			;obtain current speed of RoboTrike
		EXTRN	GetMotorDirection:NEAR		;obtain current direction of movement
											;	for the RoboTrike



                                        
; InitMotorMainLoop
;
; Description:			The function initializes all of the necessary components
;                       for the motor unit main loop. It calls the appropriate
;                       initialization functions.
;
; Operation:            The function clears the interrupt to prevent any critical
;                       code issues while resetting the critical error flag. It
;                       then calls all of the necessary initialization functions.
;                       Finally, the critical error flag is reset since there 
;                       should be no errors when beginning the program.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		NoError (AL) - value indicating no critical errors.
; Shared Variables:		None.		
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
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/08/16    Dong Hyun Kim       initial revision   

InitMotorMainLoop   PROC        NEAR
                    PUBLIC      InitMotorMainLoop                    
                   
        
        CLI                                 ;clear interrupts to prevent any 
                                            ;   critical code issues whlie resetting  
                                            ;   the critical error flag
                   
		CALL	InitCS					    ;initialize the 80188 chip selects
                                            ;   assumes LCS and UCS already set up  
		CALL	InitPP						;initialize the parallel port of the 
											;	16C450
                                        
        CALL    InitParser                  ;initializes the parsing variables
        CALL    InitSerial                  ;initializes the 16C450 and serial I/O 
                                            ;   variables       
		CALL	InitMotor					;initializes the motor variables
        CALL    InitEventQueue              ;initializes the EventQueue                                        
										
		CALL	ClrIRQVectors			    ;clear (initialize) interrupt vector 
                                            ;   table
		
		CALL	InstallINT2Handler	        ;install the event handlers
        CALL    InstallTimer2Handler        ;   ALWAYS install handlers before
                                            ;   allowing the hardware to interrupt.
                                        
        MOV     AL, SYSTEM_OK               ;the system has not started to operate,
        CALL    SetCriticalError            ;   so reset the critical error flag  
        
		CALL	InitINT2				    ;initialize the INT2 interrupt
        CALL    InitTimer2                  ;initialize the Timer2 interrupt
        STI                                 ;	and finally allow interrupts.
        
        RET
                    
InitMotorMainLoop	ENDP  



; UpdateStatus
;
; Description:			The function is called whenever the speed, direction or
;						laser status setting is updated. It will output the letter
;						'S' followed by the speed of the RoboTrike in hexadecimal,
;						00 being the minimum speed and FF being the maximum. It
;						will then output the letter 'A' followed by the current
;						angle of movement of the RoboTrike in degrees and decimal.
;						Hence, the status message will look like: 'S__ A___'.
;
; Operation:			The function intially obtains the current speed of the
;                       RoboTrike and writes it out to the appropriate location
;                       of UpdateStrBuf after converting it to a hex value. It 
;                       will then write the SPEED_CHAR at the correct index to
;                       indicate that the next two characters after it will be
;                       the current speed. The, the current direction of movement
;                       is obtained and written out to the appropriate location
;                       of UpdateStrBuf after converting it to a decimal value.
;                       Finally, a blank space is written out between the two
;                       arguments, and the entire string is output to the 
;                       serial channel.         
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		CurrentVal (AX) - Either the current speed or current
;                                         direction of movement setting of the
;                                         RoboTrike.
; Shared Variables:		None.
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
; Registers Changed:	AX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     12/08/16    Dong Hyun Kim       initial revision

UpdateStatus		PROC        NEAR
                    PUBLIC      UpdateStatus
                    
OutputCurrentSpeed:                             ;form the speed part of the status 
                                                ;   message
        CALL    GetMotorSpeed                   ;obtain the current speed of the 
                                                ;   RoboTrike
        LEA     SI, UpdateStsBuf[SPEED_VAL]     ;now, we set the address of SI as 
                                                ;   SPEED_VAL to ensure that the
                                                ;   speed, in hex, will be displayed 
        PUSH    SI                              ;preserve the value of the address 
                                                ;   since Hex2String will manipulate 
                                                ;   the value
        CALL    Hex2String                      ;obtain the upper byte value of the 
                                                ;   current speed in hexadecimal
                                                ;   the lower byte will not be
                                                ;   displayed 
        POP     SI                              ;restore the value of the address
        ;JMP    OutputSpeedChar

OutputSpeedChar:                                ;now, output the speed character 
                                                ;   which will alert the user that 
                                                ;   the number following SPEED_CHAR 
                                                ;   will be the speed in hexadecimal
        MOV     UpdateStsBuf[SPEED_POS], SPEED_CHAR     ;start off the speed part
                                                        ;   by displaying SPEED_CHAR
        ;JMP    OutputCurrentDirection                    
                    
OutputCurrentDirection:                         ;form the angle part of the status
                                                ;   message
        CALL    GetMotorDirection               ;obtain the current direction of 
                                                ;   movement of the RoboTrike
        LEA     SI, UpdateStsBuf[DIR_VAL]       ;now, we set the address of SI 
                                                ;   as DIR_VAL to ensure that 
                                                ;   the angle, in decimal, will 
                                                ;   be displayed in the proper 
                                                ;   position
        PUSH    SI                              ;preserve the value of the address 
                                                ;   since Dec2String will manipulate 
                                                ;   the value
        CALL    Dec2String                      ;obtain the current angle in decimal 
                                                ;   and write it to the correct 
                                                ;   location in UpdateStsBuf
        POP     SI                              ;restore the address value
        ;JMP    OutputDirectionChar
        
OutputDirectionChar:                            ;now, output the direction character 
        MOV     UpdateStsBuf[DIR_POS], DIR_CHAR ;   which will alert the user that 
                                                ;   the number following DIR_CHAR 
                                                ;   will be the angle in degrees 
                                                ;   and decimal
        ;JMP    CheckLaserStatus
                    
        
CheckLaserStatus:                               ;check if the laser is currently
                                                ;   on or off
        CALL    GetLaser                        ;obtain current status of the laser
        CMP     AX, LASER_ON                    ;if the laser is on, add the 
        JE      OutputLaserOn                   ;   LASER_ON_CHAR in the correct
                                                ;   location
        ;JNE    OutputLaserOff              

OutputLaserOff:                                 ;if not, add the LASER_OFF_CHAR
                                                ;   in the correct location
        MOV     UpdateStsBuf[LASER_POS], LASER_OFF_CHAR  ;now, write the correct
                                                         ;  laser character to 
                                                         ;  indicate that the
                                                         ;  laser is off
        JMP     OutputStatusMessage                                                         
        
OutputLaserOn:                                  
        MOV     UpdateStsBuf[LASER_POS], LASER_ON_CHAR   ;now, write the correct
                                                         ;  laser character to
                                                         ;  indicate that the
                                                         ;  laser is on
        ;JMP    OutputStatusMessage

OutputStatusMessage:                            ;now, output the status message
                                                ;   to the serial channel
        LEA     SI, UpdateStsBuf                ;obtain the address of the complete 
                                                ;   string back to SI
		PUSH	DS						        ;Need to change from DS:SI to ES:SI 
		POP		ES						        ;	in order to to invoke next 
                                                ;	function correctly.
		CALL	SerialPutString 		        ;Output the string to the serial	
												;	channel
                                                
EndUpdateStatus:                                ;now, end the function                                                                                      
        RET 
                    
UpdateStatus		ENDP  



; SerialErrorEvent
;
; Description:			The function should be called whenever there is a serial
;                       error. It will form the appropriate error message utilizing
;                       the passed down error value and send it to the serial channel. 
;                       The error message itself will be eight characters long,
;                       the last four showing the type of serial error. 
;
; Operation:			The function starts off by adding the first four characters
;                       of the error message, "SERM", to a separate buffer. This
;                       will allow the user to differentiate between the status
;                       updates on the LED. It will then utilize the passed down
;                       error value and add it to the buffer through the DisplayHex
;                       function.
;
; Arguments:			EventVal       (AL) - the event value from EventQueue, in 
;                                             this case the value of the serial 
;                                             error.
; Return Value:			MotorError	   (AX)	- value indicating whether or not
;											  there was a error in the motor unit.
;											  MOTOR_OK indicates that there was
;											  no error, while MOTOR_FAILURE 
;											  indicates otherwise.
;
; Local Variables:		None.
; Shared Variables:		SerialErrorBuf (DS) - array containing the serial error
;                                             message that will be displayed (W).		
; Global Variables:		None.
;
; Input:				None.
; Output:				The error message to the serial channel.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        A different value is designated for each serial error.
;                       To find out which error has been caused, please check
;                       the functional specification of the remote unit.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/08/16    Dong Hyun Kim       initial revision   

SerialErrorEvent    PROC        NEAR
                    PUBLIC      SerialErrorEvent                    
                   
SerialErrorEventInit:                           ;initialization
        MOV     SerialErrorBuf[0], 'S'          ;the first character of the error
                                                ;   message will be set to 'S'
        MOV     SerialErrorBuf[1], 'E'          ;the second will be set to 'E'
        MOV     SerialErrorBuf[2], 'R'          ;the third will be set to 'R'
		MOV		SerialErrorBuf[3], 'M'			;the fourth will set to 'M' 
												;	to denote that it was an error
												;	from the motor unit
        LEA     SI, SerialErrorBuf[4]           ;now, we set SI as the address of
                                                ;   the fourth element of the
                                                ;   buffer. The error value will 
                                                ;   thus be displayed after the 
                                                ;   'SERM'
        ;JMP    ObtainErrorVal           
                   
ObtainErrorVal:                                 ;find the error value
        XOR     AH, AH                          ;clear the AH register in order
                                                ;   to use the AL register as
                                                ;   AX, since DisplayHex requires
                                                ;   an argument in AX
        ;JMP    ConvertErrorVal

ConvertErrorVal:								;convert error val to Hex
		PUSH	SI						        ;Save the value of address because 
                                                ;	Hex2String modifies SI values
		CALL	Hex2String				        ;Converts the unsigned 16-bit value
                                                ;	in AX to hexadecimal and stores 
                                                ;   it as a string in ES:SI. 
		POP		SI						        ;Return SI back to its original 
                                                ;   value
		;JMP	DisplaySerErrorMsg				

DisplaySerErrorMsg:								;output the error message
        LEA     SI, SerialErrorBuf              ;move the address of the complete
                                                ;   string back to SI
		PUSH	DS						        ;Need to change from DS:SI to ES:SI 
		POP		ES						        ;	in order to to invoke next 
                                                ;	function correctly.
		CALL	SerialPutString 		        ;Output the string to the serial	
												;	channel		
        MOV     CX, 0                           ;prepare for the delay loop that
                                                ;   will follow immediately
        ;JMP    DelayLoop

DelayLoop:                                      ;without the delay loop, the error
                                                ;   message will be displayed on
                                                ;   the screen for an extremely
                                                ;   short amount of time if another
                                                ;   event has occured. to prevent
                                                ;   this problem, a delay loop
                                                ;   is added 
        INC     CX                              ;increment the counter                                               
        CMP     CX, ERROR_DELAY                 ;check if the delay loop should
                                                ;   be over
        JB      DelayLoop                       ;keep looping until the counter 
                                                ;   value is greater than that
                                                ;   of ERROR_DELAY
		
                 
EndSerialErrorEvent:                            ;now, end the function
		MOV		AX, MOTOR_OK					;alert the program that there 
												;	was no error
        RET                                             
                    
SerialErrorEvent    ENDP   



; ParseErrorEvent
;
; Description:			The function should be called whenever there is a parsing
;                       error. It will form the appropriate error message and 
;						output it to the serial channel. The error message itself
;						will simply be 'PE'. 
;
; Operation:			The function will simply output the string of two 
;						characters, 'P' and 'E' to the serial channel.
;
; Arguments:			None.
; Return Value:			MotorError	   (AX)	- value indicating whether or not
;											  there was a error in the motor unit.
;											  MOTOR_OK indicates that there was
;											  no error, while MOTOR_FAILURE 
;											  indicates otherwise.
;
; Local Variables:		None.
; Shared Variables:		SerialErrorBuf (DS) - array containing the serial error
;                                             message that will be displayed (W).	
; Global Variables:		None.
;
; Input:				None.
; Output:				The error message to the serial channel.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AH, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        A different value is designated for each serial error.
;                       To find out which error has been caused, please check
;                       the functional specification of the remote unit.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/08/16    Dong Hyun Kim       initial revision   

ParseErrorEvent     PROC        NEAR
                    PUBLIC      ParseErrorEvent                    
                   
ParseErrorEventInit:                            ;initialization
        MOV     SerialErrorBuf[0], 'P'          ;the first character of the error
                                                ;   message will be set to 'P'
        MOV     SerialErrorBuf[1], 'E'          ;the second will be set to 'E'
		MOV		SerialErrorBuf[2], ASCII_NULL	;the third will be the string
												;	termination character
        LEA     SI, SerialErrorBuf[3]           ;now, we set SI as the address of
                                                ;   the fourth element of the
                                                ;   buffer. The error value will 
                                                ;   thus be displayed after the 
                                                ;   'SER'
		;JMP	DisplayParErrorMsg				

DisplayParErrorMsg:								;output the error message
        LEA     SI, SerialErrorBuf              ;move the address of the complete
                                                ;   string back to SI
		PUSH	DS						        ;Need to change from DS:SI to ES:SI 
		POP		ES						        ;	in order to to invoke next 
                                                ;	function correctly.
		CALL	SerialPutString 		        ;Output the string to the serial	
												;	channel
		;EndSerialErrorEvent
                 
EndParseErrorEvent:                             ;now, end the function
		MOV		AX, MOTOR_OK					;since we have handled the error
												;	correctly, alter the program
												;	that there is no error
        RET                                             
                    
ParseErrorEvent     ENDP  


; NoEvent
;
; Description:			The function is called whenever there is a NO_EVENT_TYPE
;                       or KEY_EVENT_TYPE event type. It sets the accumulator
;						to MOTOR_OK to indicate that there is no error.
;
; Operation:	        The function simply sets the AX register to MOTOR_OK to
;						indicate that there was no error in the motor unit. 
;
; Arguments:			None.
; Return Value:			MotorError (AX)	- value indicating whether or not there
;										  was an error in the motor unit. MOTOR_OK
;										  indicates that there was no error, while
;										  MOTOR_FAILURE indicates otherwise.
;
; Local Variables:		None.
; Shared Variables:		None.		
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
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/08/16    Dong Hyun Kim       initial revision   

NoEvent             PROC        NEAR
                    PUBLIC      NoEvent                    
                   
		MOV		AX, MOTOR_OK				;alert the program that there is no
											;	error
        RET                                 ;do nothing and return
                    
NoEvent             ENDP   



CODE    ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

SerialErrorBuf  DB      SER_ERR_LENGTH  DUP (?) ;The array containing the string
                                                ;   with the appropriate error 
                                                ;   message that will be displayed
                                                ;   on the LED whenever there is
                                                ;   a serial error. 
UpdateStsBuf    DB      UP_STS_LENGTH   DUP (?) ;The array containing the status
                                                ;   update message that will be
                                                ;   output to the serial channel
                                                ;   and displayed on the LED.
                                            
DATA    ENDS

END