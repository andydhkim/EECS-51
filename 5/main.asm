        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MAIN                                   ;
;                           Keypad Function Main Loop                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program contains the main loop for the Keypad Function.
;					It initializes the chip set logic, timers, interrupts, display 
;					variables and the keypad variables. It then calls the KeyTest
;					procedure.                
;
; Input:            None.
; Output:           None.
;
; User Interface:   User has to press down on a key, which will output a hex code
;                   for any enqueued key value along with a repetition count in
;                   decimal to the display. 
; Error Handling:   The user has to test the code by checking the output on the
;					display.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;   11/02/16		Dong Hyun Kim		initial revision
;	11/02/16		Dong Hyun Kim		updated comments



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations
		
		EXTRN	InitDisplay:NEAR			;initialize display variables
		EXTRN	InitKeypad:NEAR				;initialize keypad variables
		EXTRN	InitCS:NEAR					;initialize the 80188 chip selects
		EXTRN	InstallTimer2Handler:NEAR	;install the event handler
		EXTRN	InitTimer2:NEAR				;initialize the internal timer
		EXTRN	ClrIRQVectors:NEAR			;clear (initialize) interrupt vector table
        EXTRN   KeyTest:NEAR				;output a hex code for any enqueued
											;	key value and count in decimal to
											;	the LED display

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

		CALL	InitDisplay				;initialize display variables
		
		CALL	InitKeypad				;initialize keypad variables
		
		CALL	InitCS					;initialize the 80188 chip selects
                                        ;   assumes LCS and UCS already set up
										
		CALL	ClrIRQVectors			;clear (initialize) interrupt vector table
		
		CALL	InstallTimer2Handler	;install the event handler
                                        ;   ALWAYS install handlers before
                                        ;   allowing the hardware to interrupt.
		
		CALL	InitTimer2				;initialize the internal timer
        STI                             ;	and finally allow interrupts.
		
        CALL    KeyTest    		        ;do the appropriate tests
        ;JMP    Forever		            ;go to an infinite loop

Forever: 
		JMP    Forever                 	;sit in an infinite loop, nothing to
                                        ;   do in the background routine
        HLT                             ;never executed (hopefully)



CODE    ENDS
        
        
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

;Empty but needed to initialize DS

DATA    ENDS


;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS


        END     START