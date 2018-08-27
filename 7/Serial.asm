    NAME    Serial

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Serial                                  ;
;                         Serial I/O Routines Function                       ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description: This file contains five public functions and three private tables
;              that will be used for the Serial I/O of the 16C450. It can initialize
;              the serial line, output a passed character into the serial channel,
;              set the parity setting, and set the baud rate. It also includes an
;              event handler that is divided into four subfunctions and used to 
;              handle each interrupt type appropriately. If necessary, it will 
;              enqueue the error type and code into EventQueue. Two tables are 
;              used to set the correct parity setting and baud rate, and one
;              is used as a jump table for the event handler.
;
; Table of Contents (Functions):
;	InitSerial:		    Initialize the serial line of 16C450.
;	SerialPutChar:	    Outputs a passed character into the serial channel.
;	SetSerialParity:	Set the parity setting.
;	SetBaudRate:		Set the baud rate.
;	SerialEventHandler:	Handle interrupt approriately, enqueue the error type and 
;                       error code into EventQueue if necessary.
;
; Table of Contents (Tables):
;   ParityTable:        Bits on LCR that will decide parity setting.
;   BaudTable:          Value of divisors that will set baud rate.
;   SerialEHJmpTable:   Allows SerialEventHandler to jump to appropriate section.  
;
; Revision History:
;   11/14/16    Dong Hyun Kim       wrote pseudo code
;   11/17/16    Dong Hyun Kim       initial revision
;   11/19/16    Dong Hyun Kim       debugged code and updated comments



; local include files
$INCLUDE(Serial.INC)        ;contains defintions and addresses for serial I/O routines
$INCLUDE(Queues.INC)        ;contains defintions and structure for queue functions



CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE	SEGMENT PUBLIC 	'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

        
;external function declaratoins
        EXTRN   QueueInit:NEAR          ;intializes queue of fixed length and
                                        ;   passed element size at passed address
        EXTRN   QueueEmpty:NEAR         ;returns with zero flag set if queue is 
                                        ;   empty, reset otherwise
        EXTRN   QueueFull:NEAR          ;returns with zero flag set if queue is 
                                        ;   full, reset otherwise
        EXTRN   Dequeue:NEAR            ;Removes an element from head of queue
        EXTRN   Enqueue:NEAR            ;Adds an element to tail of queue at passed
                                        ;   address
        EXTRN   EnqueueEvent:NEAR       ;stores the events and key values in a 
                                        ;   256 byte buffer, EventBuf                                        


   
; InitSerial
;
; Description:			The function initializes the serial line by writing the
;                       appropriate values to the registers and initializing the
;                       value of the shared variables that will be used in other
;                       functions. It also sets the parity and baud rate of the
;                       16C450.
;
; Operation:			The function starts off by clearing KickStart. It then 
;                       initializes TxQueue by setting its element size to a byte
;                       and a fixed length. The IER and LCR registers are initialized
;                       appropriately so that all interrupts are enabled and
;                       the trasmitted word length is CharWL8, there is only StopBit1
;                       stop bits, the parity is off, and the DLAB is cleared. 
;                       Finally, the parity is set (turned off in this file, but
;                       can be enabled if user wants to) through SetSerialParity
;                       and the baud rate is set (user can choose desired baud
;                       rate if needed) through SetBaudRate.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		Values    (AL) - Values read from various registers.
;                       EleSize   (BL) - Denotes size of TxQueue.
;                       Address   (DX) - Address of various registers.
;                       QueueAddr (SI) - Address of the TxQueue.
; Shared Variables:		TxQueue	  (DS) - Queue that contains all of the desired 
;                                        characters that will be sent over to
;                                        to the serial channel (W).
;						KickStart (DS) - Value that determines whether or not
;                                        kickstarting is required (W).
; Global Variables:		None.
;
; Input:				None.
; Output:				Initializes serial I/O line.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, BL, DX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        To change the parity setting and baud rate, user must
;                       modifiy the input values to SetSerialParity and SetBaudRate.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision

InitSerial          PROC        NEAR
                    PUBLIC      InitSerial

KickStartInit:                              ;initialize the KickStart variable
        MOV     KickStart, KICKSTART_ON     ;kickstart is not necessarily required,
                                            ;   since we will immediately get an 
                                            ;   interrupt (THR is empty) which 
                                            ;   sets the kickstart. 
        ;JMP    TxQueueInit
        
TxQueueInit:                                ;initialize TxQueue
        XOR     BL, BL                      ;set the element size to a byte
        LEA     SI, TxQueue                 ;obtain the address of TxQueue for
                                            ;   QueueInit function
        CALL    QueueInit                   ;initialize QueueInit
        ;JMP    RegisterInit
        
RegisterInit:                               ;initialize registers
        MOV     AL, IERRxData OR IERTxEmpty OR IERLineSts OR IERModemSts
                                            ;set the IER register so that all 
                                            ;   available interrupts are enabled
        MOV     DX, IERAddr                 ;obtain the address of IER
        OUT     DX, AL                      ;write appropriate value to IER
                                            
        MOV     AL, CharWL8 OR StopBit1 OR LCRParOff OR LCRBreakOff OR LCRDLABClr
                                            ;set the LCR register so that the
                                            ;   word length is CharWL8, there is
                                            ;   only StopBit1 stop bits, the parity
                                            ;   is turned off, there are no breaks,
                                            ;   and the DLAB is cleared.
        MOV     DX, LCRAddr                 ;obtain the address of LCR
        OUT     DX, AL                      ;write appropriate value to LCR
        ;JMP    ParityBaudSet
        
ParityBaudSet:                              ;initializes parity setting and baud
                                            ;   rate
        MOV     SI, PAR_OFF                 ;make the argument of SetSerialParity
                                            ;   equal to PAR_OFF
        CALL    SetSerialParity             ;turn the parity off through lookup
                                            ;   table and writing to LCR
        
        MOV     SI, BAUD_RATE_9600          ;make the argument of SetBaudRAte
                                            ;   equal to BAUD_RATE_9600
        CALL    SetBaudRate                 ;set baud rate appropriately by putting
                                            ;   value of divisor into DLL and DLM
        ;JMP   EndInitSerial

EndInitSerial:                              ;end the function
        RET
         
InitSerial          ENDP                



; SerialPutChar
;
; Description:          The function outputs a passed character (c) into the
;                       serial channel. It returns with the carry flag reset if 
;                       the character has been output (that is, put in the 
;                       channel's queue). If returns with the carry flag set 
;                       otherwise. The function also kickstarts the 16C450 if 
;                       necessary to allow the THR to accept characters in the
;                       future.
;
; Operation:			The function starts off by checking if the TxQueue is full.
;                       If it is, a carry flag is set and the function ends. If
;                       it is not, a value is enqueued to TxQueue using the Enqueue
;                       function. The value of KickStart is then checked. If it
;                       is enabled, the 16C450 is kickstarted by disabling the
;                       ETBE and then enabling it. After such process, the KickStart
;                       and the carry flag are both reset.
;
; Arguments:			c 	        (AL) - Passed character that will be output 
;								           to the serial channel.
; Return Value:			CF               - Set if full, reset if character has 
;                                          been output.
;
; Local Variables:		Values      (AL) - Values read from various registers.
;                       Address     (DX) - Address of various registers.
;                       QueueAddr   (SI) - Address of TxQueue.
; Shared Variables:		TxQueue		(DS) - Queue that contains all of the desired 
;                                          characters that will be sent over to
;                                          to the serial channel.
;						KickStart   (DS) - Value that determines whether or not
;                                          kickstarting is required.
; Global Variables:		None.
;
; Input:				Information from 16C450 registers.
; Output:				Character to the channel's queue (not necessarily over 
;                       the serial channel).
;
; Error Handling:		Carry flag is set if there's an error.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, BX, DX, SI, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        Kickstaring is essential because the Transmitter Holding
;                       Register Empty interrupt will never be called again without
;                       it. Kickstarting involves resetting and setting the 
;                       ETBE of the IER. 
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision
;                       11/19/16    Dong Hyun Kim       updated comments

SerialPutChar       PROC        NEAR
                    PUBLIC      SerialPutChar

CheckTxQueue:                               ;check if TxQueue is full
        LEA     SI,  TxQueue                ;obtain address of TxQueue for QueueFull
                                            ;   function                                           
        PUSH    AX                          ;preserve the value of the passed
                                            ;   character since QueueFull function
                                            ;   changes the value of the accumulator
        CALL    QueueFull                   ;returns with zero flag set if TxQueue
                                            ;   is full, reset otherwise
        POP     AX                          ;restore the value of the passed
                                            ;   character back to the accumulator                                 
        JNZ     EnqueueTxQueue              ;if TxQueue is not full, enqueue the
                                            ;   the character to TxQueue
        ;JZ     SetCarryFlag                

SetCarryFlag:                               ;if full, set carry flag and exit
        STC                                 ;set carry flag to indicate that the
                                            ;   TxQueue is full. Since we cannoThis
                                            ;   do anything else, we will exit 
                                            ;   the function.
        JMP     EndSerialPutChar            ;now, we are done
        
EnqueueTxQueue:                             
        CALL    Enqueue                     ;enqueue the character to TxQueue,
                                            ;   which may not necessarily be 
                                            ;   sent over the serial channel.
        ;JMP    CheckKickStart
        
CheckKickStart:                             ;check if KickStart is set
        CMP     KickStart, KICKSTART_OFF    ;compared value of KickStart with 
                                            ;   that of KICKSTART_OFF
        JE      ResetCarryFlag              ;if KickStart is not set, reset carry
                                            ;   flag
        ;JNE    KickStartTx                                       

KickStartTx:                                ;if KickStart is set, KickStart the
                                            ;   16C450 and allow future interrupts
        MOV     DX, IERAddr                 ;read the value of the IER and store
        IN      AL, DX                      ;   in AL register
        AND     AL, IERDisableTx            ;reset the ETBE of the IER so that
        OUT     DX, AL                      ;   Trasmitter Holding Register Empty
                                            ;   interrupts are disabled. IERDisableTx
                                            ;   also acts a mask so that other bits
                                            ;   are left alone.
        OR      AL, IEREnableTx             ;set the ETBE of the IER so that the
        OUT     DX, AL                      ;   Trasmitter Holding Register Empty
                                            ;   interrupts are enabled. These two
                                            ;   processes succesfully kickstarts
                                            ;   the 16C450.
        PUSHF                               ;since the following code is critical
        CLI                                 ;   code, we need to disable interrupts
                                            ;   and create no issues
        MOV     KickStart, KICKSTART_OFF    ;reset the KickStart variable since
                                            ;   we have succesfully kickstarted
        POPF                                ;restore the flags
        ;JMP    ResetCarryFlag
                                                                
ResetCarryFlag:                             ;reset carry flag and exit
        CLC                                 ;reset carry flag to indicate that 
                                            ;   the enqueue call was successful.
                                            ;   This is our return value.
        ;JMP    EndSerialPutChar            ;now, we are done             

EndSerialPutChar:                           ;end the function
        RET
        
SerialPutChar       ENDP   



; SetSerialParity
;
; Description:			The function sets the appropriate parity setting for the
;                       16C450. It utilizes the lookup table, ParityTable, and 
;                       writes a value to the parity bits of the Line Control
;                       Register.
;
; Operation:			The function will first read the Line Control Register
;                       (LCR). It will then mask the LCR so that only the parity
;                       bits are being altered. The appropriate value is then
;                       obtained from the ParityTable and written to the LCR to
;                       set the parity setting.						
;
; Arguments:			Parity  (SI) - desired parity setting that will be obtained
;                                      from the ParityTable.
; Return Value:			None.
;
; Local Variables:		LCRPar  (AL) - Value of parity bits of LCR.
;                       LCRAddr (DX) - address of LCR.
; Shared Variables:		None.		
; Global Variables:		None.
;
; Input:				Information from 16C450 registers.
; Output:				Parity setting of the 16C450.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AL, DX, flags.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision
;                       11/19/16    Dong Hyun Kim       updated comments

SetSerialParity     PROC        NEAR
                    PUBLIC      SetSerialParity                    
                   
        MOV     DX, LCRAddr                 ;read the value of LCR and store in
        IN      AL, DX                      ;   the AL register
       
        AND     AL, LCRParMsk               ;mask out value of LCR to only alter
                                            ;   parity bits and leave non parity
                                            ;   settings
        
        OR      AL, CS:ParityTable[SI]      ;obtain the appropriate value of the
                                            ;   parity bits from ParityTable. This
                                            ;   allows the user to choose a desired
                                            ;   parity setting when initializing
                                            ;   the serial line.
 
        OUT     DX, AL                      ;set the parity setting with the new
                                            ;   value
                                            
        RET                                                
                    
SetSerialParity     ENDP   



; SetBaudRate
;
; Description:			The function sets the appropriate baud rate for the 
;                       16C450. It utilizes a lookup table, BaudTable, and writes 
;                       a value to the Divisor Latch.
;
; Operation:			The function first starts off by saving the current value
;                       of the IER and disabling any interrupts that may happen
;                       by writing IERDisableINT to the IER. It then saves the
;                       current value of the LCR and sets the Divisor Latch Access
;                       bit by writing LCRDLABSet to the LCR. The appropriate 
;                       divisor is then obtained from BaudTable and written out
;                       to the Divisor Latch. The LCR is restored, and finally
;                       the IER is restored to allow interrupts once again.
;
; Arguments:			Baud    (SI) - Desried baud rate. The corresponding divisor
;                                      will be obtained from BaudTable.
; Return Value:			None.
;
; Local Variables:		IERVal  (CL) - Current value of the IER.
;                       LCRVal  (CH) - Current value of the LCR.
;                       Address (DX) - Stores address of various registers.
; Shared Variables:		None.			
; Global Variables:		None.
;
; Input:				Information from 16C450 registers.
; Output:				Baud rate of the 16C450.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AL, CX, DX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision
;                       11/19/16    Dong Hyun Kim       updated comments

SetBaudRate         PROC        NEAR
                    PUBLIC      SetBaudRate

DisableInterrupts:                          ;disable interrupts from the IER
        MOV     DX, IERAddr                 ;read value of IER and store in the 
        IN      AL, DX                      ;   AL register
        XOR     CX, CX                      ;clear CX register and prepare to 
                                            ;   store register values
        MOV     CL, AL                      ;save value of IER since we wish to
                                            ;   restore it later. The function 
                                            ;   should never change the value of
                                            ;   IER.
        MOV     AL, IERDisableINT           ;disable interrupts from the IER 
        OUT     DX, AL                      ;   by writing IERDisableINT. This 
                                            ;   allows the critical code below
                                            ;   to set the baud rate without any
                                            ;   potential errors.
        ;JMP    SetDLAB
        
SetDLAB:                                    ;enable DLAB of LCR
        MOV     DX, LCRAddr                 ;read value of LCR and store in the
        IN      AL, DX                      ;   AL register
        MOV     CH, AL                      ;save value of LCR since we wish to
                                            ;   restore it later. The function
                                            ;   should never change the value of
                                            ;   LCR when it is done.
        MOV     AL, LCRDLABSet              ;set the DLAB of the LCR by writing
        OUT     DX, AL                      ;   LCRDLABSet. This allows the user
                                            ;   to set the baud rate by loading 
                                            ;   the appropriate divisor values 
                                            ;   to the DLL and DLM.
        ;JMP    SetBaud                                            
                                            
SetBaud:                                    ;now, set the baud rate    
        MOV     DX, DLLAddr                 ;set the desired baud rate by obtaining
        MOV     AX, CS:BaudTable[SI]        ;   the appropriate divisor value from
        OUT     DX, AX                      ;   BaudTable and loading it to the
                                            ;   DLL and DLM
        ;JMP    Restore                                            
                                            
Restore:                                    ;restore the previous register values
        MOV     AL, CH                      ;first, reset the DLAB from the LCR
        MOV     DX, LCRAddr                 ;   by restoring the previous value
        OUT     DX, AL                      ;   of the LCR and writing to the 
                                            ;   LCRAddr
        
        MOV     AL, CL                      ;now, reset the IER by restoring the
        MOV     DX, IERAddr                 ;   previous value of the IER and 
        OUT     DX, AL                      ;   writing to the IERAddr
        ;JMP    EndSetBaudRate
        
EndSetBaudRate:                             ;end the function
        RET
                    
SetBaudRate         ENDP 



; SerialEventHandler
;
; Description:			The function checks which interrupt is being called and
;                       handles each one appropriately. It utilizes a jump table
;                       to go to the appropriate subfunction within the event 
;                       handler, and calls EventQueue if necessary. All of the
;                       subfunctions at least read the value from the interrupt
;                       source register to turn it off. This function is called
;                       every time there is an INT2 interrupt from the 16C450.
;
; Operation:			The function reads a value from the Interrupt Identification
;                       Register. It then extends the value to a word and utilizes
;                       the SerialEHJmpTable to go the appropriate subfunction 
;                       of the event handler. A separate functional specification
;                       is attached for each subfunction for more detailed 
;                       information.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		InterruptVal (BX) - Value read from IIR, used as index
;                                           for the SerialEHJmpTable.
; Shared Variables:		TxQueue		 (DS) - Queue that contains all of the desired 
;                                           characters that will be sent over to
;                                           to the serial channel (R/W).
;						KickStart    (DS) - Value that determines whether or not
;                                           kickstarting is required (R/W).	
; Global Variables:		None.
;
; Input:				Information from 16C450 registers.
; Output:				Information to the serial channel.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, BX, DX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision
;                       11/19/16    Dong Hyun Kim       updated comments

SerialEventHandler  PROC        NEAR
                    PUBLIC      SerialEventHandler
           
CheckInterrupt:                             ;check which interrupt should be handled          
        MOV     DX, IIRAddr                 ;read value of IIR and store it in
        IN      AL, DX                      ;   AL register
		
        XOR     AH, AH                      ;prepare to index through the 
        MOV     BX, AX                      ;   SerialEHJmpTable, converting the
                                            ;   interrupt type to a word and storing
                                            ;   in the BX register
        JMP     CS:SerialEHJmpTable[BX]     ;utilize the jump table to follow the
                                            ;   label and handle the interrupt
                                            ;   appropriately
                     

                
; ModemStatus
;
; Description:			The subfunction is called whenever there is a Modem Status
;                       interrupt in the IIR. It resets the interrupt by reading
;                       the modem status register. Nothing else is done with the
;                       input value, for the subfunction is only interested in
;                       clearing the interrupt.
;
; Operation:			The subfunction simply reads the value from the MSR and 
;                       resets the interrupt from the IIR. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		MSRVal (AL) - Value read from the MSR.
; Shared Variables:		None.			
; Global Variables:		None.
;
; Input:				Information from the MSR.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		None.
;
; Registers Changed:	AL, DX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision               
        
ModemStatus:
        MOV     DX, MSRAddr                 ;read value of MSR and store it in 
        IN      AL, DX                      ;   AL register. Although we do not
                                            ;   do anything with the value we
                                            ;   obtained in AL, this will clear 
                                            ;   the Modem Status Interrupt and
                                            ;   allows the event handler to run
                                            ;   properly
        JMP     EndSerialEventHandler       ;end the function

        
        
; TxEmpty
;
; Description:			The subfunction is called whenever there is a Transmitter
;                       holding register empty interrupt in the IIR. It sets the
;                       KickStart variable if the TxQueue is empty. Otherwise, 
;                       it dequeues the head value from TxQueue and writes it to
;                       the Transmitter Holding Register. This also resets the
;                       interrupt.
;
; Operation:			The function will initially check if TxQueue is empty.
;                       If it is, the function will set KickStart and just exit
;                       the eventhandler. If not, the function will dequeue a 
;                       value from TxQueue by calling Dequeue. It will then write
;                       the dequeued value to the THR. 
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		Value     (AL) - Value that was dequeued from TxQueue.
;                       QueueAddr (SI) - Address of TxQueue.
; Shared Variables:		TxQueue	  (DS) - Queue that contains all of the desired 
;                                        characters that will be sent over to
;                                        to the serial channel.
;						KickStart (DS) - Value that determines whether or not
;                                        kickstarting is required.			
; Global Variables:		None.
;
; Input:				None.
; Output:				Information to the serial channel if there is any characters
;                       in TxQueue.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AL, DX, SI.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision               

TxEmpty:
        LEA     SI, TxQueue                 ;obtain address of TxQueue for 
                                            ;   QueueEmpty function
        CALL    QueueEmpty                  ;returns zero flag set if queue is
                                            ;   empty, reset otherwise
        JNZ     DequeueTxQueue              ;if TxQueue is not empty, Dequeue
                                            ;   the head value from TxQueue and
                                            ;   store it in THR so that the 
                                            ;   desired information will be sent
                                            ;   over to the serial channel.
        ;JZ    KickStartOn                  ;if TxQueue is empty, there are no 
                                            ;   values to write to the THR so 
                                            ;   the KickStart variable must be 
                                            ;   set to alert SerialPutChar that
                                            ;   the appropriate interrupt bit 
                                            ;   must be disabled and enabled.
 
KickStartOn:
        MOV     KickStart, KICKSTART_ON     ;When there are no values to write 
                                            ;   to the THR, the 16C450 will not
                                            ;   be able to generate Transmitter
                                            ;   Holding Register Empty interrupts
                                            ;   and accept new values. Hence,
                                            ;   we must set KickStart to let the
                                            ;   SerialPutChar function disable
                                            ;   and enable the ETBE bit of the 
                                            ;   IER and kickstart before clearing
                                            ;   the carryflag.
        JMP     EndTxEmpty                  ;now, we are done
 
DequeueTxQueue:                             ;if not, dequeue the head value
        CALL    Dequeue                     ;dequeue a value from TxQueue and 
                                            ;   store in the AL register
        MOV     DX, THRAddr                 ;obtain address of THR 
        OUT     DX, AL                      ;output the dequeued value from TxQueue
                                            ;   to the Transmitter Holding Register
                                            ;   which will send information over
                                            ;   to the serial channel
        ;JMP    EndTxEmpty                  

EndTxEmpty:                                 
        JMP     EndSerialEventHandler       ;end the function
                    

                    
; DataReceived
;
; Description:			The subfunction is called whenever there is a Received
;                       Data Available Interrupt in the IIR. It will read the
;                       appropriate value from the RBR and enqueue the interrupt
;                       event type and value to EventBuf. 

; Operation:			The function reads a value from the RBR and stores it as
;                       the interrupt event value. The appropriate interrupt
;                       event type is then stored, and the EnqueueEvent is called
;                       to enqueue the interrupt event type and value to the
;                       EventBuf.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		RxDataVal   (AL) - value read from the RBR.
;                       RxDataEvent (AH) - type of the DataReceived interrupt event.
; Shared Variables:		None.			
; Global Variables:		None.
;
; Input:				Information from the RBR.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, DX.
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code  
;                       11/18/16    Dong Hyun Kim       initial revision               

DataReceived:
        MOV     AH, RxDataEvent             ;set the appropriate event type for
                                            ;   this interrupt
											
        MOV     DX, RBRAddr                 ;read value of the RBR and store it
        IN      AL, DX                      ;   in the AL register. we will use
                                            ;   this as the interrupt event value
											
        CALL    EnqueueEvent                ;enqueue the event type and event 
                                            ;   value to EventBuf
											
        JMP     EndSerialEventHandler       ;end the function 
   
   
                
; LineStatus
;
; Description:			This subfunction is called whenever there is a Receiver
;                       Line Status Interrupt in the IIR. It will only read the
;                       error bits from the LSR and enqueue the interrupt event
;                       type and value to EventBuf.
;
; Operation:			The function reads a value from the LSR and applies a bit
;                       mask so that only the error bits are being stored as
;                       event values. The appropriate interrupt event type is
;                       then stored, and the EventQueue is called to enqueue
;                       the interrupt event type and value to the EventBuf.
;
; Arguments:			None.
; Return Value:			None.
;
; Local Variables:		LineStsVal   (AL) - error value read from the LSR.
;                       LineStsEvent (AH) - type of the LineStatus interrupt event.
; Shared Variables:		None.			
; Global Variables:		None.
;
; Input:				Information from the LSR.
; Output:				None.
;
; Error Handling:		None.
;
; Algorithms:			None.
; Data Structures:		Queues.
;
; Registers Changed:	AX, DX. 
; Limitations:			None.
; Known Bugs:           None.
; Special Notes:        None.
;
; Revision History:     11/14/16    Dong Hyun Kim       wrote pseudo code
;                       11/18/16    Dong Hyun Kim       initial revision               

LineStatus:
        MOV     DX, LSRAddr                 ;read value of the LSR and store it
		
        IN      AL, DX                      ;   in the AL register
        AND     AL, LSRErrorMsk             ;mask out LSR so we only read the 
                                            ;   error bits

        CMP     AL, NO_ERROR                ;check if there is an error
        JE      EndSerialEventHandler       ;if not, end the function since we
                                            ;   do not have to enqueue
        ;JNE    CallEnqueueEvent

CallEnqueueEvent:                           ;otherwise, call the appropriate 
                                            ;   function
											
        MOV     AH, LineStsEvent            ;set the appropriate event type for
                                            ;   this interrupt
											
        CALL    EnqueueEvent                ;enqueue the event type and event
                                            ;   value to EventBuf
        ;JMP    EndSerialEventHandler

EndSerialEventHandler:                       ;end the function
        RET        

SerialEventHandler      ENDP



; ParityTable
;
; Description:          This is the table that contains the values of the various
;                       parity settings that will be output to the Line Control
;                       Register of the 16C450. It will be utilized in SetSerialParity
;                       to allow the user to choose the appropriate parity setting.
;
; Notes:                More detail for each definition utilized in the table is
;                       available in the include file.
;
; Author:               Dong Hyun Kim
; Last Modified:        11/18/16

ParityTable     LABEL       BYTE

        DB      LCRParOff                               ;Parity is off
        DB      LCRParOn OR LCRParOdd                   ;Parity is on and odd
        DB      LCRParOn OR LCRParEven                  ;Parity is on and even
        DB      LCRParOn OR LCRParOdd  OR LCRParStickOn ;Parity is on, odd and stick
        DB      LCRParOn OR LCRParEven OR LCRParStickOn ;Parity is on, even and stick

        
        
; BaudTable
;
; Description:          This is the table that contains the values of the divisors
;                       that will be output to the Divisor Latch of the 16C450.
;                       It will be utilized in SetBaudRate to allow the user to
;                       choose a desired buad rate, assuming a 9.216MHz clock
;                       frequency. 
;
; Notes:                Divisor = Clock Frequency / (desired baud rate * 16).
;                       More detail for each definition utilized in the table is
;                       available in the include file.
;
; Author:               Dong Hyun Kim
; Last Modified:        11/18/16

BaudTable       LABEL       WORD

        DW      BAUD_DIV_9600              ;divisor that sets baud rate to 9600
        DW      BAUD_DIV_4800              ;divisor that sets baud rate to 4800
        DW      BAUD_DIV_7200              ;divisor that sets baud rate to 7200
        DW      BAUD_DIV_19200             ;divisor that sets baud rate to 19200
        DW      BAUD_DIV_38400             ;divisor that sets baud rate to 38400


        
; SerialEHJmpTable
;
; Description:          This is the table that contains the subfunctions of the 
;                       SerialEventHandler. After checking the IER, the type of
;                       interrupt is determined in the SerialEventHandler. It then
;                       goes to the appropriate section utilizing this jump table
;                       and handles each interrupt in an unique fashion. The values
;                       in the IER can be used as an index right away, since the
;						first bit of the IER is not set if there is any type of 
;						interrupt. That is, the values of IER is already a word
;						index that can be used right away by the SerialEHJmpTable. 
;
;
; Author:               Dong Hyun Kim
; Last Modified:        11/18/16

SerialEHJmpTable    LABEL       WORD

        DW      ModemStatus                 ;modem status interrupt
        DW      TxEmpty                     ;trasmitter holding register empty interrupt
        DW      DataReceived                ;received data available interrupt
        DW      LineStatus                  ;receiver line status interrupt
         
        
        
CODE    ENDS



;the data segment

DATA    SEGMENT PUBLIC  'DATA'

TxQueue			MYQUEUE <>  			    ;Queue that contains all of the desired 
                                            ;   characters that will be sent over
                                            ;   to the serial channel.
KickStart       DB      ?                   ;Value that determines whether or not
                                            ;   kickstarting is required. If there
                                            ;   is no character to output to the
                                            ;   serial channel (that is, if there 
                                            ;   are no characters in TxQueue) and
                                            ;   a TrasmitterEmpty interrupt occurs,
                                            ;   the 16C450 is unable to produce 
                                            ;   the same interrupt since it assumes
                                            ;   that there will be no characters
                                            ;   that will be sent over to the
                                            ;   serial channel in the future. Hence,
                                            ;   the 16C450 must be kickstarted by
                                            ;   disabling and enabling the ETBE
                                            ;   bit of the IER. This will allow
                                            ;   TrasmitterEmpty interrupts to
                                            ;   occur in the future as well, and
											;	let the serial line communicate
											;	properly. 
                                            
DATA    ENDS

END