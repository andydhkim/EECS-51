;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Timer2M.INC                               ;
;                           Timer2 Handler Functions                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Timer2 Handler Functions program, 
; (Timer2M.ASM).
;
; Revision History:
;   11/09/16    Dong Hyun Kim       initial revision


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
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
                                

; Timing Definitions

COUNTS_PER_QMS  EQU     576             ;number of timer counts per quarter ms 
										;	(assumes 18.432 MHz clock)
CUR_FREQ        EQU     4               ;the frequency (in KHz) that the clock
                                        ;   is scaled down to