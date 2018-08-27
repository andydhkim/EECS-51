       NAME  INT2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     INT2                                   ;
;                            INT2 Handler Functions                          ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: This file contains three functions that handles INT2 and INT2
;              events in the 16C450. It initializes the 16C450 so it can 
;              generate interrupts, installs the event handler for the INT2
;              interrupt, and calls the SerialEventHandler function every
;              time there is an interrupt. This allows the external interrupts
;              that happen on the 16C450 to be interpreted as an internal
;              interrupt in the PCB and allow the processor to generate interrupts
;			   appropriately.
;
; Table of Contents:
;   InitINT2:				Initializes the 16C450 INT2 and interrupt controller.
;   InstallINT2Handler:     Installs the event handler for the INT2 interrupt.
;   INT2EventHandler:       The event handler for the INT2 interrupt, calling the
;                           SerialEventHandler function at every interrupt.
;
; Revision History:
;   	11/17/16    Dong Hyun Kim       initial revision



; local include files
$INCLUDE(INT2.INC)					    ;add include files with definitions,
										;	addresses, and values

                                        
                                        
CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP


		
		
;external function declarations
        EXTRN   SerialEventHandler:NEAR     ;Handle each interrupt appropriately
                                            ;   and enqueue in EventBuf if needed
                                            
                                        

; InitINT2
;
; Description:       This function initializes the 16C450 INT2 and interrupt 
;                    controller. The INT2 control register is initialized to 
;                    generate interrupts, utilize level triggering, and have the
;                    highest priority. The interrupt controller is also initialized
;                    to allow the INT2 interrupts. 
;
; Operation:         The appropriate values are written to the INT2 control 
;                    register in the PCB. The interrupt controller is then set up
;                    to accept the INT2 interrupts and any pending interrupts are
;                    cleared by sending a INT2EOI to the interrupt controller.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Limitations:       None.
; Known Bugs:        None.
; Special Notes:	 None.
;
; Revision History:  11/17/16    Dong Hyun Kim   initial revision

InitINT2        PROC    NEAR
				PUBLIC  InitINT2

        MOV     DX, INT2Ctrl        ;set up the control register with interrupts, 
        MOV     AX, INT2CtrlVal     ;   level triggering, and highest priority.
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI     ;send a timer EOI (to clear out controller)
        MOV     AX, INT2EOI
        OUT     DX, AL


        RET                         ;done so return

InitINT2       ENDP



; InstallINT2Handler
;
; Description:       Install the event handler for the INT2 interrupt.
;
; Operation:         Writes the address of the INT2 event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, ES.
; Limitations:       None.
; Known Bugs:        None.
; Special Notes:	 None.
;
; Revision History:  11/17/16    Dong Hyun Kim   initial revision

InstallINT2Handler    PROC    NEAR
                      PUBLIC  InstallINT2Handler


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * INT2Vec), OFFSET(INT2EventHandler)
        MOV     ES: WORD PTR (4 * INT2Vec + 2), SEG(INT2EventHandler)


        RET                     ;all done, return

InstallINT2Handler     ENDP
 


; INT2EventHandler
;
; Description:       This function is the event handler for the INT2 interrupt.
;                    The SerialEventHandler function is called whenever there is
;                    an INT2 interrupt and an EOI is sent to the interrupt
;                    controller. Each interrupt is then handled appropriately
;                    and enqueued in EventQueue is necessary.
;
; Operation:         The registers are initially pushed onto a stack to preserve 
;                    their values. SerialEventHandler is then called to handle 
;                    each interrupt case appropriately and enqueue in EventHandler
;                    if necessary. The EOI is then sent to the interrupt controller,
;                    and the registers are then restored.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - INT2's EOI.
;                    DX - Address of interrupt controller EOI register.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Limitations:       None.
; Known Bugs:        None.
; Stack Depth:       10 words (8 regs + 1 call)
;
; Revision History:  11/17/16    Dong Hyun Kim   initial revision

INT2EventHandler        PROC    NEAR
                        PUBLIC  INT2EventHandler

        PUSHA                           ;save the registers and flags, since 
                                        ;   Event Handlers should NEVER change
                                        ;   any register values
        
		CALL	SerialEventHandler      ;Handle each interrupt appropriately
                                        ;   and enqueue in EventBuf if needed

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, INT2EOI
        OUT     DX, AL
      						
        POPA                            ;restore the registers
   

        IRET                            ;and return (Event Handlers end with 
                                        ;   IRET not RET)

INT2EventHandler        ENDP



CODE    ENDS



        END