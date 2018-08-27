;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Parser                                   ;
;                        Serial Parcing Routines Functions                   ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Serial Parcing Routines Program 
; (Parser.asm).
;
; Revision History:
;   11/24/16    Dong Hyun Kim       initial revision

; State definitions
;   note that these MUST match the layout of the transition table

ST_IDLE                 EQU     0           ;idle state
ST_SETABSSPEEDINIT      EQU     1           ;command starts with S or s
ST_SETABSSPEEDDIGIT     EQU     2           ;have a digit
ST_SETABSSPEEDSIGN      EQU     3           ;have a + sign
ST_SETRELSPEEDINIT      EQU     4           ;command starts with V or v
ST_SETRELSPEEDDIGIT     EQU     5           ;have a digit
ST_SETRELSPEEDSIGN      EQU     6           ;have a + or - sign
ST_SETDIRECTIONINIT     EQU     7           ;command starts with D or d
ST_SETDIRECTIONDIGIT    EQU     8           ;have a digit
ST_SETDIRECTIONSIGN     EQU     9           ;have a + or - sign
ST_ROTTURANGLEINIT      EQU     10          ;command starts with T or t
ST_RELTURANGLEDIGIT     EQU     11          ;have a digit after sign
ST_RELTURANGLESIGN      EQU     12          ;have a + or - sign
ST_ABSTURANGLEDIGIT     EQU     13          ;have a digit after no sign
ST_SETTURELEVINIT       EQU     14          ;command starts with E or e
ST_SETTURELEVDIGIT      EQU     15          ;have a digit
ST_SETTURELEVSIGN       EQU     16          ;have a + or - sign
ST_SETLASERINIT         EQU     17          ;command starts with O, o, F, or f 

NUM_STATES              EQU     18          ;number of states



; Token Type Definitions
;   note that these MUST match the layout of the transition table

TOKEN_POS               EQU     0           ;token is a positive sign: +
TOKEN_NEG               EQU     1           ;token is a negative sign: -
TOKEN_DIGIT             EQU     2           ;token is a digit: 0 to 9
TOKEN_ENTER             EQU     3           ;token is end of command: <Return>
TOKEN_S                 EQU     4           ;token is S or s
TOKEN_V                 EQU     5           ;token is V or v
TOKEN_D                 EQU     6           ;token is D or d
TOKEN_T                 EQU     7           ;token is T or t
TOKEN_E                 EQU     8           ;token is E or e
TOKEN_OF                EQU     9           ;token is O, o, F or f
TOKEN_OTHER             EQU     10          ;anything else

NUM_TOKEN_TYPES         EQU     11          ;number of token types



; Other Constants

TOKEN_MASK              EQU     01111111b   ;mask high bit of token

NUM_DEC_BASE            EQU     10          ;value to multiply digit with to 
                                            ;   get appropriate value of CurrNum
                                            ;   in decimal base

PARSING_ERROR           EQU     1           ;value indicating a parsing error
NO_ERROR                EQU     0           ;value indicating no parsing error

NUM_ZERO                EQU     0           ;initial value of CurrNum

POS_SIGN                EQU     +1          ;used to denote positive sign
NEG_SIGN                EQU     -1          ;used to denote negative sign

LASER_ON                EQU     1           ;value indicating that laser is on
LASER_OFF               EQU     0           ;value indicating that laser is off

MIN_ELEV                EQU     -60         ;minimum value of turret elevation
MAX_ELEV                EQU     +60         ;maximum value of turret elevation