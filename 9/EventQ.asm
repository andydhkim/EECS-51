	NAME	EventQ
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    EventQ                                  ;
;                          EventQueue Routine Functions                      ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file includes three functions that will be utilized for the
;              EventQueue routines that are used in both the remote and motor unit.
;              It will initialize the EventQueue, and enqueue / dequeue from the
;              EventQueue as necessary.
;
; Table of Contents:
;   InitEventQueue:     Initializes the EventQueue.
;   EnqueueEvent:       Enqueues an event to the EventQueue.
;   DequeueEvent:       Dequeues an event from the EventQueue.		
;
; Revision History:
;   12/02/16    Dong Hyun Kim       initial revision



; local include files
$INCLUDE(Queues.INC)        ;contains definitions for queue routine functions
$INCLUDE(General.INC)       ;contains general definitions



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

        
        
;external function declarations
        EXTRN   QueueInit:NEAR          ;initializes queue of fixed length and
                                        ;   passed element size at passed address
        EXTRN   QueueEmpty:NEAR         ;returns with zero flag set if queue is 
                                        ;   empty, reset otherwise
        EXTRN   QueueFull:NEAR          ;returns with zero flag set if queue is 
                                        ;   full, reset otherwise
        EXTRN   Dequeue:NEAR            ;removes an element from head of queue
        EXTRN   Enqueue:NEAR            ;adds an element to tail of queue at passed
        EXTRN   SetCriticalError:NEAR   ;sets critical error flag to appropriate
                                        ;   value
        EXTRN   GetCriticalError:NEAR   ;obtain the critical error flag setting                                        
        

        
; InitEventQueue
;
; Description:			The function initializes the EventQueue of type MYQUEUE
;                       that will be utilized throughout the activation of the
;                       RoboTrike. It will have an element size of a word since
;                       it needs to able to hold the event type and value in 
;                       separate registers within the accumulator. It also has 
;                       fixed length MAX_LENGTH. The function will reset the 
;                       critical error flag as well since we will not begin with
;                       an error.
;
; Operation:			The function obtains the address of the EventQueue from
;                       the data segment and calls the QueueInit function to 
;                       initialize the queue. It will set the element size to 
;                       WORD_SIZE and utilize a fixed length of MAX_LENGTH. 
;                       Finally, it will set the critical error flag to the
;                       SYSTEM_OK value to indicate that there is no error.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		QueueAddress  (SI) - address of EventQueue.
; Shared Variables:		EventQueue    (DS) - The queue that contains all the 
;                                            RoboTrike events (W).
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
; Registers Changed:	AX, BX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision

InitEventQueue		PROC        NEAR
                    PUBLIC      InitEventQueue                    

EventQueueInit:                             ;initialize the EventQueue
        LEA     SI, EventQueue              ;obtain the address of the EventQueue
                                            ;   from the data segment to prepare
                                            ;   for function call
        MOV     BL, WORD_SIZE               ;set the size of the element in the
                                            ;   queue to word since we need to
                                            ;   store the event type in AH and 
                                            ;   event value in AL
        CALL    QueueInit                   ;initialize the EventQueue        
        ;JMP    EndEventQueueInit
        
EndEventQueueInit:                          ;now, end the function
        RET
             
InitEventQueue      ENDP



; EnqueueEvent
;
; Description:			The function enqueues the event type (AH) and the event
;                       value (AL) into the EventQueue, which has elements that
;                       are the size of words. This allows the system to handle
;                       large amounts of events appropriately, since it can store
;                       them in EventQueue and handle them correctly in the
;                       main files of the RoboTrike. If EventQueue is already
;                       full, the function will set the critical error flag which
;                       alerts the program that it should be restarted and empty
;                       the events in EventQueue.
;
; Operation:			The function initially checks whether or not the EventQueue
;                       is full. If it is, the critical error flag is set and
;                       the function ends immediately. If not, the appropriate
;                       event type and event value is enqueued to EventQueue. It
;                       will then be processed appropriately in the Motor Unit
;                       or the Remote Unit. 
;
; Arguments:			EventType     (AH) - The type of the event.
;                       EventVal      (AL) - The value of the event type.
; Return Value:			None.
;
; Local Variables:		QueueAddress  (SI) - address of EventQueue.
; Shared Variables:		EventQueue    (DS) - The queue that contains all the 
;                                            RoboTrike events (R/W). 
; Global Variables:		None.
;
; Input:				Keypad pressing or information from the serial channel.
; Output:				None.
;
; Error Handling:		When there are more incoming events than the program can
;                       process (that is, when the EventQueue is full), the 
;                       critical error flag is set to alert the system that it 
;                       needs to restart.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, SI, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision

EnqueueEvent		PROC        NEAR
                    PUBLIC      EnqueueEvent                    

CheckSystemError:                           ;see if the system has to restart
        LEA     SI, EventQueue              ;obtain the address of the EventQueue
                                            ;   from the data segment to prepare
                                            ;   for function call
        PUSH    AX                          ;preserve the event since QueueFull
                                            ;   utilizes the AX register
        CALL    QueueFull                   ;check if queue is full
        POP     AX                          ;restore the event back in AX        
        JZ      AlertCriticalError          ;if the queue is full, set the error
                                            ;   flag to alert the system that 
                                            ;   it needs to restart
        ;JNZ    EnqueuePassedEvent
        
EnqueuePassedEvent:                         ;if not, enqueue the event
        CALL    Enqueue                     ;enqueue the event into EventQueue
                                            ;   so it can be handled appropriately
                                            ;   in the main loop
        JMP     EndEnqueueEvent                                            

AlertCriticalError:                         ;set the critical error flag
        MOV     AL, SYSTEM_FAILURE          ;since there the eventQueue is full,
        CALL    SetCriticalError            ;   we must set the critical error
                                            ;   flag and restart the system
       ;JMP     EndEnqueueEvent   

EndEnqueueEvent:                            ;now, end the function
        RET
             
EnqueueEvent        ENDP



; DequeueEvent
;
; Description:			The function dequeues an event from the EventQueue and
;                       stores the event type (AH) and the event value (AL) into
;                       the AX register. This allows the system to remove any
;                       of the events it has already taken care of and handle
;                       the events appropriately in the main files of the RoboTrike.
;                       If the the queue is empty when the function is called,
;                       it will return a NO_EVENT_TYPE in the event type.
;
; Operation:			The function initially checks whether or not the EventQueue
;                       is empty. If it is, the NO_EVENT_TYPE is returned
;                       to AH and the function ends. If not, the appropriate 
;                       event type and event value is dequeued from the EventQueue.
;                       It will then be processed appropriately in the Motor Unit
;                       or the Remote Unit.
;
; Arguments:			None.
; Return Value:			EventType     (AH) - The type of the event.
;                       EventVal      (AL) - The value of the event type.
;
; Local Variables:		QueueAddress  (SI) - address of EventQueue.
; Shared Variables:		EventQueue    (DS) - The queue that contains all the 
;                                            RoboTrike events (R/W). 
; Global Variables:		None.
;
; Input:				Keypad pressing or information from the serial channel.
; Output:				None.
;
; Error Handling:		When the program processes more events than currently
;                       being generated, it will simply return a NO_EVENT_TYPE
;                       as the event type. 
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, SI, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision

DequeueEvent		PROC        NEAR
                    PUBLIC      DequeueEvent                    

CheckNoEvent:                               ;see if system has no event
        LEA     SI, EventQueue              ;obtain the address of the EventQueue
                                            ;   from the data segment to prepare
                                            ;   for function call
        CALL    QueueEmpty                  ;check if queue is empty     
        JZ      SetNoEventValue             ;if the queue is empty, set the event
                                            ;   type as NO_EVENT_TYPE
        ;JNZ    EnqueuePassedEvent
        
DequeuePassedEvent:                         ;if not, enqueue the event
        CALL    Dequeue                     ;dequeue the event from EventQueue
                                            ;   so it can be handled appropriately
                                            ;   in the main loop
        JMP     EndDequeueEvent                                            

SetNoEventValue:                            
        MOV     AH, NO_EVENT_TYPE           ;set event type as NO_EVENT_TYPE
       ;JMP     EndEnqueueEvent   

EndDequeueEvent:                            ;now, end the function
        RET
             
DequeueEvent        ENDP


CODE    ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

EventQueue		MYQUEUE <>  			    ;Queue that contains all of the 
                                            ;   events that occurred throughout
                                            ;   the operation of the RoboTrike,
                                            ;   will be of type MYQUEUE, which 
                                            ;   is described more in depth in
                                            ;   the Queues Routine Functions
                                            ;   Include File above.
                                            
DATA    ENDS

END