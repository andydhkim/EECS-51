        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MAIN                                   ;
;                            Motor Routines Main Loop                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program contains the main loop for the Serial I/O Routines.
;					It initializes the chip set logic, the 16C450 serial I/O line,
;                   INT2, interrupts, and the serial I/O variables. It then allows
;                   the hardware to interrupt and calls the SerialIOTest procedure,
;                   which the user can use to test the serial I/O routine functions.
;
; Input:            Information from the 16C450 Serial I/O Line.
; Output:           Information to the 16C450 Serial I/O Line.
;
; User Interface:   The test code will output a certain string 100 times, each 
;                   with a count of the iteration number. It will also echo background
;                   any code sent to the serial line back 100 times. 
; Error Handling:   If the code does not work properly, the serial I/O terminal
;                   will display a lot of broken characters that are incomprehensible
;                   by most users.
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
		EXTRN	InitINT2:NEAR			    ;initialize the INT2 interrupt
		EXTRN	InstallINT2Handler:NEAR	    ;install the event handler
        EXTRN   InitSerial:NEAR             ;initialize the 16C450 and serial I/O 
                                            ;   variables
        EXTRN   SerialPutChar:NEAR          ;Outputs a passed character into the 
                                            ;   serial channel.                                            
		EXTRN	ClrIRQVectors:NEAR			;clear (initialize) interrupt vector table
        EXTRN   SerialIOTest:NEAR			;calls a series of different test calls

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX	
        
		CALL	InitCS					;initialize the 80188 chip selects
                                        ;   assumes LCS and UCS already set up                                      
                                        
        CALL    InitSerial              ;initializes the 16C450 and serial I/O 
                                        ;   variables                                            
										
		CALL	ClrIRQVectors			;clear (initialize) interrupt vector table
		
		CALL	InstallINT2Handler	    ;install the event handler
                                        ;   ALWAYS install handlers before
                                        ;   allowing the hardware to interrupt.
		
		CALL	InitINT2				;initialize the INT2 interrupt
        STI                             ;	and finally allow interrupts.
		
        CALL    SerialIOTest            ;do the appropriate tests
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