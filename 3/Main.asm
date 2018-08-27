        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    MAIN                                    ;
;                          Queues Function Main Loop                         ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program contains the main loop for the Queue Function.
;                   It calls the QueueTest procedure in the hw3test.obj file with
;                   appropriate arguments. It is called with the address of the 
;                   queue for testing in DS:SI and the size of the queue in bytes
;                   in CX. 
;
; Input:            None.
; Output:           None.
;
; User Interface:   No real user interface.  The user can set breakpoints at
;                   QueueGood and QueueError to see if the code is working
;                   or not.
; Error Handling:   If a test fails the program jumps to QueueError.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    10/18/16   Dong Hyun Kim       initial revision
;    10/19/16   Dong Hyun Kim       added an infinite loop
;    10/21/16   Dong Hyun Kim       added values to DS:SI and CX

$INCLUDE(Queues.INC)    ;add the include file with definitions and structure


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations

        EXTRN   QueueTest:NEAR          ;tests the queue functions


START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX
		LEA		SI, testQueue			;move address of queue to SI
		MOV		CX, QUE_LENGTH			;move size of queue (in bytes) to CX

        CALL    QueueTest               ;do the appropriate tests
        JCXZ    QueueGood               ;go to appropriate infinite loop
        ;JMP    QueueError              ;based on return value


QueueError:                             ;a test failed
        JMP     QueueError              ;just sit here until get interrupted


QueueGood:                              ;all tests passed
        JMP     QueueGood               ;just sit here until get interrupted

CODE    ENDS
        
        
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

testQueue   MYQUEUE <>

DATA    ENDS


;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS


        END     START