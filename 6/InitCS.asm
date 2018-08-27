       NAME  InitCS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    InitCS                                  ;
;                            Initialize Chip Function                        ;
;									EE/CS 51								 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: 	This file includes a single function, InitCS, that initializes 
;              	the peripheral chip selects on the 80188.				
;
; Table of Contents:
;   InitCS:	   	Initializes the Peripheral Chip Selects on the 80188.
;
; Revision History:
;   10/27/16    Dong Hyun Kim       initial revision
;   10/27/16    Dong Hyun Kim       updated functional specification
;	11/04/16	Dong Hyun Kim		updated comments



; local include files
$INCLUDE(InitCS.INC)				;add include file with addresses and values



CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP
		
		
		

; InitCS
;
; Description:          Initialize the Peripheral Chip Selects on the 80188.
;
; Operation:            Write the initial values (PACSval and MPCSval) to the 
;                       PACS and MPCS registers (PACSreg and MPCSreg).
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
; Stack Depth:          0 words.
;
; Special Notes:        None.
;
; Revision History:     10/27/16    Dong Hyun Kim   initial revision

InitCS  PROC    NEAR
        PUBLIC  InitCS

        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                     ;done so return


InitCS  ENDP




CODE    ENDS



        END