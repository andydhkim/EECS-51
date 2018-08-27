        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MAIN                                   ;
;                            Motor Routines Main Loop                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program contains the main loop for the Motor Routines.
;					It initializes the chip set logic, parellel I/O ports,
;                   Timer 2, interrupts, and the motor variables. It then allows
;                   the hardware to interrupt and calls the MotorTest procedure,
;                   which the user can use to test the motor routine functions.
;
; Input:            None.
; Output:           Port B of the 8255A, which will activate DC motors and laser.
;
; User Interface:   User has to press one key at a time to run through the test
;                   code correctly. When the last test is done (last call is 
;                   made), the testing restarts with the first call.
; Error Handling:   The user has to test the code by setting breakpoints at 
;                   functions and checking the contents of arrays. The user can 
;                   also use the Parallel Port Test Board to check if the output
;                   to Port B of the 8255A is correct.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;   11/09/16		Dong Hyun Kim		initial revision



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations
		
		EXTRN	InitCS:NEAR					;initialize the 80188 chip selects
		EXTRN	InitPP:NEAR					;initialize the 8255A
		EXTRN	InstallTimer2Handler:NEAR	;install the event handler
		EXTRN	InitTimer2:NEAR				;initialize the internal timer
        EXTRN   InitMotor:NEAR              ;initialize the motor variables
        EXTRN   SetMotorSpeed:NEAR          ;sets RoboTrike's speed and direction.
		EXTRN	ClrIRQVectors:NEAR			;clear (initialize) interrupt vector table
        EXTRN   MotorTest:NEAR				;calls a series of different test calls

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX	
        
		CALL	InitCS					;initialize the 80188 chip selects
                                        ;   assumes LCS and UCS already set up
                                        
		CALL	InitPP					;initialize the 8255A by setting correct
										;	value in control register
                                        
        CALL    InitMotor               ;initializes the motor variables                                            
										
		CALL	ClrIRQVectors			;clear (initialize) interrupt vector table
		
		CALL	InstallTimer2Handler	;install the event handler
                                        ;   ALWAYS install handlers before
                                        ;   allowing the hardware to interrupt.
		
		CALL	InitTimer2				;initialize the internal timer
        STI                             ;	and finally allow interrupts.
		
        CALL    MotorTest  		        ;do the appropriate tests
        ;JMP    Forever		            ;go to an infinite loop

Forever: 
		JMP    Forever                 	;sit in an infinite loop, nothing to
                                        ;   do in the background routine
        HLT                             ;never executed (hopefully)



CODE    ENDS
        
        
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

;Empty but needed to initialize DGROUP

DATA    ENDS


;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS


        END     START