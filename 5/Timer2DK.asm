       NAME  Timer2DK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Timer2DK                                 ;
;                          Timer2 Handler Functions                          ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: 		This file contains three functions that handle Timer 2 and 
;			   		Timer 2 events in the clock. It allows the LED to display the 
;			   		necessary strings for RoboTrike by calling the Multiplex
;                   function every millisecond. It also allows the keypad to check
;					for a new key being pressed or debounce the currently pressed
;					key by calling the Debounce function every millisecond.
; 
; Table of Contents:
;   InitTimer2:				Initializes the 80188 Timer 2, the time keeping 
;                  		    variables, and flags.
;	InstallTimer2Handler:   Installs the event handler for the timer interrupt.
;   Timer2EventHandler:		The event handler for the Timer 2 interrupt, calling
;							the Multiplex and Debounce function every millisecond.
;
; Revision History:
;   	10/27/16    Dong Hyun Kim       initial revision
;       10/28/16    Dong Hyun Kim       updated comments
;		11/02/16	Dong Hyun Kim		added the Debounce function for keypad
;										routines and updated comments



; local include files
$INCLUDE(Timer2DK.INC)					;add include files with definitions,
										;	addresses, and values

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

		
		
;external function declarations
        EXTRN   Multiplex:NEAR			;Called whenever there is an interrupt
										;	and displays a digit on the LED display.
		EXTRN	Debounce:NEAR			;Called whenever there is an interrupt
										;	and checks if a new key is pressed
										;	or debounces the currently pressed key


; InitTimer2
;
; Description:       This function initializes the 80188 Timer 2 and the time 
;                    keeping variables. The Timer is initialized to generate
;                    interrupts every 1 ms. The interrupt controller is also 
;                    initialized to allow the timer interrupts. The Timer 2 is 
;                    used to scale the internal clock from 18 MHz to 1 KHz.
;
; Operation:         The timer count registers are reset to zero. The appropriate
;                    values are then written to the timer control registers in the
;                    PCB. Finally, the interrupt controller is set up to accept
;                    timer interrupts and any pending interrupts are cleared by
;                    sending a TimerEOI to the interrupt controller.
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
; Revision History:  10/27/16    Dong Hyun Kim   initial revision
;                    10/28/16    Dong Hyun Kim   updated comments
;					 11/02/16	 Dong Hyun Kim	 updated comments

InitTimer2      PROC    NEAR
				PUBLIC  InitTimer2

        MOV     DX, Tmr2Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr2MaxCnt  ;set up max count for 1ms counts
        MOV     AX, COUNTS_PER_MS
        OUT     DX, AL

        MOV     DX, Tmr2Ctrl    ;set up the control register with interrupts
        MOV     AX, Tmr2CtrlVal
        OUT     DX, AL
        
                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;set up the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return

InitTimer2      ENDP




; InstallTimer2Handler
;
; Description:       Install the event handler for the Timer 2 interrupt.
;
; Operation:         Writes the address of the Timer 2 event handler to the
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
; Registers Changed: flags, AX, ES
; Limitations:       None.
; Known Bugs:        None.
; Special Notes:	 None.
;
; Revision History:  10/27/16    Dong Hyun Kim   initial revision
;                    10/28/16    Dong Hyun Kim   updated comments
;					 11/02/16	 Dong Hyun Kim	 updated comments

InstallTimer2Handler  PROC    NEAR
                      PUBLIC  InstallTimer2Handler


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr2Vec), OFFSET(Timer2EventHandler)
        MOV     ES: WORD PTR (4 * Tmr2Vec + 2), SEG(Timer2EventHandler)


        RET                     ;all done, return


InstallTimer2Handler  ENDP




; Timer2EventHandler
;
; Description:       This function is the event handler for the Timer 2
;                    interrupt. Every millisecond, the Debounce and Multiplex
;					 function is called and an EOI is sent to the interrupt 
;					 controller. It outputs a segment pattern onto the LED every
;					 millisecond. It also checks if there is a new key being pressed
;					 or debounces the currently pressed key every millisecond as
;					 well.  
;
; Operation:         The registers are initially pushed onto a stack to preserve 
;                    their values. Multiplex and Debounce are called to update the 
;					 segment pattern index and check the keypad. The EOI is then 
;					 sent to the interrupt controller; the registers are then restored. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - Timer 2's EOI.
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
; Stack Depth:       9 words (5 regs + 2 calls)
;
; Revision History:  10/27/16    Dong Hyun Kim   initial revision
;                    10/28/16    Dong Hyun Kim   fixed stack issue and updated
;                                                comments
;					 11/02/16	 Dong Hyun Kim	 updated comments

Timer2EventHandler      PROC    NEAR
                        PUBLIC  Timer2EventHandler

        PUSH    AX                      ;save the registers and flags, since 
        PUSH    BX                      ;   Event Handlers should NEVER change
        PUSH    CX                      ;   any register values
		PUSH	DX
		PUSH	SI
        
		CALL	Debounce				;Check the keypad every clock tick
        CALL    Multiplex               ;Update the digit every clock tick

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POP     SI						;restore the registers
        POP     DX                      
        POP     CX
		POP		BX
		POP		AX

        IRET                            ;and return (Event Handlers end with IRET not RET)

Timer2EventHandler      ENDP




CODE    ENDS



        END