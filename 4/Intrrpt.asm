       NAME  Intrrpt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Intrrpt                                  ;
;                         Interrupt Handler Functions                        ;
;									EE/CS 51								 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:	This file includes two interrupt handler functions for Timer2. 
;               For all interrupt vectors, it installs the IllegalEventHandler, 
;               which does nothing and returns after sending a non-specific EOI. 
;				
; Table of Contents:
;	IllegalEventHandler:  Event handler for uninitialized interrupts. Returns
;                         after sending a non-specific EOI.
;	ClrIRQVectors:        Installs the IllegalEventHandler for all interrupt
;                         vectors in the interrupt vector table.
;   
; Revision History:
;   01/27/16    Dong Hyun Kim       initial revision
;   01/27/16    Dong Hyun Kim       updated functional specification



; local include files
$INCLUDE(Intrrpt.INC)



CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP


		

; IllegalEventHandler
;
; Description:          This procedure is the event handler for illegal
;                       (uninitialized) interrupts.  It does nothing - it just
;                       returns after sending a non-specific EOI.
;
; Operation:            Send a non-specific EOI and return.
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
; Registers Changed:    None.
; Limitations:          None.
; Known Bugs:           None.
; Stack Depth:          2 words
;
; Special Notes:        None.
;
; Revision History:     10/27/16    Dong Hyun Kim   initial revision

IllegalEventHandler     PROC    NEAR
                        PUBLIC  IllegalEventHandler

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-specific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP




; ClrIRQVectors
;
; Description:          This functions installs the IllegalEventHandler for all
;                       interrupt vectors in the interrupt vector table.  Note
;                       that all 256 vectors are initialized so the code must be
;                       located above 400H.  The initialization skips  (does not
;                       initialize vectors) from vectors FIRST_RESERVED_VEC to
;                       LAST_RESERVED_VEC.
;
; Operation:            The function clears ES (since interrupt vectors are in
;                       segment 0), initializes SI to 0, and sets the vector 
;                       counter to 256. It then enters a loop where it stores the
;                       vector if it is before the start of a reserved field; if 
;                       it is in the reserved field, the pointer is updated to
;                       the next vector and the loop continues until all the
;                       vectors are cleared.
;
; Arguments:            None.
; Return Value:         None.
;
; Local Variables:      CX    - vector counter.
;                       ES:SI - pointer to vector table.
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
; Registers Changed:    flags, AX, CX, SI, ES
; Limitations:          None.
; Known Bugs:           None.
; Stack Depth:          1 word
;
; Special Notes:        None.
;
; Revision History:     10/27/16    Dong Hyun Kim   initial revision

ClrIRQVectors   PROC    NEAR
                PUBLIC  ClrIRQVectors


InitClrVectorLoop:                  ;set up to store the same handler 256 times
        XOR     AX, AX              ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0               ;initialize SI to skip RESERVED_VECS (4 bytes each)

        MOV     CX, 256             ;up to 256 vectors to initialize


ClrVectorLoop:                      ;loop clearing each vector
                                    ;check if should store the vector
        CMP 	SI, 4 * FIRST_RESERVED_VEC
        JB		DoStore				;if before start of reserved field - store it
        CMP		SI, 4 * LAST_RESERVED_VEC
        JBE		DoneStore			;if in the reserved vectors - don't store it
        ;JA		DoStore				;otherwise past them - so do the store

DoStore:                            ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

DoneStore:						    ;done storing the vector
        ADD     SI, 4               ;update pointer to next vector

        LOOP    ClrVectorLoop       ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors    ;and all done


EndClrIRQVectors:                   ;all done, return
        RET


ClrIRQVectors   ENDP




CODE    ENDS



        END