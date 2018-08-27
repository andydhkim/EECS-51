       NAME  Timer2M

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Timer2M                                  ;
;                           Timer2 Handler Functions                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: 		This file contains three functions that handle Timer 2 and
;                   the Timer 2 events in the motor. It initializes the Timer 2
;                   so it can  generate interrupts every quarter millisecond,
;                   installs the event handler for the timer interrupt, and calls
;                   the MotorEventHandler function every time there is an interrupt.
;                   The DC Motors on the RoboTrike are then activated via pulse
;                   width modulation at a CUR_FREQ Khz timer interrupt rate.
; 
; Table of Contents:
;   InitTimer2:				Initializes the 80188 Timer 2, the time keeping 
;                  		    and variables.
;	InstallTimer2Handler:   Installs the event handler for the timer interrupt.
;   Timer2EventHandler:		The event handler for the Timer 2 interrupt, calling
;							the MotorEventHandler function approximately every 
;							quarter millisecond.
;
; Revision History:
;   	11/09/16    Dong Hyun Kim       initial revision
;       11/11/16    Dong Hyun Kim       updated comments



; local include files
$INCLUDE(Timer2M.INC)					;add include files with definitions,
										;	addresses, and values
$INCLUDE(General.INC)                   ;add include file with general definitions                                        
										
                                        
                                        
CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP


		
		
;external function declarations
        EXTRN   MotorEventHandler:NEAR  ;Utilize pulse width modulation in order 
                                        ;   to activate DC Motors on the RoboTrike.

                                        

; InitTimer2
;
; Description:       This function initializes the 80188 Timer 2 and the time 
;                    keeping variables. The Timer 2 is initialized to generate
;                    interrupts every quarter millisecond. The interrupt controller
;					 is also initialized to allow the timer interrupts. Timer 2
;					 is used to scale the internal clock from 18 MHz to CUR_FREQ
;                    KHz.
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
; Revision History:  11/09/16    Dong Hyun Kim   initial revision
;                    11/11/16    Dong Hyun Kim   updated comments


InitTimer2      PROC    NEAR
				PUBLIC  InitTimer2

        MOV     DX, Tmr2Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr2MaxCnt  ;set up max count for quarter ms counts
        MOV     AX, COUNTS_PER_QMS
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
; Revision History:  11/09/16    Dong Hyun Kim   initial revision

InstallTimer2Handler  PROC    NEAR
                      PUBLIC  InstallTimer2Handler


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr2Vec), OFFSET(Timer2EventHandler)
        MOV     ES: WORD PTR (4 * Tmr2Vec + 2), SEG(Timer2EventHandler)


        RET                     ;all done, return


InstallTimer2Handler   ENDP
 


; Timer2EventHandler
;
; Description:       This function is the event handler for the Timer 2
;                    interrupt. Every quarter millisecond, the MotorEH function 
;					 is called and an EOI is sent to the interrupt controller.
;					 This effectively activates the DC motors on the RoboTrike.
;
; Operation:         The registers are initially pushed onto a stack to preserve 
;                    their values. MotorEH is then called to activate the DC
;					 motors on the RoboTrike. The EOI is then sent to the 
;					 interrupt controller; the registers are then restored.
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
; Stack Depth:       6 words (4 regs + 1 call)
;
; Revision History:  11/09/16    Dong Hyun Kim   initial revision



Timer2EventHandler      PROC    NEAR
                        PUBLIC  Timer2EventHandler

        PUSH AX                         ;save the registers and flags, since 
        PUSH BX                         ;   Event Handlers should NEVER change
        PUSH CX                         ;   any register values
		PUSH DX
        
		CALL	MotorEventHandler       ;Utilize pulse width modulation to activate
                                        ;   motors

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL
      						
        POP DX                           ;restore the registers
        POP CX
        POP BX
        POP AX

        IRET                            ;and return (Event Handlers end with 
                                        ;   IRET not RET)

Timer2EventHandler       ENDP




CODE    ENDS



        END