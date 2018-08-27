      NAME  InitPP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    InitPP                                  ;
;                       Initialize Parallel I/O Function                     ;
;									EE/CS 51								 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: 	This file includes a single function, InitPP, that initializes 
;              	the parallel I/O control register on the 8255A. 
;
; Table of Contents:
;   InitPP:	   	Sets the initialization value for the the 8255A.
;
; Revision History:
;   11/09/16    Dong Hyun Kim       initial revision



; local include files
$INCLUDE(InitPP.INC)				;add include file with addresses and values



CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP
		
		
		

; InitPP
;
; Description:			This function sets the initialization value for the 
;						8255A and implements the parallel I/O. It sets both Group
;						A and B to Mode 0, and sets all ports to outputs.
;
; Operation:			Write the initial values (PPval) to the 8255A control
;						register (PPreg).
;
; Arguments:            None.
; Return Value:         None.
;
; Local Variables:      None.
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           None.
; Data Structures:      None.
;
; Registers Changed:    AX, DX.
; Limitations:          None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/09/16    Dong Hyun Kim   initial revision

InitPP  PROC    NEAR
        PUBLIC  InitPP

		MOV     DX, PPCtrlREg   ;setup to write to 82C55A control register
        MOV     AX, PPCtrlRegInit
        OUT     DX, AL          ;write PPval to PPreg (all ports used for output, 
								;	mode 0 for both Groups)

		RET						;done so return
				
InitPP  ENDP




CODE    ENDS



        END