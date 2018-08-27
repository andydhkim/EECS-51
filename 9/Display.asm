        NAME    Display

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Display                                  ;
;                               Display Functions                          	 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:	This file includes five display functions used for RoboTrike. It
;				can initialize shared variables that will be used in other functions
;				and output a string or number to the display. It also displays
;				a digit on the LED display whenever there is an interrupt. 
;               
; Table of Contents:
;   Display:		Outputs a string to the display.
;	DisplayNum:		Outputs a number to the display in decimal, with a negative
;					sign if negative. 
;	DisplayHex:		Outputs a number to the display in hexadecimal.
;	InitDisplay:	Initializes the shared variables that will be used in the file.
;	Multiplex:		Displays a digit on the display whenever there is an interrupt.
;	
; Revision History:
;   10/27/16    Dong Hyun Kim       initial revision
;   10/28/16    Dong Hyun Kim       debugged code and updated comments
;   12/01/16    Dong Hyun Kim       updated code so that it is compatible with
;                                   14-segment display



; local include files
$INCLUDE(Display.INC)					;includes addresses and definitions
$INCLUDE(General.INC)                   ;include general definitions 



CGROUP  GROUP   CODE
DGROUP  GROUP	DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

		
		
;external function declarations
        EXTRN   Dec2String:NEAR			;converts singed 16-bit value to decimal 
										;	and outputs the string
		EXTRN	Hex2String:NEAR			;converts unsigned 16-bit value to hexa-
										;	decimal and outputs the string
		EXTRN   ASCIISegTable:NEAR      ;table of segment patterns for display

		

	   
; Display
;
; Description:			The function is passed a <null> terminated string (str) 
;						to the output to the LED display. The string is passed 
;						by reference in ES:SI. The string will be left justified
;                       at all times. If the string is of longer length than 
;                       LED_LENGTH, only the first LED_LENGTH digits/characters 
;                       will be displayed on the LED. If the string is of shorter
;                       length than LED_LENGTH, only the digits associated with
;                       the string will be shown on the LED.
;
; Operation:			The function will go through each digit of the code segment
;						until there is an ASCII_NULL (0H). Each of the digits
;                       will be converted into the appropriate segment pattern
;                       (which is represented by a binary number in segtable.asm)
;                       and stored into MuxBuffer. Any digits after the ASCII_NULL
;                       will be cleared by being set to 0, so that there are only
;                       the necessary digits displayed on the LED.
;
; Arguments:			str (ES:SI)	- address with memory location containing string
; Return Value:			None.
;
; Local Variables:		CurrentVal(AL) - current value of string
;                       i 		  (BX) - count variable for MuxBuffer.
; Shared Variables:		MuxIndex  (DS) - index of current digit (R/W).
;						MuxBuffer (DS) - array containing all of the digits
;										 that will be displayed (R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				Communicates with the LED display but does not output directly.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	Flags, AX, BX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        ES is used (as opposed to DS) so the string can be in 
;						code segment (i.e. it can be a constant string) without
;						needing to change DS, which can cause many problems.
; Revision History:     10/28/16    Dong Hyun Kim       initial revision
;                       10/28/16    Dong Hyun Kim       debugged code and updated
;														comments
;						12/01/16	Dong Hyun Kim		revised code

Display			PROC        NEAR
                PUBLIC      Display

DisplayInit:                            ;Initialization
        MOV     BX, 0                   ;Set count variable to 0 so the function
										;	can start loop at the first element
										;	of MuxBuffer
        ;JMP    SetPatternLoop          

SetPatternLoop:                         ;loop that goes through MuxBuffer to
                                        ;   convert digit into segment pattern
        CMP     BX, BUF_LENGTH          ;if the MuxBuffer is already fully converted,
                                        ;   there is no space to convert any more
                                        ;   digits so we should exit the loop.
        JAE     ClearRemainderLoop      ;if i >= BUF_LENGTH, exit the loop and
                                        ;   clear the remainder of MuxBuffer so 
                                        ;   the it won't affect any strings in 
                                        ;   the future
        ;JB     CheckIfNull             ;if i < BUF_LENGTH, continue to stay in 
                                        ;   the loop and check if digit is an
                                        ;   ASCII_NULL 
        
CheckIfNull:                            ;checks to see if there is ASCII_NULL
                                        ;   in the string
        PUSH    BX                      ;preserve counter value since we are
                                        ;   manipulating it for just one operation
        SAR     BX, 1                   ;currently, the index is for a word array
                                        ;   that will be incremented by 
                                        ;   WORD_SIZE every loop. Since we
                                        ;   are now going to go through the byte
                                        ;   array (specifically, the string), we
                                        ;   need to convert to a byte index.
        MOV     AL, ES:[SI + BX]        ;obtain the character to display to the
                                        ;   LED and store in the AL register to
                                        ;   compare with ASCII_NULL
        POP     BX                      ;restore original value of register                  
        CMP     AL, ASCII_NULL          ;if the current digit in the passed string
                                        ;   is an ASCII_NULL, we should exit the
                                        ;   loop
        JE      ClearRemainderLoop      ;if current digit == ASCII_NULL, exit the
                                        ;   loop and clear remainder        
        ;JNE    SetPattern              ;if current digit =! ASCI_NULL, continue
                                        ;   to stay in the loop and set pattern
        
SetPattern:                             ;sets the segment pattern for the digits
                                        ;   in MuxBuffer
        CBW                             ;convert the character that we obtained
                                        ;   from a byte to a string so we can
                                        ;   utilize the lookup table correctly
        PUSH    BX                      ;preserve counter value since we are
                                        ;   manipulating it for just one operation                  
        MOV     BX, AX                  ;put the word character into BX since we
                                        ;   need to index through the lookup 
                                        ;   table
        SAL     BX, 1                   ;as above, the index is currently for a
                                        ;   byte table. Since we going to utilize
                                        ;   a word table for the 14-segment display,
                                        ;   we must convert the index to a word
                                        ;   index to go through the look up
                                        ;   table 
        MOV     AX, CS:ASCIISegTable[BX];obtain the correct segment pattern for
                                        ;   higher byte and store appropriately
        POP     BX                      ;restore original value of register                                                           
        MOV     MuxBuffer[BX], AX       ;Store the converted digit into MuxBuffer
        ADD     BX, WORD_SIZE           ;stay in loop by incrementing i
        JMP     SetPatternLoop          ;continue the process through the string
        
ClearRemainderLoop:                     ;loop to clear any data after the ASCII_NULL
                                        ;   to make sure there are no problems in
                                        ;   the future regarding the display.
        CMP     BX, BUF_LENGTH          ;if final index of the MuxBuffer is reached
                                        ;   we have cleared all the data and can
                                        ;   safely exit loop
        JAE     EndDisplay              ;if i >= BUF_LENGTH, we are done clearing
        MOV     MuxBuffer[BX], 0        ;if i < BUF_LENGTH, set the element in 
                                        ;   the MuxBuffer to 0
        ADD     BX, WORD_SIZE           ;stay in loop by incrementing the word
                                        ;   index properly
        JMP     ClearRemainderLoop      ;continue the process until end of MuxBuffer
                                        ;   is reached
        
EndDisplay:                             ;end the function
        RET


Display		ENDP




; DisplayNum
;
; Description:			The function is passed a 16-bit value (AX) to output in
;						decimal to the LED display. There will be 5 numerical
;						digits if the number is positive, without a sign. There
;						will be 5 numerical digits and a '-' sign in the front
;						if the number is negative. Hence, a positive number will
;						be 5 digits long and a negative number will be 6 digits
;						long. There may be leading zeroes and the number will
;						be left justified. The reamining LEDs, if any, will be 
;						blanked. 
;
; Operation:			The function will start off by changing the address from
;						DS:SI to ES:SI (hence, the string will be stored in ES:SI).
;						It will then call Dec2String from converts.asm and convert
;						the 16-bit signed value into decimal. It will end by 
;						calling the display function from above and outputting the
;						decimal to the LED display. 
;
; Arguments:			n (AX)	- 16-bit signed value to display in decimal
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		StrCallBuffer (DS) - array containing the string from the 
;                                            Dec2String function call (R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				Communicates with the LED display but does not output directly.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	Flags, AX, BX, CX, DX, ES, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        Separate functional specification for the Dec2String
;						function is included in the converts.asm file.
;
; Revision History:     01/28/16    Dong Hyun Kim       initial revision
;                       01/28/16    Dong Hyun Kim       debugged code and updated comments

DisplayNum      PROC        NEAR
                PUBLIC      DisplayNum

DisplayNumInit:							;Initialization
        MOV     SI, OFFSET(StrCallBuffer)   ;Use a separate buffer to make sure 
                                            ;   important data in SI will not be  
                                            ;   overwritten and we know where SI   
                                            ;   is currently pointing.
		PUSH	DS						;Need to change from DS:SI to ES:SI in 
		POP		ES						;	order to to call Display function
										;	correctly.
		;JMP	ConvertNum
		
ConvertNum:								;Call the Dec2String function
		PUSH	SI						;Save the value of SI because Dec2String
										;	modifies SI values									
		CALL	Dec2String				;Converts the signed 16-bit value in AX
										;	to decimal and stores it as a string 
										;	in ES:SI. 
		POP		SI						;Return SI back to its original value
		;JMP	OutputNum				

OutputNum:								;Call the Display function
		CALL	Display					;Output the string to the display, which 
										;	will be included in MuxBuffer and 
										;	displayed correctly on the LED through
                                        ;   Multiplex if needed.
		;JMP	EndDisplayNum			
		
EndDisplayNum:							;end the function		
		RET

DisplayNum	ENDP



; DisplayHex
;
; Description:			The function is passed a 16-bit unsigned value (AX) to 
;						output in hexadecimal to the LED display. There will be 4
;						numerical digits. There may be leading zeroes and the 
;						number will be left justified. The reamining LEDs will
;						be blanked. 
;
; Operation:			The function will start off by changing the address from
;						DS:SI to ES:SI (hence, the string will be stored in ES:SI).
;						It will then call Hex2String from converts.asm and convert
;						the 16-bit unsigned value into hexadecimal. It will end by 
;						calling the display function from above and output the
;						decimal to the LED display.
;
; Arguments:			n (AX)	- 16-bit unsigned value to display in hex.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		StrCallBuffer (DS) - array containing the string from the 
;                                            Dec2String function call (R/W).
; Global Variables:		None.
;
; Input:				None.
; Output:				Communicates with the LED display but does not output directly.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	Flags, AX, BX, CX, DX, ES, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        Separate functional specification for the Hex2String
;						function is included in the converts.asm file.   
;
; Revision History:     01/28/16    Dong Hyun Kim       initial revision
;                       01/28/16    Dong Hyun Kim       debugged code and updated comments

DisplayHex		PROC        NEAR
                PUBLIC      DisplayHex

DisplayHexInit:							;Initialization
        MOV     SI, OFFSET(StrCallBuffer)   ;Use a separate buffer to make sure 
                                            ;   important data in SI will not be  
                                            ;   overwritten and we know where SI   
                                            ;   is currently pointing.
		PUSH	DS						;Need to change from DS:SI to ES:SI in 
		POP		ES						;	order to to invoke Display function
										;	correctly.
		;JMP	ConvertHex				

ConvertHex:								;Call the Hex2String function
		PUSH	SI						;Save the value of SI because Hex2String
										;	modifies SI values
		CALL	Hex2String				;Converts the unsigned 16-bit value in AX
										;	to hexadecimal and stores it as a string 
										;	in ES:SI. 
		POP		SI						;Return SI back to its original value
		;JMP	OutputHex				

OutputHex:								;Call the display function	
		CALL	Display					;Output the string to the display, which 
										;	will be included in MuxBuffer and 
										;	displayed correctly on the LED through
                                        ;   Multiplex if needed.
		;JMP	EndDisplayHex

EndDisplayHex:							;end the function
		RET

DisplayHex	ENDP



; InitDisplay
;
; Description:			This function initializes the index of the current digit
;						being output and the buffer (MuxBuffer) containing the 
;						digits that will be displayed. 
;
; Operation:			The index of the current digit, MuxIndex, is set to zero. 
;						The function will then go through each digit of the MuxBuffer
;						and clear the values. This will successfully initialize
;						the code segment to display to the LED. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		i 		  (SI) - count variable for MuxBuffer. 
; Shared Variables:		MuxIndex  (DS) - index of current digit to be output (W).
;						MuxBuffer (DS) - array containing all of the digits
;										 that will be displayed (W).
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
; Registers Changed:	Flags, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     01/28/16    Dong Hyun Kim       initial revision
;                       01/28/16    Dong Hyun Kim       debugged code and updated comments 

InitDisplay		PROC        NEAR
                PUBLIC      InitDisplay

InitDisplayInit:						;Initialization
		MOV		MuxIndex, 0				;Set index of current digit to 0 in order to
										;	start at the beginning of the MuxBuffer
		MOV		SI, 0					;Set count variable to 0 so the function
										;	can start loop at the first element
										;	of MuxBuffer
		;JMP	ClearMuxBufLoop			

ClearMuxBufLoop:						;loop to initialize values of the MuxBuffer
		CMP		SI, BUF_LENGTH			;check if the index of current digit is
										;	greater than the BUF_LENGTH
		JAE		EndInitDisplay			;if index >= BUF_LENGTH, we have successfully
										;	initialized MuxBuffer
		;JB		ClearMuxBuf				;if not, we have to initialize the value
	
ClearMuxBuf:							;sets the value of current digit to 0
		MOV		MuxBuffer[SI], 0		;initializes the value of current digit
										;	by setting it to 0
		ADD		SI, WORD_SIZE  	        ;move on to the next element of MuxBuffer
		JMP		ClearMuxBufLoop			;repeat the process until index >= BUF_LENGTH

EndInitDisplay:							;end the function
		RET

InitDisplay		ENDP



; Multiplex
;
; Description:			The function is called whenever there is an interrupt
;						and displays a digit on the LED display. It should be
;						called every millisecond and go through the entire MuxBuffer
;                       from left to right to display the string on the LED
;						display correctly.
;
; Operation:			The function will first obtain the index of the current
;                       digit and the segment pattern of the current digit. It
;                       then outputs the high byte of the character by finding
;                       the correct offset address and utilizing the OUT command
;                       to display in the appropriate I/O location. If will then
;                       output the lower byte of the character by using the 
;                       correct address and following the same operation as the
;                       high byte character. Since the OUT command will only light 
;                       up one digit at a time, it will have to go through the entire
;                       MuxBuffer by incrementing MuxIndex by WORD_SIZE. It
;                       will wrap around MuxBuffer appropriately utilizing the
;                       modulo operation with BUF_LENGTH - 1. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		Pattern   (AX) - Segment pattern of a character.
;                       Address   (DX) - Address of appropriate segment.
; Shared Variables:		MuxIndex  (DS) - index of current digit to be output (R/W).
;						MuxBuffer (DS) - array containing all of the digits
;										 that will be displayed (R).
; Global Variables:		None.
;
; Input:				None.
; Output:				Pattern segment of digit to the LED display. 
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AL, DX, SI, flags.
; Limitations:			Length of mux buffer must be 2^n.
; Known Bugs:           None.
; Special Notes:       	None.
;
; Revision History:     10/28/16    Dong Hyun Kim       initial revision
;                       10/28/16    Dong Hyun Kim       debugged code and updated
;														comments
;						12/01/16	Dong Hyun Kim		revised code

Multiplex       PROC        NEAR
                PUBLIC      Multiplex

MultiplexInit:							;Initialization		
		MOV		BX, MuxIndex			;Store the index of current digit so the 
										;	function can increment later 
        MOV     AX, MuxBuffer[BX]       ;obtain the segment pattern to output to
                                        ;   the LED from MuxBuffer 
        ;JMP    HighCharOutput          
        
HighCharOutput:                         ;output the higher byte of the word character
        MOV     DX, HighCharAddr        ;obtain the address of the correct segment
                                        ;   of the LED display to output the 
                                        ;   higher byte to
        XCHG    AL, AH                  ;store the higher byte of the word character
                                        ;   into the AL register in order to use
                                        ;   the OUT command
        OUT     DX, AL                  ;write the higher byte of the word 
                                        ;   character to the LED display                                          
		;JMP	LowCharOutput			
        
LowCharOutput:                          ;output the lower byte of the word character
        MOV     DX, LowCharAddr         ;obtain the address of the first segment
                                        ;   of the LED display to output the 
                                        ;   lower byte to     
        PUSH    BX                      ;preserve value of BX since we will use
                                        ;   it to index through byte array
        SAR     BX, 1                   ;MuxIndex is used to go through a word
                                        ;   array, but the offset address we need
                                        ;   for the display is one for a byte
                                        ;   array. This is because we can imagine
                                        ;   the LED display as a byte array with
                                        ;   LED_LENGTH bytes.
        ADD     DX, BX                  ;make sure the address we are outputting 
                                        ;   to is the correct one by adding the
                                        ;   correct offset to LowCharAddr
        POP     BX                      ;restore value of BX                      
        XCHG    AL, AH                  ;store the lower byte of the word character
                                        ;   into the AL register                                          
        OUT     DX, AL                  ;write the lower byte of the word character
                                        ;   to the LED display
        ;JMP    CheckIndex

CheckIndex:								;Wrap around MuxBuffer if index is greater
                                        ;   than BUF_LENGTH
        ADD     BX, WORD_SIZE		    ;Move on to the next index of digit
		AND		BX, BUF_LENGTH - 1		;MuxIndex = MuxIndex MOD BUF_LENGTH
										;	allows the MuxIndex to wrap around
										;	MuxBuffer and go to the beginning
		MOV		MuxIndex, BX			;update the value of MuxIndex if needed
		;JMP	EndMultiplex

EndMultiplex:							;end the function
		RET
		
Multiplex	ENDP



CODE    ENDS


				
;the data segment (empty for the main loop)

DATA    SEGMENT PUBLIC  'DATA'

MuxIndex		DW		?						;Index of current digit 
MuxBuffer		DW		LED_LENGTH	DUP (?)		;The array containing all of the
                                                ;   digits/characters that will
                                                ;   be displayed. The length is 
                                                ;   limited to LED_LENGTH since
                                                ;   there can be only LED_LENGTH
                                                ;   amount of digits/characters
                                                ;   that can be displayed on the
                                                ;   LED. However, this does mean'
                                                ;   that there are a total of 
                                                ;   BUF_LENGTH bytes in the array.
StrCallBuffer   DB      BUF_LENGTH  DUP (?)     ;The array containing the string
                                                ;   from the Dec2String and Hex2String
                                                ;   function calls. This buffer is
                                                ;   needed because we do not want
                                                ;   any important information in 
                                                ;   SI to be overwritten, and we
                                                ;   also want to make sure where
                                                ;   SI is pointing during the call.

DATA    ENDS

END