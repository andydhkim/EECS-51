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
;	 10/28/16	Dong Hyun Kim			updated comments and names                                


; definitions

ASCII_NULL      EQU     0H              ;string termination character (<null>)
MAXPWR10	    EQU	    10000		    ;max power of 10 possible in binary value
MAXPWR16	    EQU	    1000H		    ;max power of 16 possible in binary value
FIRSTBITZERO    EQU	    8000H		    ;used to test if first bit is 1