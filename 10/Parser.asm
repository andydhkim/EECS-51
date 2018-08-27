	NAME	PARSER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Parser                                  ;
;                        Serial Parsing Routines Functions                   ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file contains seventeen public functions and three private tables
;			   that will be used for the serial parsing routine of the RoboTrike.
;			   It will revolve around the function ParseSerialChar, which utilizes
;			   the three private tables - a state transition table and two token 
;			   tables - to move from one state to another as necessary and carry
;			   out the necessary actions. Essentially, the file models a finite
;			   state machine. The first three functions initialize the shared 
;			   variables and return the token type and value for the parsed
;			   character. The fourth function will update necessary status update
;			   messages on the LED display. The remaining twelve functions are
;			   utilized as the action routines of the state machine. 
;
; Table of Contents (Functions):
;	InitParser:			Initializes shared variables for parsing.
;   ResetParser:        Resets the state machine to prepare for parsing.
;	GetToken:			Returns the token type and value for the passed character.
;	UpdateStatus:		Outputs a status update message to the display, only called
;						when the speed, direction, or laser setting is altered.
;	ParseSerialChar:	Updates state and performs an action using current state, 
;						token type, and token value.
;
; Table of Contents (Action Routines):
;	ParseDigit:			Parses current digit, converting from ASCII to numerical.
;	SetSign:			Puts appropriate value in the signed variable, Sign.
;	SetError:			Puts appropriate value in the signed variable, Error.
;	SetLaserSV:			Puts appropriate value in the signed variable, Laser.
;	DoNOP:				Does nothing and returns.
;	SetAbsSpeed:		Sets the absolute speed of the RoboTrike.
;	SetRelSpeed:		Accelerate or decelerate RoboTrike by relative speed.
;	SetDirection:		Set direction of movement of the RoboTrike.
;	RotRelTurAngle:		Rotate turret on RoboTrike by relative angle.
;	RotAbsTurAngle:		Rotate turret on RoboTrike by absolute angle.
;	SetTurElev:			Sets absolute angle of elevation of laser.
;	OperateLaser:		Turns the laser on or off.  
;
; Table of Contents (Tables):
;	StateTable:			State transition table for the state machine. 
;	TokenTypeTable:		Table with the token types.
;	TokenValueTable:	Table with the token values.				
;
; Revision History:
;   11/21/16    Dong Hyun Kim       wrote pseudo code
;   11/24/16    Dong Hyun Kim       initial revision
;	11/25/16	Dong Hyun Kim		debugged code and updated comments
;	12/08/16	Dong Hyun Kim		added a new function, UpdateStatus



; local include files
$INCLUDE(Parser.INC)			;contains definitions and addresses for parsing
$INCLUDE(Motor.INC)             ;contains definitions and addresses for motors
                                ;   routines



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

		

;external function declarations
        EXTRN   SetMotorSpeed:NEAR              ;set speed and direction of movement
        EXTRN   GetMotorSpeed:NEAR              ;get current speed setting
        EXTRN   GetMotorDirection:NEAR          ;get current direction of momvement
        EXTRN   SetLaser:NEAR                   ;turn laser on or off
        EXTRN   GetLaser:NEAR                   ;get status of laser
        EXTRN   SetTurretAngle:NEAR             ;set absolute angle to turn turret
        EXTRN   SetRelTurretAngle:NEAR          ;set relative angle to turn turret
        EXTRN   GetTurretAngle:NEAR             ;get current angle setting for turret
        EXTRN   SetTurretElevation:NEAR         ;set angle of elevation for turret
        EXTRN   GetTurretElevation:NEAR         ;get current elevation setting
                                                ;   for turret
		EXTRN	UpdateStatus:NEAR				;outputs a status update message
												;	to the LED
		


; InitParser
;
; Description:			The function initializes the shared variables used for
;                       serial parsing to prepare for the first character input
;                       from the serial line. 
;
; Operation:			The function calls the ResetParser function to initialize 
;                       all of the shared variables (except CurrSt) appropriatly
;                       The function also sets the current state of the state
;                       machine to ST_IDLE to indicate that the state machine
;					    is ready to accept characters. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrSt (DS) - Current state of the state machine (W). 
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

InitParser			PROC        NEAR
                    PUBLIC      InitParser                    
					
        CALL    ResetParser                     ;reset Sign, CurrNum and Laser
                                                ;   shared variables. 
        MOV     CurrSt, ST_IDLE                 ;initialize the state so that it
                                                ;   is ready to read first command
                                                ;   prompt character  
        RET 
        
InitParser          ENDP     					



; ResetParser
;
; Description:			The function resets all of the shared variables (except
;                       CurrState) back to the initial state to prepare for a 
;                       new character input from the serial line. It is called
;                       when there is an error while transitioning within the 
;						finite state machine.
;
; Operation:			The function initializes all the shared variables by 
;                       setting CurrNum equal to NUM_ZERO, Sign to POS_SIGN, and
;                       ParserError to NO_ERROR. This allows the parser to accept
;						new characters and handle them correctly through the 
;						state machine.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrNum     (DS) - Current number that is being parsed (W).
;                       Sign        (DS) - Variable used to indicate sign (W).
;                       ParserError (DS) - Indicates whether or not there was a 
;                                          parsing error (W).
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

ResetParser			PROC        NEAR
                    PUBLIC      ResetParser
                    
        MOV     CurrNum, NUM_ZERO               ;there is no number being parsed
                                                ;   so set CurrNum to NUM_ZERO
        MOV     Sign, POS_SIGN                  ;if there is no negative sign,
                                                ;   assume CurrNum to be positive
        MOV     ParserError, NO_ERROR           ;initialize the error flag so 
                                                ;   that the state machine does
                                                ;   not have any errors
        RET                                     ;now, we are done                                                
                            
ResetParser         ENDP     			

; GetToken
;
; Description:			The function returns the token class and token value for
;                       the passed character. The possible token classes are 
;                       TOKEN_POS, TOKEN_NEG, TOKEN_DIGIT, TOKEN_ENTER, TOKEN_S,
;                       TOKEN_V, TOKEN_D, TOKEN_T, TOKEN_E, TOKEN_OF, and TOKEN_
;                       OTHER. The token value is either based on the numerical 
;                       value of the character itself or how it is utilized in
;                       the action routines.
;
; Operation:			The function looks up the passed character in two tables,
;                       one for the token type/class, the other for token values.
;                       It utilizes the TokenTypeTable and the TokenValueTable.
;
; Arguments:			c 	      (AL) - The passed character to process as a 
;								         serial command.
; Return Value:			TokenVal  (AL) - Token value for the character.
;                       TokenType (AH) - Token type for the character.
;
; Local Variables:		Index     (BX) - table pointer, points at lookup tables.
; Shared Variables:		None.
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			Table lookup.
; Data Structures:		Two tables, one containing token values and the other 
;                       containing token types.
;
; Registers Changed:	AX, BX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

GetToken			PROC        NEAR
                    PUBLIC      GetToken
					
GetTokenInit:				                    ;setup for lookups
        AND	    AL, TOKEN_MASK		            ;strip the unused bit (highest
                                                ;   bit) since it is unused for
                                                ;   ASCII characters
        MOV	    AH, AL			                ;preserve the value of the 
                                                ;   ASCII character in AH
        ;JMP    TokenTypeLookup                                                


TokenTypeLookup:                                ;get the token type
        MOV     BX, OFFSET(TokenTypeTable)      ;BX points at TokenTypeTable
        XLAT	CS:TokenTypeTable	            ;obtain the token type and put
                                                ;   it in the AL register
        XCHG	AH, AL			                ;token type in AH, value of the
                                                ;   ASCII character in AL
        ;JMP    TokenValueLookup                                                

TokenValueLookup:			                    ;get the token value
        MOV     BX, OFFSET(TokenValueTable)     ;BX points at TokenValueTable
        XLAT	CS:TokenValueTable	            ;obtain the token value and put 
                                                ;   it in the AH register
        ;JMP    EndGetToken                                                

EndGetToken:                          	        ;done looking up type and value
        RET
                    
GetToken   	        ENDP  



; ParseSerialChar
;
; Description:			The function is passed a character (c) which is presumed
;                       to be from the serial input. The character should be 
;                       processed as a serial command. It checks the status of 
;                       the current state, along with the token value and type
;                       of the passed character. It then transitions into the
;                       appropriate state and performs the appropriate action.
;                       The function also checks if the updated state is equal to 
;                       ST_IDLE. If it is, the parser is reset. The function also
;                       returns the status of the parsing operation in AX. NO_ERROR
;                       is returned if there are no parsing errors, and PARSING_ERROR
;                       is returned if otherwise. 
;
; Operation:			The current state is put in the CL register to prepare 
;                       for the transition. The token value and type of the passed
;                       character is then found through the GetToken function.
;                       The appropriate entry in the StateTable is then found 
;                       utilizing the token type and current state, and the 
;                       CurrSt is updated with the new state. The appropriate
;                       action is also carried out through the action routines,
;                       which do not affect the registers. Errors are checked and
;                       returned through the AX register. Finally, the function
;                       checks if the new state is ST_IDLE. If so, the parser is
;                       reset through the ResetParser function to prepare for 
;                       another command in the serial line.
;
; Arguments:			c 	        (AL) - The passed character to process as a 
;								           serial line.
; Return Value:			None.
;
; Local Variables:		TokenVal    (CH) - Token value for the character.
;                       TokenType   (DH) - Token type for the character.
; Shared Variables:		CurrSt      (DS) - Current state of the state machine (W).
;                       ParserError (DS) - Indicates whether or not there was a 
;                                          parsing error (W).                    
; Global Variables:		None.
;
; Input:				Chacters from the serial line.
; Output:				Appropriate commands of the motors (not directly).
;
; Error Handling:		If an error occured while transitioning, the ParserError
;                       shared variable is set to PARSING_ERROR. The value is 
;                       returned in the AX register.
;
; Algorithms:			None.
; Data Structures:		Three tables, one containing the transition type and 
;                       actions, and two with the token type and token values.
;
; Registers Changed:	AX, BX, CX, DX, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        Illegal characters (anything other than the token types)
;                       are ignored. Legal characters that are misused will flag
;                       an error.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/25/16    Dong Hyun Kim       initial revision

ParseSerialChar		PROC        NEAR
                    PUBLIC      ParseSerialChar
					
ParseSeialCharInit:                             ;initialization
        MOV     CL, CurrSt                      ;put the value of current state
                                                ;   in CL to prepare for
                                                ;   transition
        ;JMP    DoNextToken

DoNextToken:                                    ;get next input for state machine
        CALL    GetToken                        ;obtain the token type and value
                                                ;   value of the passed character
        MOV     DH, AH                          ;save token type in DH 
        MOV     CH, AL                          ;save token value in CH
        ;JMP    ComputeTransition
        
ComputeTransition:                              ;figure out what transition to do
        MOV     AL, NUM_TOKEN_TYPES             ;find row in the table
        MUL     CL                              ;AX is start of row for current
                                                ;   state
        ADD     AL, DH                          ;get the actual transition by
                                                ;   utilizing the token type
        ADC     AH, 0                           ;propogate low byte carry into
                                                ;   high byte
        IMUL    BX, AX, SIZE TRANSITION_ENTRY   ;now, convert to table offset 
        ;JMP    DoTransition
        
DoTransition:                                   ;now go to next state
        MOV     CL, CS:StateTable[BX].NEXTSTATE ;get the updated state from the
                                                ;   StateTable
        MOV     CurrSt, CL                      ;update the state by putting the
                                                ;   value in CurrSt
        ;JMP    DoAction
        
DoAction:                                       ;do the appropriate action
                                                ;   (don't affect registers)
        MOV     AL, CH                          ;get token value back for action
        CALL    CS:StateTable[BX].ACTION        ;do the appropriate action
        ;JMP    CheckError
        
CheckError:                                     ;now, check if there were any
        MOV     AL, ParserError                 ;   errors during the transition.
                                                ;   If there were any errors, the
                                                ;   value of ParseError will be
                                                ;   equal to PARSING_ERROR. 
                                                ;   Otherwise it will be equal
                                                ;   to NO_ERROR.
        XOR     AH, AH                          ;clear the AH register to return
                                                ;   a word (AX) instead of a byte
        ;JMP    CheckIdle

CheckIdle:                                      ;now, check if the current state
        CMP     CurrSt, ST_IDLE                 ;   state is ST_IDLE. If it is,
                                                ;   there must have been some 
                                                ;   sort of error, or the command
                                                ;   must have been fully parsed.
                                                ;   Hence, we must reset the 
                                                ;   parser to let it accept a new
                                                ;   command correctly from the 
                                                ;   serial line.                                  
        JNE     EndParseSerialChar              ;if it is not in idle state,
                                                ;   we are done
        ;JE     CallResetParser
        
CallResetParser:                                ;if it was in the idle state,
        CALL    ResetParser                     ;   reset the parser
        ;JMP    EndParseSerialChar

EndParseSerialChar:                             ;now, we are done
        RET
                                                    
ParseSerialChar     ENDP    



; ParseDigit
;
; Description:			The action routine is called whenever there is a character
;                       of a digit in the serial line. It converts the character
;                       from ASCII to a numerical value utilizing its token value,
;                       and parses the numerical value appropriately to form 
;                       CurrNum. If there is ever an error during the mathematical
;                       operation, an error is set and the state is reverted 
;                       back to the idle state. This allows the program to start
;                       accepting new values in the command prompt correctly. 
;
; Operation:			The action routine utilizes the value passed down from 
;                       AL and multiplies it by the Sign shared variable to 
;                       convert it to the appropriate digit value. CurrNum is 
;                       then multiplied by NUM_DEC_BASE and added with the new
;                       digit value. If there is any error during the mathematical
;                       operation (that is, if there is ever an overflow during
;                       the signed operation) the SetError function is called and
;                       the state is changed to ST_IDLE. If there are no errors,
;                       the value of CurrNum is updated succesfully.
;
; Arguments:			Digit 	 (AL) - The number that has to be parsed.
; Return Value:			None.
;
; Local Variables:		
; Shared Variables:		CurrNum  (DS) - Current number that is being parsed (W).
;						Sign     (DS) - Variable used to indicate sign (W).
; Global Variables:		None.
;
; Input:				A numerical value in the serial line.
; Output:				None.
;
; Error Handling:		An error is set whenever there is an overflow during 
;                       the multiplication or addition.
;
; Algorithms:			abc = c*10^0 + b*10^1 + a*10^2. Basically, the function 
;                       utilizes the fact that a decimal number can be broken 
;                       down as (digit) * 10^n. 
; Data Structures:		None.
;
; Registers Changed:	AX, BX, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/25/16    Dong Hyun Kim       initial revision

ParseDigit			PROC        NEAR
                    PUBLIC      ParseDigit
					
ParseDigitInit:                                 ;initialization
        IMUL    Sign                            ;prepare to add the value of the
                                                ;   the passed digit by performing
                                                ;   a signed multiplication with
                                                ;   Sign. This makes the digit 
                                                ;   have the appropriate sign
        MOV     BX, AX                          ;preserve the value of the digit
                                                ;   since we wish to utilize
                                                ;   later for addition
        MOV     AX, CurrNum                     ;prepare to multiply the value of
                                                ;   CurrNum with NUM_DEC_BASE
        ;JMP    MultiplyDecBase

MultiplyDecBase:                                ;multiply current number appropriately
        IMUL    AX, AX, NUM_DEC_BASE            ;CurrNum = CurrNum * NUM_DEC_BASE
                                                ;   perform a signed multiplication
                                                ;   with CurrNum to make sure 
                                                ;   that there is space in the 
                                                ;   one's digit for the value
                                                ;   of Digit to be added to
        JO      OverflowError                   ;if there was an overflow, handle
                                                ;   it appropriately
        ;JNO    AddDigit

AddDigit:                                       ;add the digit to one's digit
        ADD     AX, BX                          ;CurrNum = CurrNum + Digit
                                                ;   add the digit to the one's
                                                ;   digit of CurrNum. This 
                                                ;   should have correctly parsed
                                                ;   the digit
        JO      OverflowError                   ;if there was an overflow, handle
                                                ;   it appropriatly
        ;JNO    UpdateCurrNum
        
UpdateCurrNum:                                  ;if there was no overflow, 
        MOV     CurrNum, AX                     ;   update the CurrNum so that
                                                ;   it is ready for next action
                                                ;   routine
        JMP     EndParseDigit                   ;now, we are done                                                

OverflowError:                                  ;if there was an overflow,
        CALL    SetError                        ;   set ParserError to alert 
                                                ;   program that there was an 
                                                ;   error
        MOV     CurrSt, ST_IDLE                 ;also set the current state to 
                                                ;   ST_IDLE. Although we do not
                                                ;   want to directly change the
                                                ;   state in our action routines,
                                                ;   the state machine cannot handle
                                                ;   errors while parsing a digit
                                                ;   so we must take care it off
                                                ;   it manually
        ;JMP    EndParseDigit

EndParseDigit:                                  ;now, we are done
        RET
                    
ParseDigit   	    ENDP  



; SetSign
;
; Description:			The action routine is called whenever there was a sign
;                       character (+ or -) entered after a command character
;                       (S, s, V, v, D, d, T, t, E, e, O, o, F or F). It sets the
;                       Sign variable to POS_SIGN or NEG_SIGN depending on the 
;                       value of the token. 
;
; Operation:			The function simply moves the value of the token, which 
;                       is saved in the AL register, to the shared variable
;                       Sign. If the positive sign character (+) was entered, 
;                       Sign will be set to POS_SIGN. If the negative sign character
;                       (-) was entered, Sign will be set to NEG_SIGN.
;
; Arguments:			TokenVal (AL) - Token value for the character.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		Sign     (DS) - Variable used to indicate sign (W).

; Global Variables:		None.
;
; Input:				A sign character in the serial line.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

SetSign			    PROC        NEAR
                    PUBLIC      SetSign
                    
        MOV     Sign, AL                        ;sets Sign to appropriate value
                                                ;   depending on the type of 
                                                ;   sign character that was input
                                                ;   in the serial line
        RET                                     ;now, we are done
					
SetSign   	        ENDP  



; SetError
;
; Description:			The action routine is called whenever there was an error
;                       while transitioning through the state machine. It alerts
;                       the program that there was an error by setting the 
;                       ParserError variable. It is not called only when a legal
;                       character is misused. Illegal characters are ignored.
;
; Operation:			The action routine simply sets the ParserError variable
;                       to PARSING_ERROR, alterting the program that there was 
;                       an error within the state machine.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		ParserError (DS) - Indicates whether or not there was a 
;                                          parsing error (W). 
; Global Variables:		None.
;
; Input:				Invalid input in the serial line.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

SetError			PROC        NEAR
                    PUBLIC      SetError
					
        MOV     ParserError, PARSING_ERROR      ;sets ParserError to alert program
                                                ;   that there was an error within
                                                ;   the state machine
        RET                                     ;now, we are done           
                    
SetError   		    ENDP  



; SetLaserSV
;
; Description:			The action routine is called whenever there was a laser
;                       related command character (O, o, F, and f). It sets the
;                       Laser variable to LASER_ON or LASER_OFF depending on the
;                       the value of the token. 
;
; Operation:			The action routine simply moves the value of the token,  
;                       which is saved in the AL register, to the shared variable
;                       Laser. If either O or o was entered, Laser will be set to 
;                       LASER_ON. If either F or f was entered, Laser will be 
;                       set to Laser_OFF. 
;
; Arguments:			TokenVal (AL) - Token value for the character.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		Laser    (DS) - Value indicating whether laser is on or 
;                                       off (W).
; Global Variables:		None.
;
; Input:				Laser related command character from the serial line.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

SetLaserSV			PROC        NEAR
                    PUBLIC      SetLaserSV
                    
        XOR     AH, AH                          ;clear the AH register so that
                                                ;   SetLaser function will be
                                                ;   called with correct values                                
        MOV     Laser, AX                       ;sets Laser to appropriate value
                                                ;   depending on the type of 
                                                ;   command character that was
                                                ;   input to the serial line
        RET                                     ;now, we are done					
                    
SetLaserSV   		ENDP  



; DoNOP
;
; Description:			The action routine is called whenever the state machine
;                       has to change the state but does not need to perform any
;                       particular action. It does nothing and just returns.
;
; Operation:			The action routine simply returns. It does not perform
;                       any other operation since the state machine only requires
;                       the state to be changed. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		None.
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	None.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

DoNOP			    PROC        NEAR
                    PUBLIC      DoNOP
					
        RET                                     ;do nothing and return
                    
DoNOP   		    ENDP  



; SetAbsSpeed
;
; Description:			The action routine is called whenever <return> is input  
;                       in the serial line while the state machine is in the 
;                       ST_SETABSSPEEDDIGIT. It sets the absolute speed of the
;                       RoboTrike by setting the parsed number, CurrNum, as the 
;                       speed while making sure the direction of movement 
;                       is not changed. It then outputs a status update message
;						to the LED display.
;
; Operation:			The action routine utilizes the value in CurrNum as the  
;                       speed argument of SetMotorSpeed. Since the direction
;                       of movement should not change, KEEP_ANGLE is used as
;                       the angle argument. It then calls the UpdateStatus 
;						function to put a message to the LED display.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrNum (DS) - Current number that is being parsed (R).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Activation of DC motors on the RoboTrike.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, BX, flags.
; Limitations:			The action routine can only accept an integer that will
;                       fit in fifteen bits. Hence, to operate at maximum speed,
;                       the user must utilize SetAbsSpeed AND SetRelSpeed.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

SetAbsSpeed			PROC        NEAR
                    PUBLIC      SetAbsSpeed
					
SetAbsSpeedInit:                                ;prepare for function call
        MOV     AX, CurrNum                     ;move the parsed numerical value
                                                ;   to AX to prepare for function
                                                ;   call
        MOV     BX, KEEP_ANGLE                  ;make sure the direction of movement
                                                ;   is not changed by moving 
                                                ;   KEEP_ANGLE to BX
        ;JMP    CallSetAbsSpeed

CallSetAbsSpeed:                                ;call the appropriate functions
        CALL    SetMotorSpeed                   ;set speed to CurrNum, and do not
                                                ;   change the current direction
                                                ;   of movement
		CALL	UpdateStatus					;update the status
        ;JMP    EndSetAbsSpeed

EndSetAbsSpeed:                                 ;now, we are done
        RET 
                    
SetAbsSpeed   		ENDP  



; SetRelSpeed
;
; Description:			The action routine is called whenever <return> is input
;                       in the serial line while the state machine is in
;                       ST_SETRELSPEEDDIGIT. It accelerates or decelerates the
;                       RoboTrike by the value of the parsed number, CurrNum, 
;                       while making sure the direction of movement is not changed.
;                       If the speed goes over MAX_SPEED, it will just be set to
;                       MAX_SPEED and report no error. If the speed goes below 
;                       MIN_SPEED, it will just be set to MIN_SPEED and report
;                       no error. If the updated speed happens to equal KEEP_SPEED,
;                       it will be set to MAX_SPEED to actually change the speed
;                       of the RoboTrike. It then outputs a status update message
;						to the LED display.

; Operation:			The action routine initially calls GetMotorSpeed to obtain
;                       the current speed of the RoboTrike. It then adds the 
;                       current speed of the RoboTrike to the value in CurrNum.
;                       The carry flag and value of Sign is then utilized to see
;                       if the speed has gone over KEEP_SPEED or below MIN_SPEED.
;                       (1) If the flag was set and Sign was equal to POS_SIGN,
;                       there must have been a unsigned carry and the speed is
;                       set to MAX_SPEED. (2) If the flag was set and Sign was
;                       equal to NEG_SIGN, |Current Speed| > |CurrNum|, so the
;                       new speed would still be a valid positive speed. (3) If
;                       the flag was NOT set and the Sign was equal to POS_SIGN,
;                       there was no positive overflow and the speed just needs
;                       to be checked if it is equal to KEEP_SPEED. If it is, it
;                       is simply set to MAX_SPEED. (4) If the flag was NOT set
;                       and the Sign was equal to NEG_SIGN, |Current Speed| <
;                       |CurrNum|, so there must have been an unsigned borrow
;                       and the speed is set to MIN_SPEED.
;                       Once this operation is over, SetMotorSpeed is called with
;                       the appropriate speed argument and KEEP_ANGLE as the 
;                       angle argument since we do not wish to change the direction
;                       of movement. It then calls the UpdateStatus function to
;						put a message to the LED display.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		NewSpeed(AX) - Updated speed of the RoboTrike. 
; Shared Variables:		CurrNum (DS) - Current number that is being parsed (R).
;                       Sign    (DS) - Variable used to indicate sign (R).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Activation of DC motors on the RoboTrike.
;
; Error Handling:		If the updated speed argument is greater than or equal
;                       to KEEP_SPEED, it is set to MAX_SPEED. If the updated
;                       speed argument is less than MIN_SPEED, it is set to 
;                       MIN_SPEED. 
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, BX, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision
;						11/25/16	Dong Hyun Kim		debugged code

SetRelSpeed			PROC        NEAR
                    PUBLIC      SetRelSpeed
					
SetRelSpeedInit:                                ;initialization
        MOV     BX, KEEP_ANGLE                  ;make sure the direction of movement
                                                ;   is not changed by moving 
                                                ;   KEEP_ANGLE to BX
        CALL    GetMotorSpeed                   ;obtain value of current speed
                                                ;   in AX register
        ADD     AX, CurrNum                     ;NewSpeed = Current Speed + CurrNum
                                                ;   this will also update the 
                                                ;   carry flag
        JC      CheckPositiveBounds             ;if the carry flag was set, there
                                                ;   is a possibility that the 
                                                ;   updated speed went out of 
                                                ;   positive bounds. Hence, we 
                                                ;   must check whether or not
                                                ;   this happened while performing
                                                ;   the addition.
        ;JNC    CheckNegativeBounds        

CheckNegativeBounds:                            ;if the carry flag was not set,
        CMP     Sign, POS_SIGN                  ;   there was no unsigned carry.
                                                ;   However, there might have 
                                                ;   been an unsigned borrow or
                                                ;   the updated speed might be
                                                ;   equal to KEEP_SPEED. Hence,
                                                ;   we must check which case it 
                                                ;   is and handle it accordingly
        JE      CheckFixSpeed                   ;if CurrNum was positive, we just
                                                ;   have to make sure the updated
                                                ;   speed is not equal to KEEP_SPEED
        ;JNE    SetMinSpeed                     
        
SetMinSpeed:                                    ;otherwise, |Current Speed| <
                                                ;   |CurrNum|, and since CurrNum
                                                ;   was negative and Current Speed
                                                ;   is always positive, there must
                                                ;   have been an unsigned borrow
        MOV     AX, MIN_SPEED                   ;since there was an unsigned 
                                                ;   borrow and the updated speed
                                                ;   is less than that of MIN_SPEED,
                                                ;   we set it to MIN_SPEED to 
                                                ;   prevent issues 
        JMP     CallSetRelSpeed                 ;now, call the appropriate function
        
CheckFixSpeed:                                  ;since there was no unsigned carry,
        CMP     AX, KEEP_SPEED                  ;   we just have to make sure that
                                                ;   the added positive values of
                                                ;   speed will not equal that of
                                                ;   KEEP_SPEED                                                
        JE      SetMaxSpeed                     ;since we wish to change the value
                                                ;   of speed of the RoboTrike,
                                                ;   we set the speed to MAX_SPEED
        JNE     CallSetRelSpeed                 ;now, call the appropriate function

CheckPositiveBounds:                            ;if the carry flag was set, we 
        CMP     Sign, POS_SIGN                  ;   must check if the updated 
                                                ;   speed is valid or not. 
        JE      SetMaxSpeed                     ;if CurrNum was positive, there 
                                                ;   must have been an unsigned
                                                ;   carry and the updated speed
                                                ;   went out of bounds. Hence,
                                                ;   we must set it to MAX_SPEED
                                                ;   to prevent issues
        JNE     CallSetRelSpeed                 ;otherwise, |Current Speed| >
                                                ;   |CurrNum|, and since CurrNum
                                                ;   was negative and Current Speed
                                                ;   is always positive, the updated
                                                ;   speed must be valid    
        
SetMaxSpeed:                                    ;if speed is greater than or 
        MOV     AX, MAX_SPEED                   ;   equal to KEEP_SPEED, set the
                                                ;   updated speed to MAX_SPEED
                                                ;   so it will not ignore the 
                                                ;   speed argument
        ;JMP    CallSetRelSpeed

CallSetRelSpeed:                                ;call the appropriate functions
        CALL    SetMotorSpeed                   ;update the speed but do not
                                                ;   change the current direction
                                                ;   of movement      
		CALL	UpdateStatus					;update the status												
        ;JMP    EndSetRelSpeed
        
EndSetRelSpeed:                                 ;end the function
        RET
                                                                   
SetRelSpeed   		ENDP  



; SetDirection
;
; Description:			The action routine is called whenever <return> is input
;                       in the serial line while the state machine is in 
;                       ST_SETDIRECTIONDIGIT. It sets the direction of movement
;                       specified by the parsed number, CurrNum, relative to the
;                       current direction of movement. A positive angle indicates
;                       a direction to the right (looking down on the RoboTrike),
;                       while a negative angle indicates a direction to the left.
;                       The action routine does not change the speed setting.
;						It then outputs a status update message to the LED display.
;
; Operation:			The action routine initially normalizes the value of 
;                       CurrNum by performing an operation (similar to a modulo,
;                       but not quite) that makes it fall between negative 
;                       MAX_ANGLE and positive MAX_ANGLE. This operation is 
;                       important since it prevents any potential overflow. 
;                       It then calls the GetMotorDirection function to obtain
;                       the current angle of movement, which is added with the
;                       normalized value of CurrNum. The SetMotorSpeed function
;                       is then called with the updated angle value as the 
;                       angle argument and KEEP_SPEED as the speed argument
;                       since we do not want to change the speed setting. It then 
;						calls the UpdateStatus function to put a message to the
;						LED display.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrNum (DS) - Current number that is being parsed (R).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Change of direction of movement on the RoboTrike.
;
; Global Variables:		None.
;
; Input:				None.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, BX, DX, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision
;						11/25/16	Dong Hyun Kim		debugged code

SetDirection		PROC        NEAR
                    PUBLIC      SetDirection
					
NormalizeAngle:                                 ;perform operation so angle is 
                                                ;   between negative MAX_ANGLE 
                                                ;   and positive MAX_ANGLE
        MOV     AX, CurrNum                     ;store angle in the accumulator
                                                ;   to use the IDIV command
        MOV     BX, FULL_ANGLE                  ;store FULL_ANGLE in BX to use
                                                ;   IDIV command
        CWD                                     ;extend the sign bit of the angle 
                                                ;	for signed division, converting 
                                                ;   the angle to a double word 
                                                ;   to allow IDIV to store the 
                                                ;   remainder in the DX register    
		IDIV	BX							    ;perform a signed division of the 
                                                ;	current angle to get a remainder
                                                ;	in the DX register. Since the 
                                                ;	sign of the remainder is always  
                                                ;	the same as the sign of the 
                                                ;	dividend for the IDIV command,
                                                ;	CurrNum is now betweeen 
                                                ;   negative MAX_ANGLE and 
                                                ;   positive MAX_ANGLE
        ;JMP    UpdateAngle     

UpdateAngle:                                    ;now, update the value of angle  
        CALL    GetMotorDirection               ;obtain value of current direction
                                                ;   of movement and put in AX
        ADD     AX, DX                          ;NewAngle = Angle + Normalized                                                        
                                                ;   Value of CurrNum
        ;JMP    CallSetDirection

CallSetDirection:                               ;call the appropriate functions
        MOV     BX, AX                          ;used the updated angle as the 
                                                ;   argument for function                                       
        MOV     AX, KEEP_SPEED                  ;make sure the speed setting is
                                                ;   not changed by moving
                                                ;   KEEP_SPEED to AX   
        CALL    SetMotorSpeed                   ;update the direction of movement
                                                ;   but do not affect the speed
                                                ;   of the RoboTrike
		CALL	UpdateStatus					;update the status																								
        ;JMP    EndSetDirection

EndSetDirection:                                ;end the function
        RET
                                      
SetDirection   		ENDP  



; RotRelTurAngle
;
; Description:			The action routine is called whenever <return> is input
;                       in the serial line while the state machine is in 
;                       ST_RELTURANGLEDIGIT. It sets the angle of the turret
;                       specified by the parsed number, CurrNum, relative to 
;                       the current position of the turret. A positive angle 
;                       indicates a rotation to the right from the current position
;                       (looking down on the RoboTrike), while a negative angle
;                       indicates a rotation to the left from the current position.
;
; Operation:			The action routine utilizes the value in CurrNum as the 
;                       argument of SetRelTurretAngle. It then calls the function
;                       accordingly. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrNum (DS) - Current number that is being parsed (R).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Rotation of turret on the RoboTrike.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

RotRelTurAngle		PROC        NEAR
                    PUBLIC      RotRelTurAngle
                    
        MOV     AX, CurrNum                     ;move the parsed numerical value
                                                ;   to AX to prepare for function
                                                ;   call
        CALL    SetRelTurretAngle               ;set the relative angle through 
                                                ;   which to turn the turret 
                                                ;   to CurrNum																							
												
        RET                                     ;now, end the function
        
RotRelTurAngle   	ENDP  



; RotAbsTurAngle
;
; Description:			The action routine is called whenever <return> is input
;                       in the serial line while the state machine is in 
;                       ST_ABSTURANGLEDIGIT. It sets the absoulte angle of the 
;                       turret specified by the parsed number, CurrNum, at which 
;                       the turret is to be pointed. An angle of zero indicates 
;                       straight ahead relative to the RoboTrike orientation and 
;                       non-zero angles are measured clockwise.
;
; Operation:			The action routine utilizes the value in CurrNum as the 
;                       argument of SetTurretAngle. It then calls the function
;                       accordingly. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrNum (DS) - Current number that is being parsed (R).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Rotation of turret on the RoboTrike.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

RotAbsTurAngle		PROC        NEAR
                    PUBLIC      RotAbsTurAngle
					
        MOV     AX, CurrNum                     ;move the parsed numerical value
                                                ;   to AX to prepare for function
                                                ;   call
        CALL    SetTurretAngle                  ;set the absolute angle at 
                                                ;   which to point the turret 
                                                ;   to CurrNum
        RET                                     ;now, end the function                    
                    
RotAbsTurAngle   	ENDP  



; SetTurElev
;
; Description:			The action routine is called whenver <return> is input 
;                       in the serial line while the state machine is in 
;                       ST_SETTURELEVDIGIT. It sets the angle (in degrees relative
;                       to the horizontal), specified by the parsed number, 
;                       CurrNum, at which the turret is to be pointed up or down.
;                       The angle is signed (positive for "up" and negative for
;                       "down") and must be in the range of MIN_ELEV and MAX_ELEV.
;                       If a positive signed angle is greater than MAX_ELEV, it
;                       will just be set to MAX_ELEV. If a negative signed angle
;                       is less than MIN_ELEV, it will just be set to MIN_ELEV.
;
; Operation:			The action routine utilizes the value in CurrNum as the
;                       argument of SetTurretElevation. If the signed positive
;                       value is greater than MAX_ELEV, the argument will just
;                       be set to MAX_ELEV. If the signed negative value is 
;                       greater than MIN_ELEV, the argument will just be set to
;                       MIN_ELEV. It then calls the function accordingly.
;
; Arguments:		    None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrNum (DS) - Current number that is being parsed (R).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Change of elevation of turret on RoboTrike.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision
;						11/25/16	Dong Hyun Kim		debugged code

SetTurElev		    PROC        NEAR
                    PUBLIC      SetTurElev

SetTurElevInit:                                 ;initialization
        MOV     AX, CurrNum                     ;move the parsed numerical value
                                                ;   to AX to prepare for function
                                                ;   call
                    
CheckIfBig:                                     ;check if signed angle, currently       
        CMP     AX, MAX_ELEV                    ;   stored in CurrNum, is less
                                                ;   than or equal to MAX_ELEV
        JLE     CheckIfSmall                    ;if so, check if signed angle
                                                ;   is greater than or equal to
                                                ;   MIN_ELEV
        ;JG     SetMaxElev                      ;if not, set the argument to 
                                                ;   MAX_ELEV so there will be 
                                                ;   no issues when calling the 
                                                ;   function             
        
SetMaxElev:                                     ;set the argument to MAX_ELEV
        MOV     AX, MAX_ELEV                    ;   so there are no issues when
                                                ;   calling the function
        JMP     CallSetTurElev                  ;now, call the function        

CheckIfSmall:                                   ;check if signed angle, currently
        CMP     AX, MIN_ELEV                    ;   stored in CurrNum, is smaller
                                                ;   than MIN_ELEV
        JGE     CallSetTurElev                  ;if so, call the function since
                                                ;   the angle is valid
        ;JL     SetMinElev                      ;if not, set the argument to 
                                                ;   MIN_ELEV so there will be
                                                ;   no issues when calling the
                                                ;   function
                                                
SetMinElev:                                     ;set the argument to MIN_ELEV
        MOV     AX, MIN_ELEV                    ;   so there are no issues when
                                                ;   calling the function
        ;JMP    CallSetTurElev                                                                  

CallSetTurElev:                                 ;call the appropriate function
        CALL    SetTurretElevation              ;set the angle at which the 
                                                ;   turret is to be pointed up
                                                ;   or down
        ;JMP    EndSetTurElev

EndSetTurElev:                                  ;end the function        
        RET                                                              
					
SetTurElev   	    ENDP 



; OperateLaser
;
; Description:			The action routine is called whenever <return> is input
;                       in the serial line while the state machine is in 
;                       ST_SETLASERINIT. It turns the laser of the RoboTrike either
;                       on or off depending on the value of the shared variable,
;                       Laser. It outputs a status update message to the LED
;						display.
;
; Operation:			The action routine simply utilizes the value in Laser  
;                       and calls the SetLaser function to indicate that the 
;                       laser must be turned on or off. If the value of Laser
;                       was equal to that of LASER_OFF, the laser will be turned
;                       onff Otherwise, it will be turned on. It then calls the
;						UpdateStatus function to output a update status message.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		Laser   (DS) - Value indicating whether laser is on or 
;                                      off (W).
; Global Variables:		None.
;
; Input:				<return> from the serial line.
; Output:				Activation of the laser through SetLaser.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/21/16    Dong Hyun Kim       wrote pseudo code
;                       11/24/16    Dong Hyun Kim       initial revision

OperateLaser		PROC        NEAR
                    PUBLIC      OperateLaser
        
        MOV     AX, Laser                       ;move the value of Laser to the
                                                ;   accmunlator to prepare for
                                                ;   function call
        CALL    SetLaser                        ;turn laser on or off depending
                                                ;   on the value in AX
		CALL	UpdateStatus					;update the status																								
												
        RET                                     ;now, we are done                                                
					
OperateLaser   		ENDP  



; StateTable
;
; Description:      This is the state transition table for the state machine.
;                   Each entry consists of the next state and an action for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Dong Hyun Kim
; Last Modified:    Nov. 24, 2016


TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entry to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act)>
)


StateTable      LABEL   TRANSITION_ENTRY

        ;Current State = ST_IDLE                         Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, DoNOP)                     ;TOKEN_ENTER
        %TRANSITION(ST_SETABSSPEEDINIT, DoNOP)          ;TOKEN_S
        %TRANSITION(ST_SETRELSPEEDINIT, DoNOP)          ;TOKEN_V
        %TRANSITION(ST_SETDIRECTIONINIT, DoNOP)         ;TOKEN_D
        %TRANSITION(ST_ROTTURANGLEINIT, DoNOP)          ;TOKEN_T
        %TRANSITION(ST_SETTURELEVINIT, DoNOP)           ;TOKEN_E
        %TRANSITION(ST_SETLASERINIT, SetLaserSV)        ;TOKEN_0F
        %TRANSITION(ST_IDLE, DoNOP)                     ;TOKEN_OTHER
        
        ;Current State = ST_SETABSSPEEDINIT              Input Token Type
        %TRANSITION(ST_SETABSSPEEDSIGN, SetSign)        ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETABSSPEEDDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETABSSPEEDINIT, DoNOP)          ;TOKEN_OTHER
        
        ;Current State = ST_SETABSSPEEDDIGIT             Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETABSSPEEDDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetAbsSpeed)               ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETABSSPEEDDIGIT, DoNOP)         ;TOKEN_OTHER
        
        ;Current State = ST_SETABSSPEEDSIGN              Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETABSSPEEDDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETABSSPEEDSIGN, DoNOP)          ;TOKEN_OTHER
        
        ;Current State = ST_SETRELSPEEDINIT              Input Token Type
        %TRANSITION(ST_SETRELSPEEDSIGN, SetSign)        ;TOKEN_POS
        %TRANSITION(ST_SETRELSPEEDSIGN, SetSign)        ;TOKEN_NEG
        %TRANSITION(ST_SETRELSPEEDDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETRELSPEEDINIT, DoNOP)          ;TOKEN_OTHER
        
        ;Current State = ST_SETRELSPEEDDIGIT             Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETRELSPEEDDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetRelSpeed)               ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETRELSPEEDDIGIT, DoNOP)         ;TOKEN_OTHER
        
        ;Current State = ST_SETRELSPEEDSIGN              Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETRELSPEEDDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETRELSPEEDSIGN, DoNOP)          ;TOKEN_OTHER        

        ;Current State = ST_SETDIRECTIONINIT             Input Token Type
        %TRANSITION(ST_SETDIRECTIONSIGN, SetSign)       ;TOKEN_POS
        %TRANSITION(ST_SETDIRECTIONSIGN, SetSign)       ;TOKEN_NEG
        %TRANSITION(ST_SETDIRECTIONDIGIT, ParseDigit)   ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETDIRECTIONINIT, DoNOP)         ;TOKEN_OTHER
        
        ;Current State = ST_SETDIRECTIONDIGIT            Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETDIRECTIONDIGIT, ParseDigit)   ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetDirection)              ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETDIRECTIONDIGIT, DoNOP)        ;TOKEN_OTHER
        
        ;Current State = ST_SETDIRECTIONSIGN             Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETDIRECTIONDIGIT, ParseDigit)   ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETDIRECTIONSIGN, DoNOP)         ;TOKEN_OTHER 

        ;Current State = ST_ROTTURANGLEINIT              Input Token Type
        %TRANSITION(ST_RELTURANGLESIGN, SetSign)        ;TOKEN_POS
        %TRANSITION(ST_RELTURANGLESIGN, SetSign)        ;TOKEN_NEG
        %TRANSITION(ST_ABSTURANGLEDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_ROTTURANGLEINIT, DoNOP)          ;TOKEN_OTHER
        
        ;Current State = ST_RELTURANGLEDIGIT             Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_RELTURANGLEDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, RotRelTurAngle)            ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_RELTURANGLEDIGIT, DoNOP)         ;TOKEN_OTHER
        
        ;Current State = ST_RELTURANGLESIGN              Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_RELTURANGLEDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_RELTURANGLESIGN, DoNOP)          ;TOKEN_OTHER           
    
        ;Current State = ST_ABSTURANGLEDIGIT             Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_ABSTURANGLEDIGIT, ParseDigit)    ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, RotAbsTurAngle)            ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_ABSTURANGLEDIGIT, DoNOP)         ;TOKEN_OTHER
        
        ;Current State = ST_SETTURELEVINIT               Input Token Type
        %TRANSITION(ST_SETTURELEVSIGN, SetSign)         ;TOKEN_POS
        %TRANSITION(ST_SETTURELEVSIGN, SetSign)         ;TOKEN_NEG
        %TRANSITION(ST_SETTURELEVDIGIT, ParseDigit)     ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETTURELEVINIT, DoNOP)           ;TOKEN_OTHER
        
        ;Current State = ST_SETTURELEVDIGIT              Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETTURELEVDIGIT, ParseDigit)     ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetTurElev)                ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETTURELEVDIGIT, DoNOP)          ;TOKEN_OTHER
        
        ;Current State = ST_SETTURELEVSIGN               Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_SETTURELEVDIGIT, ParseDigit)     ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETTURELEVSIGN, DoNOP)           ;TOKEN_OTHER  

        ;Current State = ST_SETLASERINIT                 Input Token Type
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_POS
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_NEG
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_DIGIT
        %TRANSITION(ST_IDLE, OperateLaser)              ;TOKEN_ENTER
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_S
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_V
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_D
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_T
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_E
        %TRANSITION(ST_IDLE, SetError)                  ;TOKEN_0F
        %TRANSITION(ST_SETLASERINIT, DoNOP)             ;TOKEN_OTHER
        
        

; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Author:           Dong Hyun Kim
; Last Modified:    Nov. 24, 2016

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_OTHER, 0)		;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_OTHER, 9)		;TAB
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_ENTER, 13)    ;<return> (carriage return)
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_OTHER, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_POS, POS_SIGN);+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_NEG, NEG_SIGN);-  (negative sign)
        %TABENT(TOKEN_OTHER, '.')	;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, 0)		;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)		;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)		;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)		;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)		;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)		;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)		;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)		;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)		;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_D,     'D')	;D  (Set Direction)
        %TABENT(TOKEN_E,     'E')   ;E  (Set Turret Elevation Angle)
        %TABENT(TOKEN_OF, LASER_ON) ;F  (Laser On)
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_OF, LASER_OFF);O  (Laser Off)
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S,     'S')	;S  (Set Absolute Speed)
        %TABENT(TOKEN_T,     'T')	;T  (Rotate Turret Angle)
        %TABENT(TOKEN_OTHER, 'U')	;U 
        %TABENT(TOKEN_V,     'V')	;V  (Set Relative Speed)
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_D,     'd')	;d  (Set Direction)
        %TABENT(TOKEN_E,     'e')   ;e  (Set Turret Elevation Angle) 
        %TABENT(TOKEN_OF, LASER_ON) ;f  (Laser On)
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_OF, LASER_OFF);o  (Laser Off)
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_S,     's')	;s  (Set Absolute Speed)
        %TABENT(TOKEN_T,     't')	;t  (Rotate Turret Angle)
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_V,     'v')	;v  (Set Relative Speed)
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE


; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE
       
        
        
CODE    ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

CurrNum         DW      ?               ;Value of current number that is being
                                        ;   parsed. Unless there is an error, 
                                        ;   CurrNum will be utilized in action
                                        ;   routines as an argument for the 
                                        ;   external functions declared above.
Sign            DB      ?               ;Variable used to indicate whether there
                                        ;   was a sign in the command line. If 
                                        ;   there was a positive sign, Sign will
                                        ;   equal POS_SIGN. Otherwise, it will
                                        ;   equal NEG_SIGN. It will be utilized
                                        ;   in the ParseDigit function to calculate
                                        ;   the correct numerical value from 
                                        ;   ASCII.
CurrSt          DB      ?               ;Value that corresponds to the current
                                        ;   state of the state machine. It will
                                        ;   be updated in ParseSerialChar after
                                        ;   performing the appropriate action. 
                                        ;   Anytime there is an error, it will
                                        ;   be reset to ST_IDLE.
Laser           DW      ?               ;Variable used to indicate whether or not
                                        ;   the laser should be turned on or off.
                                        ;   If it equals LASER_ON, the laser 
                                        ;   should be turned on. Otherwise, the 
                                        ;   laser should be turned off.
ParserError     DB      ?               ;Variable used to indicate whether or not
                                        ;   there was an error while parsing the
                                        ;   command. It is set whenever a legal
                                        ;   character is misused - for example,
                                        ;   if there is a sign after a digit. It
                                        ;   is NOT set if an illegal character is
                                        ;   entered (those are just ignored).                                    
											
DATA    ENDS

END