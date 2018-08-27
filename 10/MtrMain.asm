        NAME    MTRMAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   MTRMAIN                                  ;
;                             Motor Unit Main File                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program is the main file for the motor unit of the 
;                   RoboTrike. Please refer to the RoboTrike_Motor_Unit_
;                   Functional_Specification.docx for more in depth information
;                   regarding the motor unit.
;
; Revision History:
;	12/08/16		Dong Hyun Kim			initial revision



; local include files
$INCLUDE(General.INC)                       ;add general definitions  
$INCLUDE(MtrFuncs.INC)						;contains definitions and addresses 
											;	for parsing
                                          



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations		
        EXTRN   GetCriticalError:NEAR       ;obtain the critical error flag
        EXTRN   DequeueEvent:NEAR           ;dequeue event from EventQueue
        EXTRN   InitMotorMainLoop:NEAR      ;initialize necessary variables for
                                            ;   motor main loop
        EXTRN   NoEvent:NEAR                ;do nothing, since there is no event
		EXTRN	ParseSerialChar:NEAR		;parse the appropriate command
        EXTRN   SerialErrorEvent:NEAR       ;serial error occurred during operation
		EXTRN	ParseErrorEvent:NEAR		;parsing error occurred during operation
        
        

; Main
;
; Description:			This is the main loop of the motor unit of the RoboTrike.
;                       It will initialize all of the necessary components of the
;                       code (variables, registers values, etc.) and enter an 
;                       infinite loop that checks the critical error flag. If it
;                       is set, it will restart the entire system by reinitializing
;                       the components. If it is not set, it will dequeue an 
;                       event from the eventqueue and handle it appropriately
;                       by calling the appropriate function within the file 
;                       through a jump table. It will then check for a motor unit
;						error. If one exists, it will handle it appropriately by
;						outputting an error message to the serial channel.
;
; Operation:			The main loop starts off by initializing the entire code
;                       by calling the necessary initialization functions. The
;                       critical error flag will then set to SYSTEM_OK and the
;                       main loop enters an infinite loop. Within the loop it
;                       will check if there is any critical error. If there is
;                       an error, the system will reinitialize the entire 
;                       system by going through the initialization functions 
;                       again. If there is no error, it will dequeue an event
;                       from the EventQueue and utilize its value to call the 
;                       appropriate helper function. It will then check for a motor 
;						unit error. If one exists, it will call the ParseErrorEvent
;						and handle it appropriately.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		None.
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		Restarts the system if the critical error flag is set
;						and outputs a error message if there is a motor unit 
;						error.
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

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX	
        
InitializeMotorLoop:                  
     
		CALL    InitMotorMainLoop       ;initialize the variables necessary for  
                                        ;   remote main loop
        ;JMP    CheckCrticalError

CheckCriticalError:                     ;check for critical error within the system
        CALL    GetCriticalError        ;obtain the critical error setting
        CMP     AL, SYSTEM_FAILURE      ;if there is a critical error, reset the
        JE      InitializeMotorLoop     ;   system by reinitializing the motor
                                        ;   unit 
        ;JNE    HandleEvent

HandleEvent:                            ;handle the appropriate event
        CALL    DequeueEvent            ;obtain the next event to handle from the
                                        ;   EventQueue
        XOR     BX, BX                  ;prepare the BX register to index through
                                        ;   a word array
        MOV     BL, AH                  ;use the event type to determine which 
        SHL     BX, 1                   ;   function to call and handle the 
                                        ;   event uniquely
        CALL    CS:MotorEventTable[BX]  ;call the appropriate helper function
                                        ;   and take care of the event
		;JMP	CheckMotorError
		
CheckMotorError:						;check if there was a motor error 
		CMP		AX, MOTOR_FAILURE		;if there was no error, continue to 
		JNE		ContinueMotorOp			;	operate the motor unit
		;JE		HandleMotorError
		
HandleMotorError:						;if there was a motor failure, call the
										;	appropriate function
		CALL	ParseErrorEvent			;write and output the appropriate error
										;	message to the serial channel
		;JMP	ContinueMotorOp
		
ContinueMotorOp:						;continue to operate the motor unit									
		JMP		CheckCriticalError		;if there is no error, continue to loop
										;	and handle the events unless there
										;	is a critical error
 
        
; MotorEventTable
;
; Description:          This is the table that contains the helper functions of
;                       the motor unit main loop. After checking the event value,
;                       the motor loop indexes through the RemoteEventTable and
;                       calls the appropriate function. This allows the motor
;                       unit to handle the event in a unique fashion and operate
;                       the RoboTrike correctly.
;
; Author:               Dong Hyun Kim
; Last Modified:        12/08/16

MotorEventTable		LABEL       WORD
        DW      NoEvent                     ;do nothing
        DW      NoEvent						;key was pressed on the keypad        
        DW      ParseSerialChar             ;data was received from serial channel  
        DW      SerialErrorEvent            ;there was a serial error
   
        
        
CODE    ENDS
        

        
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

;empty, but it is needed to initialize the DGROUP

DATA    ENDS


;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS


        END     START