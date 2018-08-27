        NAME    QUEUES

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    QUEUES                                  ;
;                               Queue Functions                          	 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:	This file includes five queue functions used for RoboTrike. It
;               can initialize a queue, remove a value from the queue, or add
;               a value to the queue. It can also check if the queue is empty
;               or if it is full. All functions require a passed address in SI.
;
; Table of Contents:
;	QueueInit:  Initializes the queue of fixed length and passed element size at 
;               the passed address. 
;	QueueEmpty: Returns with the zero flag set if the queue is empty and with 
;               the zero flag reset otherwise.
;	QueueFull:  Returns with the zero flag set if the queue is full and with the 
;               zero flag reset otherwise.
;	Dequeue:    Removes either an 8 or 16-bit value (depending on the queue's 
;               element size) from the head of the queue at the passed address 
;               and returns it in AL or AX. Blocking occurs if queue is empty.
;	Enqueue:    Adds the passed 8 or 16-bit value to the tail of the queue at 
;               the passed address. Blocking occurs if queue is full.
;
; Revision History:
;     01/26/06  Glen George      initial revision
;	  10/16/16  Dong Hyun Kim    added functional specification
;     10/18/16  Dong Hyun Kim    updated comments
;     10/20/16  Dong Hyun Kim    added code for the five functions

$INCLUDE(Queues.INC)    ;add the include file with definitions and structure



CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP




; QueueInit
;
; Description:			This function initializes the queue of fixed length and
;						passed element size at the passed address. It does all the
;						necessary initialization to prepare the queue for use. 
;						After calling the function, the queue will be empty and
;						ready to accept values. The length, MAX_LENGTH, is the 
;                       maximum number of items that can be stored in the queue. 
;                       The passed element size specifies whether each entry in 
;                       the queue is a byte or a word. If the element size is true
;						(non-zero) the elements are words and if its false (zero)
;						they are bytes. The address is passed in SI by value (thus
;						the queue starts at DS:SI), the length is passed by value
;						in AX, and the element size is passed by value in BL. The
;                       length is ignored since the file uses a fixed length.
;
; Operation:			The include file defines a queue through a structure. 
;                       The function will then initialize a circular queue at the
;                       passed address. It will set the index of the first element 
;                       (head), index of the next open space after the last 
;                       element (tail) and the size of the element (either 
;                       BYTE_SIZE or WORD_SIZE). If size is 0, the queue will 
;                       allocate 8-bits per element; otherwise, the queue will 
;                       allocate 16-bits per element. The index of the head and 
;                       tail will be set to 0 form a circular queue.
;
; Arguments:			a (SI)	- address with memory location to start queue.
;						l (AX)	- length of the queue.
;						s (BL)	- element size.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		a.ele_size (SI) - defines whether the element is a byte or
;                                         a word (R/W).
;						a.head (SI)     - index of the first element (R/W).
;						a.tail (SI)     - index of the next open space after the 
;                                         last element (R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	Flags.
; Limitations:			Length of the queue is fixed. Size of array has to be 
;                       power of 2.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     10/18/16    Dong Hyun Kim       initial revision
;                       10/19/16    Dong Hyun Kim       added initial code
;                       10/20/16    Dong Hyun Kim       debug and commented

QueueInit		PROC        NEAR
                PUBLIC      QueueInit

QueueDefine:                              ;initialization
        MOV     [SI].head, 0              ;set index of head to 0 
        MOV     [SI].tail, 0              ;set index of tail to 0 
        CMP     BL, 0                     ;check if passed element size is = 0
        JNZ     SizeWord                  ;if s != 0, size of element is 2 byte
        ;JZ     SizeByte                  ;if s  = 0, size of element is 1 byte
        
SizeByte:                                 ;size of element is 1 byte
        MOV     [SI].ele_size, BYTE_SIZE  ;set size of element to 1 byte
        JMP     EndQueueInit              ;done with initializing the queue

SizeWord:                                 ;size of element is 2 byte
        MOV     [SI].ele_size, WORD_SIZE  ;set size of element to 2 bytes
        ;JMP    EndQueueInit              ;done with initializing the queue
        
EndQueueInit:                             ;end the function
        RET

QueueInit	ENDP




; QueueEmpty
;
; Description:			The function is called with the address of the queue to be
;						checked. It returns with the zero flag set if the queue is
;						empty and with the zero flag reset otherwise. The address
;						is passed in SI by value (thus the queue starts at DS:SI).
;
; Operation:			The function will compare the index of the head and the index
;						of the tail. If the two are equal, the queue is empty.			
;
; Arguments:			a (SI)	    - address of queue to be checked.
; Return Value:			ZF		    - set to 1 if queue is empty, 0 otherwise.
;
; Local Variables:		h (AX)      - stored index of head (R/W).
; Shared Variables:		a.head (SI) - index of the first element (R).
;						a.tail (SI)	- index of the next open space after the
;                                     last element (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, flags.
; Limitations:			Length of the queue is fixed. Size of queue has to be 
;                       power of 2.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     10/18/16    Dong Hyun Kim       initial revision
;                       10/19/16    Dong Hyun Kim       added initial code
;                       10/20/16    Dong Hyun Kim       debug and commented

QueueEmpty      PROC        NEAR
                PUBLIC      QueueEmpty

QueueEmptyInit:                         ;initialization
        MOV     AX, [SI].head           ;store index of head in h (AX)
        ;JMP    CheckIfEmpty            ;now, compare index of head with tail
        
CheckIfEmpty:                           ;determine if queue is empty
        CMP     AX, [SI].tail           ;check if index of head == index of tail
        ;JMP    EndQueueEmpty           ;if equal, set zero flag to 1
        
EndQueueEmpty:                          ;end the function
        RET

QueueEmpty	ENDP




; QueueFull
;
; Description:			The function is called with the address of the queue to be
;						checked. It returns with the zero flag set if the queue is
;						full and with the zero flag reset otherwise. The address
;						is passed in SI by value (thus the queue starts at DS:SI).
;
; Operation:			The function will compare (1) the index of the first element
;						with (2) (the index of the open space after the last element
;						+ the size of the element) mod (length of the queue). This
;                       will essentially check to see if the index of the head is
;                       equal to the index of the tail after adding the size and 
;                       looping around the circular queue. If they are equal, 
;                       the queue is full.
;
; Arguments:			a (SI)	- address of queue to be checked.
; Return Value:			ZF		- set to 1 if queue is full, 0 otherwise.
;
; Local Variables:		t (AX)          - stored index of (tail + size) (R).
; Shared Variables:		a.head     (SI) - index of the first element (R).
;						a.tail 	   (SI) - index of the next open space after the 
;                                         last element (R).
;						a.ele_size (SI) - defines whether the element is a byte or
;                                         a word (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, flags.
; Limitations:			Length of the queue is fixed. Size of queue has to be 
;                       power of 2.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     10/18/16    Dong Hyun Kim       initial revision
;                       10/19/16    Dong Hyun Kim       added initial code
;                       10/20/16    Dong Hyun Kim       debug and commented

QueueFull		PROC        NEAR
                PUBLIC      QueueFull

QueueFullInit:                          ;initialization
        MOV     AX, [SI].tail           ;store index of tail in t (AX)
                
CheckIfFull:                            ;determine if queue is full
        ADD     AX, [SI].ele_size       ;add BYTE_SIZE to t if byte, WORD_SIZE
                                        ;to t if word
        AND     AX, QUE_LENGTH          ;t (AX) = t (AX) mod QUE_LENGTH
        CMP     AX, [SI].head           ;check if index of head == ((index of tail
                                        ;+ size) mod QUE_LENGTH)
        ;JMP    EndQueueFull            ;if equal, set zero flag to 1
        
EndQueueFull:                           ;end the function
        RET 

QueueFull	ENDP




; Dequeue
;
; Description:			The function removes either an 8 or 16-bit value (depending
;						on the queue's element size) from the head of the queue at
;						the passed address and returns it in AL or AX. The value
;						is returned in AL if the element size is bytes and in AX
;						if it is words. If the queue is empty it blocks until the
;						queue has a value to be removed and returned. It does not
;						return until a value is taken from the queue. The address
;						is passed in SI by value (thus the queue starts at DS:SI).
;
; Operation:			The function initially starts off by setting the value of 
;						the head equal to a temporary variable called value. The
;						index of the head is then updated by adding the previous 
;						index of the head with the size and performing a modulo
;						operation with the length. This will set the index of the 
;						head to the next element. If the queue is empty, the 
;                       function will jump within a loop until the queue has a
;                       value to be removed and returned. 
;
; Arguments:			a (SI)	    - address of queue to be checked.
; Return Value:			v (AL/AX)   - value at head of queue. AL if element 
;                                     size is bytes, AX if words.
;
; Local Variables:		v (AL/AX)         - the value of the head before it is 
;                                           removed (R/W).
;                       h (BX)            - stored index of head (R/W).
; Shared Variables:		a.head	   (SI)   - index of the first element (R/W).
;						a.ele_size (SI)   - defines whether the element is a byte
;                                           or a word (R).
;                       a.array    (SI)   - array including the queue's data(R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AL/AX, BX, flags.
; Limitations:			Length of the queue is fixed. Size of queue has to be 
;                       power of 2.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     10/18/16    Dong Hyun Kim       initial revision
;                       10/19/16    Dong Hyun Kim       added initial code
;                       10/20/16    Dong Hyun Kim       debug and commented

Dequeue	        PROC        NEAR
                PUBLIC      Dequeue
   
CheckQueueEmpty:                        ;blocks function if queue is empty
        CALL    QueueEmpty              ;checks if queue is empty
        JZ      CheckQueueEmpty         ;if it is empty, keep looping until it isn't 
        ;JNZ    DequeueInit             ;if is not empty, remove the first element
		
DequeueInit:                            ;initialization
        MOV     BX, [SI].head           ;store index of head in h (BX)
        ;JMP    CheckEleSize            ;now, check size of first element

CheckEleSize:                           ;determine size of element to be removed
        CMP     [SI].ele_size,WORD_SIZE ;check if size of element is BYTE_SIZE 
                                        ;or WORD_SIZE
        JE      DequeueWord             ;if WORD_SIZE, dequeue a word
        ;JNE    DequeueByte             ;if BYTE_SIZE, dequeue a byte

DequeueByte:                            ;prepare value to return (byte)
        MOV     AL, [SI + BX].array     ;store value of head in v (AL)
        JMP     DequeueEle              ;now, remove element from queue

DequeueWord:                            ;prepare value to return (word)
        MOV     AL, [SI + BX].array     ;store first half of value of head in v (AL)
        INC     BX                      ;increment index of head for next value
        MOV     AH, [SI + BX].array     ;store later half of value of head in v (AH)
		DEC		BX						;reset the index of head
        ;JMP    DequeueEle              ;now, take care of index of head

DequeueEle:                             ;modify the index of head
		ADD     BX, [SI].ele_size       ;add BYTE_SIZE to h if byte, WORD_SIZE 
                                        ;if word
        AND     BX, QUE_LENGTH          ;h (BX) = h (BX) mod QUE_LENGTH
        MOV     [SI].head, BX           ;store the new index of head
        ;JMP    EndDequeue              ;the index of head is now updated
        
EndDequeue:                             ;end the function
        RET

Dequeue		ENDP




; Enqueue
;
; Description:			This function adds the passed 8 or 16-bit value to the tail
;						of the queue at the passed address. If the queue is full it
;						waits until the queue has an open space in which to add the
;						value. It does not return until the value is added to the 
;						queue. The address is passed in SI by value (thus the queue
;						starts at DS:SI) and the value to enqueue is passed by value
;						in AL if the element size for the queue is bytes and in AX
;						if it is words.
;
; Operation:			The function sets the value of tail equal to v. The index
;						of the tail is reset by adding the index of the tail with
;						the size and performing a modulo operation with the length.
;						This will set the index of the tail to the next open space.
;                       If the queue is full, it will jump within a loop until
;                       the queue has an open space in which to add the value.
;
; Arguments:			a (SI)		- address of queue to be checked.
;						v (AL/AX) 	- value to be added to the queue. AL if element
;									  size is bytes, AX if words.
; Return Value:			None.
;
; Local Variables:		t (BX)            - stored index of tail (R/W).
; Shared Variables:		a.tail 	   (SI) - index of the next open space after the 
;                                         last element (R/W).
;						a.ele_size (SI) - defines whether the element is a byte
;                                         or a word (R).
;                       a.array    (SI)   - array including the queue's data(R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, BX, flags.
; Limitations:			Length of the queue is fixed. Size of queue has to be 
;                       power of 2.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     10/18/16    Dong Hyun Kim       initial revision
;                       10/19/16    Dong Hyun Kim       added initial code
;                       10/20/16    Dong Hyun Kim       debug and commented

Enqueue	        PROC        NEAR
                PUBLIC      Enqueue

EnqueueInit:							;initialization
		PUSH	AX						;store AX in stack for later use
		;JMP	CheckQueueFull			;check if queue is full
				
CheckQueueFull:                         ;blocks function if queue is full
        CALL    QueueFull               ;checks if queue is full
        JZ      CheckQueueFull          ;if it is full, keep looping until it isn't 
        ;JNZ    CheckEnqueueInit        ;if is not empty, add the element
		
CheckValueSize:                         ;determine size of value to be added
		POP		AX						;restore AX back to its original value
        MOV     BX, [SI].tail           ;store index of tail in t (BX)
        CMP     [SI].ele_size,WORD_SIZE ;check if size of value is BYTE_SIZE or 
                                        ;WORD_SIZE
        JE      StoreWord               ;if WORD_SIZE, enqueue a word
        ;JNE    StoreByte               ;if BYTE_SIZE, enqueue a byte

StoreByte:                              ;prepare to store value (byte)
        MOV     [SI + BX].array, AL     ;set v (AL) as the value of tail
        JMP     EnqueueEle              ;now, take care of index of tail

StoreWord:                              ;prepare to store value (word)
        MOV     [SI + BX].array, AL     ;store first half of v in value of tail (AL)
        INC     BX                      ;increment index of tail for next value
        MOV     [SI + BX].array, AH     ;store later half of v in value of tail (AH)
		DEC		BX						;reset the index of tail
        ;JMP    EnqueueEle              ;now, take care of index of tail

EnqueueEle:                             ;modify the index of tail
        ADD     BX, [SI].ele_size       ;add 1 to t if byte, 2 if word
        AND     BX, QUE_LENGTH          ;t (BX) = t (BX) mod QUE_LENGTH
        MOV     [SI].tail, BX           ;store the new index of tail
        ;JMP    EndEnqueue              ;the index of tail is now updated
        
EndEnqueue:                             ;end the function
        RET

Enqueue		ENDP




CODE    ENDS



        END