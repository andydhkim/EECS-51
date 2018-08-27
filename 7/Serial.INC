;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Serial                                   ;
;                         Serial I/O Routines Function                       ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the TL16C450. 
;
; Revision History:
;   11/17/16    Dong Hyun Kim       initial revision
;   11/19/16    Dong Hyun Kim       added definitions


; Serial I/O Definitions

;Addresses
SerialBase      EQU     00100H              ;base address of 16C450 asynchronous 
                                            ;   communications element.

RBRAddr         EQU     SerialBase          ;address of Recevier Buffer Register
                                            ;   (read only) when DLAB is not set
THRAddr         EQU     SerialBase          ;address of Transmitter Holding Register
                                            ;   (write only) when DLAB is not set
DLLAddr         EQU     SerialBase          ;address of Divisor Latch when DLAB
                                            ;   is set
DLMAddr         EQU     SerialBase          ;addresss of Latch when DLAB is set                                            
IERAddr         EQU     SerialBase + 01H    ;address of Interrupt Enable Register
                                            ;   when DLAB is not set
IIRAddr         EQU     SerialBase + 02H    ;address of Interrupt Ident. Register
LCRAddr         EQU     SerialBase + 03H    ;address of Line Control Register
MCRAddr         EQU     SerialBase + 04H    ;address of Modem Control Register
LSRAddr         EQU     SerialBase + 05H    ;address of Line Status Register
MSRAddr         EQU     SerialBase + 06H    ;address of Modem Status Register
SCRAddr         EQU     SerialBase + 07H    ;address of Scratch Register


;Line Control Register (LCR) Definitions
                                            
;Word Lengths
CharWL5         EQU     00000000b           ;set word length to five bits
CharWL6         EQU     00000001b           ;set word length to six bits
CharWL7         EQU     00000010b           ;set word length to seven bits
CharWL8         EQU     00000011b           ;set word length to eight bits

;Number of Stop Bits
StopBit1        EQU     00000000b           ;set one stop bit in each character
StopBit12       EQU     00000100b           ;set one and one-half stop bit in
                                            ;   character ONLY five bits long
StopBit2        EQU     00000100b           ;set two stop bits in each character

;Parity
LCRParMsk       EQU     11000111b           ;mask used to alter parity bits in
                                            ;   the LCR register without changing
                                            ;   any other settings with AND command
                                            
LCRParOn        EQU     00001000b           ;bit used to enable parity                                                   
LCRParOff       EQU     00000000b           ;bit used to disable parity

LCRParEven      EQU     00010000b           ;bit used to select even parity
LCRParOdd       EQU     00000000b           ;bit used to select odd parity

LCRParStickOn   EQU     00100000b           ;bit used to check trasmitted parity
                                            ;   bit as cleared
LCRParStickOff  EQU     00000000b           ;bit used to check trasmitted parity
                                            ;   bit as set                                             
                         
;Break Control Bit
LCRBreakOn      EQU     01000000b           ;bit used to force a break condition
LCRBreakOff     EQU     00000000b           ;bit used to disable break condition
  
;Divisor Latch Access Bit
LCRDLABSet      EQU     10000000b           ;bit used to set the DLAB, which allows
                                            ;   user to access divisor latch and
                                            ;   choose appropriate baud rate
LCRDLABClr      EQU     00000000b           ;bit used to clear the DLAB, which 
                                            ;   allows user to access the Receiver
                                            ;   Buffer Register and Trasmitter 
                                            ;   Holding Register

                                            
;Interrupt Enable Register (IER) Definitions

;Transmitter
IERTxMsk        EQU     00001101b           ;mask used to alter only the ETBE bit
                                            ;   of the IER without changing any
                                            ;   other settings with AND command
                                            
IEREnableTx     EQU     00000010b           ;value used to enable Trasmitter Holding
                                            ;   Register Empty interrupts with
                                            ;   OR command
IERDisableTx    EQU     NOT IEREnableTx     ;value used to disable Trasmitter Holding
                                            ;   Register Empty interrupts with 
                                            ;   AND command                                            

;Interrupt Enablers/Disablers
IERDisableINT   EQU     00000000b           ;value used to disable all interrupts
IERRxData       EQU     00000001b           ;bit used to enable received data 
                                            ;    available interrupt
IERTxEmpty      EQU     00000010b           ;bit used to enable trasmitter holding
                                            ;    register empty interrupt
IERLineSts      EQU     00000100b           ;bit used to enable receiver line status
                                            ;   interrupt
IERModemSts     EQU     00001000b           ;bit used to enable modern status 
                                            ;   interrupt
                                            

;Interrupt Identification Register (IIR) Definitions

;Interrupt Types
IIRModemStsINT  EQU     00000000b           ;value indicating a modem status interrupt
IIRTxEmptyINT   EQU     00000010b           ;value indicating trasmitter holding
                                            ;   holding register empty interrupt
IIRRxDataINT    EQU     00000100b           ;value indicating receiver data interrupt
IIRLineSts      EQU     00000110b           ;value indicating line status interrupt
                                            
                                            
;Divisor Latch (DLL) Definitions

;Divisors (assumes 9.216MHz clock frequency) 
BAUD_DIV_9600   EQU     60                  ;divisor that sets baud rate to 9600
BAUD_DIV_4800   EQU     120                 ;divisor that sets baud rate to 4800
BAUD_DIV_7200   EQU     80                  ;divisor that sets baud rate to 7200
BAUD_DIV_19200  EQU     30                  ;divisor that sets baud rate to 19200
BAUD_DIV_38400  EQU     15                  ;divisor that sets baud rate to 38400

;Line Status Register (LSR) Definitions

LSRErrorMsk     EQU     00011110b           ;mask used to check only the error
                                            ;   bits of the LSR using the AND 
                                            ;   command


                                            
;General Definitions

;Parity Setting Constants (used as inputs for SetSerialParity)
PAR_OFF         EQU     0                   ;constant to disable parity bit 
PAR_ODD         EQU     1                   ;constant to select odd parity 
PAR_EVEN        EQU     2                   ;constant to select even parity 
PAR_STICK_ODD   EQU     3                   ;constant to select odd parity and
                                            ;   stick parity bit 
PAR_STICK_EVEN  EQU     4                   ;constant to select even parity and
                                            ;   stick parity bit 
                                            
;Baud Rate Constants (used as inputs for SetBaudRate)
BAUD_RATE_9600  EQU     0                   ;constant to set baud rate to 9600
BAUD_RATE_4800  EQU     2                   ;constant to set baud rate to 4800
BAUD_RATE_7200  EQU     4                   ;constant to set baud rate to 7200
BAUD_RATE_19200 EQU     6                   ;constant to set baud rate to 19200
BAUD_RATE_38400 EQU     8                   ;constant to set baud rate to 38400
                                            
;KickStart Settings
KICKSTART_ON     EQU    1                   ;value of KickStart flag that tells
                                            ;   user that serial chip requires a
                                            ;   kickstart in order to receive
                                            ;   characters
KICKSTART_OFF    EQU    0                   ;value of KickStart flag that tells 
                                            ;   user that serial chip is receiving
                                            ;   characters correctly and does not
                                            ;   require a kickstart
                                            
;Error Type
NO_ERROR        EQU     0                   ;value when there is no line status
                                            ;   error 
                                            
;Interrupt Event Type
RxDataEvent     EQU     1                   ;the event type of a Received Data
                                            ;   Available interrupt
LineStsEvent    EQU     2                   ;the event type of a Receiver Line
                                            ;   Status interrupt