	NAME	SRIALSTR
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   SRIALSTR                                 ;
;                           SerialPutString Function                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file includes a single function that will be output a string
;              to the serial channel.
;
; Table of Contents:
;   SerialPutString:    Output a string to the serial channel.		
;
; Revision History:
;   12/02/16    Dong Hyun Kim       initial revision


; local include files
$INCLUDE(General.INC)       ;contains general definitions



CGROUP	GROUP	CODE

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP


;external function declarations
        EXTRN   SerialPutChar:NEAR          ;output a char to the serial channel
        EXTRN   EnqueueEvent:NEAR           ;enqueue event to EventQueue
        
        
        
; SerialPutString
;
; Description:			The function outputs a string into the serial channel by
;                       calling the SerialPutChar function repeatedly while
;                       going through the string one character at a time. It ends
;                       with the carriage return value to indicate that the 
;                       string has been completely sent over to the serial 
;                       channel. If there is an error, it will enqueue a ERROR_EVENT_TYPE
;                       as the event type and STRING_OUTPUT_ERROR as the event
;                       value to the EventQueue.
;
; Operation:			The function initially checks if the it has reached the
;                       ASCII_NULL character. If it has, it adds a carriage 
;                       return to the end of the string and exists the function.
;                       If not, it continually iterates the string by calling the
;                       SerialPutChar function and outputting one character at a
;                       time to the serial channel. If there is ever an error 
;                       while outputting the string, it will enqueue ERROR_EVENT_TYPE
;                       and STRING_OUTPUT_ERROR and exit the function.
;
; Arguments:			StrAddr (ES:SI) - the address of the passed down string
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		None.
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		Enqueues ERROR_EVENT_TYPE and STRING_OUTPUT_ERROR to 
;                       EventQueue if there is ever an error. 
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, SI, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        We use ES:SI instead of DS:SI so the string can be in the
;                       code segment without needing to change to DS, which can
;                       cause many problems.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision

SerialPutString     PROC        NEAR
                    PUBLIC      SerialPutString        

SerialPutStringLoop:                            ;iterate through the string
        CMP     BYTE PTR ES:[SI], ASCII_NULL    ;if the string has reached the 
        JE      SendCarriageReturn              ;   end, alert serial channel that
                                                ;   message has been fully sent
        ;JNE    CallSerialPutChar
        
CallSerialPutChar:                              ;if not, call the appropriate function
        MOV     AL, BYTE PTR ES:[SI]            ;move the character from the string
                                                ;   to the AL register to prepare
                                                ;   for function call
        PUSH    SI                              ;preserve value of the address since
                                                ;   the function uses SI
        CALL    SerialPutChar                   ;output a character to the serial
                                                ;   channel
        POP     SI                              ;restore the address value 
        INC     SI                              ;if there is no error (if the
        JNC     SerialPutStringLoop             ;   TxQueue) is not full, we can
                                                ;   continue to go through the
                                                ;   string without issues  
        ;JC     HandlePutStringError

HandlePutStringError:                           ;if there is an error, handle it
                                                ;   appropriately
        MOV     AH, ERROR_EVENT_TYPE            ;set event type to alert user that
                                                ;   it is an error
        MOV     AL, STRING_OUTPUT_ERROR         ;set event value to alert user that
                                                ;   it is a string output error
        CALL    EnqueueEvent                    ;enqueue the appropriate event
                                                ;   type and value to EventQueue
                                                ;   to utilize in the future
        ;JMP    SendCarriageReturn                                                

SendCarriageReturn:                             ;output a carriage return
        MOV     AL, CARRIAGE_RETURN             ;tell the serial channel that the
        CALL    SerialPutChar                   ;   full message has been output
                                                ;   by sending a carriage return
                                                ;   character
        ;JMP    EndSerialPutString
    
EndSerialPutString:                             ;now, end the function
        RET
                            
SerialPutString     ENDP


CODE    ENDS

END