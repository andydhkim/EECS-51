        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MAIN                                   ;
;                         Serial Parsing Routines Main Loop                  ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program contains the main loop for the serial parsing
;					routines of the RoboTrike. It initializes the parsing code
;					and then calls the ParseTest procedure.
;
; Input:            Information from the 16C450 Serial I/O Line.
; Output:           Activation of RoboTrike.
;
; User Interface:   User can set a breakpoint at ParseDone, CompareOK or MisCompare.
;					Each time one of these breakpoints have been reached a test
;					has been completed. Alternatively, a breakpoint can be set at
;					DoParse and the BX register can be set to point to a command
;					string buffer. 
; Error Handling:   The user will have to have to go through each test and see 
;					if passed or failed.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;   11/23/16		Dong Hyun Kim		initial revision



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations
		
		EXTRN	InitParser:NEAR			;initialize the parsing variables
		EXTRN	ParseTest:NEAR			;calls a series of different test calls

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX	
        
		CALL	InitParser				;initialize the parsing variables
		
        CALL    ParseTest               ;runs the appropriate test
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