;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   RMTFUNCS                                  ;
;                      Remote Unit Main File Helper Functions                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains definitions for the remote unit main file helper function
; program (RmtFuncs.ASM). 
;
; Revision History:
;   12/02/16    Dong Hyun Kim       initial revision


;General Definitions

                                          
RX_BUF_LENGTH       EQU     9               ;the amount of characters that the
                                            ;   RxDataBuf can handle each time