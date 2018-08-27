       NAME  KEYPAD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    KEYPAD                                  ;
;                               Keypad Routines                              ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file contains two functions that will be used for the RoboTrike
;              keypad. It can initialize shared variables that will be used in 
;              other functions and check for/debounce key presses on the keypad.
;			   It also allows auto-repeat to the keypad by checking the keypad
;			   every AUTOREPEAT_TIME ms.
;
; Table of Contents:
;   InitKeypad:     Initializes the shared variables used in Debounce.
;   Debounce:       Checks for a new key being pressed or debounces the currently
;                   pressed key, enqueuing key event and key value. Also allows
;					auto-repeat.
;
; Revision History:
;   11/02/16    Dong Hyun Kim       initial revision
;	11/04/16	Dong Hyun Kim		updated comments
;	11/04/16	Dong Hyun Kim		debugged and updated comments



; local include files
$INCLUDE(Keypad.INC)        ;contains definitions and addresses for keypad routines



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC  'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        

; external function declarations
        EXTRN   EnqueueEvent:NEAR       ;stores the events and key values in 
										;	EventQueue, which will enqueue events
										;	for processing on the Remote Main loop
                                       


; InitKeypad
;
; Description:			This function initializes the index of the current row
;						that is being examined for key presses, the value of the
;						last key that was being pressed, and the value of the 
;						counter used to debounce the input signal.
;
; Operation:			The function will move the appropriate value to CurrentRow,
;						PreviousKey, and DebounceCnt. It will set CurrentRow to 
;						the very top row of the keypad, PreviousKey to NO_KEY_PRESS,
;						and DebounceCnt to its maximum value.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrentRow (DS) - the address of the current row of the 
;										  keypad that is being checked for key
;										  presses (W).
;						PreviousKey(DS) - the value of the last key that was
;										  being pressed (W).
;						DebounceCnt(DS) - value of counter that will decrement
;										  once a key is pressed to debounce
;										  the input signal (W).
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
; Revision History:     11/02/16	Dong Hyun Kim	initial revision
;						11/04/16	Dong Hyun Kim	updated comments

InitKeypad      PROC        NEAR
                PUBLIC      InitKeypad
                
        MOV     CurrentRow, FIRST_ROW_INDEX     ;initialize index of row currently 
                                                ;   being exmained to FIRST_ROW_INDEX,
												;	the very top row of keypad
        MOV     PreviousKey, NO_KEY_PRESS        ;no keys were pressed, so 
												;	initialize PreviousKey to 
												;	NO_KEY_PRESS
        MOV     DebounceCnt, DEBOUNCE_TIME      ;no keys are debounced, so set
                                                ;   DebounceCnt to DEBOUNCE_TIME.
        RET
        
InitKeypad      ENDP
        
        

; Debounce
;
; Description:			The function should be called approximately every millisecond
;						by the Timer2EventHandler and goes through a single row
;						of the keypad. It either checks for a new key being pressed
;						if none is currently pressed or debounces the current
;						pressed key. Once there is a debounced key, it calls the
;						EnqueueEvent function with the key event in AH and the 
;						key value in AL. If a key is pressed and held down, the 
;						EnqueueEvent function will be called every REPEAT_TIME ms
;						and the decimal counter will increase every half second.
;
; Operation:			The function starts off by checking if there is key that
;						is being pressed on CurrentRow. If there is none, the DebounceCnt
;						is reset to its maximum value and CurrentRow is updated 
;						to the next row. If there is, the function compares the 
;						value of the current key being pressed to that of the 
;						last key that was pressed. If the two are not equal, the
;						DebounceCnt is reset to its maximum value and PreviousKey 
;						is updated. If the two are equal, the key value is first
;						updated because we wish to differentiate between each
;						Then the DebounceCnt decrements by one. If DebounceCnt
;						reaches END_DEBOUNCE_TIME, the key is considered to have
;						been debounced and the EnqueueEvent is called. After such
;						event, the DebounceCnt is set to AUTOREPEAT_TIME. This 
;						allows the function to call EnqueueEvent every AUTOREPEAT_TIME
;						ms if the user continues to press the same key.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		CurrentRow (DS) - the address of the current row of the 
;										  keypad that is being checked for key
;										  presses (R/W).
;						PreviousKey(DS) - the value of the last key that was
;										  being pressed (R/W).
;						DebounceCnt(DS) - value of counter that will decrement
;										  once a key is pressed to debounce
;										  the input signal (R/W).
; Global Variables:		None.
;
; Input:				Keypresses from the keypad.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, BX, CX, DX, flags
; Limitations:			Simultaneous keypresses can only be detected when they 
;						occur within the same row. 
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/02/16	Dong Hyun Kim	initial revision
;						11/04/16	Dong Hyun Kim	debugged code and updated comments

Debounce        PROC        NEAR
                PUBLIC      Debounce
                
InitDebounce:								;check the value of current key
		MOV		DX, FIRST_ROW_ADDR			;Store the address of the current
		ADD		DX, CurrentRow				;	row that is being checked
		IN		AL, DX						;Obtain the unmasked key value from
											;	the keypad
		AND		AL, KEY_VALUE_MASKER		;Mask the upper nibble of the key
											;	value to compare with NO_KEY_PRESS
											;	appropriately
		CMP		AL, NO_KEY_PRESS			;check if there is key being pressed
											;	in the row that is being examined
		JNE		CompareKey					;if there is, compare the values of
											;	old key value and new key value
		;JE		KeyNotPressed				;if not, reset DebounceCnt and update
											;	CurrentRow
		
KeyNotPressed:								;change variables if no keys are pressed 
		INC		CurrentRow					;update CurrentRow to the next row to
											;	continue checking for key presses
		AND		CurrentRow, NUM_ROWS - 1	;CurrentRow = CurrentRow MOD NUM_ROWS
											;	Since NUM_ROWS is a power of 2, 
											;	we can do such operation. This
											;	allows the CurrentRow to wrap
											;	around the keypad and go to the
											;	beginning if needed
		MOV		DebounceCnt, DEBOUNCE_TIME	;reset DebounceCnt back to its maximum
											;	value
		JMP		EndDebounce					;now, we are done
		
CompareKey:									;compare value of old key and new key
		CMP		AL, PreviousKey				;check if the value of new key is
											;	equal to PreviousKey
		JE		UpdateKeyValue				;if it is, update key value to put in AL
		;JNE	KeyDiffPressed				;if not, reset DebounceCnt and update
											;	PreviousKey

KeyDiffPressed:								;change variables if different key
											;	was pressed
		MOV		PreviousKey, AL				;update PreviousKey to the key that is
											;	currently being pressed											
		MOV		DebounceCnt, DEBOUNCE_TIME	;reset DebounceCnt back to its maximum
											;	value
		JMP		EndDebounce					;now, we are done

UpdateKeyValue:								;update the key value that will be
											;	added to the EventBuf
		XOR		CX, CX						;clear register in case it has been
											;	used before
		MOV		CX, CurrentRow				;move CurrentRow to a register to use
											;	the SHL command
		SHL		CX, DECIMAL_DIGIT			;shift the CurrentRow left by DECIMAL_DIGIT
											;	number of bits. This essentially
											;	puts the CurrentRow in the tens 
											;	digit of the key value, allowing
											;	user to differentiate between the 
											;	keys in each row
		ADD		AX, CX						;update the key value so that Key Value
											;	= 10 * CurrentRow + Key Value
											;	in decimal.
		;JMP	DebounceKey					;now, debounce the key
		
DebounceKey:								;debounce the currently pressed key
		DEC		DebounceCnt					;decrement counter value by one
		JNE		EndDebounce					;if it has not, we are done
		;JE		CallEnqueueEvent			;if it has, call EnqueueEvent
		
CallEnqueueEvent:							;Call the EnqueueEvent procedure
		MOV		AH, KEY_EVENT_VALUE			;update the Key Event value to indicate
											;	a key was pressed and debounced
		CALL	EnqueueEvent				;Store the events and key values passed
											;	to it in EventBuf
		MOV		DebounceCnt, AUTOREPEAT_TIME;Update DebounceCnt so that EnqueueEvent
											;	will be called every AUTOREPEAT_TIME
											;	ms.
		;JMP	EndDebounce					;now, we are done
		
EndDebounce:								;end the function
		RET
		
Debounce        ENDP



		
CODE            ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

CurrentRow      DB      ?       ;The current row of the keypad that is being checked
                                ;   for key presses. The value itself is equal to
                                ;   the offset from the address of the very top 
                                ;   row of the keypad. Hence, 0 is the top row, 1
                                ;   is the second row, 2 is the third row, and 3
                                ;   is the bottom row. 
PreviousKey     DB      ?       ;The previous key from a row that was being pressed.
                                ;   The upper 4 bits are masked off and ignored, 
                                ;   and the lower 4 bits are read from the keypad
                                ;   to determine which keys are being pressed.
								;	The leftmost key corresponds to the bit 0, 
								;	and the rightmost key corresponds to bit 3.
								;	The keypad is active low, so pressing the key
								;	will set the corresponding bit to 0.
DebounceCnt     DW      ?       ;Counter that will be used to determine how long
								;	a key must be actually pressed down for the 
								;	program to fully debounce the input signal 
								;	and consider the key to be pressed down


DATA    ENDS

END