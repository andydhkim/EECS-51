    NAME    RMTFUNCS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   RMTFUNCS                                 ;
;                      Remote Unit Main File Helper Functions                ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file contains five public functions and one private table
;              that will be used for the remote unit main file of the RoboTrike.
;              The first functoin can initialize all of the necessary components 
;              of the remote unit. The remaining four functions act as helper
;              functions for the main file, carrying out the appropriate action
;              for each event type. The private table is utilized for keypad
;              presses, and each key value corresponds to a unique command.
;              
;
; Table of Contents (Functions):
;   InitRemoteMainLoop: Initializes the necessary components of the remote unit.
;   KeypadPressEvent:   Outputs the correct command to the serial channel.
;   DataReceviedEvent:  Displays the received data.
;   SerialErrorEvent:   Displays the appropriate serial error message.
;   NoEvent:            Does nothing and returns.
;
; Table of Contents (Tables):
;   KeyCommandTable:    Contains the commands, in strings, that will be output
;                       to the serial channel through the KeypadPressEvent.
;
; Revision History:
;   12/02/16    Dong Hyun Kim       initial revision



; local include files
$INCLUDE(RmtFuncs.INC)      ;contains definitions for main file helper functions
$INCLUDE(General.INC)       ;contains general definitions



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

        
;external function declarations
        EXTRN	InitDisplay:NEAR            ;initialize the display variables             
        EXTRN   InitKeypad:NEAR             ;initialize the keypad variables
        EXTRN   InitSerial:NEAR             ;initialize the serial routine variables
		EXTRN	InitCS:NEAR					;initialize the 80188 chip selects
        EXTRN   InitEventQueue:NEAR         ;initialize EventQueue
        EXTRN   ClrIRQVectors:NEAR          ;clear (initialize) interrupt vector table
        EXTRN   InitTimer2:NEAR             ;initialize the Timer 2 Interrupt
        EXTRN   InstallTimer2Handler:NEAR   ;install the Timer 2 Handler
        EXTRN   InitINT2:NEAR               ;initialize the INT2 Interrupt        
        EXTRN   InstallINT2Handler:NEAR     ;install the INT 2 Handler
        EXTRN   SetCriticalError:NEAR       ;appropriately set the critical error
                                            ;   flag    
        EXTRN   SerialPutString:NEAR        ;output a string to the serial channel
        EXTRN   Hex2String:NEAR             ;convert a unsigned number to Hex
        EXTRN   Display:NEAR                ;create the appropriate segment
                                            ;   pattern to be displayed
        EXTRN   EnqueueEvent:NEAR           ;enqueue the appropriate event type
                                            ;   and value to the EventQueue


                                        
; InitRemoteMainLoop
;
; Description:			The function initializes all of the necessary components
;                       for the remote unit main loop. It calls the appropriate
;                       initialization functions.
;
; Operation:            The function clears the interrupt to prevent any critical
;                       code issues while resetting the critical error flag. It
;                       then calls all of the necessary initialization functions.
;                       Finally, the critical error flag is reset since there 
;                       should be no errors when beginning the program.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		NoError (AL) - value indicating no critical errors.
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
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision   

InitRemoteMainLoop  PROC        NEAR
                    PUBLIC      InitRemoteMainLoop                    
                   
        
        CLI                                 ;clear interrupts to prevent any 
                                            ;   critical code issues whlie resetting  
                                            ;   the critical error flag
                   
		CALL	InitCS					    ;initialize the 80188 chip selects
                                            ;   assumes LCS and UCS already set up  
                                        
        CALL    InitDisplay                 ;initializes the display variables
        CALL    InitKeypad                  ;initializes the keypad variables
        CALL    InitSerial                  ;initializes the 16C450 and serial I/O 
                                            ;   variables       
        CALL    InitEventQueue              ;initializes the EventQueue                                        
										
		CALL	ClrIRQVectors			    ;clear (initialize) interrupt vector 
                                            ;   table
		
		CALL	InstallINT2Handler	        ;install the event handlers
        CALL    InstallTimer2Handler        ;   ALWAYS install handlers before
                                            ;   allowing the hardware to interrupt.
                                        
        MOV     AL, SYSTEM_OK               ;the system has not started to operate,
        CALL    SetCriticalError            ;   so reset the critical error flag  

        MOV     RxDataIndex, 0              ;set the initial value of the index
        
		CALL	InitINT2				    ;initialize the INT2 interrupt
        CALL    InitTimer2                  ;initialize the Timer2 interrupt
        STI                                 ;	and finally allow interrupts.
        
        RET
                    
InitRemoteMainLoop     ENDP  



; KeypadPressEvent
;
; Description:			The function should be called whenever there is a keypad
;                       press. It utilizes the passed down event value (AL) as
;                       an index to go through a string pointer table. It will
;                       then find the appropriate command string and output it
;                       to the serial channel. The outputted string can then 
;                       activate the DC motors on the RoboTrike.
;
; Operation:			The function utilizes the passed down event value (AL) as
;                       an index to go through the KeyCommandTable. It is converted
;                       as a word index because it has to go through a string pointer
;                       table. Once it finds the appropriate command string, it
;                       calls the SerialPutString function and outputs the string 
;                       to the serial line.
;
; Arguments:			EventVal (AL) - the event value from EventQueue, in this
;                                       case the key value.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		None.		
; Global Variables:		None.
;
; Input:				None.
; Output:				Command string to the serial line.
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
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision   

KeypadPressEvent    PROC        NEAR
                    PUBLIC      KeypadPressEvent                    
                   
CreateIndex:                                ;utilize the key value as an index
        XOR     BX, BX                      ;clear BX so we can use it as an index
                                            ;   go through the KeyCommandTable
        MOV     BL, AL                      ;move the key value to the empty
                                            ;   BL register. Since BH is empty,
                                            ;   BX can be used as an index
        SHL     BX, 1                       ;convert the value into a word index
                                            ;   address so it can go through the
                                            ;   string pointer table correctly
        ;JMP    FindCommand

FindCommand:                                ;find the appropriate string command
        LEA     SI, KeyCommandTable         ;obtain the offset address of the
                                            ;   KeyCommandTable
        MOV     SI, CS:[SI][BX]             ;find the correct command message 
                                            ;   from the table by utilizing the
                                            ;   address and the offset
        ;OutputCommand

OutputCommand:                              ;output the appropriate command 
                                            ;   string
        PUSH    CS                          ;SerialPutString expects the string
        POP     ES                          ;   to be located in ES, not CS, so
                                            ;   we must set the value at ES 
                                            ;   equal to that of CS
        CALL    SerialPutString             ;output the command string to the
                                            ;   serial port
        ;JMP    EndKeypadPressEvent

EndKeypadPressEvent:                        ;now, we are done
        RET        
                    
KeypadPressEvent     ENDP   



; DataReceviedEvent
;
; Description:			The function is called whenever data is received from 
;                       the serial channel. It will put the individual characters
;                       sent from the channel to a buffer that will be used to
;                       display the message on the LED. If the information received
;                       is too big to display on the LED, it will create a 
;                       DATA_OVERFLOW_ERROR.
;
; Operation:		    The function will start off by checking if the buffer is
;                       already full or not. If it is, a serial error will be 
;                       outputted with DATA_OVERFLOW_ERROR as the error value. 
;                       If is not full, the function will check if the CARRIAGE_RETURN
;                       value has been sent. If it it has, the function will add
;                       a ASCII_NULL to terminate the string and display it to
;                       the LED. If not, the function will continue to loop and
;                       add values to the buffer untli it is full or encounters
;                       a DATA_OVERFLOW_ERROR. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		None.
; Shared Variables:		RxDataIndex (DS) - Current index of the RxDataBuf (R/W).
;                       RxDataBuf   (DS) - array containing data received from
;                                          serial channel.
; Global Variables:		None.
;
; Input:				None.
; Output:				Communicates with the LED display but does not output directly.
;
; Error Handling:		If there is more data received than the buffer can handle,
;                       a serial error will be displayed on the Display
;
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AX, SI, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision   

DataReceivedEvent   PROC        NEAR
                    PUBLIC      DataReceivedEvent                    
                   
CheckDataOverflow:                              ;determine if there is too much
                                                ;   data for the function to 
                                                ;   handle
        MOV     SI, RxDataIndex                 ;obtain the current index of the
                                                ;   RxDataBuf, which may or 
                                                ;   may not have a character
                                                ;   added to its next open space
        CMP     SI, LED_LENGTH                  ;check if there is more data 
                                                ;   received than can be stored
                                                ;   in the buffer
        JBE     CheckEndOfData                  ;if not, check if the message 
                                                ;   has been fully sent across
                                                ;   the serial channel
        ;JA     HandleOverflowError

HandleOverflowError:                            ;if so, we treat this as a 
                                                ;   serial error and enqueue the
                                                ;   appropriate event type and
                                                ;   event value to EventQueue
        MOV     AH, ERROR_EVENT_TYPE            ;set the event type to a serial
                                                ;   error
        MOV     AL, DATA_OVERFLOW_ERROR         ;set the event value to the
                                                ;   data received overflow error
        CALL    EnqueueEvent                    ;enqueue the event to EventQueue
                                                ;   so we can handle it appropriately
                                                ;   in the main loop
        JMP     ResetIndex                      ;reset the index since we have
                                                ;   have encountered an error,
                                                ;   this will also reset the 
                                                ;   RxDataBuf since for the next
                                                ;   command we will overwrite 
                                                ;   previous data

CheckEndofData:                                 ;check if the message has ended
        CMP     AL, CARRIAGE_RETURN             ;if there is a carriage return,
                                                ;   the message has been completely
                                                ;   sent from the serial channel
        JE      NullTerminateStr                ;so we can add an ASCII_NULL
                                                ;   and display to the LED
        ;JNE    ObtainData
        
ObtainData:                                     ;if there is no carraige return,
        MOV     RxDataBuf[SI], AL               ;   utilize the passed down
                                                ;   character and add it to the
                                                ;   buffer
        INC     RxDataIndex                     ;increment the index so we can
                                                ;   add it to the next open
                                                ;   space of the buffer if necessary
        JMP     EndDataReceivedEvent            ;end the function
        
NullTerminateStr:                               ;terminate the string so it can
        MOV     RxDataBuf[SI], ASCII_NULL       ;   be properly utilized in the
                                                ;   display function
        ;JMP    DisplayRxData

DisplayRxData:                                  ;display the components in the buffer
        LEA     SI, RxDataBuf                   ;obtain the address of the RxDataBuf
                                                ;   in SI so we can utilize the
                                                ;   display fuction correclt
        PUSH	DS						        ;Need to change from DS:SI to ES:SI 
		POP		ES						        ;	in order to to invoke Display 
                                                ;	function correctly.   
		CALL	Display					        ;Output the string to the display,
                                                ;   which will be displayed on
                                                ;   the LED  
        ;JMP    ResetIndex                                                
                                                
ResetIndex:                                     ;restore the value of the index
        MOV     RxDataIndex, 0                  ;   so it can start going through
                                                ;   the next string from the
                                                ;   serial command correctly
        ;JMP    EndDataReceivedEvent

EndDataReceivedEvent:                           ;now, we are done
        RET                                                 
                    
DataReceivedEvent   ENDP   



; SerialErrorEvent
;
; Description:			The function should be called whenever there is a serial
;                       error. It will form the appropriate error message utilizing
;                       the passed down error value and display it to the LED. 
;                       The error message itself will be seven characters long,
;                       the last four showing the type of serial error. To prevent
;                       the serial error message from disappearing very quickly,
;                       a delay loop is added at the very end.
;
; Operation:			The function starts off by adding the first four characters
;                       of the error message, "SERR", to a separate buffer. This
;                       will allow the user to differentiate between the status
;                       updates on the LED. It will then utilize the passed down
;                       error value and add it to the buffer through the DisplayHex
;                       function. At the very end, it will go through a loop of
;                       delays to ensure that the error message is output on 
;						the display for a more realistic time.
;
; Arguments:			EventVal       (AL) - the event value from EventQueue, in 
;                                             this case the value of the serial 
;                                             error.
; Return Value:			None.
;
; Local Variables:		DelayCounter   (CX) - the counter for the delay loop.
; Shared Variables:		SerialErrorBuf (DS) - array containing the serial error
;                                             message that will be displayed (W).		
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
; Registers Changed:	AH, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        A different value is designated for each serial error.
;                       To find out which error has been caused, please check
;                       the functional specification of the remote unit.
;
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision   

SerialErrorEvent    PROC        NEAR
                    PUBLIC      SerialErrorEvent                    
                   
SerialErrorEventInit:                           ;initialization
        MOV     SerialErrorBuf[0], 'S'          ;the first character of the error
                                                ;   message will be set to 'S'
        MOV     SerialErrorBuf[1], 'E'          ;the second will be set to 'E'
        MOV     SerialErrorBuf[2], 'R'          ;the third will be set to 'R'
		MOV		SerialErrorBuf[3], 'R'			;the fourth will set to 'R' again
												;	to denote that it was an error
												;	from the remote unit
        LEA     SI, SerialErrorBuf[4]           ;now, we set SI as the address of
                                                ;   the fourth element of the
                                                ;   buffer. The error value will 
                                                ;   thus be displayed after the 
                                                ;   'SER'
        ;JMP    ObtainErrorVal           
                   
ObtainErrorVal:                                 ;find the error value
        XOR     AH, AH                          ;clear the AH register in order
                                                ;   to use the AL register as
                                                ;   AX, since DisplayHex requires
                                                ;   an argument in AX
        ;JMP    ConvertErrorVal

ConvertErrorVal:								;convert error val to Hex
		PUSH	SI						        ;Save the value of address because 
                                                ;	Hex2String modifies SI values
		CALL	Hex2String				        ;Converts the unsigned 16-bit value
                                                ;	in AX to hexadecimal and stores 
                                                ;   it as a string in ES:SI. 
		POP		SI						        ;Return SI back to its original 
                                                ;   value
		;JMP	DisplayErrorMsg				

DisplayErrorMsg:								;output the error message
        LEA     SI, SerialErrorBuf              ;move the address of the complete
                                                ;   string back to SI
		PUSH	DS						        ;Need to change from DS:SI to ES:SI 
		POP		ES						        ;	in order to to invoke Display 
                                                ;	function correctly.
		CALL	Display					        ;Output the string to the display,
                                                ;   which will be displayed on
                                                ;   the LED
        MOV     CX, 0                           ;prepare for the delay loop that
                                                ;   will follow immediately
        ;JMP    DelayLoop

DelayLoop:                                      ;without the delay loop, the error
                                                ;   message will be displayed on
                                                ;   the screen for an extremely
                                                ;   short amount of time if another
                                                ;   event has occured. to prevent
                                                ;   this problem, a delay loop
                                                ;   is added 
        INC     CX                              ;increment the counter                                               
        CMP     CX, ERROR_DELAY                 ;check if the delay loop should
                                                ;   be over
        JB      DelayLoop                       ;keep looping until the counter 
                                                ;   value is greater than that
                                                ;   of ERROR_DELAY
                 
EndSerialErrorEvent:                            ;now, end the function
        RET                                             
                    
SerialErrorEvent    ENDP   



; NoEvent
;
; Description:			The function is called whenever there is a NO_EVENT_TYPE
;                       event type. It does nothing and simply returns.
;
; Operation:	        The function simply returns. It does not perform any
;                       specific operation the event type specified that nothing
;                       should happen.
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
; Revision History:     11/28/16    Dong Hyun Kim       wrote pseudo code
;                       12/02/16    Dong Hyun Kim       initial revision   

NoEvent             PROC        NEAR
                    PUBLIC      NoEvent                    
                   
        RET                                 ;do nothing and return
                    
NoEvent             ENDP   



; KeyCommandTable
;
; Description:      This table contains the commands, in form of a string, that
;                   will be sent to the motor unit via the serial channel. Each 
;                   command will correspond to a different key press. The table
;                   itself mimics a variable length string table, which utilize
;                   the string themselves and their pointers.
;
; Special Notes:    Each key press has a unique value ranging from 00 to 3E. For 
;                   a more intuitive visual, check the separate functional 
;                   specification, which includes a table of values vs key press 
;                   combinations.
;
; Author:           Dong Hyun Kim
; Last Modified:    Dec. 2, 2016


; this macro sets up the table of variable length strings
%*DEFINE(STRVARTABLE)  (
        %SET(EntryNo, 0)		        ;first string is string #0
        
        ;Row 1                          ;key value
        %TABENT('')                     ;00
        %TABENT('')                     ;01
        %TABENT('')                     ;02
        %TABENT('')                     ;03
        %TABENT('')                     ;04
        %TABENT('')                     ;05
        %TABENT('')                     ;06
        %TABENT('F')                    ;07 (Laser On)
        %TABENT('')                     ;08
        %TABENT('')                     ;09
        %TABENT('')                     ;0A
        %TABENT('')                     ;0B
        %TABENT('')                     ;0C
        %TABENT('D0')                   ;0D (Forward)
        %TABENT('S32676')               ;0E (Start)
        %TABENT('')                     ;0F
        
        ;Row 2                          ;key value
        %TABENT('')                     ;10
        %TABENT('')                     ;11
        %TABENT('')                     ;12
        %TABENT('')                     ;13
        %TABENT('')                     ;14
        %TABENT('')                     ;15
        %TABENT('')                     ;16
        %TABENT('O')                    ;17 (Laser Off)
        %TABENT('')                     ;18
        %TABENT('')                     ;19
        %TABENT('')                     ;1A
        %TABENT('D+45')                 ;1B (Right)
        %TABENT('')                     ;1C
        %TABENT('S0')                   ;1D (Stop)
        %TABENT('D-45')                 ;1E (Left)
        %TABENT('')                     ;1F

        ;Row 3                          ;key value
        %TABENT('')                     ;20
        %TABENT('')                     ;21
        %TABENT('')                     ;22
        %TABENT('')                     ;23
        %TABENT('')                     ;24
        %TABENT('')                     ;25
        %TABENT('')                     ;26
        %TABENT('V-4096')               ;27 (Big Decelerate)
        %TABENT('')                     ;28
        %TABENT('')                     ;29
        %TABENT('')                     ;2A
        %TABENT('V+4096')               ;2B (Big Accelerate)
        %TABENT('')                     ;2C
        %TABENT('D180')                 ;2D (Reverse)
        %TABENT('')                     ;2E
        %TABENT('')                     ;2F

        ;Row 4                          ;key value
        %TABENT('')                     ;30
        %TABENT('')                     ;31
        %TABENT('')                     ;32
        %TABENT('')                     ;33
        %TABENT('')                     ;34
        %TABENT('')                     ;35
        %TABENT('')                     ;36
        %TABENT('V-176')                ;37 (Slight Decelerate)
        %TABENT('')                     ;38
        %TABENT('')                     ;39
        %TABENT('')                     ;3A
        %TABENT('V+176')                ;3B (Slight Accelerate)
        %TABENT('')                     ;3C
        %TABENT('D+10')                 ;3D (Slight Right)
        %TABENT('D-10')                 ;3E (Slight Left)
        %TABENT('')                     ;3F  
        
)


; this macro defines the strings
%*DEFINE(TABENT(string))  (
Str%EntryNo	LABEL	BYTE
	DB      %string, 0			    %' define the string '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)

; create the table of strings
	%STRVARTABLE



; this macro defines the table of string pointers
%*DEFINE(TABENT(string))  (
	DW      OFFSET(Str%EntryNo)		%' define the string pointer '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)

; create the table of string pointers
KeyCommandTable     LABEL	BYTE
	%STRVARTABLE



CODE    ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

RxDataIndex     DW      ?                       ;The current index of the 
                                                ;   RxDataBuf, used to go through
                                                ;   the buffer and read/write
                                                ;   its values.

RxDataBuf       DB      RX_BUF_LENGTH   DUP (?) ;The array containing the received
                                                ;   data from the serial channel.
                                                ;   If it does not overflow, it
                                                ;   will end with an ASCII_NULL
                                                ;   and be displayed to the LED.
                                                ;   The length is one larger than
                                                ;   the LED_LENGTH since the 
                                                ;   ASCII_NULL has to be a part
                                                ;   of the array to display 
                                                ;   correctly, but will not be 
                                                ;   displayed if the data happens
                                                ;   to be LED_LENGTH characters
                                                ;   long.

SerialErrorBuf  DB      SER_ERR_LENGTH  DUP (?) ;The array containing the string
                                                ;   with the appropriate error 
                                                ;   message that will be displayed
                                                ;   on the LED whenever there is
                                                ;   a serial error. 
                                            
DATA    ENDS

END