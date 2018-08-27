;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Timer2DK.INC                               ;
;                           Timer2 Handler Functions                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Timer2 Handler Functions program, 
; (Timer2DK.ASM).
;
; Revision History:
;   10/27/16    Dong Hyun Kim       initial revision
;	10/28/16	Dong Hyun Kim		updated Tmr2CtrlVal to enable interrupt


; Timer Definitions

; Addresses
Tmr2Ctrl        EQU     0FF66H          ;address of Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ;address of Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ;address of Timer 2 Count Register

; Control Register Values
Tmr2CtrlVal     EQU     0E001H          ;value to write to Timer 2 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000-0000-  reserved
                                        ;---0------0-----  read only
                                        ;---------------1  continuous mode

; Interrupt Vectors
Tmr2Vec         EQU     19              ;interrupt vector for Timer 2


; Interrupt Controller Definitions

; Addresses
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer

; Register Values
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
                                

; Timing Definitions

COUNTS_PER_MS   EQU     2304            ;number of timer counts per 1 ms 
										;	(assumes 18.432 MHz clock)