       NAME  Timer2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Timer2                                  ;
;                          Timer2 Handler Functions                          ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: 		This file contains three functions that handles Timer 2 and 
;			   		Timer 2 events in the clock. It allows the LED to display the 
;			   		necessary strings for RoboTrike by calling the Multiplex
;                   function at every interrupt.
; 
; Table of Contents:
;   InitTimer2:				Initializes the 808188 Timer 2, the time keeping 
;                  		    variables, and flags.
;	InstallTimer2Handler:   Installs the event handler for the timer interrupt.
;   Timer2EventHandler:		The event handler for the Timer 2 interrupt, outputting
;						    the next segment pattern.
;
; Input:            None.
; Output:           The Timer2EventHandler will call the Multiplex function to 
;					output to the LED display through interrupts.
;
; User Interface:   None.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Revision History:
;   	10/27/16    Dong Hyun Kim       initial revision
;       10/28/16    Dong Hyun Kim       updated comments



; local include files
$INCLUDE(Timer2.INC)



;external function declarations
        EXTRN   Multiplex:NEAR			;Called whenever there is an interrupt
										;	and displays a digit on the LED display.



CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP




; InitTimer2
;
; Description:       This function initializes the 808188 Timer 2, the time keeping
;                    variables, and flags. The Timer is initialized to generate
;                    interrupts every 1 ms. The interrupt controller is also 
;                    initialized to allow the timer interrupts. The Timer 2 is 
;                    used to scale the internal clock from 18 MHz to 1 KHz.
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count registers
;                    are reset to zero.  Finally, the interrupt controller is
;                    set up to accept timer interrupts and any pending
;                    interrupts are cleared by sending a TimerEOI to the
;                    interrupt controller.
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
; Stack Depth:       0 words
;
; Revision History:  10/27/16    Dong Hyun Kim   initial revision
;                    10/28/16    Dong Hyun Kim   updated comments

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
; Description:       Install the event handler for the timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
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
; Stack Depth:       0 words
;
; Revision History:  10/27/16    Dong Hyun Kim   initial revision
;                    10/28/16    Dong Hyun Kim   updated comments

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
; Description:       This function is the event handler for the Timer #2
;                    interrupt. It outputs the next segment pattern to the
;                    LED display. After going through all the segment patterns
;                    for a digit it goes on to the next digit. After doing all 
;                    the digits it starts over again.
;
; Operation:         The registers are initially pushed onto a stack to preserve 
;                    their values. Multiplex is called to update the segment 
;                    pattern index. The EOI is then sent to the interrupt controller;
;                    the registers are then restored. 
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
; Output:            A segment to the display.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Limitations:       None.
; Known Bugs:        None.
; Stack Depth:       3 words
;
; Revision History:  10/27/16    Dong Hyun Kim   initial revision
;                    10/28/16    Dong Hyun Kim   fixed stack issue and updated
;                                                   comments


Timer2EventHandler      PROC    NEAR
                        PUBLIC  Timer2EventHandler

        PUSH    AX                      ;save the registers and flags, since 
        PUSH    DX                      ;   Event Handlers should NEVER change
        PUSH    SI                      ;   any register values
        PUSHF
        
        CALL    Multiplex               ;Update the digit every clock tick

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POPF                            ;restore the registers
        POP     SI
        POP     DX                      
        POP     AX

        IRET                            ;and return (Event Handlers end with IRET not RET)

Timer2EventHandler      ENDP




CODE    ENDS



        END