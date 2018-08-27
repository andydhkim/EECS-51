;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  QUEUES.INC                                ;
;                               Queue Functions                          	 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Queues Program (Queues.asm).
;
; Revision History:
;	  10/18/16  Dong Hyun Kim    initial revision
;     10/21/16  Dong Hyun Kim    added struct and definitions
;     10/21/16  Dong Hyun Kim    added new magic numbers as definitions
;	  12/01/16	Dong Hyun Kim	 changed definiton of QUE_LENGTH

; Definitions
MAX_LENGTH      EQU     128           	;Length of the array used for the queue.
QUE_LENGTH      EQU     MAX_LENGTH - 1	;Length of the queue. It is also used when
										;performing modulo operations within the 
										;Queue.asm file. It is one less than the 
										;actual length of the array because the index
										;of the tail points to th enext open space
										;of the queue. 

; Defines the queue
MYQUEUE         STRUC                       
    head        DW      ?           	;Index of head of queue.
    tail        DW      ?           	;Index of tail of queue.
    ele_size    DW      ?           	;Size of the element in the queue. Although
										;this value can fit within a byte, a word
										;was used because it is easier to add to
										;the head and tail.
    array       DB      MAX_LENGTH      DUP (?) ;the array with necessary data                                                
 MYQUEUE        ENDS