        NAME    CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:  This file includes two functions, the Dec2String and the 
;               Hex2String. The Dec2String converts a signed binary value into
;		        decimal and stores it as a string with a sign. The Hex2String
;		        converts an unsigned binary value into hexadecimal and stores it
;		        as a string. The string is stored at the memory location
; 		        indicated by the passed address.
;
; Table of Contents:
;     1. Dec2String
;     2. Hex2String
;
; Revision History:
;     01/26/06   Glen George      initial revision
;     10/14/16   Dong Hyun Kim    added code and the functional specification

$INCLUDE(Converts.INC)


	
CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP



	
; Dec2String
;
; Description:          This function converts the 16-bit signed value passed to 
;                       it to decimal (5-digits and a sign if negative) and stores it
;			            as a string. The string should contain the <null> terminated
;                       decimal representation of the value in ASCII. The resulting
;                       string is stored starting at the memory location indicated
;                       by the passed address. If positive, there will be no sign,
;                       but if negative, there will be a '-' in front. There may
;                       be leading zeroes.
;
; Operation:		    The function initially checks to see if the number is positive
;			            or negative. If negative, the '-' sign is added to the string
; 			            and the number is negated to become positive. Once the number
; 			            is positive, the function starts with the largest power of 10
;			            possible (10000) and loops dividing the number by the power
;                       of 10 the quotient is a digit and the remainder is used in the
;                       next iteration of the loop. Each iteration divides the
;                       power of 10 by 10 until it is 0. At that point the number
;                       has been converted to decimal. Each time a digit is found,
;                       it is converted into a string by adding 48 and becoming
;                       the appropriate ASCII value.  A 0 is added at the very end 
;                       of the string for null termination. 
;
; Arguments:            n (AX)  - binary value to convert to decimal
;                       a (SI)  - address with memory location to store string
; Return Value:         None.
;
; Local Variables:      digit (AX)  	- computed decimal digit.
;			            remainder (BX)	- the remainder after MODULO 10. 
;                       pwr10 (CX) 	    - current power of 10 being computed.
;			            temp (DX)	    - temporary value used during loop		
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           Repeatedly divide by powers of 10 and get the remainders
;                       (which are the decimal digits).
; Data Structures:      None.
;
; Registers Changed:    flags, AX, BX, CX, DX, SI
; Stack Depth:          None.
;
; Author:               Dong Hyun Kim
; Last Modified:        Oct 14, 2016

Dec2String      PROC        NEAR
                PUBLIC      Dec2String

                
Dec2StringInit:                             ;initialization
        MOV     BX, 0                       ;start with remainder (BX) = 0
        MOV     CX, MAXPWR10                ;start with pwr10 (CX) = 10^5
        ;JMP    CheckIfNegative             ;check the first bit for sign
        
CheckIfNegative:                            ;check whether number is negative
        TEST    AX, NEGSIGN                 ;test if first bit is a 1
        JZ     	Dec2StringLoop              ;if first bit is 0, go to Dec2StringLoop
        ;JNZ    AddMinusSign                ;if it is 1, go to AddMinusSign
        
AddMinusSign:                               ;add minus sign to string and negate
        MOV     BYTE PTR [SI], ASCII_NEG    ;store minus sign in the address
        INC     SI                          ;move address to next open location
        NEG     AX                          ;negate number to make it positive
        ;JMP    Dec2StringLoop              ;now start looping to get the digits
        
Dec2StringLoop:                             ;loop getting the digits in number
        CMP     CX, 0                       ;check if pwr10 > 0
        JLE     ENDDec2StringLoop           ;if not, have done all digits, done
        MOV     DX, 0                       ;setup for digit (AX) /pwr10
        DIV     CX                          ;digit (AX) = digit/pwr10,
                                            ;temp (DX) = digit MODULO pwr10
        ADD     AX, ASCII_ZERO              ;digit = digit + '0'
        MOV     [SI], AL                    ;stores Ascii character in the address
        MOV     BX, DX                      ;remainder = digit MODULO pwr10
        MOV     AX, CX                      ;setup to update pwr10
        MOV     CX, 10                      ;temporarily set pwr 10 = 10
        MOV     DX, 0                       ;resets temp to 0 
        DIV     CX                          ;divide pwr10 by 10
        MOV     CX, AX                      ;pwr10 = pwr10/10 (note: CH = 0)
        MOV     AX, BX                      ;move the remainder to digit
        INC     SI                          ;move address to next open location
        JMP     Dec2StringLoop              ;go back to Dec2StringLoop
        
EndDec2StringLoop:                          ;done converting
        MOV     BYTE PTR [SI], ASCII_NULL   ;add NULL for termination
        RET


	RET

Dec2String	ENDP



; Hex2String
;
; Description:          This function converts the 16-bit unsigned value passed to 
;                       it to hexadecimal (always 4 digits) and stores it as a
;                       string. The string should contain the <null> terminated 
;                       decimal representation of the value in ASCII. The resulting
;                       string is stored starting at the memory location indicated
;                       by the passed address. There may be leading zeros.
;
; Operation:            The function starts with the largest power of 16 possible
;                       (4096) and loops dividing the number by the power of 16;
;                       the quotient is a digit and the remainder is used in the
;                       next iteration of the loop. Each iteration divides the
;                       power of 16 by 16 until it is 0. At that point the number
;                       has been converted to hexadecimal. Each time a digit is
;			            found it is converted into a string by adding 48 (if a
;			            (number) or 55 (if a letter) and becoming the apprpriate
;                       ASCII value. A 0 is added at the very end of the string
;     			        for null termination. 
;
; Arguments:            n (AX)  - binary value to convert to hexadecimal
;                       a (SI)  - address with memory location to store string
; Return Value:         None.
;
; Local Variables:      digit (AX)     	- computed hexadecimal digit.
; 			            remainder (BX) 	- the remainder after MODULO 16.
;                       pwr16 (CX)     	- current power of 16 being computed.
;			            temp (DX)	    - temporary values used during loop.
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           Repeatedly divide by powers of 16 and get the remainders
;                       (which are the hexadecimal digits).
; Data Structures:      None.
;
; Registers Changed:    flags, AX, BX, CX, DX, SI
; Stack Depth:          None.
;
; Author:               Dong Hyun Kim
; Last Modified:        Oct 14, 2016

Hex2String      PROC        NEAR
                PUBLIC      Hex2String

                
Hex2StringInit:                             ;initialization
        MOV     BX, 0                       ;start with remainder (BX) = 0
        MOV     CX, MAXPWR16                ;start with pwr 16 (CX) = 16^4
        ;JMP    Hex2StringLoop              ;now start looping to get the digits
        

Hex2StringLoop:                             ;loop getting the digits in n
        CMP     CX, 0                       ;check if pwr16 > 0
        JLE     ENDHex2StringLoop           ;if not, have done all digits, done
        MOV     DX, 0                       ;setup for digit (AX)/pwr16
        DIV     CX                          ;digit (AX) = digit/pwr16
                                            ;remainder (BX) = digit MODULO pwr16 
        CMP     AX,10                       ;check if digit < 10
        JL      AddAsciiNumHex              ;if less than, add '0'
        JGE     AddAsciiLetHex              ;if equal or greater than, add 'A' - 10
                
AddAsciiNumHex:                             ;converts number into Ascii character
        ADD     AX, ASCII_ZERO              ;digit = AX + '0'
        JMP     Hex2StringLoopBody          ;go to Hex2StringLoopBody
        
AddAsciiLetHex:				                ;converts letter into Ascii character
        ADD     AX, ASCII_OFFSET            ;digit = AX + 'A' - 10
        ;JMP    Hex2StringLoopBody          ;go to Hex2StringLoopBody
        
Hex2StringLoopBody:                         ;get a digit
        MOV     [SI], AL                    ;stores Ascii character to the address
        MOV     BX, DX                      ;now set remainder = digit MODULO pwr16
        MOV     AX, CX                      ;setup to update pwr16
        MOV     CX, 16                      ;temporarily set pwr16 = 16
        MOV     DX, 0                       ;resets temp(DX) to 0 
        DIV     CX                          ;divide pwr16 by 16
        MOV     CX, AX                      ;pwr16 = pwr16/16 (note: CH = 0)
        MOV     AX, BX                      ;move the remainder to AX
        INC     SI                          ;move address to next open location
        JMP     Hex2StringLoop              ;go back to Hex2StringLoop
        
EndHex2StringLoop:                          ;done converting
        MOV     BYTE PTR [SI], ASCII_NULL   ;add NULL for termination
        RET

        
Hex2String	ENDP


CODE    ENDS



        END
