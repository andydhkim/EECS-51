;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Converts.INC                              ;
;                                   Converts                                 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Convert Program (Converts.asm).
;
; Revision History:
;    10/14/16   Dong Hyun Kim           initial revision (originally part of
;                                       Converts.asm)
;    10/14/16   Dong Hyun Kim           split definitions into own file                                


; definitions

ASCII_NULL      EQU     0               ;string termination character (<null>)
ASCII_NEG       EQU     45              ;negative sign character ('-')
ASCII_ZERO	    EQU	    48		        ;zero character ('0')
ASCII_OFFSET	EQU	    55		        ;offset for A ('A' - 10)
MAXPWR10	    EQU	    10000		    ;max power of 10
MAXPWR16	    EQU	    4096		    ;max power of 16
NEGSIGN		    EQU	    8000H		    ;used to test if first bit is 1