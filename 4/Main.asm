        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MAIN                                   ;
;                          Display Function Main Loop                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program contains the main loop for the Display Function.
;					It initializes the chip set logic, timers, interrupts and 
;					the display code then calls the DisplayTest procedure.                
;
; Input:            None.
; Output:           None.
;
; User Interface:   No real user interface.  The DisplayTest initially displays 
;                   a series of strings for 3 seconds. The user can set breakpoints 
;                   at HexDisplay and DecimalDisplay to see if the code is working
;                   or not.
; Error Handling:   The user has to test the code by setting breakpoints before
;					the calls to DisplayHex and DisplayNum and putting appropriate
;					test values in AX.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;   10/27/16    Dong Hyun Kim       initial revision
;   10/28/16    Dong Hyun Kim       debugged and updated comments



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations
		
		EXTRN	InitDisplay:NEAR		
		EXTRN	InitCS:NEAR				
		EXTRN	InstallTimer2Handler:NEAR
		EXTRN	InitTimer2:NEAR	
		EXTRN	ClrIRQVectors:NEAR
        EXTRN   DisplayTest:NEAR

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

		CALL	InitDisplay				;initialize display variables
		
		CALL	InitCS					;initialize the 80188 chip selects
                                        ;   assumes LCS and UCS already set up
										
		CALL	ClrIRQVectors			;clear (initialize) interrupt vector table
		
		CALL	InstallTimer2Handler	;install the event handler
                                        ;   ALWAYS install handlers before
                                        ;   allowing the hardware to interrupt.
		
		CALL	InitTimer2				;initialize the internal timer
        STI                             ;	and finally allow interrupts.
		
        CALL    DisplayTest             ;do the appropriate tests
        ;JMP    Forever		            ;go to an infinite loop

Forever: 
		JMP    Forever                 	;sit in an infinite loop, nothing to
                                        ;   do in the background routine
        HLT                             ;never executed (hopefully)



CODE    ENDS
        
        
;the data segment (empty for the main loop)

DATA    SEGMENT PUBLIC  'DATA'

DATA    ENDS


;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS


        END     START