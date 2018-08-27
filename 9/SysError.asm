	NAME	SYSERROR
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   SYSERROR                                 ;
;                         System Error Handler Functions                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file includes two functions that will be utilized to handle
;              the system errors appropriately. It can set the critical error
;              flag to alert the system of an error, or it can obtain the 
;              current error setting of the system.
;
; Table of Contents:
;   SetCriticalError:   Sets the critical error flag to the appropriate value.
;   GetCriticalError:   Gets the error flag setting from the system.
		
;
; Revision History:
;   12/02/16    Dong Hyun Kim       initial revision



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

        
        
; SetCriticalError
;
; Description:			The function is passed a single argument (error) in AX
;                       that indicates whether there is a critical error in the
;                       system or not. The SYSTEM_OK value indicates no error,
;                       while the SYSTEM_FAILURE value indicates that there is
;                       an error. Specifically, the flag is set to SYSTEM_FAILURE 
;                       whenever the EventQueue is full and is unable to accept 
;                       any more events.
;
; Operation:			This function simply moves a copy of error (AX) into
;                       CriticalError, a shared variable in the data segment.
;
; Arguments:			error         (AL) - value indicating whether or not
;                                            there is an error.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CriticalError (DS) - Value indicating whether or not there
;                                            is an error. SYSTEM_OK denotes no
;                                            error, while SYSTEM_FAILURE denotes
;                                            an error (W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		Sets CriticalError is there is an error.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision

SetCriticalError    PROC        NEAR
                    PUBLIC      SetCriticalError                    

        MOV     CriticalError, AL               ;set the value of CriticalError
                                                ;   as indicated by the value
                                                ;   passed down from AL
        RET                                     ;now, we are done        
                    
SetCriticalError    ENDP



; GetCriticalError
;
; Description:			The function returns the critical error setting of the 
;                       system back in AX. The SYSTEM_OK value indicates no error,
;                       while the SYSTEM_FAILURE value indicates that there is
;                       an error. Specifically, the flag is set to SYSTEM_FAILURE 
;                       whenever the EventQueue is full and is unable to accept 
;                       any more events. 
;
; Operation:			This function simply moves a copy of the shared variable,
;                       CriticalError, into the AX register. 
;
; Arguments:			None.
; Return Value:			error         (AL) - value indicating whether or not
;                                            there is an error.
;
; Local Variables:		None.
; Shared Variables:		CriticalError (DS) - Value indicating whether or not there
;                                            is an error. SYSTEM_OK denotes no
;                                            error, while SYSTEM_FAILURE denotes
;                                            an error (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision

GetCriticalError    PROC        NEAR
                    PUBLIC      GetCriticalError                    

        MOV     AL, CriticalError               ;set the value of CriticalError
                                                ;   as indicated by the value
                                                ;   passed down from AX
        RET                                     ;now, we are done        
                    
GetCriticalError    ENDP



CODE    ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

CriticalError   DB      ?                   ;Value that determines whether or not
                                            ;   there was a critical error while
                                            ;   the program was running. It is
                                            ;   set whenever the EventQueue is
                                            ;   full and no more events can be
                                            ;   enqueued correctly. If there is
                                            ;   an error, it will be of value
                                            ;   SYSTEM_FAILURE. Any other value
                                            ;   indicates that there is no error,
                                            ;   although SYSTEM_OK will be used 
                                            ;   for most operations.
                                            
DATA    ENDS

END