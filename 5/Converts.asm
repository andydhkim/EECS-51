        NAME    CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description: 	 This file includes two conversion functions that convert a 16-bit
;			   	 signed and unsigned value into a string which is stored at the 
;                memory location indicated by the passed address. 
;
; Table of Contents: 
;	Dec2String:	 converts a signed binary value into decimal and stores it as a 
;				 string (with a sign if negative). 
;	Hex2String:  converts an unsigned binary value into hexadecimal and stores it
;		         as a string. 
;
; Revision History:
;     01/26/06   Glen George      initial revision
;     10/14/16   Dong Hyun Kim    added code and the functional specification
;	  10/28/16	 Dong Hyun Kim    updated comments



;local include files
$INCLUDE(Converts.INC)


	
CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP



	
; Dec2String
;
; Description:          This function converts the 16-bit signed value passed to 
;                       it to decimal (5-digits and a sign if negative) and stores it
;			            as a string. The string contains the <null> terminated
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
;			            possible (MAXPWR10) and loops dividing the number by the power
;                       of 10 the quotient is a digit and the remainder is used in the
;                       next iteration of the loop. Each iteration divides the
;                       power of 10 by 10 until it is 0. At that point the number
;                       has been converted to decimal. Each time a digit is found,
;                       it is converted into a string by adding '0' and becoming
;                       the appropriate ASCII value.  A NULL is added at the very end 
;                       of the string for null termination. 
;
; Arguments:            n (AX)  - binary value to convert to decimal
;                       a (SI)  - address with memory location to store string
; Return Value:         None.
;
; Local Variables:      digit (AX)  	- computed decimal digit.
;			            remainder (BX)	- the remainder after MODULO 10. 
;                       pwr10 (CX) 	    - current power of 10 being computed.
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
;
; Revision History:
;   10/14/16    Dong Hyun Kim       initial revision
;	10/28/16	Dong Hyun Kim		updated comments and removed unncessary RET

Dec2String      PROC        NEAR
                PUBLIC      Dec2String

                
Dec2StringInit:                             ;initialization
        MOV     CX, MAXPWR10                ;start with pwr10 (CX) = MAXPWR10
        ;JMP    CheckIfNegative             ;check the first bit for sign
        
CheckIfNegative:                            ;check whether number is negative
        TEST    AX, FIRSTBITZERO            ;test if number is negative
        JZ     	Dec2StringLoop              ;if positive, start algorithm right away
        ;JNZ    AddMinusSign                ;if not, add minus sign and negate first
        
AddMinusSign:                               ;add minus sign to string and negate
        MOV     BYTE PTR [SI], '-'          ;store minus sign in the address
        INC     SI                          ;move address to next open location
        NEG     AX                          ;negate number to make it positive
											;	and apply algorithm easily
        ;JMP    Dec2StringLoop              ;now start looping to get the digits
        
Dec2StringLoop:                             ;loop getting the digits in number
        CMP     CX, 0                       ;check if pwr10 > 0
        JLE     ENDDec2StringLoop           ;if not, have done all digits, done
        XOR		DX, DX                      ;setup for digit (AX) /pwr10
        DIV     CX                          ;digit (AX) = digit/pwr10,
                                            ;	temp (DX) = digit MODULO pwr10
        ADD     AL, '0'                     ;convert digit into Ascii character
        MOV     BYTE PTR [SI], AL           ;stores Ascii character in the address
		INC		SI							;move address to next open location
        MOV     BX, DX                      ;remainder = digit MODULO pwr10
        MOV     AX, CX                      ;setup to update pwr10
        MOV     CX, 10                      ;temporarily set pwr 10 = 10
        XOR     DX, DX                      ;resets temp to 0 
        DIV     CX                          ;divide pwr10 by 10
        MOV     CX, AX                      ;pwr10 = pwr10/10 (note: CH = 0)
        MOV     AX, BX                      ;move the remainder to digit
        JMP     Dec2StringLoop              ;go back to Dec2StringLoop
        
EndDec2StringLoop:                          ;done converting
        MOV     BYTE PTR [SI], ASCII_NULL   ;add NULL for termination
        RET

		
Dec2String	ENDP



; Hex2String
;
; Description:          This function converts the 16-bit unsigned value passed to 
;                       it to hexadecimal (always 4 digits) and stores it as a
;                       string. The string contains the <null> terminated 
;                       decimal representation of the value in ASCII. The resulting
;                       string is stored starting at the memory location indicated
;                       by the passed address. There may be leading zeros.
;
; Operation:            The function starts with the largest power of 16 possible
;                       (MAXPWR16) and loops dividing the number by the power of 16;
;                       the quotient is a digit and the remainder is used in the
;                       next iteration of the loop. Each iteration divides the
;                       power of 16 by 16 until it is 0. At that point the number
;                       has been converted to hexadecimal. Each time a digit is
;			            found it is converted into a string by adding '0' (if a
;			            (number) or 'A' - 10 (if a letter) and becoming the apprpriate
;                       ASCII value. A NULL is added at the very end of the string
;     			        for null termination. 
;
; Arguments:            n (AX)  - binary value to convert to hexadecimal
;                       a (SI)  - address with memory location to store string
; Return Value:         None.
;
; Local Variables:      digit (AX)     	- computed hexadecimal digit.
; 			            remainder (BX) 	- the remainder after MODULO 16.
;                       pwr16 (CX)     	- current power of 16 being computed.
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
; Revision History:
;   10/14/16    Dong Hyun Kim       initial revision
;	10/28/16	Dong Hyun Kim		updated comments

Hex2String      PROC        NEAR
                PUBLIC      Hex2String

                
Hex2StringInit:                             ;initialization
        MOV     CX, MAXPWR16                ;start with pwr 16 (CX) = MAXPWR16
        ;JMP    Hex2StringLoop              ;now start looping to get the digits
        
Hex2StringLoop:                             ;loop getting the digits in n
        CMP     CX, 0                       ;check if pwr16 > 0
        JLE     ENDHex2StringLoop           ;if not, have done all digits, done
        XOR		DX, DX                      ;setup for digit (AX)/pwr16
        DIV     CX                          ;digit (AX) = digit/pwr16
                                            ;	remainder (BX) = digit MODULO pwr16 
        CMP     AL,10                       ;check if digit < 10
        JL      AddAsciiNumHex              ;if less than, add '0'
        ;JGE    AddAsciiLetHex              ;if equal or greater than, add 'A' - 10
		
AddAsciiLetHex:				                ;converts letter into Ascii character
        ADD     AL, 'A' - 10                ;	by adding an offset
        JMP     Hex2StringLoopBody          ;go to Hex2StringLoopBody
                
AddAsciiNumHex:                             ;converts number into Ascii character
        ADD     AL, '0'		                ;	by adding an offset
        ;JMP     Hex2StringLoopBody         ;go to Hex2StringLoopBody
        
Hex2StringLoopBody:                         ;get a digit
        MOV     [SI], AL                    ;stores Ascii character to the address
		INC		SI							;move address to next open location
        MOV     BX, DX                      ;now set remainder = digit MODULO pwr16
        MOV     AX, CX                      ;setup to update pwr16
        MOV     CX, 16                      ;temporarily set pwr16 = 16
        XOR		DX, DX                      ;resets temp(DX) to 0 
        DIV     CX                          ;divide pwr16 by 16
        MOV     CX, AX                      ;pwr16 = pwr16/16 
        MOV     AX, BX                      ;move the remainder to AX
        JMP     Hex2StringLoop              ;go back to Hex2StringLoop
        
EndHex2StringLoop:                          ;done converting
        MOV     BYTE PTR [SI], ASCII_NULL   ;add NULL for termination
        RET

        
Hex2String	ENDP


CODE    ENDS



        END
