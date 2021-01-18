DRAWMACRO MACRO IMG,IMGW,IMGH,X,Y,W,H,LABEL1 ; PASS THE IMAGE DETAILS TO DRAWIMAGE MACRO + X,Y COORDINATES OF WHERE WE WANT TO DRAW IT + W, H DUMMY VARIABLES TO BE USED

   
        
  ;==================================SerialPortInitialization======================================
InitSerialPort MACRO
    ;Set divisor latch access bit
    MOV DX, 3FBH    ;Line control register
    MOV AL, 10000000b
    OUT DX, AL

    ;Set the least significant byte of the Baud rate divisor latch register
    MOV DX, 3F8H
    MOV AL, 01H
    OUT DX, AL

    ;Set the most significant byte of the Baud rate divisor latch register
    MOV DX, 3F9H
    MOV AL, 00H
    OUT DX, AL

    ;Set serial port configurations
    MOV DX, 3FBH    ;Line Control Register
    MOV AL, 00000011B
    ;0:     Access to receiver and transmitter buffers
    ;0:     Set break disabled
    ;000:   NO parity
    ;0:     One stop bit
    ;11:    8-bit word length
    OUT DX, AL
ENDM InitSerialPort
;===========================================================================================

;=====================GetKeyPressed==========================================================
GetKeyPress MACRO
    MOV AH,01H                     ;DOESN'T WAIT FOR KEY PRESSED, JUST CHECKS THE KEYBOARD BUFFER FOR ONE
    INT 16H
ENDM GetKeyPress
;============================================================================================

;=====================DisplayASingleCharacter=============================================
PrintChar MACRO MyChar
    MOV AH, 2
    MOV DL, MyChar
    INT 21H
ENDM PrintChar
;=========================================================================================

;===============================ENTERTEXTMODE===============================================
TEXTMODE MACRO 
                        MOV          AH,0
	                    MOV          AL,3
	                    INT          10H
    ENDM TEXTMODE
;===========================================================================================

;================================MOVECURSORPOSITION=========================================
MOVECURSOR MACRO   X,Y
                        MOV          AH,2
	                    MOV          BH,0
	                    MOV          DL,X
	                    MOV          DH,Y
	                    INT          10H
    ENDM MOVECURSOR
;============================================================================================

;====================================DRAWSEPARATIONLINE======================================
DRAWSEPLINE MACRO
MOV          AH,09H
	                    MOV          BH,0
	                    MOV          AL,2DH
	                    MOV          CX, 80
	                    MOV          BL,0FH
	                    INT          10H
    ENDM DRAWSEPLINE
;============================================================================================

;====================================SENDINGSERIALPORT========================================
SENDCHAR MACRO CHAR
LOCAL AGAIN
                    mov  dx , 3FDH
	                AGAIN:          
	                In   al , dx
	                AND  al , 00100000b
	                JZ   AGAIN


	                mov  dx , 3F8H
	                mov  al,CHAR
	                out  dx , al

    ENDM SENDCHAR
;=============================================================================================

;====================================RECEIVINGSERIALPORT========================================
RECEIVECHAR MACRO CHAR
LOCAL Return
    MOV AL, 0
    MOV DX, 3FDH   ;Line Status Register
    IN AL, DX
    AND AL, 00000001B       ;Check for data ready
    JZ Return               ;No character received
    MOV DX, 3F8H     ;Receive data register
    IN AL, DX
    Return:
    ENDM RECEIVECHAR
;================================================================================================

;=======================ScrollUp=================================================================
ScrollUp MACRO X1, Y1, X2, Y2, LinesCount
    MOV AH, 06H
    MOV AL, LinesCount
    MOV BH, 07H
    MOV CL, X1
    MOV CH, Y1
    MOV DL, X2
    MOV DH, Y2
    INT 10H
ENDM ScrollUp
;===============================================================================================

;====================================DEALWITHCHARCATERINPUTBYUSER===============================
PROCESSINPUT_INLINE MACRO SCANCODE,Char, X, Y, STARTINGY
LOCAL CheckF5_1, CheckBackspace_1, CheckPrintable_1, AdjustCursorPos_1, Return_1
    
    ;IF F3 IS PRESSED CHAT MUST END
    CheckF5_1:
    CMP SCANCODE, 3FH
    JNE CheckBackspace_1
    MOV IsChatEnded_INLINE, 1
    JMP Return_1
    ;==================================
    
    ;IF ENTER IS PRESSED, CURSOR JUMPS TO THE START OF THE FOLLOWING LINE
    ; CheckEnter:
    ; CMP Char, Enter_AsciiCode
    ; JNE CheckBackspace
    ; MOV X, ChatMargin
    ; INC Y
    ; JMP Scroll
    ;==================================

    ;IN CASE BACKSPACE IS PRESSED, THE PREVIOUS CHARACTER IS REMOVED
    CheckBackspace_1:
    CMP Char, Back_AsciiCode
    JNE CheckPrintable_1
	MOV AL,ChatMargin
    CMP X, AL
    JBE CheckPrintable_1
    MOV Char, ' '
    DEC X
    MOVECURSOR X, Y
    MOV AH,13H
	MOV BH,0
	MOV BL,71
	MOV CH,0
	MOV CL,1
	MOV DL, X
	MOV DH,Y
	MOV BP, WORD PTR Char
	INT 10H
    JMP Return_1
    ;==================================
    
    ;MAKES SURE THAT THE USER CHOOSE A PRINTABLE CHARACTER (I.E. NOT A SOUND OR A FUNCTION SUCH AS DELETE)
    CheckPrintable_1:
    CMP Char, ' '   ;SMALLEST PRINTABLE CHARACTER
    JB Return_1
    CMP Char, '~'   ;HIGHEST PRINTABLE CHARACTER
    JA Return_1
    
    ;Print char
    MOVECURSOR X,Y
   MOV AH,13H
	MOV BH,0
	MOV BL,71
	MOV CH,0
	MOV CL,1
	MOV DL, X
	MOV DH,Y
	MOV BP, WORD PTR Char
	INT 10H
    ;==================================
    
    ;AFTER PRINTING THE CHARACTER, THE CURSOR MUST BE ADJUSTED ACCORDINGLY
    AdjustCursorPos_1:
    INC X
    CMP X, ChatAreaWidth-ChatMargin
    JL Return_1
    MOV X, ChatMargin
    INC Y
    ;==================================
    
    ;IN CASE WHERE THE CHAT AREA IS FILLED, WE HAVE TO SCROLL UP IN ORDER TO ALLOW FOR THE CHAT TO PROCEED
    ; Scroll:
    ; CMP Y, ChatAreaHeight+STARTINGY-1
    ; JBE Return
    ; DEC Y
    ; ScrollUp ChatMargin, STARTINGY+3, ChatAreaWidth-ChatMargin, ChatAreaHeight+STARTINGY-1, 1
    ;==================================
    Return_1:
	
ENDM PROCESSINPUT_INLINE
;===============================================================================================
PROCESSINPUT MACRO SCANCODE,Char, X, Y, STARTINGY
LOCAL CheckF3, CheckEnter, CheckBackspace, CheckPrintable, AdjustCursorPos, Scroll, Return
    
    ;IF F3 IS PRESSED CHAT MUST END
    CheckF3:
    CMP SCANCODE, F3_ScanCode
    JNE CheckEnter
    MOV IsChatEnded, 1
    RET
    ;==================================
    
    ;IF ENTER IS PRESSED, CURSOR JUMPS TO THE START OF THE FOLLOWING LINE
    CheckEnter:
    CMP Char, Enter_AsciiCode
    JNE CheckBackspace
    MOV X, ChatMargin
    INC Y
    JMP Scroll
    ;==================================

    ;IN CASE BACKSPACE IS PRESSED, THE PREVIOUS CHARACTER IS REMOVED
    CheckBackspace:
    CMP Char, Back_AsciiCode
    JNE CheckPrintable
    CMP X, ChatMargin
    JBE CheckPrintable
    MOV Char, ' '
    DEC X
    MOVECURSOR X, Y
    PrintChar Char
    RET
    ;==================================
    
    ;MAKES SURE THAT THE USER CHOOSE A PRINTABLE CHARACTER (I.E. NOT A SOUND OR A FUNCTION SUCH AS DELETE)
    CheckPrintable:
    CMP Char, ' '   ;SMALLEST PRINTABLE CHARACTER
    JB Return
    CMP Char, '~'   ;HIGHEST PRINTABLE CHARACTER
    JA Return
    
    ;Print char
    MOVECURSOR X,Y
    PrintChar Char
    ;==================================
    
    ;AFTER PRINTING THE CHARACTER, THE CURSOR MUST BE ADJUSTED ACCORDINGLY
    AdjustCursorPos:
    INC X
    CMP X, ChatAreaWidth-ChatMargin
    JL Return
    MOV X, ChatMargin
    INC Y
    ;==================================
    
    ;IN CASE WHERE THE CHAT AREA IS FILLED, WE HAVE TO SCROLL UP IN ORDER TO ALLOW FOR THE CHAT TO PROCEED
    Scroll:
    CMP Y, ChatAreaHeight+STARTINGY-1
    JBE Return
    DEC Y
    ScrollUp ChatMargin, STARTINGY+3, ChatAreaWidth-ChatMargin, ChatAreaHeight+STARTINGY-1, 1
    ;==================================
    
    Return:
ENDM PROCESSINPUT


;===========================DISPLAYESCMESSAGE====================================================
DrawEscMessBar MACRO 
    MOVECURSOR  0,22
    DRAWSEPLINE 
    MOVECURSOR ChatMargin,23
    MOV AH, 09H
    MOV DX, OFFSET ESC_MESSAGE
    INT 21H
ENDM DrawEscMessBar
;================================================================================================

;===========================DISPLAYTHEPLAYERNAMEUNDERLINED=======================================
DISPLAYPLAYERNAME MACRO NAME,X,Y,LINELENGTH
MOVECURSOR X,Y
    MOV AH, 09H
    MOV DX, OFFSET NAME
	DEC DX
    INT 21H
    MOVECURSOR X,Y+1
    MOV          AH,09H
	                    MOV          BH,0
	                    MOV          AL,2DH
	                    MOV          CX, LINELENGTH
						MOV CH,0
	                    MOV          BL,0FH
	                    INT          10H
ENDM DISPLAYPLAYERNAME
;================================================================================================        
	     
         
         
	      MOV AX, IMGW
          ADD AX, X        ; THE IMAGE WILL BE DRAWN AT X=50
          MOV W,AX
          MOV CX,W          ;TO SET THE CX WITH THE NEW WIDTH

          
		   MOV AX,IMGH
           ADD AX,Y        ; THE IMAGE WILL BE DRAWN AT Y
           MOV H,AX
           MOV DX,H         ; TO SET THE DX WITH THE NEW HEIGHT

           MOV AH,0BH   	;SET THE CONFIGURATION ///

           MOV DI, OFFSET IMG  ; TO ITERATE OVER THE PIXELS
	      
	
           INC DI
	       DEC CX       	;  LOOP ITERATION IN X DIRECTION
	     
           CMP CX,X          ; COMPARE WITH THE X AT WHICH THE IMAGE SHOUD BE DRAWN  .. NOT WITH 0 NOW BECAUSE WE WANT TO MOVE THE IMAGE

    
    LABEL1:
	       MOV AH,0CH   	;SET THE CONFIGURATION TO WRITING A PIXEL
           MOV AL, [DI]     ; COLOR OF THE CURRENT COORDINATES
	       MOV BH,00H   	;SET THE PAGE NUMBER
	       INT 10H      	;EXECUTE THE CONFIGURATION
	 
		   INC DI
	       DEC CX       	;  LOOP ITERATION IN X DIRECTION
	     
           CMP CX,X          ; COMPARE WITH THE X AT WHICH THE IMAGE SHOUD BE DRAWN  .. NOT WITH 0 NOW BECAUSE WE WANT TO MOVE THE IMAGE


           JNZ LABEL1      	;  CHECK IF WE CAN DRAW C URRENT X AND Y AND EXCAPE THE Y ITERATION
	      ; MOV CX, IMGW 	;  IF LOOP ITERATION IN Y DIRECTION, THEN X SHOULD START OVER SO THAT WE SWEEP THE GRID
	     
           MOV CX, W        ; RESET CX WITH THE NEW WIDTH
         
           DEC DX       	;  LOOP ITERATION IN Y DIRECTION
	       
           CMP DX,Y       ; COMPARE WITH THE NEW Y
           
           JNZ  LABEL1 	;  BOTH X AND Y REACHED THE VALUES INDICATED AT WHICH WE WANT TO DRAW THE IMAGE SO END PROGRAM
		   

	
ENDM DRAWMACRO
;----------END OF MACRO

PRINT MACRO MSG
	 	       LEA  DX,MSG
	 	       MOV  AH,09H
	 	       INT  21H
ENDM PRINT
;----------------------

READ MACRO 
	LOCAL LOOP_READING,RECEIVING,FINISHED_READING,FINISHED_RECEIVING,NO_READING,send_just_once

InitSerialPort

MOV DI,OFFSET CURRENTNAMEDATA
MOV SI, OFFSET OTHERNAMEDATA
MOV BX,0

LOOP_READING:
MOV AH,1
INT 16H
JZ RECEIVING
CMP AL,Enter_AsciiCode
JZ send_just_once
cmp BOOL_FINISHED_ENTERING,1
jz RECEIVING

MOV AH,1
INT 21H
MOV SentChar,AL
SENDCHAR SentChar

MOV [DI],AL
INC DI

jmp RECEIVING

send_just_once:
cmp BOOL_FINISHED_ENTERING,1
jz RECEIVING
mov BOOL_FINISHED_ENTERING,1
MOV BH,Enter_AsciiCode
SENDCHAR Enter_AsciiCode
 
RECEIVING:
RECEIVECHAR
JZ NO_READING
CMP AL,Enter_AsciiCode
JZ FINISHED_RECEIVING
CMP BL,Enter_AsciiCode
JZ FINISHED_RECEIVING
MOV [SI],AL
INC SI
JMP LOOP_READING

NO_READING:
CMP BL,Enter_AsciiCode
JZ FINISHED_RECEIVING
JMP LOOP_READING

FINISHED_RECEIVING:
MOV BL,Enter_AsciiCode
CMP BH,Enter_AsciiCode
JZ FINISHED_READING
JMP LOOP_READING


FINISHED_READING:

ENDM READ

GET_NAME_SIZE MACRO N, SIZE
LOCAL LOOP_GET_NAME,END_COUNT

MOV SI,OFFSET N
LOOP_GET_NAME:
CMP [SI],24H
JE END_COUNT
INC SI	
INC SIZE
JMP LOOP_GET_NAME
END_COUNT:

ENDM GET_NAME_SIZE
;----------------------------
;--------------------------------------------------

.286
.MODEL COMPACT
.386
.STACK 100H
.DATA
	BOOL_FINISHED_ENTERING                DB                  0
	BOOL_FINISHED_RECEIVING               DB                  0

	QUIT_GAME_MESSAGE                     DB                  'TO QUIT PRESS ESC'
	START_GAME_MESSAGE                    DB                  'TO START PRESS F2'
	F4_Message                            DB                  "TO DISPLAY SCORE AND QUIT PRESS F4 ..."
	START_INLINE_CHATING                  DB                  "TO START INLINE CHATTING PRESS F5 ..."
	PROMPT_THE_USER_TO_ENTER_NAME_MESSAGE DB                  'ENTER PLAYER NAME(MAX 11 CHARACTERS):', '$'
	CHATTING_GAME_MESSAGE                 DB                  'TO CHAT PRESS F1'
	RECEIVED_CHAT_INVITAITON              DB                  ' SENT YOU A CHAT INVITAION TO ACCEPT PRESS F1'
	RECEIVED_GAME_INVITAITON              DB                  ' SENT YOU A GAME INVITAION TO ACCEPT PRESS F2 '
	SENT_CHAT_INVITAITON                  DB                  'YOU SENT A CHAT INVITATION TO '
	SENT_GAME_INVITAITON                  DB                  'YOU SENT A GAME INVITATION TO '
	                                      PLAYER_1_NAME       LABEL BYTE
	NAME1BUFFERSIZE                       DB                  30
	NAME1ACTUALSIZE                       DW                  ?
	NAME1DATA                             DB                  30 DUP('$')
	                                      PLAYER_2_NAME       LABEL BYTE
	NAME2BUFFERSIZE                       DB                  30
	NAME2ACTUALSIZE                       DW                  ?
	NAME2DATA                             DB                  30 DUP('$')
	                                      CURRENT_PLAYER_NAME LABEL BYTE
	CURRENTNAMEBUFFERSIZE                 DB                  30
	CURRENTNAMEACTUALSIZE                 DW                  0
	CURRENTNAMEDATA                       DB                  30 DUP('$')
	CURRENTPLAYERNUMBER                   DB                  ?
	                                      OTHER_PLAYER_NAME   LABEL BYTE
	OTHERNAMEDATA                         DB                  30 DUP('$')
	OTHERNAMEACTUALSIZE                   dw                  0
	OTHERNAMEBUFFERSIZE                   db                  30

	PLAYER_1_SCORE                        DB                  'SCORE1:'
	PLAYER_1_SCORE_LENGTH                 DW                  $-PLAYER_1_SCORE                                                                                                                                                                                      	;MAX PLAYER NAME IS 50 CHARACTERS
	PLAYER_2_SCORE                        DB                  'SCORE2:'
	PLAYER_2_SCORE_LENGTH                 DW                  $-PLAYER_2_SCORE
	PLAYER_1_CURRENT_SCORE                DW                  '00'
	PLAYER_2_CURRENT_SCORE                DW                  '00'
	WINNER_PLAYER_1_MESSAGE               DB                  'WINNER PLAYER 1'
	WINNER_PLAYER_2_MESSAGE               DB                  'WINNER PLAYER 2'
	LENGTH_WINNER_PLAYER_1_MESSAGE        Dw                  15
	LENGTH_WINNER_PLAYER_2_MESSAGE        Dw                  15
	STARTING_X_1                          DB                  10
	ENDING_X_1                            DB                  110
	STARTING_X_2                          DW                  530
	ENDING_X_2                            DW                  630
	HEALTH_PLAYER1                        DW                  99
	HEALTH_PLAYER2                        DW                  99
	F                                     DB                  0
	N                                     DB                  0
	XC                                    DW                  0
	YC                                    DW                  0
	XC1                                   DW                  0
	YC1                                   DW                  0
	X                                     DW                  0
	Y                                     DW                  0
	P                                     DW                  0
	R                                     DW                  0
	HEIGHT                                EQU                 20                                                                                                                                                                                                    	; HEIGHT OF BLOCK IN Y AXIS
	HEIGHT_PLUS_ONE                       EQU                 21
	WIDTH                                 EQU                 10                                                                                                                                                                                                    	; WIDTH OF THE BLOCK IN X AXIS
	WIDTH_PLUS_ONE                        EQU                 11
	CASTLE_HEIGHT_BLOCKS                  EQU                 9
	DOOR_HEIGHT_BLOCKS                    EQU                 2
	CASTLE_HALF_WIDTH_BLOCKS              EQU                 4
	;PUT THE IMG DATA OUTPUTED BY PYTHON SCRIPT HERE:
	IMGW                                  EQU                 39
	IMGH                                  EQU                 42
	IMGW_B                                EQU                 19
	IMGH_B                                EQU                 19
	;('IMGW EQU', 218)
	;('IMGH EQU', 147)


	W                                     DW                  ?
	H                                     DW                  ?                                                                                                                                                                                                     	; TO SET THE NEW WIDTH AND HEIGHT TO MOVE THE IMAGE
	X1                                    DW                  66                                                                                                                                                                                                    	;
	Y1                                    DW                  134                                                                                                                                                                                                   	;
	X2                                    DW                  535                                                                                                                                                                                                   	;
	Y2                                    DW                  134


	PLAYER_1_CURRENT_SEC                  DB                  ?                                                                                                                                                                                                     	; TO STORE THE SEC AT WHICH THE PLAYER HAS NO NORMAL AMMUNITION LEFT
	PLAYER_2_CURRENT_SEC                  DB                  ?
	REFUEL_TIME_INDICATOR_PLAYER_1        DB                  ?                                                                                                                                                                                                     	; TO STORE THE TIME AT WHICH NORMAL AMMUNITION GET REFUELED FOR PLAYER 1
	REFUEL_TIME_INDICATOR_PLAYER_2        DB                  ?


	IMG_BOMB_L                            DB                  25, 16, 25, 16, 183, 25, 16, 16, 183, 182, 182, 182, 183, 17, 16, 25, 182, 16, 25, 25, 25, 16, 16, 25, 16, 182, 110, 110, 110, 110, 110, 110, 110, 182, 16, 25, 17, 16, 16, 16
	                                      DB                  16, 25, 16, 110, 39, 39, 39, 39, 39, 110, 111, 111, 110, 111, 17, 25, 16, 25, 17, 25, 16, 110, 39, 39, 39, 39, 39, 39, 39, 110, 111, 111, 110, 182, 16, 25, 16, 182, 16, 183
	                                      DB                  39, 39, 39, 39, 39, 39, 39, 39, 39, 110, 111, 111, 110, 182, 16, 16, 25, 16, 110, 39, 63, 64, 39, 39, 39, 39, 39, 39, 39, 110, 111, 110, 111, 16, 111, 182, 17, 39, 39, 29
	                                      DB                  31, 12, 39, 39, 39, 39, 39, 39, 39, 110, 111, 110, 183, 37, 25, 182, 39, 39, 64, 62, 39, 39, 39, 39, 39, 39, 39, 39, 110, 111, 110, 183, 13, 25, 182, 39, 63, 30, 88, 12
	                                      DB                  39, 39, 39, 39, 39, 39, 39, 110, 111, 110, 182, 109, 39, 183, 39, 87, 31, 31, 87, 39, 39, 39, 39, 39, 39, 39, 109, 111, 110, 183, 183, 25, 17, 110, 63, 31, 31, 86, 39, 39
	                                      DB                  39, 39, 39, 39, 39, 109, 111, 111, 17, 16, 13, 16, 111, 39, 23, 27, 64, 39, 39, 39, 39, 39, 39, 39, 4, 110, 182, 16, 25, 183, 25, 17, 182, 110, 111, 182, 110, 39, 39, 39
	                                      DB                  39, 39, 39, 110, 111, 17, 25, 16, 16, 16, 16, 111, 39, 110, 109, 183, 182, 39, 39, 39, 39, 39, 110, 17, 16, 17, 16, 233, 138, 17, 110, 110, 136, 110, 110, 183, 109, 39, 39, 39
	                                      DB                  110, 17, 16, 25, 16, 25, 16, 25, 16, 16, 24, 164, 4, 110, 182, 110, 110, 110, 182, 16, 25, 25, 16, 25, 16, 16, 17, 235, 24, 24, 18, 111, 183, 16, 16, 16, 16, 25, 25, 38
	                                      DB                  16, 25, 16, 16, 18, 138, 24, 163, 18, 16, 16, 16, 25, 25, 25, 25, 13, 17, 16, 16, 16, 25, 16, 17, 18, 18, 16, 16, 25, 25, 25, 16, 17, 16, 16, 16, 16, 16, 25, 25
	                                      DB                  25

	IMG_BOMB_R                            DB                  25, 16, 16, 25, 16, 16, 183, 183, 182, 183, 17, 16, 25, 17, 16, 25, 16, 25, 25, 16, 17, 25, 16, 182, 111, 110, 110, 110, 110, 111, 182, 17, 16, 25, 16, 25, 16, 25, 182, 25
	                                      DB                  17, 182, 110, 110, 111, 111, 111, 111, 111, 110, 111, 17, 16, 25, 16, 16, 25, 25, 16, 111, 110, 111, 111, 110, 110, 110, 109, 109, 4, 110, 110, 17, 25, 38, 16, 16, 16, 182, 110, 111
	                                      DB                  111, 110, 39, 39, 39, 39, 39, 39, 39, 39, 110, 16, 25, 17, 16, 17, 110, 111, 111, 110, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 182, 25, 13, 16, 183, 110, 111, 110, 39, 39
	                                      DB                  39, 39, 39, 39, 39, 39, 39, 39, 39, 110, 16, 25, 16, 182, 110, 110, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 110, 16, 25, 16, 182, 110, 39, 39, 39, 39, 39, 39
	                                      DB                  39, 39, 39, 39, 39, 39, 109, 110, 16, 25, 17, 182, 110, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 182, 183, 182, 16, 25, 16, 183, 110, 39, 39, 39, 39, 39, 39, 39, 39
	                                      DB                  39, 39, 110, 183, 110, 110, 183, 16, 25, 16, 110, 39, 39, 39, 39, 12, 39, 12, 87, 86, 64, 182, 109, 110, 4, 111, 16, 25, 16, 182, 39, 39, 39, 64, 31, 62, 88, 31, 31, 27
	                                      DB                  111, 110, 136, 164, 18, 16, 25, 25, 16, 110, 39, 39, 63, 29, 64, 30, 31, 31, 23, 110, 39, 110, 24, 24, 18, 16, 183, 25, 16, 110, 39, 39, 39, 39, 63, 87, 63, 39, 182, 111
	                                      DB                  110, 16, 24, 163, 16, 16, 16, 25, 16, 183, 110, 39, 39, 39, 39, 110, 111, 17, 16, 17, 16, 235, 24, 18, 25, 16, 16, 25, 16, 16, 17, 182, 182, 183, 17, 16, 25, 16, 138, 25
	                                      DB                  17, 138, 18, 16, 25, 16, 17, 182, 25, 182, 25, 25, 39, 25, 13, 183, 16, 233, 16, 16, 18, 17, 25, 25, 16, 25, 16, 16, 111, 37, 13, 109, 183, 16, 25, 16, 16, 25, 16, 16
	                                      DB                  16                                                                                                                                                                                                    	;

	IMG                                   DB                  27, 27, 27, 20, 27, 23, 18, 16, 27, 27, 31, 154, 202, 18, 18, 17, 18, 16, 17, 18, 18, 18, 18, 17, 18, 18, 201, 204, 25, 27, 31, 17, 20, 27, 16, 23, 27, 27, 27, 27
	                                      DB                  24, 16, 27, 19, 18, 27, 30, 227, 18, 17, 18, 216, 216, 118, 118, 143, 143, 47, 47, 47, 47, 47, 47, 143, 118, 119, 216, 18, 18, 228, 27, 16, 18, 21, 27, 20, 27, 27, 22, 16
	                                      DB                  27, 19, 16, 31, 202, 18, 18, 119, 118, 47, 10, 10, 10, 46, 46, 46, 46, 46, 46, 46, 46, 10, 46, 46, 46, 10, 47, 118, 216, 18, 130, 27, 17, 19, 27, 19, 27, 18, 27, 224
	                                      DB                  27, 21, 18, 216, 118, 47, 46, 46, 10, 46, 10, 10, 10, 10, 10, 47, 47, 47, 47, 47, 10, 10, 10, 10, 46, 46, 46, 10, 118, 216, 201, 84, 16, 20, 27, 20, 27, 18, 27, 230
	                                      DB                  18, 118, 47, 46, 10, 10, 10, 10, 10, 10, 10, 10, 47, 47, 47, 47, 47, 47, 47, 47, 10, 10, 10, 10, 10, 10, 10, 46, 10, 118, 18, 108, 27, 228, 27, 228, 27, 21, 18, 118
	                                      DB                  46, 10, 10, 10, 10, 10, 10, 10, 10, 10, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 10, 10, 10, 10, 10, 10, 10, 46, 10, 118, 18, 5, 27, 228, 27, 31, 18, 118, 46, 10
	                                      DB                  46, 10, 10, 10, 10, 10, 10, 10, 10, 47, 47, 117, 116, 116, 116, 116, 117, 47, 47, 47, 10, 10, 10, 10, 10, 10, 10, 10, 46, 143, 224, 27, 16, 27, 178, 118, 46, 10, 10, 10
	                                      DB                  10, 10, 10, 10, 10, 10, 10, 47, 47, 116, 46, 46, 46, 46, 46, 46, 116, 117, 47, 10, 10, 10, 10, 10, 10, 10, 10, 10, 46, 144, 202, 27, 31, 18, 47, 10, 10, 46, 10, 10
	                                      DB                  10, 10, 10, 10, 10, 10, 47, 116, 46, 46, 46, 46, 46, 46, 46, 46, 116, 117, 47, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 214, 13, 204, 118, 46, 10, 46, 10, 10, 10, 10
	                                      DB                  10, 10, 10, 46, 10, 117, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 116, 47, 10, 46, 10, 10, 10, 10, 10, 10, 10, 46, 143, 202, 18, 143, 46, 10, 10, 10, 10, 10, 10, 10
	                                      DB                  10, 10, 10, 116, 46, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45, 46, 46, 46, 10, 10, 10, 47, 47, 47, 47, 10, 46, 10, 240, 239, 10, 46, 10, 10, 47, 47, 47, 10, 10, 46
	                                      DB                  46, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 10, 47, 47, 47, 117, 117, 47, 10, 10, 144, 239, 10, 46, 10, 47, 47, 47, 47, 47, 10, 10, 116
	                                      DB                  45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 47, 140, 26, 28, 28, 24, 141, 10, 143, 144, 10, 10, 47, 117, 164, 25, 140, 47, 47, 116, 45, 45
	                                      DB                  45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 46, 45, 45, 45, 45, 45, 46, 140, 30, 31, 31, 31, 31, 27, 46, 144, 143, 10, 47, 140, 29, 31, 31, 31, 28, 141, 46, 45, 45, 45
	                                      DB                  45, 45, 45, 45, 45, 45, 45, 46, 191, 119, 46, 45, 45, 45, 45, 46, 164, 31, 31, 31, 29, 23, 29, 71, 144, 143, 72, 140, 30, 31, 31, 31, 31, 31, 26, 46, 45, 45, 45, 45
	                                      DB                  45, 116, 119, 117, 45, 45, 118, 192, 191, 191, 46, 45, 45, 45, 45, 140, 31, 31, 31, 25, 16, 23, 95, 214, 144, 10, 70, 26, 22, 30, 31, 31, 31, 26, 46, 45, 45, 45, 45, 116
	                                      DB                  192, 192, 191, 46, 45, 118, 191, 191, 191, 119, 45, 45, 45, 46, 140, 31, 31, 31, 29, 21, 28, 70, 215, 144, 10, 95, 21, 16, 27, 31, 31, 31, 26, 46, 45, 45, 45, 45, 118, 192
	                                      DB                  191, 191, 46, 45, 118, 191, 191, 191, 192, 46, 45, 45, 46, 25, 31, 31, 31, 31, 31, 31, 164, 215, 19, 141, 96, 28, 24, 31, 31, 31, 31, 27, 46, 14, 45, 45, 45, 119, 191, 191
	                                      DB                  191, 46, 45, 118, 192, 191, 191, 192, 116, 45, 45, 46, 164, 31, 31, 31, 31, 31, 70, 143, 202, 179, 143, 72, 29, 31, 31, 31, 31, 31, 26, 116, 14, 45, 45, 45, 118, 192, 192, 119
	                                      DB                  46, 45, 46, 190, 192, 192, 191, 46, 45, 45, 116, 141, 164, 27, 28, 28, 24, 46, 144, 108, 27, 240, 10, 72, 28, 30, 30, 29, 26, 46, 116, 45, 14, 45, 45, 45, 117, 117, 46, 45
	                                      DB                  45, 45, 46, 116, 116, 46, 45, 45, 46, 116, 10, 46, 47, 141, 47, 46, 10, 19, 27, 27, 201, 143, 71, 140, 140, 140, 141, 47, 10, 46, 116, 45, 14, 45, 45, 45, 45, 45, 45, 45
	                                      DB                  45, 45, 45, 45, 45, 45, 45, 116, 10, 10, 10, 10, 10, 10, 10, 144, 179, 27, 2, 27, 240, 10, 71, 72, 72, 10, 46, 46, 10, 141, 46, 14, 14, 45, 46, 45, 45, 45, 45, 45
	                                      DB                  45, 45, 45, 45, 45, 46, 141, 10, 10, 142, 119, 118, 143, 142, 247, 27, 16, 229, 27, 180, 239, 72, 71, 71, 71, 10, 10, 10, 10, 141, 46, 45, 14, 45, 45, 45, 45, 45, 45, 45
	                                      DB                  45, 45, 45, 46, 141, 10, 10, 46, 10, 10, 47, 10, 239, 180, 27, 20, 27, 18, 27, 179, 144, 72, 142, 143, 118, 119, 47, 10, 10, 46, 116, 45, 14, 45, 45, 45, 45, 45, 45, 45
	                                      DB                  46, 116, 141, 10, 10, 10, 46, 46, 10, 10, 144, 179, 27, 19, 27, 18, 27, 18, 27, 177, 144, 10, 142, 143, 10, 10, 10, 10, 10, 10, 46, 116, 46, 45, 45, 45, 46, 46, 46, 116
	                                      DB                  10, 10, 10, 10, 10, 10, 10, 46, 143, 17, 228, 27, 16, 31, 23, 16, 27, 224, 27, 202, 240, 10, 71, 71, 71, 72, 10, 10, 10, 10, 10, 46, 46, 46, 116, 116, 46, 10, 10, 10
	                                      DB                  10, 10, 10, 10, 10, 10, 10, 10, 10, 214, 226, 27, 18, 27, 21, 27, 31, 18, 27, 179, 18, 144, 10, 71, 71, 71, 10, 10, 10, 46, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                      DB                  46, 46, 46, 10, 118, 192, 119, 10, 10, 144, 179, 27, 27, 27, 21, 16, 27, 247, 27, 54, 137, 212, 144, 10, 71, 71, 71, 72, 10, 10, 46, 10, 10, 10, 10, 10, 10, 46, 46, 10
	                                      DB                  10, 144, 10, 119, 191, 191, 191, 10, 10, 239, 27, 27, 27, 27, 26, 26, 27, 43, 79, 148, 43, 6, 188, 214, 143, 10, 72, 71, 71, 10, 10, 10, 46, 10, 10, 10, 10, 142, 144, 215
	                                      DB                  18, 10, 119, 191, 191, 119, 10, 10, 144, 107, 27, 27, 27, 12, 77, 17, 44, 25, 24, 43, 43, 164, 140, 116, 117, 212, 214, 144, 142, 10, 10, 10, 10, 142, 215, 215, 18, 178, 27, 201
	                                      DB                  165, 142, 191, 119, 142, 46, 10, 144, 36, 27, 27, 12, 27, 42, 27, 12, 43, 43, 43, 25, 54, 24, 44, 44, 140, 162, 16, 144, 10, 191, 191, 143, 10, 215, 204, 27, 21, 27, 180, 143
	                                      DB                  72, 10, 10, 46, 46, 142, 19, 27, 27, 65, 27, 65, 27, 26, 42, 43, 43, 43, 14, 26, 71, 44, 45, 54, 79, 18, 10, 119, 191, 191, 191, 10, 10, 18, 27, 17, 243, 27, 201, 168
	                                      DB                  72, 72, 10, 142, 243, 27, 16, 65, 27, 64, 44, 32, 42, 43, 44, 43, 43, 44, 44, 44, 44, 44, 25, 150, 214, 10, 119, 191, 191, 191, 10, 46, 238, 5, 27, 23, 20, 27, 178, 20
	                                      DB                  143, 20, 228, 27, 214, 156, 27, 26, 27, 100, 42, 43, 43, 43, 42, 43, 44, 44, 44, 44, 43, 43, 176, 143, 10, 118, 191, 191, 118, 10, 10, 144, 180, 27, 21, 27, 20, 121, 27, 121
	                                      DB                  36, 27, 240, 23, 27, 65, 27, 27, 42, 43, 42, 42, 12, 65, 43, 44, 43, 43, 44, 43, 42, 176, 143, 72, 10, 10, 10, 10, 10, 10, 144, 107, 27, 22, 238, 27, 21, 240, 10, 144
	                                      DB                  20, 31, 27, 22, 65, 27, 25, 65, 42, 64, 67, 27, 65, 44, 43, 12, 43, 44, 43, 64, 27, 238, 72, 10, 46, 46, 46, 46, 10, 240, 27, 16, 23, 27, 27, 27, 26, 22, 24, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 6, 27, 42, 27, 43, 43, 12, 27, 42, 44, 43, 64, 27, 204, 143, 72, 72, 10, 10, 10, 238, 227, 27, 19, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 6, 27, 137, 6, 42, 65, 42, 27, 65, 64, 27, 27, 64, 43, 43, 62, 27, 27, 201, 144, 166, 166, 143, 239, 202, 27, 16, 83, 23, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 89, 90, 27, 89, 24, 27, 26, 26, 41, 27, 64, 43, 43, 27, 44, 20, 234, 27, 18, 202, 179, 36, 120, 20, 27, 16, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 42, 83, 27, 42, 65, 42, 27, 42, 42, 27, 42, 27, 242, 216, 27, 192, 27, 192, 19, 27, 27, 24, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 65, 27, 65, 65, 27, 64, 27, 65, 65, 27, 6, 90, 27, 23, 21, 21, 21, 23, 27, 22, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27

	IMG2                                  DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 27, 16, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 16, 16, 16, 16, 16, 17, 118, 27, 16, 27, 27, 27, 27, 27, 27, 27, 27, 71, 27, 31, 119, 16, 16, 16, 16, 27, 16, 27, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 16, 27, 16, 16, 17, 27, 27, 16, 27, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 27, 16, 16, 27, 191, 16, 16, 27, 16, 27, 27, 27, 27, 27, 27, 16, 27
	                                      DB                  27, 16, 17, 16, 27, 16, 16, 16, 17, 191, 190, 119, 119, 119, 119, 119, 119, 119, 119, 119, 191, 191, 192, 16, 16, 16, 27, 16, 189, 16, 16, 27, 16, 27, 27, 27, 16, 27, 16, 16
	                                      DB                  27, 119, 16, 16, 191, 119, 118, 118, 143, 117, 117, 117, 117, 116, 116, 115, 142, 10, 142, 117, 117, 117, 118, 119, 191, 16, 16, 17, 27, 16, 16, 27, 16, 27, 16, 27, 16, 16, 27, 16
	                                      DB                  16, 190, 118, 10, 47, 117, 114, 6, 6, 6, 41, 6, 4, 41, 41, 115, 10, 115, 4, 113, 113, 114, 115, 117, 2, 119, 17, 16, 189, 17, 16, 27, 16, 27, 16, 191, 17, 16, 191, 143
	                                      DB                  10, 47, 142, 114, 6, 41, 42, 42, 42, 42, 41, 6, 42, 42, 6, 118, 6, 42, 6, 6, 6, 41, 4, 115, 116, 114, 190, 16, 16, 27, 16, 27, 16, 27, 17, 16, 118, 10, 10, 140
	                                      DB                  114, 115, 6, 42, 42, 41, 42, 42, 41, 42, 41, 41, 42, 6, 113, 41, 42, 41, 42, 42, 42, 42, 6, 41, 6, 117, 117, 17, 16, 27, 16, 17, 27, 16, 144, 10, 10, 10, 141, 6
	                                      DB                  6, 6, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 6, 6, 42, 42, 42, 42, 42, 42, 41, 42, 41, 114, 113, 115, 2, 17, 16, 27, 27, 16, 215, 10, 10, 10, 10, 10, 115, 41
	                                      DB                  6, 42, 42, 42, 42, 6, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 6, 41, 6, 141, 10, 118, 16, 27, 27, 17, 10, 10, 10, 10, 10, 10, 140, 6, 42
	                                      DB                  41, 42, 42, 42, 6, 6, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 41, 115, 10, 10, 47, 191, 16, 16, 216, 10, 10, 10, 10, 10, 10, 10, 115, 41, 42
	                                      DB                  6, 42, 42, 41, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 41, 42, 41, 41, 6, 42, 6, 140, 10, 10, 10, 119, 16, 16, 144, 10, 10, 10, 10, 10, 22, 24, 171, 6, 42, 6
	                                      DB                  6, 41, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 41, 138, 10, 10, 10, 10, 118, 16, 16, 144, 10, 10, 10, 10, 24, 172, 173, 172, 154, 6, 42, 6
	                                      DB                  6, 6, 114, 115, 116, 116, 116, 116, 116, 116, 116, 115, 6, 6, 6, 6, 42, 6, 172, 172, 172, 23, 10, 144, 16, 16, 144, 10, 10, 10, 24, 149, 167, 164, 168, 172, 174, 114, 6, 114
	                                      DB                  117, 46, 46, 45, 45, 45, 45, 45, 45, 46, 46, 116, 117, 114, 6, 6, 154, 148, 168, 169, 149, 72, 143, 16, 16, 215, 10, 10, 10, 172, 25, 31, 31, 30, 24, 172, 165, 116, 117, 46
	                                      DB                  45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 6, 159, 171, 26, 30, 29, 24, 172, 144, 16, 27, 17, 10, 10, 167, 24, 31, 31, 31, 31, 31, 23, 10, 142, 46, 45, 46
	                                      DB                  45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 142, 171, 27, 31, 31, 31, 31, 24, 18, 16, 27, 16, 143, 10, 167, 28, 31, 31, 31, 31, 31, 27, 10, 117, 45, 45, 45, 116
	                                      DB                  189, 117, 45, 45, 45, 45, 117, 116, 45, 45, 45, 117, 23, 31, 31, 31, 30, 30, 29, 190, 27, 27, 16, 215, 10, 10, 27, 18, 28, 31, 31, 31, 28, 142, 117, 45, 45, 46, 191, 193
	                                      DB                  193, 117, 45, 45, 118, 193, 193, 116, 45, 45, 117, 24, 31, 31, 31, 23, 21, 31, 165, 27, 17, 27, 16, 142, 10, 26, 23, 29, 31, 31, 31, 25, 10, 117, 45, 45, 46, 193, 191, 191
	                                      DB                  191, 46, 46, 193, 190, 193, 117, 45, 45, 117, 164, 31, 31, 31, 29, 29, 29, 143, 27, 16, 27, 16, 215, 10, 164, 30, 31, 31, 31, 29, 141, 10, 142, 46, 45, 45, 116, 191, 191, 193
	                                      DB                  46, 116, 193, 193, 118, 45, 45, 46, 142, 141, 28, 31, 31, 31, 31, 25, 192, 27, 215, 17, 27, 16, 142, 10, 141, 26, 28, 26, 141, 10, 10, 10, 116, 45, 46, 45, 46, 193, 117, 45
	                                      DB                  46, 190, 117, 45, 45, 45, 116, 10, 10, 141, 28, 31, 31, 26, 118, 27, 164, 16, 16, 27, 16, 216, 10, 10, 142, 142, 142, 10, 10, 10, 10, 142, 46, 45, 46, 45, 46, 45, 45, 45
	                                      DB                  45, 45, 45, 45, 46, 142, 10, 10, 10, 142, 165, 143, 190, 27, 141, 16, 27, 27, 16, 27, 16, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 46, 45, 45, 45, 45, 45, 45, 45
	                                      DB                  45, 45, 45, 117, 10, 10, 10, 10, 10, 143, 16, 27, 190, 189, 27, 27, 16, 27, 17, 27, 16, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 46, 45, 45, 45, 45, 45, 45, 45
	                                      DB                  46, 117, 10, 10, 10, 10, 10, 10, 18, 112, 27, 185, 27, 143, 27, 27, 16, 16, 6, 27, 186, 140, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 46, 46, 45, 45, 45, 45, 46, 117
	                                      DB                  10, 10, 10, 10, 140, 140, 115, 6, 113, 27, 113, 113, 27, 27, 27, 16, 27, 113, 27, 113, 6, 6, 6, 6, 140, 10, 10, 10, 10, 10, 10, 10, 141, 116, 46, 116, 141, 141, 10, 10
	                                      DB                  10, 10, 140, 4, 41, 41, 6, 113, 27, 113, 113, 27, 27, 27, 27, 16, 113, 27, 185, 114, 6, 41, 6, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                      DB                  10, 10, 139, 6, 6, 113, 27, 6, 112, 27, 27, 27, 27, 27, 27, 27, 184, 27, 184, 113, 185, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                      DB                  143, 16, 184, 185, 27, 113, 27, 113, 27, 27, 27, 27, 27, 27, 113, 27, 113, 185, 27, 16, 16, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16
	                                      DB                  191, 27, 17, 113, 113, 27, 113, 27, 27, 27, 27, 27, 27, 27, 113, 16, 27, 16, 216, 10, 10, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 16
	                                      DB                  27, 185, 16, 27, 113, 27, 27, 27, 27, 27, 27, 27, 27, 16, 10, 27, 17, 10, 10, 118, 118, 142, 142, 215, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 143, 10, 143, 16, 16
	                                      DB                  27, 16, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 215, 10, 10, 118, 118, 142, 142, 16, 16, 17, 216, 215, 215, 216, 17, 190, 10, 142, 118, 118, 143, 10, 215, 16, 27
	                                      DB                  16, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 141, 27, 17, 10, 10, 142, 142, 10, 215, 27, 69, 16, 27, 27, 27, 215, 27, 191, 10, 142, 118, 118, 143, 10, 143, 16, 27, 16
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 216, 10, 10, 10, 144, 16, 27, 17, 216, 10, 31, 31, 143, 27, 16, 142, 10, 143, 144, 10, 10, 144, 16, 27, 16, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 27, 16, 17, 216, 17, 16, 27, 16, 27, 16, 16, 16, 16, 16, 27, 16, 216, 10, 10, 10, 10, 142, 17, 16, 27, 16, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 17, 27, 16, 16, 27, 17, 27, 17, 27, 27, 27, 27, 16, 16, 27, 16, 17, 143, 143, 214, 17, 16, 27, 16, 16, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 216, 27, 214, 17, 27, 142, 16, 27, 27, 27, 27, 16, 27, 16, 27, 16, 16, 16, 16, 16, 16, 16, 27, 16, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 16, 16, 27, 16, 27, 27, 27, 27, 27, 27, 27, 16, 27, 16, 16, 27, 16, 27, 17, 16, 27, 16, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 16, 27, 16, 16, 16, 16, 16, 27, 16, 27, 27, 27, 27, 27, 27, 27, 27
	                                      DB                  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 16, 16, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27


	
	
	IMGW_CLK                              EQU                 19
	IMGH_CLK                              EQU                 26

	X_win_l                               dw                  35
	Y_win_l                               dw                  300



	X_win_r                               dw                  480
	Y_win_r                               dw                  300
	XB                                    DW                  190
	YB                                    DW                  120
	IMGW_MAIN                             EQU                 257
	IMGH_MAIN                             EQU                 135

	IMG_MAIN                                       DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16
	                                               DB            124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124
	                                               DB            16, 16, 16, 16, 16, 124, 124, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16, 124, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16
	                                               DB            124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124
	                                               DB            16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 124, 16, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 124, 16, 16
	                                               DB            124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124
	                                               DB            16, 124, 16, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16
	                                               DB            124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 124, 16, 16, 16, 124, 16, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 16, 124, 16, 124, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 16, 16, 124, 16, 16
	                                               DB            16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 191, 191
	                                               DB            191, 190, 216, 216, 216, 215, 118, 215, 216, 216, 216, 216, 216, 191, 191, 17, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 216, 215, 144, 144, 143, 144, 143, 143, 143, 144, 144, 144, 144, 215, 216, 191, 17, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 17, 17, 190, 216, 118, 144, 143, 143, 143, 143, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 143, 143, 143, 144, 144, 215, 216
	                                               DB            191, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 191, 215, 144, 144, 143, 143, 143, 143, 143, 143, 143, 143, 143, 144, 144, 214, 216, 17, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 190, 216, 118, 144, 143, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142
	                                               DB            142, 142, 142, 142, 142, 142, 142, 143, 144, 215, 190, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 216, 215, 144, 143, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142
	                                               DB            142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 142, 143, 144, 215, 190, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 216, 118, 143, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142
	                                               DB            142, 142, 142, 142, 142, 143, 144, 118, 190, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 190, 144
	                                               DB            143, 142, 10, 10, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 10, 142, 143, 144, 216, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 216, 144, 143, 143, 10, 10, 142, 142
	                                               DB            142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 142
	                                               DB            143, 144, 215, 191, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 216, 144, 143
	                                               DB            142, 10, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 10, 142, 143, 144, 190, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 191, 144, 143, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 142, 142, 142, 142, 142, 143, 118, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 17, 216, 143, 143, 142, 10, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 143, 144, 191, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 215, 143, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 142, 142, 142, 142, 143, 118, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 124, 16, 124, 16, 16, 124, 16, 124, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 216, 144, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 144, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 191, 144, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142
	                                               DB            142, 143, 215, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 215, 143, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 144, 17, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 16, 124
	                                               DB            16, 16, 16, 16, 16, 124, 16, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 216, 143, 142, 142, 142, 10, 10, 10, 10, 10, 10, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 142, 142, 10, 143, 144, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 216, 144, 142, 10, 142
	                                               DB            142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 143, 143, 143, 142, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 143, 144, 191, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 216, 143, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 144, 215, 215, 215, 144, 143, 10, 10
	                                               DB            10, 10, 142, 10, 143, 118, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 124, 16, 16, 124
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 144, 142, 142, 142, 10, 10, 10, 10, 142, 144, 216, 216, 216, 216, 216, 216, 144, 142, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 143, 216, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 216, 143, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 144, 216, 216, 193, 191, 191, 191, 191, 193, 216, 215, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142
	                                               DB            144, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 144, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 144, 216, 191, 191, 191, 191, 191, 191, 191, 216, 144, 10, 10, 10, 10, 142, 142, 143, 191, 16, 16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 124, 16, 16, 16, 124, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 216, 143, 142, 142, 10, 10, 10
	                                               DB            10, 142, 215, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 214, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 142, 142, 142, 144, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 191, 144, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 214, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 216, 144, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 142, 142, 118, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 143, 142, 142, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 216, 191, 191, 191, 191, 191, 191, 191, 216, 216, 191, 191, 216, 142, 10, 10, 10, 10
	                                               DB            142, 142, 215, 16, 16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 17, 18, 16, 20, 232, 16, 16, 16
	                                               DB            124, 16, 16, 16, 124, 16, 16, 16, 16, 144, 142, 142, 10, 10, 10, 10, 10, 143, 191, 191, 193, 216, 216, 191, 191, 191, 191, 191, 191, 191, 191, 191, 143, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 143, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 118, 142, 142, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 215, 191, 191, 191, 191, 191, 191, 191
	                                               DB            191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 216, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 10, 143, 190, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 191, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 191, 190
	                                               DB            190, 190, 193, 191, 191, 191, 215, 118, 118, 118, 216, 191, 216, 142, 10, 10, 10, 10, 10, 142, 118, 16, 16, 16, 124, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 16, 16, 18, 16, 124, 16, 17, 24, 24, 18, 16, 124, 16, 124, 16, 16, 16, 16, 124, 16, 16, 16, 17, 144, 142, 10, 10, 10, 10, 10, 10, 144, 191, 191, 215, 189, 118, 118
	                                               DB            214, 193, 191, 191, 191, 216, 216, 216, 216, 191, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142
	                                               DB            143, 191, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 143, 142, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 143, 216, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 191, 191, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 142, 118, 16, 16, 16, 16, 16, 16, 16, 16, 191, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 191, 190, 118, 142, 143, 189, 191, 191, 190, 143, 24, 25, 164, 143, 190, 191, 216, 10, 10, 10, 10, 10, 10, 142, 144, 16
	                                               DB            16, 16, 124, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 17, 24, 25, 24, 22, 17, 16, 124, 16, 124, 124, 16, 124, 16, 16, 16
	                                               DB            17, 143, 142, 10, 10, 10, 10, 10, 10, 143, 191, 191, 215, 118, 164, 24, 164, 143, 215, 193, 191, 190, 189, 118, 118, 118, 216, 191, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 191, 16, 16, 16, 16, 16, 16, 16, 17, 17, 16, 16, 16, 190, 143, 142, 142, 142, 142, 142, 142
	                                               DB            142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191
	                                               DB            191, 191, 191, 191, 191, 191, 191, 215, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 10, 144, 17, 16, 16, 16, 16
	                                               DB            16, 17, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 193, 190, 143, 25, 29, 29, 24, 215, 191, 118
	                                               DB            27, 31, 31, 31, 26, 118, 216, 191, 144, 141, 141, 10, 10, 10, 10, 10, 118, 16, 16, 16, 124, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16
	                                               DB            17, 24, 25, 21, 20, 24, 20, 16, 124, 16, 16, 16, 16, 16, 16, 16, 17, 144, 10, 10, 10, 10, 10, 10, 10, 142, 216, 191, 216, 143, 26, 31, 31, 31, 27, 143, 191, 193, 118, 25
	                                               DB            28, 27, 164, 118, 216, 191, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 17, 16, 16
	                                               DB            16, 16, 17, 209, 211, 17, 16, 16, 215, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216
	                                               DB            191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 215, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 10, 143, 17, 16, 16, 16, 17, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 215, 191, 118, 26, 31, 31, 31, 31, 24, 191, 164, 31, 31, 31, 31, 31, 164, 191, 216, 118, 142, 143, 143, 10, 10, 10, 10, 10, 216, 16, 16, 16, 124, 16
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 19, 16, 124, 16, 17, 23, 25, 22, 17, 16, 21, 23, 18, 16, 124, 16, 16, 124, 16, 16, 16, 144, 10, 10, 10, 10, 10, 141
	                                               DB            118, 143, 118, 190, 193, 190, 25, 31, 31, 31, 31, 31, 24, 191, 190, 26, 31, 31, 31, 31, 24, 189, 193, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 17, 16, 16, 208, 137, 137, 18, 16, 16, 215, 142, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 191, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 216, 215, 215, 216, 193, 191
	                                               DB            191, 193, 191, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 143, 17, 16, 16, 215, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 191, 191, 143, 30, 31, 31, 31, 31, 31, 143, 25, 31, 31, 31, 31, 31, 26
	                                               DB            190, 144, 27, 31, 29, 165, 142, 10, 10, 10, 10, 142, 17, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 23, 25, 22, 23, 21, 16, 20
	                                               DB            23, 17, 16, 124, 16, 124, 16, 16, 16, 215, 10, 10, 10, 10, 10, 141, 143, 24, 27, 25, 118, 191, 214, 28, 31, 31, 31, 31, 31, 27, 190, 164, 31, 31, 31, 31, 31, 29, 142, 191
	                                               DB            17, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 144, 16, 186, 137, 137, 18, 16, 16
	                                               DB            215, 142, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 191, 191, 191, 191, 191, 191, 191, 193
	                                               DB            216, 215, 216, 191, 191, 191, 191, 191, 191, 216, 118, 118, 118, 118, 118, 118, 214, 190, 191, 191, 191, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 142, 142, 142, 142, 142, 142, 142, 143, 17, 16, 17, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144
	                                               DB            191, 191, 143, 31, 31, 30, 29, 95, 95, 164, 24, 29, 29, 30, 31, 31, 27, 214, 26, 31, 31, 31, 30, 141, 10, 10, 10, 10, 10, 144, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 16, 124, 17, 16, 21, 26, 23, 17, 19, 24, 22, 23, 232, 186, 17, 16, 124, 124, 16, 16, 191, 142, 10, 10, 10, 10, 10, 143, 26, 31, 31, 31, 27, 190, 143
	                                               DB            30, 31, 31, 31, 31, 31, 29, 143, 29, 31, 31, 31, 31, 31, 31, 165, 191, 193, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 16, 136, 137, 208, 16, 16, 216, 142, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 215, 191, 191, 191, 191, 191, 191, 191, 216, 118, 118, 118, 118, 118, 216, 191, 191, 191, 190, 118, 118, 142, 23, 24, 165, 118, 118, 118, 191, 191, 191, 216, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 143, 17, 16, 190, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 191, 191, 213, 71, 24, 140, 117, 117, 117, 117, 117, 117, 117, 140, 164, 25, 24, 164, 31, 31, 31, 31, 31
	                                               DB            25, 142, 10, 10, 10, 10, 10, 216, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 17, 25, 24, 20, 16, 16, 19, 24, 19, 208, 137, 208, 16, 124, 16
	                                               DB            16, 16, 144, 10, 10, 10, 10, 10, 142, 23, 31, 31, 31, 31, 31, 24, 142, 30, 30, 29, 27, 71, 25, 140, 117, 164, 164, 25, 71, 28, 30, 30, 167, 191, 216, 191, 142, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 16, 185, 137, 210, 16, 16, 190, 142, 142, 142, 142, 142, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 191, 191, 191, 191, 191, 191, 191, 214, 118, 141, 25, 26, 23, 143, 118, 193
	                                               DB            191, 191, 214, 118, 25, 30, 31, 31, 30, 28, 141, 118, 215, 191, 191, 191, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142
	                                               DB            142, 142, 142, 10, 144, 16, 16, 215, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 193, 190, 118, 117, 117, 116, 46
	                                               DB            46, 46, 46, 46, 46, 46, 46, 46, 46, 116, 117, 117, 140, 27, 30, 31, 31, 26, 141, 10, 10, 10, 10, 10, 143, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 16
	                                               DB            124, 16, 16, 19, 25, 24, 20, 18, 22, 20, 209, 137, 137, 211, 16, 16, 16, 16, 216, 10, 10, 10, 10, 10, 10, 142, 27, 31, 31, 31, 31, 30, 26, 142, 140, 117, 117, 117, 117, 117
	                                               DB            117, 116, 117, 117, 117, 117, 117, 117, 140, 143, 191, 193, 191, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 144, 16, 210, 136, 17, 16, 17, 143, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143
	                                               DB            191, 191, 191, 191, 191, 191, 191, 215, 118, 25, 30, 31, 31, 31, 27, 143, 215, 191, 216, 118, 24, 31, 31, 31, 31, 31, 31, 30, 142, 118, 193, 191, 191, 216, 142, 143, 143, 142, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142, 216, 16, 16, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 143, 143, 143
	                                               DB            143, 143, 10, 10, 10, 10, 10, 10, 10, 143, 190, 118, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 46, 116, 116, 26, 31, 24, 10, 10, 10, 10, 10
	                                               DB            10, 10, 190, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 17, 16, 232, 24, 25, 24, 21, 208, 137, 137, 137, 137, 17, 16, 16, 16, 144, 10, 10, 10, 10
	                                               DB            10, 10, 142, 27, 31, 31, 29, 71, 140, 117, 116, 46, 46, 46, 46, 45, 45, 45, 45, 45, 45, 45, 46, 46, 46, 116, 117, 118, 189, 191, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 193, 16, 137, 18, 16, 16, 144, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 216, 190, 216, 193, 191, 191, 191, 216, 118, 24, 31, 31, 31, 31, 31, 31, 27, 118, 216, 190, 142, 29, 31, 31
	                                               DB            31, 31, 31, 31, 31, 26, 118, 216, 191, 216, 118, 118, 142, 118, 118, 143, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 142
	                                               DB            17, 16, 17, 10, 10, 10, 10, 10, 10, 10, 10, 143, 143, 143, 118, 118, 118, 143, 143, 143, 142, 10, 10, 10, 10, 10, 142, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 140, 141, 10, 10, 10, 10, 10, 10, 10, 144, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 124, 20, 16, 17
	                                               DB            23, 22, 18, 136, 137, 137, 137, 137, 209, 16, 16, 191, 10, 10, 10, 10, 10, 10, 10, 10, 24, 31, 25, 117, 116, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 46, 46, 117, 118, 216, 10, 10, 10, 10, 10, 10, 10, 10, 143, 143, 143, 143, 143, 143, 143, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 16, 17, 210, 16
	                                               DB            16, 216, 142, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 118, 118, 143, 118, 190, 216, 191, 191
	                                               DB            216, 143, 29, 31, 31, 31, 31, 31, 31, 31, 24, 190, 190, 25, 31, 31, 31, 31, 31, 31, 31, 31, 29, 142, 191, 190, 118, 24, 29, 30, 29, 24, 143, 143, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 144, 16, 16, 214, 10, 10, 10, 10, 10, 10, 143, 143, 118, 142, 24, 24, 24, 141, 143, 118, 143, 10, 10
	                                               DB            10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 141, 10, 10, 10, 10, 10, 10, 143, 16, 16, 17
	                                               DB            124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 137, 138, 136, 137, 137, 137, 210, 16, 16, 144, 10, 10, 10, 10, 10, 10, 10, 10, 142, 141, 116
	                                               DB            46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 118, 141, 10, 10, 10, 10, 10, 10, 143, 143, 143, 118, 118, 118, 118, 143
	                                               DB            143, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 16, 208, 17, 16, 17, 143, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 142, 118, 24, 27, 28, 25, 141, 189, 190, 193, 190, 165, 30, 31, 31, 31, 31, 31, 31, 31, 28, 143, 189, 27, 31, 31, 31, 31, 31, 31, 31, 31, 30
	                                               DB            141, 191, 214, 26, 31, 31, 31, 31, 31, 27, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 216, 16, 17, 142, 10
	                                               DB            10, 10, 10, 143, 118, 142, 26, 30, 31, 31, 31, 31, 28, 164, 118, 143, 10, 10, 10, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 46, 117, 141, 10, 142, 143, 143, 143, 143, 17, 16, 16, 124, 16, 118, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 124, 16, 16, 17, 138, 138, 136
	                                               DB            137, 137, 211, 16, 16, 142, 10, 10, 10, 10, 10, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            46, 117, 117, 10, 10, 10, 10, 10, 143, 143, 118, 143, 164, 24, 24, 164, 143, 118, 143, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 18, 16, 16, 118, 142, 142, 142, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 118, 27, 31, 31, 31, 31, 30, 25, 118, 193, 191, 23, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 164, 144, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 165, 191, 25, 31, 31, 31, 31, 31, 31, 31, 26, 118, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 143, 16, 16, 215, 10, 10, 10, 10, 118, 141, 29, 31, 31, 31, 31, 31, 31, 31, 30, 24, 118, 142, 10, 117, 117, 46, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 143, 144, 118, 118, 118, 143, 191, 16, 16, 124, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 17, 16, 18, 139, 137, 136, 137, 210, 16, 17, 10, 10, 10, 10, 10, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 10, 10, 143, 143, 143, 25, 29, 30, 31, 31, 31, 29, 25, 143, 143, 143, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 214, 16, 17, 16, 17, 143, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            143, 25, 31, 31, 31, 31, 31, 31, 31, 27, 213, 191, 23, 31, 31, 31, 31, 31, 31, 31, 31, 31, 27, 142, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 166, 166, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 30, 142, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 190, 16, 17, 142, 10, 10, 143, 142, 29, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 164, 143, 10, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 116, 118, 141, 25, 27, 27, 25, 142, 190, 16, 124, 17, 124, 143, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 124, 17, 16, 234, 139, 136, 137, 209, 16, 191, 142
	                                               DB            142, 10, 10, 10, 10, 10, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 141, 10
	                                               DB            142, 118, 142, 28, 31, 31, 31, 31, 31, 31, 31, 31, 28, 142, 118, 142, 10, 10, 10, 10, 10, 10, 10, 215, 16, 16, 16, 215, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 118, 29, 31, 31, 31, 31, 31, 31, 31, 31, 27, 190, 165, 31, 31, 30, 29, 95, 27, 26, 25, 25, 164
	                                               DB            117, 140, 164, 164, 164, 25, 25, 71, 26, 27, 28, 142, 26, 30, 31, 31, 31, 31, 31, 31, 31, 31, 164, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 142, 142, 142, 142, 142, 144, 16, 16, 144, 10, 10, 118, 26, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 143, 117, 117, 46, 45, 45, 45, 45, 45, 45, 46, 118, 118
	                                               DB            117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 30, 31, 31, 31, 31, 31, 25, 143, 192, 124, 118, 118, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 16, 16, 124, 16, 124, 16, 16, 138, 137, 137, 208, 16, 190, 143, 143, 143, 143, 142, 10, 142, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 143, 143, 28, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 142, 143, 10, 10, 10, 10, 10, 10, 10
	                                               DB            216, 16, 16, 17, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 29, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 25, 142, 71, 24, 140, 117, 118, 118, 118, 118, 118, 117, 117, 117, 117, 117, 117, 118, 118, 118, 118, 118, 118, 117, 141, 140, 164, 71, 27, 29, 31, 31, 31, 30, 164
	                                               DB            142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 142, 142, 191, 16, 17, 10, 10, 143, 30, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 164, 118, 117, 46, 45, 45, 45, 45, 45, 46, 190, 193, 191, 193, 117, 45, 45, 45, 45, 45, 45, 45, 116, 117, 117, 46, 45, 45, 45, 45, 45, 46, 117, 29, 31, 31
	                                               DB            31, 31, 31, 31, 26, 118, 124, 31, 118, 118, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 209, 137, 210, 18, 16, 118, 143, 143, 118, 118, 143, 142, 117
	                                               DB            46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 142, 118, 26, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 26, 118, 10, 10, 10, 10, 10, 10, 10, 216, 16, 16, 216, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 29, 31, 31, 31, 31, 31, 31, 31, 29, 71, 141, 117, 118, 118, 117, 117, 116, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46
	                                               DB            46, 46, 46, 46, 46, 46, 116, 117, 117, 118, 117, 117, 140, 25, 29, 29, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 143, 143, 143, 143, 143, 142
	                                               DB            142, 142, 144, 16, 16, 142, 10, 164, 31, 31, 31, 31, 22, 232, 27, 31, 31, 31, 31, 31, 31, 26, 118, 117, 45, 45, 45, 45, 45, 45, 117, 193, 190, 191, 191, 191, 46, 45, 45, 45
	                                               DB            45, 45, 116, 193, 193, 193, 190, 46, 45, 45, 45, 45, 45, 117, 27, 31, 31, 31, 31, 31, 31, 31, 24, 118, 124, 143, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16
	                                               DB            16, 124, 16, 16, 16, 16, 16, 189, 164, 25, 27, 27, 25, 164, 143, 118, 117, 45, 45, 45, 45, 45, 45, 45, 46, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 193, 191, 191
	                                               DB            117, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 142, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 141, 143, 10, 10, 10, 10, 10, 10, 216, 16, 16, 144, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 29, 31, 31, 31, 31, 30, 95, 140, 117, 118, 117
	                                               DB            117, 116, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 46, 116, 117, 117, 117, 141, 117, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 142, 143, 16, 16, 215, 142, 24, 31, 31, 31, 26, 16, 16, 18, 31, 31, 31, 31, 31, 31, 27, 118
	                                               DB            117, 45, 45, 45, 45, 45, 46, 189, 191, 191, 191, 191, 191, 117, 45, 45, 45, 45, 46, 190, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 117, 71, 31, 31, 31, 31, 31, 31, 31, 28
	                                               DB            143, 124, 142, 118, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 16, 16, 17, 142, 27, 31, 31, 31, 31, 31, 31, 27, 117, 116, 45, 45, 45, 45, 45, 45
	                                               DB            46, 118, 190, 189, 117, 45, 45, 45, 45, 45, 45, 45, 116, 193, 191, 191, 191, 193, 116, 45, 45, 45, 45, 45, 45, 46, 117, 118, 25, 31, 31, 31, 31, 31, 31, 31, 30, 27, 30, 31
	                                               DB            31, 31, 31, 25, 143, 10, 10, 10, 10, 10, 10, 17, 16, 17, 143, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 143, 143, 143, 143, 143, 143, 143, 143, 142, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 143, 27, 31, 31, 31, 28, 164, 118, 118, 117, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 46, 46, 117, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 190, 16, 17
	                                               DB            142, 24, 31, 31, 31, 26, 16, 16, 232, 31, 31, 31, 31, 31, 31, 27, 118, 117, 45, 45, 45, 45, 45, 46, 190, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 116, 191, 191, 191, 191
	                                               DB            191, 189, 45, 45, 45, 45, 45, 117, 24, 31, 31, 31, 31, 29, 24, 29, 31, 141, 191, 124, 118, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 16, 17, 142
	                                               DB            29, 31, 31, 31, 31, 31, 31, 31, 31, 140, 116, 45, 45, 45, 45, 45, 46, 190, 193, 191, 193, 193, 116, 45, 45, 45, 45, 45, 46, 118, 193, 191, 191, 191, 193, 118, 45, 45, 45, 45
	                                               DB            45, 45, 46, 117, 118, 27, 31, 31, 31, 31, 31, 31, 30, 21, 16, 19, 29, 31, 31, 31, 27, 143, 10, 10, 10, 10, 10, 10, 16, 16, 190, 10, 10, 10, 10, 10, 10, 10, 10, 143
	                                               DB            143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 164, 31, 31, 71, 117, 118, 117, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 117, 117, 10, 10, 10, 10, 10, 10, 10, 143, 143
	                                               DB            143, 143, 143, 143, 143, 118, 118, 118, 143, 143, 143, 143, 143, 143, 118, 16, 17, 143, 164, 30, 31, 31, 31, 24, 21, 28, 31, 31, 31, 31, 31, 31, 25, 118, 117, 45, 45, 45, 45, 45
	                                               DB            46, 190, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 116, 191, 191, 191, 191, 191, 189, 45, 45, 45, 45, 45, 117, 24, 31, 31, 31, 31, 21, 16, 245, 30, 23, 191, 124, 118, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 213, 28, 31, 31, 31, 31, 31, 31, 31, 31, 30, 141, 46, 45, 45, 45, 45, 45, 116, 193, 191, 191, 191, 191, 190
	                                               DB            46, 45, 45, 45, 45, 46, 190, 191, 191, 191, 191, 193, 189, 46, 45, 45, 45, 45, 45, 46, 117, 118, 27, 31, 31, 31, 31, 31, 31, 27, 16, 16, 16, 24, 31, 31, 31, 28, 142, 10
	                                               DB            10, 10, 10, 10, 142, 16, 16, 118, 10, 10, 10, 10, 10, 10, 10, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 143
	                                               DB            143, 28, 164, 118, 117, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 46, 117, 117, 141, 10, 10, 10, 10, 142, 143, 143, 143, 143, 118, 118, 142, 142, 141, 142, 142, 118, 118, 143, 143, 143, 144, 16, 16, 144, 142, 29, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 30, 164, 117, 117, 46, 45, 45, 45, 45, 45, 118, 193, 191, 191, 191, 191, 116, 45, 45, 45, 45, 46, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45
	                                               DB            45, 117, 25, 31, 31, 31, 31, 22, 16, 21, 30, 164, 191, 124, 118, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 17, 164, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 29, 141, 46, 45, 45, 45, 45, 45, 117, 193, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 46, 193, 191, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 45, 46, 117, 118, 27
	                                               DB            31, 31, 31, 31, 31, 31, 28, 16, 16, 16, 26, 31, 31, 31, 27, 142, 10, 10, 10, 10, 10, 144, 16, 16, 143, 10, 10, 10, 10, 10, 10, 143, 143, 143, 143, 143, 118, 118, 118, 143
	                                               DB            118, 118, 118, 118, 143, 143, 143, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 118, 117, 118, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 141, 10, 10, 142, 143, 143, 143, 118, 118, 164, 26, 28, 29
	                                               DB            30, 30, 29, 27, 24, 143, 118, 143, 143, 191, 16, 215, 142, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 143, 141, 117, 46, 45, 45, 45, 45, 45, 116, 193, 191, 191, 191
	                                               DB            190, 46, 45, 45, 45, 45, 45, 118, 193, 191, 191, 191, 46, 45, 45, 45, 45, 45, 117, 26, 31, 31, 31, 31, 30, 26, 29, 30, 142, 192, 124, 118, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 16, 124, 16, 16, 16, 214, 26, 31, 30, 30, 31, 31, 31, 31, 31, 31, 29, 141, 46, 45, 45, 45, 45, 45, 117, 193, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 46
	                                               DB            191, 191, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 45, 46, 117, 118, 26, 31, 31, 31, 31, 31, 31, 31, 26, 21, 25, 31, 31, 31, 31, 26, 143, 10, 10, 10, 10, 10, 216, 16
	                                               DB            17, 142, 10, 10, 10, 10, 10, 143, 143, 143, 143, 118, 142, 25, 28, 29, 29, 29, 28, 25, 141, 118, 118, 143, 143, 143, 10, 10, 10, 10, 10, 10, 10, 142, 117, 117, 116, 46, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 116, 117, 141, 10, 143, 143, 143, 118, 164, 28, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 164, 118, 143, 190, 16, 17, 141, 142, 28, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 30, 141, 141, 10, 117, 116, 45, 45, 45, 45, 45, 46, 118, 193, 191, 191, 116, 45, 45, 45, 45, 45, 45, 46, 118, 190, 190, 116, 45, 45, 45, 45, 45, 46, 117, 28, 31, 31, 31
	                                               DB            31, 31, 31, 31, 28, 118, 124, 143, 143, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 214, 29, 29, 232, 18, 28, 31, 31, 31, 31, 31, 30, 141, 46, 45
	                                               DB            45, 45, 45, 45, 116, 193, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 46, 190, 191, 191, 191, 191, 193, 189, 46, 45, 45, 45, 45, 45, 46, 117, 117, 164, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 23, 142, 10, 10, 10, 10, 10, 17, 16, 191, 10, 10, 10, 10, 10, 143, 143, 143, 118, 142, 26, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 141
	                                               DB            118, 143, 143, 143, 10, 10, 10, 10, 10, 142, 117, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 142, 143, 143, 118, 25, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 24, 118, 215, 16, 16, 142, 10, 142, 28, 31, 31, 31, 31, 31, 31, 31, 29, 164, 142, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 46, 116, 117, 46, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 46, 45, 45, 45, 45, 45, 45, 45, 46, 117, 30, 31, 31, 31, 31, 31, 31, 31, 164, 190, 124, 143, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16
	                                               DB            16, 17, 213, 31, 24, 16, 16, 23, 31, 31, 31, 31, 31, 30, 140, 116, 45, 45, 45, 45, 45, 46, 190, 193, 191, 191, 193, 118, 45, 45, 45, 45, 45, 45, 117, 193, 190, 191, 191, 193
	                                               DB            117, 45, 45, 45, 45, 45, 45, 116, 117, 141, 143, 28, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 143, 10, 10, 10, 10, 10, 10, 17, 16, 216, 10, 10, 10, 10, 10
	                                               DB            143, 143, 118, 141, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 25, 118, 143, 143, 10, 10, 10, 10, 10, 117, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117
	                                               DB            117, 143, 118, 26, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 24, 118, 17, 16, 143, 10, 141, 142, 24, 28, 30, 31, 31, 29, 26, 142, 142, 10, 10, 10, 10
	                                               DB            117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 25, 31, 31, 31, 31, 31, 31, 31, 24, 118, 124
	                                               DB            25, 118, 143, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 17, 143, 29, 29, 18, 17, 28, 31, 31, 31, 31, 31, 31, 164, 117, 45, 45, 45, 45, 45, 45, 116
	                                               DB            190, 191, 191, 189, 46, 45, 45, 45, 45, 45, 45, 46, 190, 193, 191, 193, 190, 46, 45, 45, 45, 45, 45, 46, 117, 117, 10, 142, 164, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 164, 142, 10, 10, 10, 10, 10, 142, 17, 16, 144, 10, 10, 10, 10, 143, 143, 118, 142, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 26, 118, 143, 143, 10
	                                               DB            10, 10, 141, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 118, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 164, 189, 16
	                                               DB            144, 10, 10, 10, 142, 142, 141, 164, 165, 142, 143, 10, 10, 10, 10, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 46, 117, 164, 29, 31, 31, 31, 31, 29, 164, 118, 192, 31, 118, 118, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 18, 143, 27, 31, 30
	                                               DB            30, 31, 31, 31, 31, 31, 31, 31, 25, 117, 46, 45, 45, 45, 45, 45, 45, 46, 116, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 46, 118, 215, 118, 46, 45, 45, 45, 45, 45, 45
	                                               DB            46, 118, 141, 10, 10, 143, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 24, 143, 10, 10, 10, 10, 10, 143, 17, 16, 16, 143, 10, 10, 10, 10, 143, 143, 143, 28, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 25, 118, 143, 10, 10, 10, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 29, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 143, 17, 215, 10, 10, 10, 10, 10, 10, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 142, 141, 142, 164, 25, 25, 164, 213, 191, 124, 214, 190, 124, 144, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 232, 167, 164, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 46, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 10, 10, 10, 143, 164, 29, 31, 31, 31, 31, 31, 31, 29, 23, 142, 10, 10, 142, 144, 215
	                                               DB            17, 16, 16, 16, 16, 143, 10, 10, 10, 10, 143, 118, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 164, 118, 141, 10, 142, 117, 46, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 95, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 24, 189, 216, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 10
	                                               DB            10, 10, 141, 142, 142, 216, 16, 16, 124, 18, 124, 143, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 19, 22, 143, 28, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 141, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 118, 141, 10, 10, 10, 10
	                                               DB            10, 142, 142, 24, 27, 28, 28, 27, 24, 142, 118, 144, 216, 17, 16, 16, 16, 16, 17, 17, 16, 16, 142, 10, 10, 10, 10, 143, 143, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 28, 118, 142, 10, 117, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 25, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 118, 215, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 117, 10, 10, 10, 10, 10, 10, 10, 17, 16, 141, 124, 16, 118, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 16, 124, 16, 16, 16, 19, 22, 21, 141, 29, 31, 31, 31, 31, 31, 31, 31, 31, 29, 142, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 10, 10, 10, 10, 10, 10, 142, 118, 213, 213, 118, 214, 190, 16, 16, 16, 16, 16, 17, 18, 19, 20, 22, 19, 16, 16, 142
	                                               DB            10, 10, 10, 142, 118, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 164, 118, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 116, 140, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 23, 21, 26, 31, 31, 31, 30, 142, 190, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 10, 10, 10, 10, 10, 10, 143, 16
	                                               DB            16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 19, 22, 22, 142, 142, 27, 31, 31, 31, 31, 31, 31, 27, 143, 17, 189, 117
	                                               DB            46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 118, 189, 216, 216, 216, 17, 17, 17, 16, 16, 16, 16, 16
	                                               DB            16, 16, 17, 17, 18, 232, 19, 20, 21, 22, 22, 22, 22, 19, 16, 17, 142, 10, 10, 10, 142, 118, 26, 31, 31, 31, 29, 28, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 26, 118, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            46, 118, 191, 193, 190, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 19, 16, 16, 16
	                                               DB            25, 31, 31, 30, 164, 190, 10, 10, 10, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 117, 46, 46, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 46, 46, 116, 117, 142, 10, 10, 10, 10, 10, 10, 10, 10, 17, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16
	                                               DB            229, 22, 21, 22, 21, 143, 164, 26, 28, 27, 26, 164, 143, 237, 226, 237, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 46, 117, 117, 189, 17, 17, 17, 17, 17, 17, 18, 18, 240, 19, 19, 20, 20, 21, 21, 21, 22, 22, 22, 22, 22, 21, 21, 21, 22, 240, 16, 17, 142, 10, 10, 10, 142, 143, 28
	                                               DB            31, 31, 25, 18, 17, 19, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 142, 118, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 189, 193, 191, 191, 191, 193, 118, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            46, 117, 95, 31, 31, 31, 31, 31, 31, 31, 31, 31, 26, 16, 16, 16, 16, 18, 31, 31, 31, 24, 190, 10, 10, 142, 190, 118, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 117, 117, 117, 116, 46, 46, 46, 46, 46, 46, 46, 116, 116, 117, 117, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 16, 17, 46, 124, 191, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 20, 22, 21, 22, 22, 22, 21, 143, 142, 142, 143, 21, 21, 22, 22, 22, 167, 117, 117, 46, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 142, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 21, 21, 21
	                                               DB            21, 21, 22, 22, 22, 21, 22, 19, 16, 17, 142, 10, 10, 10, 142, 142, 28, 31, 28, 17, 16, 16, 16, 21, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 142, 117
	                                               DB            46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 118, 193, 190, 191, 191, 191, 191
	                                               DB            193, 118, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 25, 16, 17, 16, 16, 18, 31, 31, 31, 24, 190
	                                               DB            141, 10, 10, 143, 190, 190, 190, 190, 119, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 117, 117, 117, 117, 117, 117, 117, 117, 117, 142, 141, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 142, 142, 10, 190, 191, 119, 119, 124, 119, 192, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 20, 22, 21, 22, 22, 22
	                                               DB            22, 22, 22, 22, 22, 22, 22, 22, 21, 21, 22, 167, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 165, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 22, 22, 22, 21, 21, 21, 21, 21, 22, 19, 16, 16, 142, 10, 10, 10, 142, 142, 29, 31, 26, 16, 17, 16, 16
	                                               DB            17, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 191, 193, 193, 191
	                                               DB            117, 46, 45, 45, 45, 45, 45, 45, 45, 46, 191, 191, 191, 191, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 71, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 29, 18, 16, 16, 16, 23, 31, 31, 31, 24, 190, 142, 10, 10, 10, 141, 144, 118, 118, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 118, 190, 190, 119, 119, 190, 191, 124, 190, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 229, 22, 21, 22, 22, 22, 22, 22, 22, 21, 21, 22, 22, 21, 21, 22, 22, 22, 21, 142, 117, 117, 46, 46, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 117, 117, 164, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 23, 166, 23, 23, 23, 23, 23, 22, 22, 21
	                                               DB            22, 20, 16, 16, 143, 10, 10, 10, 141, 142, 28, 31, 27, 16, 16, 16, 16, 20, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 141, 117, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 118, 193, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45, 45, 117, 193, 191, 191, 191, 191, 191, 191, 191, 191, 193, 116, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 25, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 20, 18, 23, 31, 31, 31, 30, 164, 190, 143, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            144, 190, 190, 190, 144, 124, 190, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 17, 16, 16, 19, 22, 21, 22, 22, 22, 22, 22, 21, 22, 22, 21
	                                               DB            22, 22, 22, 21, 21, 21, 21, 22, 166, 142, 117, 117, 116, 46, 46, 46, 46, 46, 45, 45, 46, 46, 46, 46, 117, 117, 117, 165, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 166, 144, 119, 168, 23, 23, 23, 23, 23, 23, 22, 22, 20, 17, 16, 143, 10, 10, 10, 10, 118, 28, 31, 31, 23, 16, 16, 18, 28, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 28, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 118, 193, 191, 191, 191, 191, 191, 191, 193, 116, 45, 45, 45
	                                               DB            45, 45, 45, 189, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 30, 31, 31, 31, 31, 30, 142, 190, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 16, 16, 124, 191, 190, 124, 190, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            16, 16, 124, 16, 16, 19, 22, 21, 22, 22, 21, 22, 21, 214, 143, 21, 21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 141, 142, 117, 117, 117, 117, 117, 116, 117, 117, 117, 117
	                                               DB            117, 142, 165, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 168, 144, 144, 214, 190, 119, 144, 23, 23, 23, 23, 23, 23, 23, 23, 23, 22, 17, 16, 214, 10
	                                               DB            10, 10, 10, 118, 26, 31, 31, 31, 27, 24, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 27, 118, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 117, 193, 191, 191, 191, 191, 191, 191, 191, 193, 118, 45, 45, 45, 45, 45, 46, 190, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 118, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 117, 24, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 27, 118, 17, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 215, 16, 16, 124, 191, 190, 124
	                                               DB            119, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 19, 22, 21, 21, 22, 22, 22, 21, 215, 119, 215, 214, 214, 215, 143, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 164, 165, 165, 141, 141, 141, 141, 165, 164, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 168, 190, 190, 190
	                                               DB            215, 168, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 18, 16, 216, 10, 10, 10, 10, 143, 164, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 25, 118, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 46, 190, 191, 191
	                                               DB            191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 25, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 164, 189, 16, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 16, 124, 16, 17, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 232
	                                               DB            22, 21, 22, 22, 21, 21, 22, 22, 143, 215, 190, 119, 215, 166, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 167, 166, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 20, 16, 16, 10, 10, 10, 10, 141, 118, 28
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 141, 118, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 118, 193, 191, 191
	                                               DB            191, 191, 191, 191, 191, 191, 191, 191, 46, 45, 45, 45, 45, 46, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 118, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46
	                                               DB            117, 71, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 26, 118, 190, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 18, 22, 21, 21, 21, 22, 22, 23, 23, 23, 23, 167, 167, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 22, 16, 16, 143, 10, 10, 10, 10, 143, 164, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 26, 118, 117, 46, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 116, 45, 45, 45, 45, 46, 191, 191, 191, 191, 191, 191, 191, 191, 191
	                                               DB            191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 142, 118, 16, 17, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 144, 16, 16, 214, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 18, 21, 22, 22, 23, 23, 23
	                                               DB            23, 23, 23, 23, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 215, 10, 10, 10, 10, 141, 118, 25, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 142, 142, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191
	                                               DB            191, 191, 116, 45, 45, 45, 45, 46, 190, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 27, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 141, 118, 190, 16, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 17, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 24, 20, 16, 17, 10, 10, 10, 10, 10, 142, 118, 26, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 164, 143, 10, 117, 116, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 118, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 116, 45, 45, 45, 45, 45, 190, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 117
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 118, 143, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 142, 118, 143, 17, 16, 214, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 17, 16, 17, 124, 16, 16, 124
	                                               DB            16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 17, 16, 16, 22, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 22, 16, 16, 144, 10, 10, 10, 10, 10, 143, 118, 25, 31, 31, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 30, 164, 118, 10, 10, 117, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 189, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 46, 45, 45, 45
	                                               DB            45, 45, 118, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 142, 118, 24, 29, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 29, 25, 143, 118, 142, 144, 16, 16, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 215, 16, 16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            16, 124, 21, 16, 16, 21, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 216
	                                               DB            10, 10, 10, 10, 10, 10, 142, 118, 164, 28, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 141, 118, 10, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46
	                                               DB            189, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 190, 46, 45, 45, 45, 45, 45, 116, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 46, 117, 141, 10, 142, 118, 142, 164, 26, 28, 29, 29, 28, 26, 23, 142, 118, 143, 143, 10, 216, 16, 17, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 17, 16, 16, 124, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 20, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 21, 16, 16, 142, 10, 10, 10, 10, 10, 10, 142, 118, 118, 164, 26, 29, 30, 30, 30, 29, 27, 164, 143, 143, 10, 10
	                                               DB            10, 10, 10, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 118, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45, 46, 190, 191, 191
	                                               DB            191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 141, 10, 10, 10, 142, 118, 118, 143, 143, 143, 143, 118, 118, 143, 142, 142, 142, 143
	                                               DB            191, 16, 191, 143, 118, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 214, 17
	                                               DB            16, 16, 143, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 18
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 17, 16, 214, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 142, 143, 118, 118, 143, 142, 143, 118, 118, 143, 141, 10, 10, 10, 10, 10, 10, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 193, 191, 191, 191, 191
	                                               DB            191, 191, 191, 191, 191, 191, 46, 45, 45, 45, 45, 45, 45, 45, 117, 193, 191, 191, 191, 191, 191, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 117, 10
	                                               DB            10, 10, 10, 10, 10, 141, 142, 142, 142, 142, 142, 10, 10, 142, 142, 142, 144, 16, 16, 190, 118, 118, 118, 118, 10, 10, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 144, 216, 16, 16, 16, 16, 124, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 24, 20, 16, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 141, 142, 142, 142, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 117, 46
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 193, 191, 191, 191, 191, 191, 191, 191, 193, 117, 45, 45, 45, 45, 45, 45, 45, 45, 46, 118, 193, 191, 191, 191, 191, 191, 193
	                                               DB            193, 191, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 142, 216, 16, 17, 118, 118, 118, 118
	                                               DB            118, 10, 10, 17, 17, 144, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 214, 216, 17, 16, 16, 16, 124, 16, 17, 16, 16, 16, 124, 16
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 21, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 17, 16, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 190, 190, 191, 191, 193, 191, 191, 118, 46
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 190, 191, 191, 190, 190, 190, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 142, 142, 142, 143, 16, 16, 215, 143, 118, 118, 118, 143, 10, 142, 16, 16, 16, 16, 17, 215, 144, 143, 142, 141, 141, 141, 142, 141, 10, 10, 10, 10, 10, 10
	                                               DB            143, 17, 16, 16, 16, 16, 10, 124, 10, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 232, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 24, 20, 16, 17, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 116, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 116, 46, 46, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 46, 117, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 215, 16, 16, 141, 10, 143, 143, 143, 10, 10, 214, 16, 124, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 142, 10, 10, 10, 142, 10, 10, 143, 16, 16, 124, 16, 17, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 17, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 214, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 117, 117, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142
	                                               DB            142, 142, 143, 17, 16, 214, 10, 10, 10, 10, 10, 10, 142, 16, 16, 144, 17, 143, 124, 144, 17, 124, 17, 17, 16, 17, 16, 216, 10, 10, 142, 118, 118, 118, 10, 10, 143, 16, 16, 124
	                                               DB            16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            16, 16, 16, 124, 16, 16, 20, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 25, 25, 25, 24, 24, 24, 24
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 21
	                                               DB            16, 16, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 116, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116
	                                               DB            117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 10, 215, 16, 16, 143, 10, 10, 10, 10, 10, 143, 17, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16
	                                               DB            124, 16, 124, 16, 144, 10, 10, 144, 118, 118, 118, 143, 10, 10, 190, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 18, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 24, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 25, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 141, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 143, 17, 16, 16, 16
	                                               DB            216, 143, 142, 142, 215, 16, 16, 124, 16, 124, 16, 124, 16, 124, 16, 16, 16, 16, 16, 124, 16, 144, 10, 10, 144, 118, 118, 118, 144, 10, 10, 144, 16, 190, 124, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16
	                                               DB            16, 22, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 25, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 25, 25, 24, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 22, 16, 16, 143, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 142, 142, 216, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 216, 16, 16, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 215, 10
	                                               DB            10, 143, 118, 118, 118, 143, 10, 10, 142, 16, 17, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 19, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 26, 26, 25
	                                               DB            25, 26, 25, 26, 26, 26, 26, 26, 26, 26, 25, 25, 25, 26, 26, 25, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 19, 16, 17, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 142, 143, 142, 10, 10, 10, 10, 142, 142, 144, 191, 190, 190, 44, 16, 68, 215, 16, 17, 10, 124
	                                               DB            16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 17, 10, 10, 10, 143, 118, 143, 10, 10, 10, 143, 16, 216, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 16, 22, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 26, 25, 25, 26, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 25, 26, 25, 25, 26, 26, 24, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 215, 10, 10, 10, 142, 144, 142, 10
	                                               DB            10, 10, 10, 10, 10, 10, 142, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 118, 190, 190, 190
	                                               DB            118, 118, 118, 118, 118, 190, 119, 119, 119, 190, 124, 191, 124, 16, 124, 16, 16, 124, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 17, 124, 16, 214, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 216, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 232, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 25, 26, 25, 26, 25, 26, 26, 25, 25, 25, 25
	                                               DB            25, 25, 26, 26, 26, 25, 26, 26, 26, 25, 25, 26, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 20, 16, 16, 143, 10, 10, 118, 190, 190, 118, 144, 143, 143, 143, 144, 118, 119, 119, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 46
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46
	                                               DB            117, 117, 117, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 190, 119, 119, 119, 190, 190, 190, 190, 119, 119, 190, 119, 190, 124, 191, 16, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 144, 10, 10, 10, 10, 10, 10, 215, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 21, 24, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 24, 26, 25, 26, 25, 26, 25, 25, 26, 26, 27, 27, 26, 26, 25, 25, 25, 26, 25, 26, 26, 26, 25, 26, 25, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 20, 16, 16, 17, 141, 10, 143, 190, 190, 119, 190, 190, 190, 190, 190, 119
	                                               DB            190, 118, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 117, 117, 117, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 119, 190, 190, 119, 190, 119, 119, 190
	                                               DB            190, 190, 119, 124, 190, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 17, 16, 124, 16, 16, 190, 144, 143, 143, 215, 17, 16, 16, 124, 16, 124
	                                               DB            16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 16, 124, 16, 124, 16, 16, 18, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 25, 26, 25, 25, 26, 25, 26, 27, 29, 31, 31, 31, 31, 30, 29, 27, 26, 25
	                                               DB            26, 25, 26, 25, 26, 25, 26, 25, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            21, 17, 16, 16, 16, 216, 10, 10, 142, 118, 190, 190, 119, 119, 119, 119, 190, 119, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 117, 117, 46, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 116, 117, 117, 117, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 119, 119, 119, 190, 190, 191, 191, 124, 191, 190, 124, 190, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 16, 19, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 25
	                                               DB            26, 25, 26, 25, 26, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 26, 25, 26, 25, 26, 26, 25, 26, 25, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 16, 16, 16, 16, 215, 10, 10, 10, 143, 118, 190, 190, 190, 190, 118, 142, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 117, 117, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 46, 117, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 143, 190, 16, 16, 16, 124, 191, 119, 124, 119, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 17, 124, 17, 17, 124, 17, 124, 17, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16
	                                               DB            124, 16, 16, 16, 21, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 25, 26, 25, 26, 25, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 26, 25, 26, 25, 26, 25
	                                               DB            25, 26, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 16, 16, 124, 16, 16
	                                               DB            16, 144, 10, 10, 10, 10, 10, 142, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 117, 116, 46, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 117, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 142, 142, 215, 16, 16, 16, 124, 16, 124, 191, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 124, 16, 16, 17, 22, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 25, 26, 26, 25, 26, 30, 31
	                                               DB            31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 25, 26, 26, 26, 26, 25, 26, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 16, 16, 124, 16, 124, 16, 16, 16, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 117, 117, 117, 116, 46, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 116, 117, 117
	                                               DB            117, 117, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 118, 16, 16, 16, 124, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 17
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 26, 26, 25, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 27, 25, 26, 26, 25, 25, 26, 24, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 18, 16, 16, 16, 124, 16, 16, 16, 124, 16, 16, 17, 142, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 117, 117, 117, 116, 46, 46, 45, 45, 45, 45, 45, 45
	                                               DB            45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 46, 46, 116, 117, 117, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16
	                                               DB            16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 124, 16, 16, 16, 18, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 25, 26, 25, 26, 30, 31, 31, 31, 31, 31, 31, 31
	                                               DB            31, 31, 31, 31, 31, 31, 28, 25, 26, 26, 26, 25, 26, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24
	                                               DB            23, 18, 16, 16, 16, 124, 16, 124, 16, 16, 16, 124, 16, 16, 17, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 141, 117, 117, 117, 117, 117, 116, 46, 46, 46, 45, 45, 45, 45, 45, 45, 45, 46, 46, 46, 116, 117, 117, 118, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 17, 16, 16, 16, 124, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 124, 16, 16, 16, 18, 23, 24, 23, 23
	                                               DB            23, 23, 23, 23, 23, 24, 25, 26, 25, 28, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 25, 26, 26, 25, 25, 26, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 21, 17, 16, 16, 16, 124, 16, 16, 124, 16, 124, 16, 16, 124, 16, 16, 17, 142, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 117, 117, 117, 117, 117, 117, 117, 117, 116, 116, 116, 117, 117
	                                               DB            117, 117, 117, 117, 117, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 17, 16, 16, 16, 124, 16, 124, 16, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 16, 124, 16, 124, 16, 16, 16, 17, 22, 24, 23, 23, 23, 23, 23, 23, 23, 24, 25, 26, 26, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30
	                                               DB            26, 25, 26, 25, 25, 26, 25, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 23, 19, 16, 16, 16, 16, 124, 16, 16
	                                               DB            124, 16, 124, 16, 124, 16, 16, 124, 16, 16, 17, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 141, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 144, 17, 16, 16, 216, 124, 17, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 17, 20, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 25, 25, 26, 28, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 27, 25, 26, 25, 25, 26, 25, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 24, 23, 21, 17, 16, 16, 16, 16, 124, 16, 124, 124, 16, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 17, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 141, 141, 141, 141, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 215, 16, 16, 16, 16, 16, 17, 124, 16, 16, 16, 124, 124, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 16, 16, 124, 16, 124, 16, 16, 16, 16, 232, 23, 24, 23, 23, 23, 23, 23, 23, 23, 24, 25, 25, 26, 27, 29, 30, 30, 30, 30, 30, 29, 26, 25, 26, 25, 26, 26, 25, 24
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 23, 21, 18, 16, 16, 16, 16, 16, 17, 16, 124, 16, 16, 124, 124, 124, 124, 124, 16
	                                               DB            124, 16, 16, 124, 16, 16, 16, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142
	                                               DB            143, 143, 215, 191, 16, 16, 16, 16, 16, 124, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 16, 17, 20, 23, 24, 23, 23, 23, 23, 23, 23, 23, 24
	                                               DB            24, 25, 25, 26, 26, 26, 26, 26, 25, 25, 26, 26, 26, 25, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 23, 21, 18, 16
	                                               DB            16, 16, 16, 16, 124, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 144, 17, 16, 16, 16, 124, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124
	                                               DB            16, 16, 124, 16, 16, 16, 16, 18, 21, 23, 24, 24, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 25, 25, 25, 25, 24, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 23, 23, 20, 18, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124
	                                               DB            16, 16, 16, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 144, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 18, 20, 22, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23
	                                               DB            23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 23, 22, 21, 232, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 16
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 17, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 143, 144, 118, 118, 118, 144, 142, 10, 10, 10, 10, 10, 142, 17, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 124
	                                               DB            16, 16, 16, 16, 16, 17, 19, 21, 22, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 23, 21
	                                               DB            20, 18, 17, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 17, 16, 16, 16
	                                               DB            214, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 118, 118, 118, 118, 118, 118, 118, 118, 143, 10, 10, 10, 10, 10, 143, 16, 16
	                                               DB            16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 17, 18, 229, 21, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24
	                                               DB            24, 24, 24, 24, 24, 23, 23, 23, 23, 23, 23, 22, 21, 19, 18, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 16, 16, 16, 17, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 214, 10, 10
	                                               DB            118, 118, 118, 118, 118, 118, 118, 118, 118, 142, 10, 10, 10, 10, 10, 144, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 124, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 17, 18, 19, 20, 21, 21, 22, 22, 22, 22, 22, 22, 22, 21, 21, 20, 19, 232, 18, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            124, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 17, 16, 16, 16, 216, 142, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 16, 142, 10, 144, 118, 118, 118, 118, 118, 118, 118, 118, 143, 10, 10, 10, 10, 10, 142, 17, 16, 124, 16, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 16, 124, 16, 186, 16, 44, 6, 114, 16, 16, 214, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 191, 16, 16, 16, 214, 10, 143, 118, 118, 118, 118, 118
	                                               DB            118, 118, 118, 143, 10, 10, 10, 10, 10, 10, 216, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 124, 16, 16, 16
	                                               DB            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 6, 124, 41, 124, 41, 42, 43, 43, 188, 16, 17, 144, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 142, 216, 16, 16, 16, 17, 16, 16, 10, 10, 118, 118, 118, 118, 118, 118, 118, 118, 143, 10, 10, 10, 10, 10, 10, 216, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 124, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 16
	                                               DB            16, 124, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 55, 6, 124, 42, 41, 42, 43, 44, 43, 6, 186, 16, 16, 214, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 216, 16, 16, 16, 17, 124, 124, 17, 16, 214, 10, 143, 118, 118, 118, 118, 118, 118, 118, 142, 10, 10
	                                               DB            10, 10, 10, 10, 216, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 54, 124, 54, 54, 41, 124, 41, 42, 43, 43, 43, 43, 44, 43, 6, 188, 16, 16, 216, 143, 141, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 216, 16, 16, 16, 16, 69, 16
	                                               DB            16, 16, 124, 16, 17, 10, 10, 143, 118, 118, 118, 118, 118, 143, 10, 10, 10, 10, 10, 10, 141, 17, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 43, 41, 42
	                                               DB            43, 43, 43, 43, 43, 43, 44, 44, 43, 116, 18, 16, 17, 216, 144, 141, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 143, 215, 17, 16, 16, 16, 16, 16, 124, 16, 16, 16, 16, 124, 10, 16, 216, 10, 10, 10, 143, 143, 142, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 216
	                                               DB            124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 125, 54, 124, 124, 54, 54, 149, 6, 43, 43, 43, 43, 43, 43, 43, 43, 44, 44, 44, 44, 45, 115, 186, 17, 16, 17, 215, 143, 141, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 17, 16, 16, 16, 16, 190, 10, 124, 16, 16, 124, 124, 16, 124, 16, 124, 16, 16
	                                               DB            143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 17, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 54, 124, 54, 54, 54, 54, 149, 6, 43, 43, 43, 43, 43, 43
	                                               DB            44, 44, 44, 44, 44, 44, 44, 44, 43, 116, 188, 17, 16, 16, 17, 193, 215, 144, 143, 143, 142, 142, 142, 10, 10, 10, 10, 10, 10, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143
	                                               DB            16, 16, 17, 124, 16, 16, 16, 16, 124, 16, 124, 124, 16, 16, 16, 124, 16, 16, 142, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 144, 16, 17, 124, 16, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 125, 79, 124, 54, 102, 79, 54, 54, 116, 43, 43, 43, 43, 43, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 43, 43, 6, 186, 16, 16, 16, 16, 16, 16, 16, 17
	                                               DB            17, 17, 17, 17, 17, 17, 191, 141, 10, 10, 10, 143, 143, 10, 10, 10, 10, 143, 16, 16, 124, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 16, 124, 216, 16, 17, 142, 10, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 143, 16, 16, 124, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 125, 79, 124, 54, 101, 78, 54, 148, 43, 43, 43, 43, 43, 43, 43, 43, 43, 44, 44, 44, 44
	                                               DB            44, 44, 44, 44, 44, 44, 44, 42, 41, 124, 213, 216, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 144, 10, 10, 10, 118, 118, 118, 118, 142, 10, 10, 10, 215, 16, 17, 124, 16
	                                               DB            124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 216, 16, 17, 143, 10, 10, 10, 10, 10, 10, 10, 142, 17, 16, 124, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 125, 124, 125
	                                               DB            54, 54, 148, 140, 43, 43, 43, 43, 43, 43, 116, 116, 116, 6, 44, 44, 44, 44, 44, 44, 44, 44, 44, 43, 41, 41, 124, 41, 124, 124, 124, 124, 124, 124, 124, 16, 124, 17, 16, 17
	                                               DB            10, 10, 10, 143, 118, 118, 118, 118, 118, 142, 10, 10, 10, 17, 16, 124, 16, 16, 16, 124, 124, 124, 124, 124, 124, 16, 124, 16, 124, 17, 16, 16, 215, 142, 10, 10, 10, 10, 144, 16
	                                               DB            16, 124, 16, 16, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 43, 124, 41, 124, 41, 6, 140, 43, 44, 43, 43, 43, 43, 43, 164, 148, 148, 148, 116, 43, 44, 44, 44, 44, 44, 44, 44, 44
	                                               DB            42, 41, 42, 124, 6, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 16, 144, 10, 10, 10, 118, 118, 118, 118, 118, 118, 118, 10, 10, 10, 143, 16, 16, 124, 16, 124, 16, 124, 124, 124
	                                               DB            124, 124, 124, 16, 124, 16, 124, 17, 16, 16, 16, 190, 216, 216, 17, 16, 16, 124, 16, 17, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 124, 42, 124, 42, 41, 42, 44, 43, 43, 43, 43
	                                               DB            43, 43, 45, 54, 54, 54, 54, 148, 6, 44, 44, 44, 44, 44, 44, 44, 44, 42, 41, 124, 42, 41, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 10, 10, 10, 143, 118, 118, 118
	                                               DB            118, 118, 118, 118, 143, 10, 10, 10, 17, 16, 17, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 124, 17, 16, 16, 16, 16, 16, 216, 124, 16, 16, 124, 16, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 41, 124, 41, 124, 42, 41, 42, 43, 43, 43, 43, 43, 43, 43, 44, 172, 54, 54, 54, 54, 54, 6, 44, 44, 44, 44, 44, 44, 43, 43, 42, 41, 124, 41, 124, 124
	                                               DB            124, 124, 124, 124, 124, 16, 124, 16, 16, 216, 10, 10, 10, 118, 118, 118, 118, 118, 118, 118, 118, 118, 10, 10, 10, 144, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 16
	                                               DB            124, 16, 16, 124, 124, 16, 124, 16, 124, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 124, 44, 41, 42, 43, 43, 43, 43, 43, 43, 43, 43, 44, 172, 103, 31, 54
	                                               DB            54, 54, 43, 44, 44, 44, 44, 44, 43, 142, 21, 6, 42, 124, 41, 41, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 144, 10, 10, 10, 118, 118, 118, 118, 118, 118, 118, 118, 118, 142
	                                               DB            10, 10, 10, 16, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41
	                                               DB            124, 41, 41, 43, 43, 43, 43, 43, 43, 43, 43, 43, 44, 24, 78, 101, 54, 54, 24, 44, 44, 44, 44, 44, 44, 172, 54, 54, 54, 125, 124, 125, 124, 124, 124, 124, 124, 124, 16, 16
	                                               DB            124, 16, 16, 143, 10, 10, 142, 118, 118, 118, 118, 118, 118, 118, 118, 118, 143, 10, 10, 10, 216, 16, 216, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41, 124, 41, 41, 42, 43, 43, 43, 43, 43, 43, 43, 43, 44, 44, 44, 172, 54, 54, 172, 43, 44, 44, 44, 44
	                                               DB            44, 45, 54, 79, 54, 54, 54, 124, 54, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 142, 10, 10, 10, 118, 118, 118, 118, 118, 118, 118, 118, 118, 143, 10, 10, 10, 144, 16, 17
	                                               DB            124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 6, 41, 124, 42, 41, 42, 43, 43, 43, 43
	                                               DB            43, 43, 43, 43, 44, 44, 44, 44, 44, 45, 45, 44, 44, 44, 44, 44, 44, 44, 45, 79, 30, 79, 54, 54, 124, 54, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 142, 10, 10
	                                               DB            10, 144, 118, 118, 118, 118, 118, 118, 118, 118, 10, 10, 10, 10, 143, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 41, 124, 41, 41, 124, 42, 41, 42, 43, 43, 43, 43, 43, 43, 43, 43, 43, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 25, 79, 54, 54
	                                               DB            125, 124, 55, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 142, 10, 10, 10, 10, 144, 118, 118, 118, 118, 118, 144, 10, 10, 10, 10, 10, 143, 16, 16, 124, 16, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41, 124, 42, 41, 42, 43, 43, 43, 43, 43, 43, 43, 44, 43, 43, 44, 44
	                                               DB            44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 43, 174, 149, 55, 124, 54, 125, 124, 124, 124, 124, 124, 124, 16, 16, 124, 16, 16, 142, 10, 10, 10, 10, 10, 142, 143, 143
	                                               DB            143, 142, 10, 10, 10, 10, 10, 10, 143, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41
	                                               DB            124, 42, 41, 42, 43, 43, 43, 43, 43, 43, 43, 43, 42, 42, 43, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 43, 42, 41, 124, 41, 124, 55, 124, 124, 124
	                                               DB            124, 124, 124, 124, 16, 124, 17, 16, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 143, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 124, 42, 41, 124, 42, 41, 42, 43, 43, 43, 43, 43, 43, 42, 42, 42, 41, 42, 43, 44, 44, 44, 44, 44, 44, 44, 44
	                                               DB            44, 44, 44, 44, 44, 44, 44, 43, 41, 6, 124, 41, 54, 125, 124, 124, 124, 124, 124, 124, 124, 16, 124, 17, 16, 144, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	                                               DB            10, 10, 144, 16, 17, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41, 124, 41, 41, 42, 43, 44, 43, 43
	                                               DB            43, 42, 41, 41, 41, 41, 41, 42, 43, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 42, 41, 124, 41, 42, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16
	                                               DB            124, 16, 17, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 216, 16, 214, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 42, 124, 41, 41, 124, 41, 41, 42, 43, 43, 42, 42, 42, 41, 41, 41, 41, 42, 44, 41, 42, 44, 44, 44, 44, 44, 44, 44, 43, 43, 44, 44, 44, 44, 44, 44
	                                               DB            44, 42, 41, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 143, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 142, 16, 16, 124, 16
	                                               DB            16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 185, 42, 124, 42, 42, 42, 43, 42, 42, 41, 41, 41, 42, 42, 6, 124, 41, 124
	                                               DB            41, 42, 44, 44, 44, 44, 44, 44, 43, 41, 42, 44, 44, 44, 44, 44, 44, 43, 42, 41, 124, 41, 42, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 124, 16, 17, 10, 10
	                                               DB            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 17, 16, 124, 16, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 41
	                                               DB            124, 41, 41, 42, 42, 41, 41, 41, 41, 42, 124, 42, 42, 124, 42, 41, 124, 41, 42, 44, 44, 44, 44, 44, 43, 42, 41, 42, 43, 44, 44, 44, 44, 44, 43, 41, 42, 124, 41, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 17, 16, 216, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 141, 17, 16, 17, 124, 16, 124, 16, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 124, 6, 41, 42, 41, 41, 42, 42, 124, 42, 42, 42, 42, 41, 41, 41, 42, 124, 41, 42, 44, 44, 44, 44
	                                               DB            43, 41, 41, 42, 41, 43, 44, 44, 44, 44, 44, 42, 41, 43, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 124, 16, 16, 17, 143, 10, 10, 10, 10, 10
	                                               DB            10, 10, 10, 144, 17, 16, 10, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124
	                                               DB            41, 41, 41, 41, 124, 41, 124, 124, 124, 42, 124, 41, 42, 44, 44, 44, 43, 41, 41, 42, 42, 41, 42, 44, 44, 44, 44, 44, 42, 41, 124, 124, 42, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 16, 124, 16, 124, 17, 16, 16, 17, 215, 144, 144, 144, 214, 216, 17, 16, 16, 31, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 124, 6, 41, 42, 41, 41, 41, 41, 124, 41, 124, 124, 124, 124, 124, 124, 42, 124, 41, 43, 44, 44, 43, 41, 41, 42, 124, 42, 41, 42
	                                               DB            43, 44, 44, 44, 43, 42, 41, 124, 42, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 16, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 124, 16
	                                               DB            16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 41, 42, 124, 41, 43, 44, 43, 41, 41, 42, 124, 41, 124, 42, 41, 43, 44, 44, 44, 43, 41, 41, 124, 42, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            16, 124, 16, 16, 16, 124, 16, 124, 124, 124, 124, 30, 124, 31, 215, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 124, 42, 43, 43, 41, 41, 42, 124, 41, 41, 124, 42, 41, 42, 44, 44, 44, 43, 41
	                                               DB            42, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 16, 124, 16, 16, 16, 16, 16, 16, 16, 16, 16, 124, 16, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 42, 124, 42
	                                               DB            42, 42, 41, 44, 41, 42, 124, 41, 124, 42, 41, 42, 44, 44, 44, 43, 41, 42, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 42, 124, 42, 41, 41, 42, 40, 41, 124, 42, 41, 42, 124, 41, 42, 43, 44, 44, 42, 41, 42, 124, 41, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 42, 41, 41, 124, 41, 42, 124, 41
	                                               DB            124, 124, 41, 124, 41, 41, 43, 44, 44, 42, 41, 124, 42, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41, 42, 41, 41, 124, 41, 124, 124, 42, 41, 124, 42, 41, 42, 44, 44, 42, 41, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 42, 41, 124, 42, 124, 124, 124, 124, 124, 41, 124, 41
	                                               DB            42, 43, 43, 41, 41, 124, 41, 42, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 41, 124, 41, 41, 42, 124, 41, 124, 124, 124, 124, 124, 42, 41, 124, 42, 41, 43, 43, 41, 41, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 41, 124, 43, 41, 42, 43, 41, 6, 124
	                                               DB            41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 41, 42, 124, 41, 42, 42, 41, 124, 42, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 42, 42, 41, 124, 41, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 6, 41, 42, 124, 41, 41, 42, 124, 42, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41, 41, 41, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 41, 124, 41
	                                               DB            124, 41, 41, 124, 41, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	                                               DB            124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124
	IMG_CLK_L                             DB                  161, 161, 161, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161
	                                      DB                  163, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 163, 161, 161, 27, 161, 29, 91, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 91, 29, 162, 27, 161, 160, 28, 43
	                                      DB                  43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 28, 161, 161, 162, 137, 27, 14, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 14, 28, 137, 162, 27, 136, 25, 92, 67, 91
	                                      DB                  67, 67, 67, 43, 67, 67, 67, 91, 67, 92, 25, 136, 27, 23, 136, 163, 30, 31, 31, 31, 31, 31, 14, 31, 31, 31, 31, 31, 31, 163, 136, 23, 162, 27, 137, 25, 31, 31, 31, 31
	                                      DB                  31, 14, 31, 31, 31, 31, 31, 25, 137, 27, 162, 161, 160, 163, 160, 26, 31, 31, 31, 31, 14, 31, 31, 31, 31, 26, 160, 162, 160, 161, 27, 161, 27, 163, 137, 23, 28, 31, 31, 14
	                                      DB                  31, 31, 28, 23, 137, 163, 27, 161, 27, 161, 27, 161, 27, 27, 137, 138, 25, 31, 14, 31, 25, 138, 137, 27, 27, 160, 27, 161, 27, 161, 27, 162, 160, 27, 27, 137, 28, 14, 28, 160
	                                      DB                  27, 27, 160, 162, 27, 161, 27, 27, 161, 27, 161, 90, 27, 114, 160, 28, 14, 29, 160, 114, 27, 27, 161, 27, 161, 27, 161, 27, 160, 27, 26, 137, 161, 28, 91, 43, 68, 28, 161, 137
	                                      DB                  25, 27, 160, 27, 161, 27, 161, 27, 160, 160, 25, 29, 67, 43, 43, 43, 67, 29, 25, 160, 160, 27, 161, 27, 161, 160, 138, 161, 28, 92, 14, 43, 43, 43, 43, 43, 14, 92, 28, 161
	                                      DB                  138, 160, 161, 162, 27, 137, 26, 31, 30, 31, 31, 31, 31, 31, 31, 31, 30, 31, 26, 137, 27, 162, 27, 136, 23, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 23, 136
	                                      DB                  27, 184, 136, 25, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 25, 136, 136, 161, 137, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 28, 137, 161, 161
	                                      DB                  161, 29, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 161, 161, 27, 161, 29, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 29, 162, 27, 161, 161, 162
	                                      DB                  163, 163, 163, 163, 163, 163, 163, 163, 163, 163, 163, 163, 163, 162, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161
	                                      DB                  161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161



	
	
	START_CANON_LEFT_X                    DW                  151
	START_CANON_LEFT_X_PLUS_LENGTH        DW                  175
	START_CANON_LEFT_Y                    DW                  376
	START_CANON_LEFT_Y_PLUS_HEIGHT        DW                  396
	

	START_CANON_RIGHT_X                   DW                  465
	START_CANON_RIGHT_X_PLUS_LENGTH       DW                  489
	START_CANON_RIGHT_Y                   DW                  376
	START_CANON_RIGHT_Y_PLUS_HEIGHT       DW                  396
	START_X_LINE_1                        DW                  ?
	START_Y_LINE_1                        DW                  ?
	START_X_LINE_2                        DW                  ?
	START_Y_LINE_2                        DW                  ?
	START_X_LINE_3                        DW                  ?
	START_Y_LINE_3                        DW                  ?
	START_X_LINE_4                        DW                  ?
	START_Y_LINE_4_UP                     DW                  ?
	START_Y_LINE_4_DOWN                   DW                  ?

	START_X_LINE_5                        DW                  ?
	START_Y_LINE_5                        DW                  ?
	START_X_LINE_6                        DW                  ?
	START_Y_LINE_6                        DW                  ?
	START_X_LINE_7                        DW                  ?
	START_Y_LINE_7                        DW                  ?
	START_X_LINE_8                        DW                  ?
	START_Y_LINE_8_UP                     DW                  ?
	START_Y_LINE_8_DOWN                   DW                  ?

	DISTANCE_BETWEEN_BLOCKS               DW                  21
	NUMBER_OF_BLOCKS                      DW                  14
	COLOR_CANON_LEFT                      DW                  8
	COLOR_CANON_RIGHT                     DW                  8
	BACKGROUND_COLOR                      DW                  7
	BLOCK_COLOR_LC                        DW                  6H
	LEFT_OBSTACLES_BLOCK_COLOR            DW                  6H
	BLOCK_COLOR_RC                        DW                  4H
	RIGHT_OBSTACLES_BLOCK_COLOR           DW                  4H
	CURRENT_STATE_BLOCKS                  DW                  1
	X_FIRE_LOC_LEFT                       DW                  ?
	Y_FIRE_LOC_LEFT                       DW                  ?
	X_FIRE_LOC_RIGHT                      DW                  ?
	Y_FIRE_LOC_RIGHT                      DW                  ?
	FIRED_RIGHT_PLAYER                    DB                  0
	FIRED_LEFT_PLAYER                     DB                  0
	BOOL_INTERSECTION_OF_LEFT_FIRE        DB                  0
	BOOL_INTERSECTION_OF_RIGHT_FIRE       DB                  0
	COUNT_NORMAL_AMUNITION_PLAYER_1       DW                  '02'
	COUNT_POWER_AMUNITION_PLAYER_1        DW                  '02'
	COUNT_SHIELD_AMUNITION_PLAYER_1       DW                  '50'
	COUNT_NORMAL_AMUNITION_PLAYER_2       DW                  '02'
	COUNT_POWER_AMUNITION_PLAYER_2        DW                  '02'
	COUNT_SHIELD_AMUNITION_PLAYER_2       DW                  '50'



	COUNT_PRESSES_UP                      DB                  0
	COUNT_PRESSES_DOWN                    DB                  0
	COUNT_PRESSES_W                       DB                  0
	COUNT_PRESSES_S                       DB                  0
	COUNT_PRESSES_SPACE                   DB                  0
	COUNT_PRESSES_Q                       DB                  0
	COUNT_PRESSES_E                       DB                  0
	COUNT_PRESSES_K                       DB                  0
	COUNT_PRESSES_L                       DB                  0
	COUNT_PRESSES_R                       DB                  0

	MAIN_MENU_BOX_1_STARING_X             DW                  210
	MAIN_MENU_BOX_1_ENDING_X              DW                  430
	MAIN_MENU_BOX_1_STARING_Y             DW                  265
	MAIN_MENU_BOX_1_ENDING_Y              DW                  295
	MAIN_MENU_BOX_2_STARING_X             DW                  210
	MAIN_MENU_BOX_2_ENDING_X              DW                  430
	MAIN_MENU_BOX_2_STARING_Y             DW                  300
	MAIN_MENU_BOX_2_ENDING_Y              DW                  330
	MAIN_MENU_BOX_3_STARING_X             DW                  210
	MAIN_MENU_BOX_3_ENDING_X              DW                  430
	MAIN_MENU_BOX_3_STARING_Y             DW                  335
	MAIN_MENU_BOX_3_ENDING_Y              DW                  365

	MAIN_MENU_BACKGROUND_COLOR            DB                  124
	CANON_BODY_COLOR                      DB                  0FH
	CANON_TIP_COLOR                       DB                  6
	CANON_WHEEL_COLOR                     DB                  8
	COLOR_NORMAL_FIRE                     DB                  0
	X_POINT_OF_INTERSECTION_LEFT          DW                  ?
	Y_POINT_OF_INTERSECTION_LEFT          DW                  ?
	X_POINT_OF_INTERSECTION_RIGHT         DW                  ?
	Y_POINT_OF_INTERSECTION_RIGHT         DW                  ?
	CIRCLE_COLOR                          DB                  ?
	FLAG_SHIELD_FIRE_INTERSECTION         DB                  0

	COUNT_STICKERS                        DW                  0
	X_ARRAY_STICKERS                      DW                  100 DUP(0)
	Y_ARRAY_STICKERS                      DW                  100 DUP(0)
	LINE_ARRAY_STICKERS                   DW                  100 DUP(0)
	TYPE_OF_STICKER                       DW                  100 DUP(0)
	CURRENT_STATE_STICKERS                DW                  100 DUP(0)
	BOOL_LINE_IDENTIFIED                  DB                  0
	PREVIOUS_TIME_FIRE_LEFT               DW                  ?
	PREVIOUS_TIME_FIRE_RIGHT              DW                  ?
	PREVIOUS_TIME_MOVING_OBSTACLES        DW                  ?
	; CURRENT_TIME_FIRE_LEFT                         DW            ?
	; CURRENT_TIME_FIRE_RIGHT                        DW            ?
	; DIFFERENCE_FROM_LAST_TIME_CALL                 DW            ?
	; FIRST_TIME                                     DW            0
	; GAME_TOTAL_TIME                                DW            0
	; GAME_PREVIOUS_TIME_OBSTACLES                   DW            0
	SPEED_OBSTCLES_MOVEMENT               DW                  10
	SPEED_FIRE_MOVEMENT                   DW                  1
	END_SCREEN_LEFT_FIRE                  DB                  0
	END_SCREEN_RIGHT_FIRE                 DB                  0
	HEALTH_PLAYER1_DECREASED              DB                  0
	HEALTH_PLAYER2_DECREASED              DB                  0
	CHOSEN_LEVEL                          DB                  0
	;--------------------------------------


	;-------------------TIMING----------------------
	X_CLK_LEFT                            DW                  131
	Y_CLK_LEFT                            DW                  25


	XC_NORM_LEFT                          DW                  120
	YC_NORM_LEFT                          DW                  40
	
	X_BOMB_LEFT                           DW                  65
	Y_BOMB_LEFT                           DW                  29


	X_CLK_RIGHT                           DW                  596
	Y_CLK_RIGHT                           DW                  25


	XC_NORM_RIGHT                         DW                  585
	YC_NORM_RIGHT                         DW                  40

	X_BOMB_RIGHT                          DW                  529
	Y_BOMB_RIGHT                          DW                  29

	PLAYER_1_PREVIOUS_SEC                 DB                  0                                                                                                                                                                                                     	; TO STORE THE SEC AT WHICH THE PLAYER HAS NO NORMAL AMMUNITION LEFT
	PLAYER_2_PREVIOUS_SEC                 DB                  0
	OBSTACLES_PREV_TIME                   DB                  0
	REFUEL_NORMAL_AMMUNITION_SEC          DW                  '03'                                                                                                                                                                                                  	; =0AH   ; ADD THIS VALUE TO DH // IF 'DW' IT WILL BE ADDED TO DL ...                                                                                                                                                                                                                              	; REFUEL AFTER N SECONDS
	TIME_LEFT_REFUEL_PLAYER_1             DW                  '00'                                                                                                                                                                                                  	; =3030H                                                                                                                                                                                                                              	; TO STORE THE TIME AT WHICH NORMAL AMMUNITION GET REFUELED FOR PLAYER 1
	TIME_LEFT_REFUEL_PLAYER_2             DW                  '00'
	TIME_LEFT_MOVE_OBSTACLES              DW                  100
	TIME_LEFT_RETURN_MAIN                 DW                  5                                                                                                                                                                                                     	; =3030H
	;---------------------------------POWERUPS------------------------------------------
	HEALTH_POWERUP_BOX_COLOR              DB                  233
	BOMB_POWERUP_BOX_COLOR                DB                  56
	DEFENSE_POWERUP_BOX_COLOR             DB                  9H
	HEART_SYMBOL                          DB                  03H

	BOMB_POWERUP_BOX_STARTING_X           DW                  340
	BOMB_POWERUP_BOX_STARTING_Y           DW                  120

	BOMB_POWERUP_BOX_ENDING_X             DW                  360
	BOMB_POWERUP_BOX_ENDING_Y             DW                  140

	DEFENSE_POWERUP_CIRCLE_CENTER_X       DW                  300
	DEFENSE_POWERUP_CIRCLE_CENTER_Y       DW                  204

	DEFENSE_POWERUP_CIRCLE_RADIUS_1       DW                  10
	DEFENSE_POWERUP_CIRCLE_RADIUS_2       DW                  7
	 
	TIME_TO_APPEAR_HEALTH_POWERUP_1       DB                  1
	TIME_TO_APPEAR_HEALTH_POWERUP_2       DB                  33
	TIME_TO_APPEAR_HEALTH_POWERUP_3       DB                  59

	TIME_TO_APPEAR_BOMB_POWERUP_1         DB                  10
	TIME_TO_APPEAR_BOMB_POWERUP_2         DB                  30
	TIME_TO_APPEAR_BOMB_POWERUP_3         DB                  24

	TIME_TO_APPEAR_DEFENSE_POWERUP_1      DB                  15
	TIME_TO_APPEAR_DEFENSE_POWERUP_2      DB                  45
	TIME_TO_APPEAR_DEFENSE_POWERUP_3      DB                  55

	PREVIOUS_TIME_HEALTH_POWERUP_1        DB                  0
	PREVIOUS_TIME_HEALTH_POWERUP_2        DB                  0
	PREVIOUS_TIME_HEALTH_POWERUP_3        DB                  0

	PREVIOUS_TIME_BOMB_POWERUP_1          DB                  0
	PREVIOUS_TIME_BOMB_POWERUP_2          DB                  0
	PREVIOUS_TIME_BOMB_POWERUP_3          DB                  0

	PREVIOUS_TIME_DEFENSE_POWERUP_1       DB                  0
	PREVIOUS_TIME_DEFENSE_POWERUP_2       DB                  0
	PREVIOUS_TIME_DEFENSE_POWERUP_3       DB                  0

	CURRENT_MINUTE                        DB                  0
	 
	COUNTER_HEALTH_POWERUP                DB                  0
	COUNTER_BOMB_POWERUP                  DB                  0
	COUNTER_DEFENSE_POWERUP               DB                  0

	CENTISECOND_BOMB_POWERUP_POSITION_0   DB                  0
	CENTISECOND_BOMB_POWERUP_POSITION_1   DB                  0
	CENTISECOND_BOMB_POWERUP_POSITION_2   DB                  0
	;------------------------------------CHATTING--------------------
	MIDDLESCREEN                          EQU                 11

	PLAYER1CURSOR_X                       DB                  1
	PLAYER1CURSOR_Y                       DB                  3
	PLAYER2CURSOR_X                       DB                  1
	PLAYER2CURSOR_Y                       DB                  14

	PLAYER1CURSOR_X_INLINE                DB                  11
	PLAYER2CURSOR_X_INLINE                DB                  11
	PLAYER1CURSOR_Y_INLINE                Db                  30
	PLAYER2CURSOR_Y_INLINE                Db                  31
	IsChatEnded_INLINE                    DB                  0

	SentChar                              DB                  ?
	ReceivedChar                          DB                  ?
	ScanCodeSentChar                      DB                  ?
	ScanCodeReceivedChar                  DB                  ?
	IsChatEnded                           DB                  0
	ESC_MESSAGE                           DB                  'TO QUIT CHAT PRESS F3...','$'

	ESC_ScanCode                          EQU                 01H
	ESC_AsciiCode                         EQU                 1BH
	Enter_ScanCode                        EQU                 1CH
	Enter_AsciiCode                       EQU                 0DH
	Back_ScanCode                         EQU                 0EH
	Back_AsciiCode                        EQU                 08H
	F3_ScanCode                           EQU                 3DH
	F1_ScanCode                           EQU                 3BH

    
	CurrentPage                           EQU                 0
	WindowWidth                           EQU                 79
	WindowHeight                          EQU                 24
	ChatAreaWidth                         EQU                 WindowWidth
	ChatAreaHeight                        EQU                 11
	ChatMargin                            EQU                 1

	Current_player_NUMBER                 db                  ?
	CHOOSE_LVL_MESSAGE                    DB                  'PLEASE CHOOSE LEVEL 1 OR 2'
	TEMP_ASCII                            DB                  ?
	TEMP_SCAN                             DB                  ?
	;-------------------------------------------------------------------------
.CODE
MAIN PROC FAR

	;TRANSFER DATA
	                                               MOV                 AX,@DATA
	                                               MOV                 DS ,AX
	                                               MOV                 ES,AX
	                                               MOV                 AX,0
	;------------SET TIMER--------------------------------
	;    MOV       CX,0
	;    MOV       DX,0
	;    MOV       AH,2DH
	;    INT       21H

	;    CALL      CALC_FIRST_TIME
	;    CALL      GET_CURRENT_TIME_IN_CENTISECONDS

	;    MOV       AX,GAME_TOTAL_TIME
	;    MOV       GAME_PREVIOUS_TIME_OBSTACLES,AX
	;---------------------------------------------------

	;GRAPHICS MODE


	                                               MOV                 AX, 4F02H
	                                               MOV                 BX, 0100H
	                                               INT                 10H
	                            
	;----------------------------------------------------

	                                               PUSH                ES

	                                               PRINT               PROMPT_THE_USER_TO_ENTER_NAME_MESSAGE
	;    READ

	;==============================
	                                               InitSerialPort

	                                               MOV                 DI,OFFSET CURRENTNAMEDATA
	                                               MOV                 SI, OFFSET OTHERNAMEDATA
	                                               MOV                 BX,0

	                                               READ

	;===================================

	                                               MOV                 SI,OFFSET CURRENTNAMEDATA
	LOOP_GET_NAME1:                                
	                                               CMP                 [SI],2424h
	                                               JE                  END_COUNT1
	                                               INC                 SI
	                                               INC                 CURRENTNAMEACTUALSIZE
	                                               JMP                 LOOP_GET_NAME1
	END_COUNT1:                                    

	                                               MOV                 SI,OFFSET OTHERNAMEDATA
	LOOP_GET_NAME2:                                
	                                               CMP                 [SI],2424h
	                                               JE                  END_COUNT2
	                                               INC                 SI
	                                               INC                 OTHERNAMEACTUALSIZE
	                                               JMP                 LOOP_GET_NAME2
	END_COUNt2:                                    

	;    GET_NAME_SIZE     OTHERNAMEDATA,OTHERNAMEACTUALSIZE


	BEFORE_GAME:                                   
	                                               MOV                 IsChatEnded,0
	                                               mov                 IsChatEnded_INLINE,0
	                                               CALL                MAIN_MENU
	                                               POP                 ES
	EXIT_MAIN_MENU:                                
	                                               MOV                 AX, 4F02H
	                                               MOV                 BX, 0101H
	                                               INT                 10H

	                                               CMP                 Current_player_NUMBER,1
	                                               JNZ                 NOT_PLAYER_1
	                                               PUSHA
	                                               CALL                CHOOSE_LEVEL
	                                               POPA

	NOT_PLAYER_1:                                  

	                                               CALL                DRAW_BACKGROUND_AND_DOORS
	;==================
	                                               MOV                 AH,13H
	                                               mov                 al,0
	                                               MOV                 BH,0
	                                               MOV                 BL,71
	                                               MOV                 CH,0

	                                               MOV                 CL,37
	                                               MOV                 DL, 0
	                                               MOV                 DH, 29
	                                               MOV                 BP, OFFSET F4_Message
	                                               INT                 10H

	                                               MOV                 CL,37
	                                               MOV                 DL, 37
	                                               MOV                 DH, 29
	                                               MOV                 BP, OFFSET START_INLINE_CHATING
	                                               INT                 10H

	;==================
	                                               CALL                STATUS_BAR
	                                               DRAWMACRO           IMG2,IMGW,IMGH,X2,Y2,W,H,J1
	                                               DRAWMACRO           IMG,IMGW,IMGH,X1,Y1,W,H,J2
	                                               CALL                DRAW_LEFT_CASTLE
	                                               CALL                DRAW_RIGHT_CASTLE
	                           
	                                               CALL                DRAW_LEFT_CANON
	                                               CALL                DRAW_RIGHT_CANON

	                                               MOV                 BX,BLOCK_COLOR_LC
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 BX,BLOCK_COLOR_RC
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_INITAL_OBSTACLES
	                                               CALL                DRAW_AMMUNITION_SYMBOLS
	                                               CALL                AMMUNITION_COUNT_INDICATOR
	                                               InitSerialPort

	;    CALL      GET_CURRENT_TIME_IN_CENTISECONDS
	;    MOV       AX,DIFFERENCE_FROM_LAST_TIME_CALL
	;    MOV       PREVIOUS_TIME_MOVING_OBSTACLES,AX
	;    MOV       PREVIOUS_TIME_FIRE_RIGHT,AX
	;    MOV       PREVIOUS_TIME_FIRE_LEFT,AX
	
	;    MOV       AH,2CH
	;    INT       21H
	;    MOV       OBSTACLES_PREV_TIME,DL
	                                               InitSerialPort
	                                               pusha
	                                               CMP                 Current_player_NUMBER,2
	                                               JNZ                 DONT_WAIT
	LOOP_WAIT_LVL:                                 
	                                               ReceiveChar
	                                               jz                  LOOP_WAIT_LVL
	                                               mov                 CHOSEN_LEVEL,al


	DONT_WAIT:                                     
	                                               CMP                 CHOSEN_LEVEL,1
	                                               JZ                  start_game_1
	                                               JMP                 start_game_2

	start_game_1:                                  
	                                               popa
	LOOP_GAME_LEVEL_1:                             
	                                               MOV                 BX,0
	                                               MOV                 AX,0
	                                               MOV                 AH,2CH
	                                               INT                 21H
	                                               MOV                 BL,DL
	                                               SUB                 DL,OBSTACLES_PREV_TIME
	                                               MOV                 OBSTACLES_PREV_TIME,BL
	                                               SUB                 TIME_LEFT_MOVE_OBSTACLES,5
	                                               CMP                 TIME_LEFT_MOVE_OBSTACLES,0
	                                               JNZ                 NO_MOVE_LVL_1
	                                               pusha
	                                               CALL                MOVING_OBSTACLES_STATES
	                                               popa
	                                               pusha
	                                               CALL                DRAW_STICKERS
	                                               popa
	                                               MOV                 TIME_LEFT_MOVE_OBSTACLES,150
	;---------------------------------------
	NO_MOVE_LVL_1:                                 
	                                               PUSHA
	                                               CMP                 Current_player_NUMBER,1
	                                               JNZ                 NOW_BUFFER_RIGHT
	                                               CALL                CHECK_BUFFER_LEFT_PLAYER
	                                               JMP                 END_BUFFER_LVL_1
	NOW_BUFFER_RIGHT:                              
	                                               CALL                CHECK_BUFFER_RIGHT_PLAYER
	END_BUFFER_LVL_1:                              
	                                               popa
	                                               pusha
												   
	                                               CALL                CHECK_LEFT_CANON_MOVEMENT
	                                               popa
	                                               pusha
	                                               CALL                CHECK_RIGHT_CANON_MOVEMENT
	                                               popa
	                                               pusha
	                                               CALL                CHECK_FIRE_LEFT
	                                               popa
	                                               pusha
	                                               CALL                REFUEL_NORMAL_INDICATOR_PLAYER_1
	                                               popa
	                                               pusha
	                                               CALL                CHECK_FIRE_RIGHT
	                                               popa
	                                               pusha
	                                               CALL                REFUEL_NORMAL_INDICATOR_PLAYER_2
	                                               popa
	                                               pusha
	                                               CALL                MOVE_RIGHT_FIRE
	                                               popa
	                                               pusha
	                                               CALL                MOVE_LEFT_FIRE
	                                               popa
												 
	    
	                                               PUSHA
	                                               CALL                STATUS_BAR
	                                               POPA

	                                               PUSHA
	                                               CALL                AMMUNITION_COUNT_INDICATOR
	                                               POPA
	;    MOV               AH,86H
	;    MOV               CX,00
	;    MOV               DX,1
	;    INT               15H
		 
	                                               JMP                 LOOP_GAME_LEVEL_1
	start_game_2:                                  
	                                               popa
	                                               PUSHA
	                                               CALL                DRAW_POWERUPS
	                                               POPA
	                                               pusha
	                                               call                STATUS_BAR
	                                               popa
	LOOP_GAME_LEVEL_2:                             
	                                               MOV                 BX,0
	                                               MOV                 AX,0
	                                               PUSHA
	                                               MOV                 AH,2CH
	                                               INT                 21H
	                                               MOV                 BL,DL
	                                               SUB                 DL,OBSTACLES_PREV_TIME
	                                               MOV                 OBSTACLES_PREV_TIME,BL
	                                               SUB                 TIME_LEFT_MOVE_OBSTACLES,5
	                                               CMP                 TIME_LEFT_MOVE_OBSTACLES,0
	                                               JNZ                 NO_MOVE_LVL_2

	                                               CALL                MOVING_OBSTACLES_STATES
	                                               CALL                DRAW_STICKERS
	                                               MOV                 TIME_LEFT_MOVE_OBSTACLES,150
	;---------------------------------------
	NO_MOVE_LVL_2:                                 
	                                               POPA
	                                               PUSHA
	                                               CMP                 Current_player_NUMBER,1
	                                               JNZ                 NOW_BUFFER_RIGHT_2
	                                               CALL                CHECK_BUFFER_LEFT_PLAYER
	                                               JMP                 END_BUFFER_LVL_2
	NOW_BUFFER_RIGHT_2:                            
	                                               CALL                CHECK_BUFFER_RIGHT_PLAYER
	END_BUFFER_LVL_2:                              
	                                               CALL                CHECK_LEFT_CANON_MOVEMENT
	                                               CALL                CHECK_RIGHT_CANON_MOVEMENT
	                                               CALL                CHECK_FIRE_LEFT
	                                               CALL                REFUEL_NORMAL_INDICATOR_PLAYER_1
	                                               CALL                CHECK_FIRE_RIGHT
	                                               CALL                REFUEL_NORMAL_INDICATOR_PLAYER_2
	                                               CALL                MOVE_RIGHT_FIRE
	                                               CALL                MOVE_LEFT_FIRE
	                                               POPA
	                                        
	                                               PUSHA
	                                               CALL                STATUS_BAR
	                                               POPA

	                                               PUSHA
	                                               CALL                AMMUNITION_COUNT_INDICATOR
	                                               POPA
	 
	                                               JMP                 LOOP_GAME_LEVEL_2


	WINNER_PLAYER_1:                               
	                                               CALL                DRAW_BACKGROUND_BLACK

	                                               MOV                 AX,0
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71


	                                               MOV                 CX,LENGTH_WINNER_PLAYER_1_MESSAGE
	                                               MOV                 DL,12
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET WINNER_PLAYER_1_MESSAGE
	                                               INT                 10H

	                                               MOV                 AH,86H
	                                               MOV                 CX,004CH
	                                               MOV                 DX,4B4AH
	                                               INT                 15H
	                                               JMP                 BEFORE_GAME

	WINNER_PLAYER_2:                               
	                                               CALL                DRAW_BACKGROUND_BLACK

	                                               MOV                 AX,0
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71


	                                               MOV                 CX,LENGTH_WINNER_PLAYER_2_MESSAGE
	                                               MOV                 DL,12
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET WINNER_PLAYER_2_MESSAGE
	                                               INT                 10H

	                                               MOV                 AH,86H
	                                               MOV                 CX,004CH
	                                               MOV                 DX,4B4AH
	                                               INT                 15H
	                                               JMP                 BEFORE_GAME
	END_PROGRAM:                                   
	                                               MOV                 AH, 4CH
	                                               INT                 21H
	;--------------------------------

MAIN ENDP

	;-------------------------------------------------------------------------------------------------------------


ENTER_INLINE_CHATTING PROC

	                                               InitSerialPort
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71
	                                               MOV                 CH,0

	                                               MOV                 CL,BYTE PTR CURRENTNAMEACTUALSIZE
	                                               MOV                 DL,0
	                                               MOV                 DH,25
	                                               MOV                 BP,OFFSET CURRENTNAMEDATA
	                                               INT                 10H

	                                               MOV                 CL,BYTE PTR OTHERNAMEACTUALSIZE
	                                               MOV                 DL,0
	                                               MOV                 DH,27
	                                               MOV                 BP,OFFSET OTHERNAMEDATA
	                                               INT                 10H


	;========================
	Chat_Loop_INLINE:                              

	                                          
	                                               PUSHA
	                                               MOVECURSOR          11, 25
	                                               POPA
	Send_loop_INLINE:                              

	                                               CALL                GetKeyPressed
	                                               JZ                  Receive_loop
	                                               MOV                 SentChar, AL
	                                               MOV                 ScanCodeSentChar,AH
	                                               cmp                 ah,3FH
	                                               jz                  F5_PRESSED_INLINE
	                                               SendChar            SentChar
	                                               pusha
	                                               call                PROCESSINPUT1_INLINE
	                                               popa
	                                               jmp                 Receive_loop_INLINE

	F5_PRESSED_INLINE:                             
	                                               SendChar            ScanCodeSentChar
	                                               PUSHA
	                                               CALL                PROCESSINPUT1_INLINE
	                                               POPA
	Receive_loop_INLINE:                           
	                                               ReceiveChar
	                                               JZ                  Check_if_chat_ended_INLINE
	                                               MOV                 ReceivedChar, AL
	;    MOV               ScanCodeReceivedChar,AH
	;    cmp               ReceivedChar,F3_ScanCode
	;    jmp               BEFORE_GAME
	                                               PUSHA
	                                               CALL                PROCESSINPUT2_INLINE
	                                               POPA
	Check_if_chat_ended_INLINE:                    
	                                               CMP                 IsChatEnded_INLINE, 1
	                                               JNE                 Chat_Loop_INLINE

	                                              
	                                               POPA
	                                               POPA
	                                               RET


	;========================


ENTER_INLINE_CHATTING ENDP

CHOOSE_LEVEL PROC
	                                               MOV                 AH,13H
	                                               mov                 al,0
	                                               MOV                 BH,0
	                                               MOV                 BL,59
	                                               MOV                 CH,0

	                                               MOV                 CL,26
	                                               MOV                 DL,10
	                                               MOV                 DH,12
	                                               MOV                 BP, OFFSET CHOOSE_LVL_MESSAGE
	                                               INT                 10H
	lOOP_LVL:                                      

	                                               MOV                 AH,0
	                                               INT                 16H

	                                               CMP                 AL,31H
	                                               JNZ                 NOT_ONE
	                                               JMP                 FOUND
	NOT_ONE:                                       
	                                               CMP                 AL,32H
	                                               JNZ                 LOOP_LVL
	FOUND:                                         
	                                               sub                 al,30h
	                                               MOV                 CHOSEN_LEVEL,AL
	                                               mov                 SentChar,al
	                                               SendChar            SentChar
	                                               RET
CHOOSE_LEVEL ENDP


	;===================================================================================
PROCESSINPUT1 PROC
	                                               PROCESSINPUT        ScanCodeSentChar,SentChar,PLAYER1CURSOR_X,PLAYER1CURSOR_Y,0
	                                               RET
PROCESSINPUT1 ENDP
	;===================================================================================

	;===================================================================================
PROCESSINPUT2 PROC
	                                               PROCESSINPUT        ReceivedChar,ReceivedChar,PLAYER2CURSOR_X,PLAYER2CURSOR_Y, ChatAreaHeight
	                                               RET
PROCESSINPUT2 ENDP
	;===================================================================================
PROCESSINPUT1_INLINE PROC
	                                               PROCESSINPUT_INLINE ScanCodeSentChar,SentChar,PLAYER1CURSOR_X_INLINE,PLAYER1CURSOR_Y_INLINE,0
	                                               RET
PROCESSINPUT1_INLINE ENDP
	;===================================================================================

	;===================================================================================
PROCESSINPUT2_INLINE PROC
	                                               PROCESSINPUT_INLINE ReceivedChar,ReceivedChar,PLAYER2CURSOR_X_INLINE,PLAYER2CURSOR_Y_INLINE, 1
	                                               RET
PROCESSINPUT2_INLINE ENDP


	;===========================================================GetKeyPressed============================================================
GetKeyPressed PROC
	                                               GetKeyPress
	                                               JZ                  NoKeyPressed
	                                               MOV                 AH, 00H
	                                               INT                 16H
	NoKeyPressed:                                  
	                                               RET
GetKeyPressed ENDP
	;====================================================================================================================================
CHAT_ROOM PROC
	                                               PUSHA

	                                               PUSHA
	                                               InitSerialPort
	                                               POPA

	                                               PUSHA
	                                               TEXTMODE
	                                               POPA

	                                               PUSHA
	                                               MOVECURSOR          0,MIDDLESCREEN
	                                               POPA

	                                               PUSHA
	                                               DRAWSEPLINE
	                                               POPA

	                                               PUSHA
	                                               DrawEscMessBar
	                                               POPA

	                                               PUSHA
	                                               DISPLAYPLAYERNAME   NAME1DATA,1,0,NAME1ACTUALSIZE
	                                               POPA

	                                               PUSHA
	                                               DISPLAYPLAYERNAME   NAME2DATA,1,12,NAME2ACTUALSIZE
	                                               POPA
	;=====================STARTTHECHATTINGPROCESS==================================
	Chat_Loop:                                     

	                                          
	                                               PUSHA
	                                               MOVECURSOR          PLAYER1CURSOR_X, PLAYER1CURSOR_Y
	                                               POPA
	Send_loop:                                     

	                                               CALL                GetKeyPressed
	                                               JZ                  Receive_loop
	                                               MOV                 SentChar, AL
	                                               MOV                 ScanCodeSentChar,AH
	                                               cmp                 ah,F3_ScanCode
	                                               jz                  f3_pressed
	                                               SendChar            SentChar
	                                               pusha
	                                               call                PROCESSINPUT1
	                                               popa
	                                               jmp                 Receive_loop

	f3_pressed:                                    
	                                               SendChar            ScanCodeSentChar
	                                               PUSHA
	                                               CALL                PROCESSINPUT1
	                                               POPA
	Receive_loop:                                  
	                                               ReceiveChar
	                                               JZ                  Check_if_chat_ended
	                                               MOV                 ReceivedChar, AL
	;    MOV               ScanCodeReceivedChar,AH
	;    cmp               ReceivedChar,F3_ScanCode
	;    jmp               BEFORE_GAME
	                                               PUSHA
	                                               CALL                PROCESSINPUT2
	                                               POPA
	Check_if_chat_ended:                           
	                                               CMP                 IsChatEnded, 1
	                                               JNE                 Chat_Loop

	                                              
	                                               POPA
	                                               POPA
	                                               JMP                 BEFORE_GAME


	                                               RET
CHAT_ROOM ENDP
IN_LINE_CHATTING PROC
	; DISPLAY PLAYER NAME
	
	;DISPLAY
	                                               
	                                               mov                 ah,13h
	                                               MOV                 BH,0
	                                               MOV                 BL,00111011B
	                                               MOV                 CX, NAME1ACTUALSIZE
	                                               INC                 CX
	                                               MOV                 CH,0
	                                               MOV                 DL,0
	                                               MOV                 DH,25
	                                               MOV                 BP,OFFSET NAME1DATA
	                                               INT                 10H
									

	;MOVE CURSOR TO REQUIRED POSITION
	                                               push                es
	                                               MOV                 AH,2
	                                               MOV                 AL,0
	                                               MOV                 BH,0
	                                               MOV                 DX,NAME1ACTUALSIZE
	                                               INC                 DX
	                                               MOV                 DH,25
	                                               INT                 10H

	                                               RET
IN_LINE_CHATTING ENDP
	;-----------------------------------------------------
DRAW_BACKGROUND_BLACK PROC
	                                               MOV                 AX, 0013H
	                                               INT                 10H
	                                               MOV                 DX,0
	                                               MOV                 DI,200
	                                               MOV                 AH,0CH
	                                               MOV                 AL,00
	LOOP_Y_BACKGROUND:                             
	                                               MOV                 CX,0
	                                               MOV                 SI,320
	LOOP_X_BACKGROUND:                             
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 SI
	                                               JNZ                 LOOP_X_BACKGROUND
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_BACKGROUND
	                                               RET
DRAW_BACKGROUND_BLACK ENDP



	; GET_CURRENT_TIME_IN_CENTISECONDS PROC
	; 	                                               PUSHA
	; 	                                               MOV       DIFFERENCE_FROM_LAST_TIME_CALL,0
	; 	                                               MOV       AX,FIRST_TIME                                                              	; RETURN CH=HOUR CL=MINUTE DH=SECOND DL=1/100 SECOND (CENTISECOND)
	; 	                                               SUB       DIFFERENCE_FROM_LAST_TIME_CALL,AX
												   
	; 	                                               MOV       AH,2CH
	; 	                                               INT       21H
	; 	                                               PUSH      DX
												   
	; 	                                               MOV       AH,0
	; 	                                               MOV       DX,0
												   
	; 	                                               MOV       AL,CL
	; 	                                               MOV       BL,60
	; 	                                               MUL       BL                                                                         	; AX = MINUTES*60
	; 	                                               MOV       BX,100
	; 	                                               MUL       BX                                                                         	; DX : AX = MINUTES*60*100 ( BAS ANA 3AREF ENO MESH HAY3ADY EL BYTES OF AX )
	; 	                                               ADD       DIFFERENCE_FROM_LAST_TIME_CALL,AX
	; 	                                               POP       DX

	; 	                                               MOV       AH,0
	; 	                                               MOV       BL,100
	; 	                                               MOV       AL,DH
	; 	                                               MUL       BL                                                                         	;AX=SECONDS*100
	; 	                                               ADD       DIFFERENCE_FROM_LAST_TIME_CALL,AX
	; 	                                               ADD       BYTE PTR DIFFERENCE_FROM_LAST_TIME_CALL, DL
	; 	                                               MOV       AX,DIFFERENCE_FROM_LAST_TIME_CALL
	; 	                                               ADD       GAME_TOTAL_TIME,AX
	; 	                                               POPA
	; 	                                               RET

	; GET_CURRENT_TIME_IN_CENTISECONDS ENDP

DRAW_STICKERS PROC
	                                               MOV                 SI,COUNT_STICKERS
	                                               MOV                 DI,0
	                                               CMP                 SI,0
	                                               JZ                  END_DRAW_STICKERS

	LOOP_STICKERS:                                 
	                                               MOV                 BX,OFFSET X_ARRAY_STICKERS
	                                               ADD                 BX,DI
	                                               MOV                 CX,[BX]                                                                    	; CX HOLDS X VALUE

	                                               MOV                 BX,OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX,DI
	                                               MOV                 DX,[BX]                                                                    	; DX HOLDS Y VALUE

	                                               MOV                 BX,OFFSET TYPE_OF_STICKER
	                                               ADD                 BX,DI
	                                               MOV                 AX,[BX]                                                                    	; AX HOLDS TYPE

	                                               MOV                 BX,OFFSET LINE_ARRAY_STICKERS
	                                               ADD                 BX,DI
	                                               MOV                 BP,[BX]                                                                    	;BP HOLDS LINE

	                                               MOV                 BX, OFFSET CURRENT_STATE_STICKERS
	                                               ADD                 BX,DI                                                                      	;BX HOLDS CURRENT STATE STICKERS

	                                               CMP                 [BX],1
	                                               JZ                  IN_STATE_ONE

	                                               CMP                 [BX],2
	                                               JZ                  IN_STATE_TWO

	                                               CMP                 [BX],3
	                                               JZ                  IN_STATE_THREE

	                                               CMP                 [BX],4
	                                               JZ                  IN_STATE_FOUR


	IN_STATE_ONE:                                  
	                                               MOV                 [BX],2
	                                               CMP                 BP,1
	                                               JZ                  STATE_ONE_LINE_ONE
	                                               CMP                 BP,2
	                                               JZ                  STATE_ONE_LINE_TWO
	                                               CMP                 BP,3
	                                               JZ                  STATE_ONE_LINE_THREE
	                                               CMP                 BP,41
	                                               JZ                  STATE_ONE_LINE_FOUR_UP
	                                               CMP                 BP,42
	                                               JZ                  STATE_ONE_LINE_FOUR_DOWN
	                                               CMP                 BP,5
	                                               JZ                  STATE_ONE_LINE_FIVE
	                                               CMP                 BP,6
	                                               JZ                  STATE_ONE_LINE_SIX
	                                               CMP                 BP,7
	                                               JZ                  STATE_ONE_LINE_SEVEN
	                                               CMP                 BP,81
	                                               JZ                  STATE_ONE_LINE_EIGHT_UP
	                                               CMP                 BP,82
	                                               JZ                  STATE_ONE_LINE_EIGHT_DOWN
	                                       

	STATE_ONE_LINE_ONE:                            
	                                               ADD                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_ONE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_ONE_POWER

	STATE_ONE_LINE_ONE_NORMAL:                     
	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_ONE_LINE_ONE_POWER:                      
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	
	;-----------------------------------------------
	STATE_ONE_LINE_TWO:                            
	                                               ADD                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_TWO_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_TWO_POWER
	STATE_ONE_LINE_TWO_NORMAL:                     

	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER

	STATE_ONE_LINE_TWO_POWER:                      
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;------------------------------------------------
	STATE_ONE_LINE_THREE:                          
	                                               SUB                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_THREE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_THREE_POWER
	STATE_ONE_LINE_THREE_NORMAL:                   
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_THREE_POWER:                    
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	;------------------------------------------------------------
	STATE_ONE_LINE_FOUR_UP:                        
	                                               ADD                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_FOUR_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_FOUR_UP_POWER
	STATE_ONE_LINE_FOUR_UP_NORMAL:                 
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_FOUR_UP_POWER:                  
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	
	;---------------------------------------------------------------
	STATE_ONE_LINE_FOUR_DOWN:                      
	                                               SUB                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_FOUR_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_FOUR_DOWN_POWER
	STATE_ONE_LINE_FOUR_DOWN_NORMAL:               
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_FOUR_DOWN_POWER:                
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;---------------------------------------------------------------
	STATE_ONE_LINE_FIVE:                           
	                                               ADD                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_FIVE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_FIVE_POWER
	STATE_ONE_LINE_FIVE_NORMAL:                    
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_ONE_LINE_FIVE_POWER:                     
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	;--------------------------------------------------
	STATE_ONE_LINE_SIX:                            
                           
	                                               ADD                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_SIX_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_SIX_POWER
	STATE_ONE_LINE_SIX_NORMAL:                     
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_SIX_POWER:                      
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	

	;--------------------------------------------------
	STATE_ONE_LINE_SEVEN:                          
                            
                           
	                                               SUB                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_SEVEN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_SEVEN_POWER
	STATE_ONE_LINE_SEVEN_NORMAL:                   
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_SEVEN_POWER:                    
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	

	

	;-------------------------------------------------------
	STATE_ONE_LINE_EIGHT_UP:                       
	                                               ADD                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_EIGHT_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_EIGHT_UP_POWER
	STATE_ONE_LINE_EIGHT_UP_NORMAL:                
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_EIGHT_UP_POWER:                 
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
	;------------------------------------------------------

	STATE_ONE_LINE_EIGHT_DOWN:                     
	                                               SUB                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_ONE_LINE_EIGHT_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_ONE_LINE_EIGHT_DOWN_POWER
	STATE_ONE_LINE_EIGHT_DOWN_NORMAL:              
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_ONE_LINE_EIGHT_DOWN_POWER:               
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER

	;-----------------------------------------------------
	IN_STATE_TWO:                                  
	                                  
	                                               MOV                 [BX],3
	                                               CMP                 BP,1
	                                               JZ                  STATE_TWO_LINE_ONE
	                                               CMP                 BP,2
	                                               JZ                  STATE_TWO_LINE_TWO
	                                               CMP                 BP,3
	                                               JZ                  STATE_TWO_LINE_THREE
	                                               CMP                 BP,41
	                                               JZ                  STATE_TWO_LINE_FOUR_UP
	                                               CMP                 BP,42
	                                               JZ                  STATE_TWO_LINE_FOUR_DOWN
	                                               CMP                 BP,5
	                                               JZ                  STATE_TWO_LINE_FIVE
	                                               CMP                 BP,6
	                                               JZ                  STATE_TWO_LINE_SIX
	                                               CMP                 BP,7
	                                               JZ                  STATE_TWO_LINE_SEVEN
	                                               CMP                 BP,81
	                                               JZ                  STATE_TWO_LINE_EIGHT_UP
	                                               CMP                 BP,82
	                                               JZ                  STATE_TWO_LINE_EIGHT_DOWN
	                                              

	STATE_TWO_LINE_ONE:                            
	                                               SUB                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_ONE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_ONE_POWER

	STATE_TWO_LINE_ONE_NORMAL:                     
	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_TWO_LINE_ONE_POWER:                      
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	
	;-----------------------------------------------
	STATE_TWO_LINE_TWO:                            
	                                               ADD                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_TWO_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_TWO_POWER
	STATE_TWO_LINE_TWO_NORMAL:                     

	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER

	STATE_TWO_LINE_TWO_POWER:                      
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;------------------------------------------------
	STATE_TWO_LINE_THREE:                          
	                                               SUB                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_THREE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_THREE_POWER
	STATE_TWO_LINE_THREE_NORMAL:                   
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_THREE_POWER:                    
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	;------------------------------------------------------------
	STATE_TWO_LINE_FOUR_UP:                        
	                                               ADD                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_FOUR_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_FOUR_UP_POWER
	STATE_TWO_LINE_FOUR_UP_NORMAL:                 
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_FOUR_UP_POWER:                  
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	
	;---------------------------------------------------------------
	STATE_TWO_LINE_FOUR_DOWN:                      
	                                               SUB                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_FOUR_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_FOUR_DOWN_POWER
	STATE_TWO_LINE_FOUR_DOWN_NORMAL:               
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_FOUR_DOWN_POWER:                
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;---------------------------------------------------------------
	STATE_TWO_LINE_FIVE:                           
	                                               SUB                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_FIVE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_FIVE_POWER
	STATE_TWO_LINE_FIVE_NORMAL:                    
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_TWO_LINE_FIVE_POWER:                     
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	;--------------------------------------------------
	STATE_TWO_LINE_SIX:                            
                           
	                                               ADD                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_SIX_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_SIX_POWER
	STATE_TWO_LINE_SIX_NORMAL:                     
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_SIX_POWER:                      
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	

	;--------------------------------------------------
	STATE_TWO_LINE_SEVEN:                          
	                                               SUB                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_SEVEN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_SEVEN_POWER
	STATE_TWO_LINE_SEVEN_NORMAL:                   
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_SEVEN_POWER:                    
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	

	

	;-------------------------------------------------------
	STATE_TWO_LINE_EIGHT_UP:                       
	                                               ADD                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_EIGHT_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_EIGHT_UP_POWER
	STATE_TWO_LINE_EIGHT_UP_NORMAL:                
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_EIGHT_UP_POWER:                 
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
	;------------------------------------------------------

	STATE_TWO_LINE_EIGHT_DOWN:                     
	                                               SUB                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_TWO_LINE_EIGHT_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_TWO_LINE_EIGHT_DOWN_POWER
	STATE_TWO_LINE_EIGHT_DOWN_NORMAL:              
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_TWO_LINE_EIGHT_DOWN_POWER:               
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER

	;----------------------------------------------------------------------------------

	IN_STATE_THREE:                                
	                                               MOV                 [BX],4
	                                               CMP                 BP,1
	                                               JZ                  STATE_THREE_LINE_ONE
	                                               CMP                 BP,2
	                                               JZ                  STATE_THREE_LINE_TWO
	                                               CMP                 BP,3
	                                               JZ                  STATE_THREE_LINE_THREE
	                                               CMP                 BP,41
	                                               JZ                  STATE_THREE_LINE_FOUR_UP
	                                               CMP                 BP,42
	                                               JZ                  STATE_THREE_LINE_FOUR_DOWN
	                                               CMP                 BP,5
	                                               JZ                  STATE_THREE_LINE_FIVE
	                                               CMP                 BP,6
	                                               JZ                  STATE_THREE_LINE_SIX
	                                               CMP                 BP,7
	                                               JZ                  STATE_THREE_LINE_SEVEN
	                                               CMP                 BP,81
	                                               JZ                  STATE_THREE_LINE_EIGHT_UP
	                                               CMP                 BP,82
	                                               JZ                  STATE_THREE_LINE_EIGHT_DOWN
	                                              

	STATE_THREE_LINE_ONE:                          
	                                               SUB                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_ONE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_ONE_POWER

	STATE_THREE_LINE_ONE_NORMAL:                   
	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_THREE_LINE_ONE_POWER:                    
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	
	;-----------------------------------------------
	STATE_THREE_LINE_TWO:                          
	                                               ADD                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_TWO_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_TWO_POWER
	STATE_THREE_LINE_TWO_NORMAL:                   

	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER

	STATE_THREE_LINE_TWO_POWER:                    
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;------------------------------------------------
	STATE_THREE_LINE_THREE:                        
	                                               SUB                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_THREE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_THREE_POWER
	STATE_THREE_LINE_THREE_NORMAL:                 
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_THREE_POWER:                  
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	;------------------------------------------------------------
	STATE_THREE_LINE_FOUR_UP:                      
	                                               SUB                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_FOUR_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_FOUR_UP_POWER
	STATE_THREE_LINE_FOUR_UP_NORMAL:               
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_FOUR_UP_POWER:                
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	
	;---------------------------------------------------------------
	STATE_THREE_LINE_FOUR_DOWN:                    
	                                               ADD                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_FOUR_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_FOUR_DOWN_POWER
	STATE_THREE_LINE_FOUR_DOWN_NORMAL:             
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_FOUR_DOWN_POWER:              
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;---------------------------------------------------------------
	
	STATE_THREE_LINE_FIVE:                         
	                                               SUB                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_FIVE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_FIVE_POWER
	STATE_THREE_LINE_FIVE_NORMAL:                  
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_THREE_LINE_FIVE_POWER:                   
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	;--------------------------------------------------
	STATE_THREE_LINE_SIX:                          
                           
	                                               ADD                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_SIX_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_SIX_POWER
	STATE_THREE_LINE_SIX_NORMAL:                   
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_SIX_POWER:                    
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	

	;--------------------------------------------------
	STATE_THREE_LINE_SEVEN:                        
	                                               SUB                 DX,0
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_SEVEN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_SEVEN_POWER
	STATE_THREE_LINE_SEVEN_NORMAL:                 
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_SEVEN_POWER:                  
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	;--------------------------------------------------------------
	STATE_THREE_LINE_EIGHT_UP:                     
	                                               SUB                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_EIGHT_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_EIGHT_UP_POWER
	STATE_THREE_LINE_EIGHT_UP_NORMAL:              
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_EIGHT_UP_POWER:               
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
	;------------------------------------------------------

	STATE_THREE_LINE_EIGHT_DOWN:                   
	                                               ADD                 DX,32
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_THREE_LINE_EIGHT_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_THREE_LINE_EIGHT_DOWN_POWER
	STATE_THREE_LINE_EIGHT_DOWN_NORMAL:            
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_THREE_LINE_EIGHT_DOWN_POWER:             
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER

	;----------------------------------------------------------------------------------

	IN_STATE_FOUR:                                 
                                                              
	                                               MOV                 [BX],1
	                                               CMP                 BP,1
	                                               JZ                  STATE_FOUR_LINE_ONE
	                                               CMP                 BP,2
	                                               JZ                  STATE_FOUR_LINE_TWO
	                                               CMP                 BP,3
	                                               JZ                  STATE_FOUR_LINE_THREE
	                                               CMP                 BP,41
	                                               JZ                  STATE_FOUR_LINE_FOUR_UP
	                                               CMP                 BP,42
	                                               JZ                  STATE_FOUR_LINE_FOUR_DOWN
	                                               CMP                 BP,5
	                                               JZ                  STATE_FOUR_LINE_FIVE
	                                               CMP                 BP,6
	                                               JZ                  STATE_FOUR_LINE_SIX
	                                               CMP                 BP,7
	                                               JZ                  STATE_FOUR_LINE_SEVEN
	                                               CMP                 BP,81
	                                               JZ                  STATE_FOUR_LINE_EIGHT_UP
	                                               CMP                 BP,82
	                                               JZ                  STATE_FOUR_LINE_EIGHT_DOWN
	                                              

	STATE_FOUR_LINE_ONE:                           
	                                               ADD                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_ONE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_ONE_POWER

	STATE_FOUR_LINE_ONE_NORMAL:                    
	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_FOUR_LINE_ONE_POWER:                     
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	
	;-----------------------------------------------
	STATE_FOUR_LINE_TWO:                           
	                                               SUB                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_TWO_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_TWO_POWER
	STATE_FOUR_LINE_TWO_NORMAL:                    

	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER

	STATE_FOUR_LINE_TWO_POWER:                     
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;------------------------------------------------
	STATE_FOUR_LINE_THREE:                         
	                                               ADD                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_THREE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_THREE_POWER
	STATE_FOUR_LINE_THREE_NORMAL:                  
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_FOUR_LINE_THREE_POWER:                   
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	;------------------------------------------------------------
	STATE_FOUR_LINE_FOUR_UP:                       
	                                               SUB                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_FOUR_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_FOUR_UP_POWER
	STATE_FOUR_LINE_FOUR_UP_NORMAL:                
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_FOUR_LINE_FOUR_UP_POWER:                 
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	
	;---------------------------------------------------------------
	STATE_FOUR_LINE_FOUR_DOWN:                     
	                                               ADD                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_FOUR_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_FOUR_DOWN_POWER
	STATE_FOUR_LINE_FOUR_DOWN_NORMAL:              
	                                               

	                                               CALL                DRAW_LEFT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_FOUR_LINE_FOUR_DOWN_POWER:               
	                                               CALL                DRAW_LEFT_BIG_STICKER
	                                               JMP                 END_STICKER

	;---------------------------------------------------------------
	
	STATE_FOUR_LINE_FIVE:                          
	                                               ADD                 DX,42
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_FIVE_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_FIVE_POWER
	STATE_FOUR_LINE_FIVE_NORMAL:                   
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER
						
	STATE_FOUR_LINE_FIVE_POWER:                    
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	;--------------------------------------------------
	STATE_FOUR_LINE_SIX:                           
                           
	                                               SUB                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_SIX_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_SIX_POWER
	STATE_FOUR_LINE_SIX_NORMAL:                    
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_FOUR_LINE_SIX_POWER:                     
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       
	


	

	;--------------------------------------------------
	STATE_FOUR_LINE_SEVEN:                         
	                                               ADD                 DX,21
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_SEVEN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_SEVEN_POWER
	STATE_FOUR_LINE_SEVEN_NORMAL:                  
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER

	STATE_FOUR_LINE_SEVEN_POWER:                   
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
                                                       

	;--------------------------------------------------------------------------
	STATE_FOUR_LINE_EIGHT_UP:                      
	                                               SUB                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_EIGHT_UP_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_EIGHT_UP_POWER
	STATE_FOUR_LINE_EIGHT_UP_NORMAL:               
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_FOUR_LINE_EIGHT_UP_POWER:                
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER
	;------------------------------------------------------

	STATE_FOUR_LINE_EIGHT_DOWN:                    
	                                               ADD                 DX,31
	                                               MOV                 BX, OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX, DI
	                                               MOV                 [BX], DX
	                                               CMP                 AX,0
	                                               JZ                  STATE_FOUR_LINE_EIGHT_DOWN_NORMAL
	                                               CMP                 AX,1
	                                               JZ                  STATE_FOUR_LINE_EIGHT_DOWN_POWER
	STATE_FOUR_LINE_EIGHT_DOWN_NORMAL:             
	                                               

	                                               CALL                DRAW_RIGHT_SMALL_STICKER
	                                               JMP                 END_STICKER


						
	STATE_FOUR_LINE_EIGHT_DOWN_POWER:              
	                                               CALL                DRAW_RIGHT_BIG_STICKER
	                                               JMP                 END_STICKER

	;----------------------------------------------------------------------------------

	END_STICKER:                                   

	                                               ADD                 DI,2
	                                               DEC                 SI
	                                               JNZ                 LOOP_STICKERS


	END_DRAW_STICKERS:                             
	                                               RET

DRAW_STICKERS ENDP

DRAW_LEFT_SMALL_STICKER PROC
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               RET
DRAW_LEFT_SMALL_STICKER ENDP

DRAW_LEFT_BIG_STICKER PROC

	                                      
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA

	                                               ADD                 CX,11
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               RET

DRAW_LEFT_BIG_STICKER ENDP

DRAW_RIGHT_SMALL_STICKER PROC
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               RET

	                                               RET
DRAW_RIGHT_SMALL_STICKER ENDP

DRAW_RIGHT_BIG_STICKER PROC

	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

	                                               SUB                 CX,11
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

DRAW_RIGHT_BIG_STICKER ENDP

MOVING_OBSTACLES_STATES PROC
	                                           
	                                               CMP                 CURRENT_STATE_BLOCKS,1
	                                               JZ                  IN_STATE_ONE_O
	                                               CMP                 CURRENT_STATE_BLOCKS,2
	                                               JZ                  IN_STATE_TWO_O
	                                               CMP                 CURRENT_STATE_BLOCKS,3
	                                               JZ                  IN_STATE_THREE_O
	                                               CMP                 CURRENT_STATE_BLOCKS,4
	                                               JZ                  IN_STATE_FOUR_O

	IN_STATE_ONE_O:                                
	;ERASE
	
	                                               MOV                 BX,BACKGROUND_COLOR
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_ONE
	;REDRAW
	                                               MOV                 BX,BLOCK_COLOR_LC
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 BX,BLOCK_COLOR_RC
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_TWO

	                                               MOV                 CURRENT_STATE_BLOCKS,2
	                                               JMP                 END_STATES

	IN_STATE_TWO_O:                                
	;ERASE
	                                               MOV                 BX,BACKGROUND_COLOR
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_TWO
	;REDRAW
	                                               MOV                 BX,BLOCK_COLOR_LC
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 BX,BLOCK_COLOR_RC
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_THREE

	                                               MOV                 CURRENT_STATE_BLOCKS,3
	                                               JMP                 END_STATES

	IN_STATE_THREE_O:                              
	;ERASE
	                                               MOV                 BX,BACKGROUND_COLOR
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_THREE
	;REDRAW
	                                               MOV                 BX,BLOCK_COLOR_LC
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 BX,BLOCK_COLOR_RC
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_FOUR

	                                               MOV                 CURRENT_STATE_BLOCKS,4
	                                               JMP                 END_STATES
	IN_STATE_FOUR_O:                               
	;ERASE
	                                               MOV                 BX,BACKGROUND_COLOR
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_FOUR
	;REDRAW
	                                               MOV                 BX,BLOCK_COLOR_LC
	                                               MOV                 LEFT_OBSTACLES_BLOCK_COLOR,BX
	                                               MOV                 BX,BLOCK_COLOR_RC
	                                               MOV                 RIGHT_OBSTACLES_BLOCK_COLOR,BX
	                                               CALL                DRAW_BLOCKS_STATE_ONE

	                                               MOV                 CURRENT_STATE_BLOCKS,1
	                                               JMP                 END_STATES
	                                 
	END_STATES:                                    
	                                               RET
MOVING_OBSTACLES_STATES ENDP

CHECK_BUFFER_LEFT_PLAYER PROC

	NOT_EMPTY_LEFT:                                
	                                               MOV                 AH,1
	                                               INT                 16H

	                                               JZ                  NOT_EMPTY_OTHER
	                                               MOV                 AH,0
	                                               INT                 16H

	                                               MOV                 TEMP_ASCII,AL
	                                               MOV                 TEMP_SCAN,AH

	                                               CMP                 AH,3EH
	                                               JZ                  IS_F4_LEFT

	                                               CMP                 AH,3FH
	                                               JZ                  IS_F5_LEFT

	                                               CMP                 AL,77H
	                                               JZ                  W_KEY

	                                               CMP                 AL,73H
	                                               JZ                  S_KEY

	                                               CMP                 AL,71H
	                                               JZ                  Q_KEY

												   
	                                               CMP                 AL,65H
	                                               JZ                  E_KEY
	                                 
	                                               CMP                 AL,72H
	                                               JZ                  R_KEY

	                                               jmp                 NOT_EMPTY_LEFT
	IS_F4_LEFT:                                    
	                                               SENDCHAR            TEMP_SCAN

	                                               CALL                DRAW_BACKGROUND_BLACK

	                                               MOV                 AX,0
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71


	                                               MOV                 CX,PLAYER_1_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_CURRENT_SCORE
	                                               INT                 10H

	                                               MOV                 CX,PLAYER_2_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_CURRENT_SCORE
	                                               INT                 10H
								

	                                               MOV                 AH,86H
	                                               MOV                 CX,004CH
	                                               MOV                 DX,4B4AH
	                                               INT                 15H
	                                               
	                                               JMP                 BEFORE_GAME

	IS_F5_LEFT:                                    
	                                               SENDCHAR            TEMP_SCAN
	                                               CALL                ENTER_INLINE_CHATTING
	                                               JMP                 NOT_EMPTY_LEFT


	W_KEY:                                         
	                                               INC                 COUNT_PRESSES_W
	                                               SENDCHAR            TEMP_ASCII
	                                               JMP                 NOT_EMPTY_LEFT

	S_KEY:                                         
	                                               INC                 COUNT_PRESSES_S
	                                               SENDCHAR            TEMP_ASCII
	                                               JMP                 NOT_EMPTY_LEFT
	Q_KEY:                                         
	                                               INC                 COUNT_PRESSES_Q
	                                               SENDCHAR            TEMP_ASCII
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 RESET_LEFT_FIRE
	                                               JMP                 NOT_EMPTY_LEFT

	E_KEY:                                         
	                                               INC                 COUNT_PRESSES_E
	                                               SENDCHAR            TEMP_ASCII
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 RESET_LEFT_FIRE
	                                               JMP                 NOT_EMPTY_LEFT

	R_KEY:                                         
	                                               INC                 COUNT_PRESSES_R
	                                               SENDCHAR            TEMP_ASCII
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 RESET_LEFT_FIRE
	                                               JMP                 NOT_EMPTY_LEFT

	RESET_LEFT_FIRE:                               
	                                               MOV                 COUNT_PRESSES_Q,0
	                                               MOV                 COUNT_PRESSES_E,0
	                                               MOV                 COUNT_PRESSES_R,0
	                                               JMP                 NOT_EMPTY_LEFT

	NOT_EMPTY_OTHER:                               
	                                               RECEIVECHAR

	                                               JZ                  FINISHED_CHECK_OTHER_IF_RIGHT

	                                               CMP                 AL,3FH
	                                               JZ                  IS_F5_LEFT_OTHER

	                                               CMP                 AL,3EH
	                                               JZ                  IS_F4_OTHER

	                                               CMP                 AL,72D
	                                               JZ                  UP_KEY_OTHER

	                                               CMP                 AL,80D
	                                               JZ                  DOWN_KEY_OTHER

	                                               CMP                 AL,20H
	                                               JZ                  SPACE_KEY_OTHER
	                                 
	                                               CMP                 AL,6BH
	                                               JZ                  K_KEY_OTHER

	                                               CMP                 AL,6CH
	                                               JZ                  L_KEY_OTHER

	                                               JMP                 NOT_EMPTY_OTHER

	IS_F4_OTHER:                                   
	                                               CALL                DRAW_BACKGROUND_BLACK

	                                               MOV                 AX,0
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71


	                                               MOV                 CX,PLAYER_1_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_CURRENT_SCORE
	                                               INT                 10H

	                                               MOV                 CX,PLAYER_2_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_CURRENT_SCORE
	                                               INT                 10H
								

	                                               MOV                 AH,86H
	                                               MOV                 CX,004CH
	                                               MOV                 DX,4B4AH
	                                               INT                 15H
												   
	                                               JMP                 BEFORE_GAME

	IS_F5_LEFT_OTHER:                              

	                                               CALL                ENTER_INLINE_CHATTING
	                                               JMP                 NOT_EMPTY_OTHER

	UP_KEY_OTHER:                                  
	                                               INC                 COUNT_PRESSES_UP
	                                               JMP                 NOT_EMPTY_OTHER
	DOWN_KEY_OTHER:                                
	                                               INC                 COUNT_PRESSES_DOWN
	                                               JMP                 NOT_EMPTY_OTHER
	
	SPACE_KEY_OTHER:                               
	                                               INC                 COUNT_PRESSES_SPACE
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 RESET_RIGHT_FIRE
	                                               JMP                 NOT_EMPTY_OTHER



	K_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_K
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 RESET_RIGHT_FIRE
	                                               JMP                 NOT_EMPTY_OTHER

	L_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_L
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 RESET_RIGHT_FIRE
	                                               JMP                 NOT_EMPTY_OTHER
	

	RESET_RIGHT_FIRE_OTHER:                        
	                                               MOV                 COUNT_PRESSES_SPACE,0
	                                               MOV                 COUNT_PRESSES_K,0
	                                               MOV                 COUNT_PRESSES_L,0
	                                               JMP                 NOT_EMPTY_OTHER



	FINISHED_CHECK_OTHER_IF_RIGHT:                 
									

CHECK_BUFFER_LEFT_PLAYER ENDP

CHECK_BUFFER_RIGHT_PLAYER PROC

	NOT_EMPTY_RIGHT:                               
	                                               MOV                 AH,1
	                                               INT                 16H

	                                               JZ                  NOT_EMPTY_LEFT_OTHER
	                                               MOV                 AH,0
	                                               INT                 16H

	                                               MOV                 TEMP_ASCII,AL
	                                               MOV                 TEMP_SCAN,AH

	                                               CMP                 AH,3FH
	                                               JZ                  IS_F5_RIGHT

	                                               CMP                 AH,3EH
	                                               JZ                  IS_F4

	                                               CMP                 AH,72D
	                                               JZ                  UP_KEY

	                                               CMP                 AH,80D
	                                               JZ                  DOWN_KEY

	                                               CMP                 AL,20H
	                                               JZ                  SPACE_KEY
	                                 
	                                               CMP                 AL,6BH
	                                               JZ                  K_KEY

	                                               CMP                 AL,6CH
	                                               JZ                  L_KEY

	                                               JMP                 NOT_EMPTY_RIGHT

	IS_F4_RIGH:                                    

	                                               SENDCHAR            TEMP_SCAN

	                                               CALL                DRAW_BACKGROUND_BLACK

	                                               MOV                 AX,0
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71


	                                               MOV                 CX,PLAYER_1_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_CURRENT_SCORE
	                                               INT                 10H

	                                               MOV                 CX,PLAYER_2_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_CURRENT_SCORE
	                                               INT                 10H
								

	                                               MOV                 AH,86H
	                                               MOV                 CX,004CH
	                                               MOV                 DX,4B4AH
	                                               INT                 15H
	                                               JMP                 BEFORE_GAME

	IS_F5_RIGHT:                                   
	                                               SENDCHAR            TEMP_SCAN
	                                               CALL                ENTER_INLINE_CHATTING
	                                               JMP                 NOT_EMPTY_RIGHT

	UP_KEY:                                        
	                                               INC                 COUNT_PRESSES_UP
	                                               SENDCHAR            TEMP_SCAN
	                                               JMP                 NOT_EMPTY_RIGHT

	DOWN_KEY:                                      
	                                               INC                 COUNT_PRESSES_DOWN
	                                               SENDCHAR            TEMP_SCAN

	                                               JMP                 NOT_EMPTY_RIGHT
	
	SPACE_KEY:                                     
	                                               INC                 COUNT_PRESSES_SPACE
	                                               SENDCHAR            TEMP_ASCII
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 RESET_RIGHT_FIRE

	                                               JMP                 NOT_EMPTY_RIGHT



	K_KEY:                                         
	                                               INC                 COUNT_PRESSES_K
	                                               SENDCHAR            TEMP_ASCII
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 RESET_RIGHT_FIRE
												   
	                                               JMP                 NOT_EMPTY_RIGHT

	L_KEY:                                         
	                                               INC                 COUNT_PRESSES_L
	                                               SENDCHAR            TEMP_ASCII

	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 RESET_RIGHT_FIRE
	                                               JMP                 NOT_EMPTY_RIGHT
	

	RESET_RIGHT_FIRE:                              
	                                               MOV                 COUNT_PRESSES_SPACE,0
	                                               MOV                 COUNT_PRESSES_K,0
	                                               MOV                 COUNT_PRESSES_L,0
	                                               JMP                 NOT_EMPTY_RIGHT

	NOT_EMPTY_LEFT_OTHER:                          
	                                               RECEIVECHAR
	                                               JZ                  FINISHED_CHECK_OTHER_IF_LEFT
	                                               CMP                 AL,3FH
	                                               JZ                  IS_F5_OTHER

	                                               CMP                 AL,3EH
	                                               JZ                  IS_F4_OTHER

	                                               CMP                 AL,77H
	                                               JZ                  W_KEY_OTHER

	                                               CMP                 AL,73H
	                                               JZ                  S_KEY_OTHER

	                                               CMP                 AL,71H
	                                               JZ                  Q_KEY_OTHER

												   
	                                               CMP                 AL,65H
	                                               JZ                  E_KEY_OTHER
	                                 

	                                               CMP                 AL,72H
	                                               JZ                  R_KEY_OTHER
	                                               JMP                 NOT_EMPTY_LEFT_OTHER
	IS_F4:                                         
	                                               CALL                DRAW_BACKGROUND_BLACK

	                                               MOV                 AX,0
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71


	                                               MOV                 CX,PLAYER_1_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,10
	                                               MOV                 BP,OFFSET PLAYER_1_CURRENT_SCORE
	                                               INT                 10H

	                                               MOV                 CX,PLAYER_2_SCORE_LENGTH
	                                               MOV                 DL,15
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_SCORE
	                                               INT                 10H

	                                               MOV                 CX,2
	                                               MOV                 DL,22
	                                               MOV                 DH,15
	                                               MOV                 BP,OFFSET PLAYER_2_CURRENT_SCORE
	                                               INT                 10H
								

	                                               MOV                 AH,86H
	                                               MOV                 CX,004CH
	                                               MOV                 DX,4B4AH
	                                               INT                 15H
	                                               JMP                 BEFORE_GAME

	IS_F5_OTHER:                                   
	                                               CALL                ENTER_INLINE_CHATTING
	                                               JMP                 NOT_EMPTY_LEFT_OTHER

	W_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_W
	                                               JMP                 NOT_EMPTY_LEFT_OTHER
	S_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_S
	                                               JMP                 NOT_EMPTY_LEFT_OTHER
	Q_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_Q
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 RESET_LEFT_FIRE
	                                               JMP                 NOT_EMPTY_LEFT_OTHER

	E_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_E
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 RESET_LEFT_FIRE
	                                               JMP                 NOT_EMPTY_LEFT_OTHER

	R_KEY_OTHER:                                   
	                                               INC                 COUNT_PRESSES_R
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 RESET_LEFT_FIRE
	                                               JMP                 NOT_EMPTY_LEFT_OTHER

	RESET_LEFT_FIRE_OTHER:                         
	                                               MOV                 COUNT_PRESSES_Q,0
	                                               MOV                 COUNT_PRESSES_E,0
	                                               MOV                 COUNT_PRESSES_R,0
	                                               JMP                 NOT_EMPTY_LEFT_OTHER
	FINISHED_CHECK_OTHER_IF_LEFT:                  

	                                                                        


	                                               RET
CHECK_BUFFER_RIGHT_PLAYER ENDP

IDENTIFY_RIGHT_LINE PROC
	                                               POP                 BP                                                                         	; IP
	                                               POP                 DX                                                                         	; Y AXIS
	                                               POP                 CX                                                                         	; X AXIS
	                                               MOV                 BOOL_LINE_IDENTIFIED,1
	                                               MOV                 BX,OFFSET LINE_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	LINE_EIGHT:                                    
	                                               MOV                 AX,START_X_LINE_8
	                                               ADD                 AX,10
	                                               CMP                 CX,AX
	                                               JG                  LINE_SEVEN
	                                               CMP                 DX,START_Y_LINE_8_UP
	                                               JG                  LINE_EIGHT_DOWN
	                                               JMP                 LINE_EIGHT_UP
	LINE_EIGHT_UP:                                 
	                                               MOV                 [BX],81
	                                               JMP                 END_IDENTIFY_RIGHT
	LINE_EIGHT_DOWN:                               
	                                               
	                                               MOV                 [BX],82
	                                               JMP                 END_IDENTIFY_RIGHT

	LINE_SEVEN:                                    
	                                               MOV                 AX,START_X_LINE_7
	                                               ADD                 AX,10
	                                               CMP                 CX,AX
	                                               JG                  LINE_SIX
	                                               MOV                 [BX],7
	                                               JMP                 END_IDENTIFY_RIGHT
	LINE_SIX:                                      
	                                               MOV                 AX,START_X_LINE_6
	                                               ADD                 AX,10
	                                               CMP                 CX,AX
	                                               JG                  LINE_FIVE
	                                               MOV                 [BX],6
	                                               JMP                 END_IDENTIFY_RIGHT
	LINE_FIVE:                                     
	                                               MOV                 AX,START_X_LINE_5
	                                               ADD                 AX,10
	                                               CMP                 CX,AX
	                                               JG                  NOT_IDENTIFIED_RIGHT
	                                               MOV                 [BX],5
	                                               JMP                 END_IDENTIFY_RIGHT

	NOT_IDENTIFIED_RIGHT:                          
	                                               MOV                 BOOL_LINE_IDENTIFIED,0

	END_IDENTIFY_RIGHT:                            

	                                               PUSH                BP
	                                               RET
IDENTIFY_RIGHT_LINE ENDP

IDENTIFY_LEFT_LINE PROC
	                                               POP                 BP                                                                         	; IP
	                                               POP                 DX                                                                         	; Y AXIS
	                                               POP                 CX
	                                               MOV                 BX,OFFSET LINE_ARRAY_STICKERS
	                                               MOV                 BOOL_LINE_IDENTIFIED,1
	                                               ADD                 BX,COUNT_STICKERS                                                          	; X AXIS

	LINE_FOUR:                                     
	                                               MOV                 AX,START_X_LINE_4
	                                               CMP                 CX,AX
	                                               JL                  LINE_THREE
	                                               CMP                 DX,START_Y_LINE_4_UP
	                                               JG                  LINE_FOUR_DOWN
	                                               JMP                 LINE_FOUR_UP
	LINE_FOUR_UP:                                  
	                                               MOV                 [BX],41
	                                               JMP                 END_IDENTIFY_LEFT
	LINE_FOUR_DOWN:                                
	                                               
	                                               MOV                 [BX],42
	                                               JMP                 END_IDENTIFY_LEFT

	LINE_THREE:                                    
	                                               MOV                 AX,START_X_LINE_3
	                                               CMP                 CX,AX
	                                               JL                  LINE_TWO
	                                               MOV                 [BX],3
	                                               JMP                 END_IDENTIFY_LEFT

	LINE_TWO:                                      
	                                               MOV                 AX,START_X_LINE_2
	                                               CMP                 CX,AX
	                                               JL                  LINE_ONE
	                                               MOV                 [BX],2
	                                               JMP                 END_IDENTIFY_LEFT

	LINE_ONE:                                      
	                                               MOV                 BX,START_X_LINE_1
	                                               CMP                 CX,BX
	                                               JL                  NOT_IDENTIFIED_LEFT
	                                               MOV                 [BX],1
	                                               JMP                 END_IDENTIFY_LEFT

	NOT_IDENTIFIED_LEFT:                           
	                                               MOV                 BOOL_LINE_IDENTIFIED,0

	END_IDENTIFY_LEFT:                             



	                                               PUSH                BP
	                                               RET
IDENTIFY_LEFT_LINE ENDP

CHECK_FIRE_LEFT PROC

	                                 
	                                               CMP                 COUNT_PRESSES_E,0
	                                               JNZ                 E_PRESSED
	                                               CMP                 COUNT_PRESSES_Q,0
	                                               JNZ                 Q_PRESSED
	                                               CMP                 COUNT_PRESSES_R,0
	                                               JNZ                 R_PRESSED
	                                               JMP                 END_FIRE_LEFT

	E_PRESSED:                                     
	                                               DEC                 COUNT_PRESSES_E
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 END_FIRE_LEFT
	                                               CMP                 COUNT_NORMAL_AMUNITION_PLAYER_1,3030H
	                                               JZ                  END_FIRE_LEFT
	                                               MOV                 CX,START_CANON_LEFT_X_PLUS_LENGTH
	                                               ADD                 CX, 4
	                                               ADD                 CX, 5
	                                               MOV                 BX,START_CANON_LEFT_Y
	                                               ADD                 BX,10                                                                      	; TO GET CENTER OF CANON

	                                               MOV                 X_FIRE_LOC_LEFT,CX
	                                               MOV                 Y_FIRE_LOC_LEFT, BX
	;--
	                                               PUSH                BX
	                                               MOV                 BX, COUNT_NORMAL_AMUNITION_PLAYER_1
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_E
	                                               JNZ                 NORMAL_DEC_E

	DEC_HIGH_E:                                    
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_E

	NORMAL_DEC_E:                                  
												
	                                               DEC                 BH

	END_CALC_E:                                    
	                                               MOV                 COUNT_NORMAL_AMUNITION_PLAYER_1,BX
                                                   
	                                               POP                 BX
	                                               CMP                 COUNT_NORMAL_AMUNITION_PLAYER_1,3030H
	; JZ        END_FIRE_LEFT
	                                               JZ                  INDICATE_TIME_LEFT

	;--
	                                               MOV                 FIRED_LEFT_PLAYER,1
	                                               MOV                 XC,CX
	                                               MOV                 YC,BX
	                                               MOV                 R,5
	                                               MOV                 AL,COLOR_NORMAL_FIRE
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE
	                                               JMP                 END_FIRE_LEFT
	Q_PRESSED:                                     
	                                               DEC                 COUNT_PRESSES_Q
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 END_FIRE_LEFT
	                                               CMP                 COUNT_POWER_AMUNITION_PLAYER_1,3030H
	                                               JZ                  END_FIRE_LEFT
	                                 
	                                               MOV                 CX,START_CANON_LEFT_X_PLUS_LENGTH
	                                               ADD                 CX,4
	                                               MOV                 BX,START_CANON_LEFT_Y

	                                               MOV                 X_FIRE_LOC_LEFT,CX
	                                               MOV                 Y_FIRE_LOC_LEFT, BX
	;DEC       COUNT_POWER_AMUNITION_PLAYER_1
	;---
	                                               PUSH                BX
	                                               MOV                 BX, COUNT_POWER_AMUNITION_PLAYER_1
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_Q
	                                               JNZ                 POWER_DEC_Q

	DEC_HIGH_Q:                                    
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_Q

	POWER_DEC_Q:                                   
												
	                                               DEC                 BH

	END_CALC_Q:                                    
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_1,BX
                                                   
	                                               POP                 BX

	;--

	                                               MOV                 FIRED_LEFT_PLAYER,2
	                                               DRAWMACRO           IMG_BOMB_L,IMGW_B,IMGH_B, X_FIRE_LOC_LEFT ,Y_FIRE_LOC_LEFT ,W,H,J3
	                                               JMP                 END_FIRE_LEFT

	R_PRESSED:                                     


	                                               DEC                 COUNT_PRESSES_R
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JNZ                 END_FIRE_LEFT
	                                               CMP                 COUNT_SHIELD_AMUNITION_PLAYER_1,3030H
	                                               JZ                  END_FIRE_LEFT
	                                               MOV                 CX,START_CANON_LEFT_X_PLUS_LENGTH
	                                               ADD                 CX,4
	                                               MOV                 DX, START_CANON_LEFT_Y_PLUS_HEIGHT

	;DEC       COUNT_SHIELD_AMUNITION_PLAYER_1
	;------
	                                               PUSH                BX
	                                               MOV                 BX, COUNT_SHIELD_AMUNITION_PLAYER_1
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_R
	                                               JNZ                 SHIELD_DEC_R

	DEC_HIGH_R:                                    
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_R

	SHIELD_DEC_R:                                  
												
	                                               DEC                 BH

	END_CALC_R:                                    
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_1,BX
                                                   
	                                               POP                 BX


	;---------
	                                               MOV                 FIRED_LEFT_PLAYER,3

	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               MOV                 X_FIRE_LOC_LEFT,CX
	                                               MOV                 Y_FIRE_LOC_LEFT,DX
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               JMP                 END_FIRE_LEFT

	INDICATE_TIME_LEFT:                            
	                                               MOV                 AX,REFUEL_NORMAL_AMMUNITION_SEC
	                                               MOV                 TIME_LEFT_REFUEL_PLAYER_1,AX
	                                               MOV                 AH,2CH
	                                               INT                 21H
						
	                                               MOV                 PLAYER_1_PREVIOUS_SEC,DH

	END_FIRE_LEFT:                                 
	                                               RET
CHECK_FIRE_LEFT ENDP
	;

CHECK_FIRE_RIGHT PROC
	
	

	                                               CMP                 COUNT_PRESSES_SPACE,0
	                                               JNZ                 SPACE_PRESSED
	                                               CMP                 COUNT_PRESSES_K,0
	                                               JNZ                 K_PRESSED
	                                               CMP                 COUNT_PRESSES_L,0
	                                               JNZ                 L_PRESSED
	                                               JMP                 END_FIRE_RIGHT

	SPACE_PRESSED:                                 
	                                               DEC                 COUNT_PRESSES_SPACE
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 END_FIRE_RIGHT
	                                               CMP                 COUNT_NORMAL_AMUNITION_PLAYER_2,3030H
	                                               JZ                  END_FIRE_RIGHT

	                                               MOV                 CX, START_CANON_RIGHT_X
	                                               SUB                 CX,4
	                                               SUB                 CX,5
	                                               MOV                 BX,START_CANON_RIGHT_Y
	                                               ADD                 BX,10

	                                               MOV                 X_FIRE_LOC_RIGHT,CX
	                                               MOV                 Y_FIRE_LOC_RIGHT, BX
	;DEC       COUNT_NORMAL_AMUNITION_PLAYER_2
	;---
	                                               PUSH                BX
	                                               MOV                 BX, COUNT_NORMAL_AMUNITION_PLAYER_2
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_SPACE
	                                               JNZ                 NORMAL_DEC_SPACE

	DEC_HIGH_SPACE:                                
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_SPACE

	NORMAL_DEC_SPACE:                              
	                                               DEC                 BH

	END_CALC_SPACE:                                
	                                               MOV                 COUNT_NORMAL_AMUNITION_PLAYER_2,BX


	                                               POP                 BX
	                                               CMP                 COUNT_NORMAL_AMUNITION_PLAYER_2,3030H
	                                               JZ                  INDICATE_TIME_LEFT_2



	;----
												   
	                                               MOV                 FIRED_RIGHT_PLAYER,1
	                                               MOV                 XC,CX
	                                               MOV                 YC, BX
	                                               MOV                 R,5
	                                               MOV                 AL,COLOR_NORMAL_FIRE
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE
	                                               JMP                 END_FIRE_RIGHT
	                                 

	K_PRESSED:                                     
	                                               DEC                 COUNT_PRESSES_K
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 END_FIRE_RIGHT
	                                               CMP                 COUNT_POWER_AMUNITION_PLAYER_2,3030H
	                                               JZ                  END_FIRE_RIGHT
	                                 
	                                               MOV                 CX,START_CANON_RIGHT_X_PLUS_LENGTH
	                                               SUB                 CX,52
	                                               MOV                 BX,START_CANON_RIGHT_Y

	                                               MOV                 X_FIRE_LOC_RIGHT,CX
	                                               MOV                 Y_FIRE_LOC_RIGHT, BX
	;DEC       COUNT_POWER_AMUNITION_PLAYER_2
	;-----
	                                               PUSH                BX
	                                               MOV                 BX, COUNT_POWER_AMUNITION_PLAYER_2
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_K
	                                               JNZ                 NORMAL_DEC_K

	DEC_HIGH_K:                                    
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_K

	NORMAL_DEC_K:                                  
	                                               DEC                 BH

	END_CALC_K:                                    
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_2,BX
	                                               POP                 BX

	;---------
	                                               MOV                 FIRED_RIGHT_PLAYER,2
	                                               DRAWMACRO           IMG_BOMB_R,IMGW_B,IMGH_B, X_FIRE_LOC_RIGHT ,Y_FIRE_LOC_RIGHT ,W,H,J4
	                                               JMP                 END_FIRE_RIGHT

	L_PRESSED:                                     
	                                               DEC                 COUNT_PRESSES_L
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JNZ                 END_FIRE_RIGHT
	                                               CMP                 COUNT_SHIELD_AMUNITION_PLAYER_2,3030H
	                                               JZ                  END_FIRE_RIGHT
	                                               MOV                 CX,START_CANON_RIGHT_X
	                                               SUB                 CX,4
	                                               MOV                 DX, START_CANON_RIGHT_Y_PLUS_HEIGHT

	;DEC       COUNT_SHIELD_AMUNITION_PLAYER_2
	;---------
	                                               PUSH                BX
	                                               MOV                 BX, COUNT_SHIELD_AMUNITION_PLAYER_2
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_L
	                                               JNZ                 NORMAL_DEC_L

	DEC_HIGH_L:                                    
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_L

	NORMAL_DEC_L:                                  
	                                               DEC                 BH

	END_CALC_L:                                    
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_2,BX


	                                               POP                 BX

	;-----------------
	                                               MOV                 FIRED_RIGHT_PLAYER,3

	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               MOV                 X_FIRE_LOC_RIGHT,CX
	                                               MOV                 Y_FIRE_LOC_RIGHT,DX
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               JMP                 END_FIRE_RIGHT
	
	INDICATE_TIME_LEFT_2:                          
	                                               MOV                 AX,REFUEL_NORMAL_AMMUNITION_SEC
	                                               MOV                 TIME_LEFT_REFUEL_PLAYER_2,AX
	                                               MOV                 AH,2CH
	                                               INT                 21H
						
	                                               MOV                 PLAYER_2_PREVIOUS_SEC,DH

	END_FIRE_RIGHT:                                
	                                               RET
CHECK_FIRE_RIGHT ENDP

ERASE_POWER_LEFT_FIRE PROC
	;ERASE
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               MOV                 DI,20
	                                               MOV                 AH,0CH
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR


	LOOP_X_LEFT:                                   
	                                               MOV                 CX, X_FIRE_LOC_LEFT
	                                               MOV                 SI,20

	LOOP_Y_LEFT:                                   
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 SI
	                                               JNZ                 LOOP_Y_LEFT

	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_X_LEFT

	                                               RET
ERASE_POWER_LEFT_FIRE ENDP

ERASE_POWER_RIGHT_FIRE PROC
	;ERASE
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               MOV                 DI,20
	                                               MOV                 AH,0CH
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR


	LOOP_X_RIGHT:                                  
	                                               MOV                 CX, X_FIRE_LOC_RIGHT
	                                               MOV                 SI,20

	LOOP_Y_RIGHT:                                  
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 SI
	                                               JNZ                 LOOP_Y_RIGHT

	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_X_RIGHT

	                                               RET
ERASE_POWER_RIGHT_FIRE ENDP

MOVE_LEFT_FIRE PROC
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JZ                  END_MOVE_LEFT_FIRE
	                                               CMP                 FIRED_LEFT_PLAYER,1                                                        	; NORMAL FIRE
	                                               JZ                  PROCESS_NORMAL_LEFT_FIRE
	                                               CMP                 FIRED_LEFT_PLAYER,2
	                                               JZ                  PROCESS_POWER_LEFT_FIRE
	                                               CMP                 FIRED_LEFT_PLAYER,3
	                                               JZ                  PROCESS_SHIELD_LEFT_FIRE

	PROCESS_NORMAL_LEFT_FIRE:                      
	;ERASE
	                                               CALL                ERASE_CIRCLE_LEFT

	;IF SHIELDED NO REDRAW
	                                               CMP                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JZ                  LEFT_INTERSECTED
	;IF INTERSECTED EFFECT ONLY NO REDRAW
	                                               CALL                CHECK_INTERSECTION_OF_NORMAL_LEFT_FIRE
	                                               CMP                 BOOL_INTERSECTION_OF_LEFT_FIRE,1
	                                               JZ                  EFFECT_ON_NORMAL_LEFT_FIRE

	;IF NO INTERSECTION, DRAW IN NEW LOCATION
	                                               CMP                 END_SCREEN_LEFT_FIRE,1
	                                               JZ                  END_MOVE_LEFT_FIRE
	                                               ADD                 X_FIRE_LOC_LEFT,1
	                                               MOV                 CX,X_FIRE_LOC_LEFT
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               MOV                 XC,CX
	                                               MOV                 YC,DX
	                                               MOV                 R,5
	                                               MOV                 AL,BYTE PTR COLOR_NORMAL_FIRE
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE
	                                               JMP                 END_MOVE_LEFT_FIRE

	EFFECT_ON_NORMAL_LEFT_FIRE:                    
	                                               CALL                LEFT_NORMAL_FIRE_EFFECT
	                                               CALL                DRAW_RIGHT_CANON
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,0
	                                               JMP                 END_MOVE_LEFT_FIRE

	PROCESS_POWER_LEFT_FIRE:                       

	;ERASE
	                                               CALL                ERASE_POWER_LEFT_FIRE

	;IF SHIELDED , NO REDRAW
	                                               CMP                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JZ                  LEFT_INTERSECTED
	;IF INTERSECTED NO REDRAW BUT EFFECT
	                                               CALL                CHECK_INTERSECTION_OF_POWER_LEFT_FIRE
	                                               CMP                 BOOL_INTERSECTION_OF_LEFT_FIRE,1
	                                               JZ                  EFFECT_ON_POWER_LEFT_FIRE

	; IF NO INTERSECTION DRAW IN NEW LOCATION
	                                               CMP                 END_SCREEN_LEFT_FIRE,1
	                                               JZ                  END_MOVE_LEFT_FIRE
	                                               ADD                 X_FIRE_LOC_LEFT,1
	                                               DRAWMACRO           IMG_BOMB_L,IMGW_B,IMGH_B, X_FIRE_LOC_LEFT ,Y_FIRE_LOC_LEFT ,W,H,J5
	                                               JMP                 END_MOVE_LEFT_FIRE

	EFFECT_ON_POWER_LEFT_FIRE:                     
	                                               CALL                POWER_LEFT_EFFECT
	                                               CALL                DRAW_RIGHT_CANON
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,0
	                                               JMP                 END_MOVE_LEFT_FIRE

	PROCESS_SHIELD_LEFT_FIRE:                      
	;ERASE
	                                               PUSHA
	                                               MOV                 AX,BACKGROUND_COLOR
	                                               MOV                 CX,X_FIRE_LOC_LEFT
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	;IF SHIELDED NO REDRAW
	                                               CMP                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JZ                  LEFT_INTERSECTED
	;IF INTERSECTED NO REDRAW
	                                               CALL                CHECK_INTERSECTION_OF_SHIELD_LEFT_FIRE
	                                               CMP                 BOOL_INTERSECTION_OF_LEFT_FIRE,1
	                                               JZ                  EFFECT_ON_SHIELD_LEFT_FIRE
	;IF NO INTERSECTION REDRAW IN NEW LOCATION
	                                               ADD                 X_FIRE_LOC_LEFT,1
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               MOV                 CX,X_FIRE_LOC_LEFT
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               JMP                 END_MOVE_LEFT_FIRE

	EFFECT_ON_SHIELD_LEFT_FIRE:                    
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,0
	                                               JMP                 END_MOVE_LEFT_FIRE
	LEFT_INTERSECTED:                              
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,0
	                                               MOV                 FIRED_LEFT_PLAYER,0
	                                               JMP                 END_MOVE_LEFT_FIRE


	END_MOVE_LEFT_FIRE:                            
	                                               MOV                 END_SCREEN_LEFT_FIRE,0
	                                               RET
MOVE_LEFT_FIRE ENDP



MOVE_RIGHT_FIRE PROC
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JZ                  END_MOVE_RIGHT_FIRE

	                                               CMP                 FIRED_RIGHT_PLAYER,1
	                                               JZ                  PROCESS_NORMAL_RIGHT_FIRE
	                                               CMP                 FIRED_RIGHT_PLAYER,2
	                                               JZ                  PROCESS_POWER_RIGHT_FIRE
	                                               CMP                 FIRED_RIGHT_PLAYER,3
	                                               JZ                  PROCESS_SHIELD_RIGHT_FIRE



	PROCESS_NORMAL_RIGHT_FIRE:                     
	;ERASE
	                                               CALL                ERASE_CIRCLE_RIGHT
	; IF SHIELDED NO REDRAW
	                                               CMP                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JZ                  RIGHT_INTERSECTED

	;IF INTERSECTED --> DRAW THE EFFECT ONLY
	                                               CALL                CHECK_INTERSECTION_OF_NORMAL_RIGHT_FIRE
	                                               CMP                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1
	                                               JZ                  EFFECT_ON_NORMAL_RIGHT_FIRE
	;IF NO INTERSECTION REDRAW IN THE NEW LCATION
	                                               CMP                 END_SCREEN_RIGHT_FIRE,1
	                                               JZ                  END_MOVE_RIGHT_FIRE
	                                               SUB                 X_FIRE_LOC_RIGHT,1
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               MOV                 XC,CX
	                                               MOV                 YC,DX
	                                               MOV                 R,5
	                                               MOV                 AL,BYTE PTR COLOR_NORMAL_FIRE
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE
	                                               JMP                 END_MOVE_RIGHT_FIRE

	EFFECT_ON_NORMAL_RIGHT_FIRE:                   
	                                               CALL                RIGHT_NORMAL_FIRE_EFFECT
	                                               CALL                DRAW_LEFT_CANON
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,0
	                                               JMP                 END_MOVE_RIGHT_FIRE


	PROCESS_POWER_RIGHT_FIRE:                      
	                                               CALL                ERASE_POWER_RIGHT_FIRE
	;IF SHIELDED NO REDRAW
	                                               CMP                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JZ                  RIGHT_INTERSECTED

	;IF INTERSECTED DRAW EFFECT ONLY
	                                               CALL                CHECK_INTERSECTION_OF_POWER_RIGHT_FIRE
	                                               CMP                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1
	                                               JZ                  EFFECT_ON_POWER_RIGHT_FIRE

	; IF NO INTERSECTION DRAW IN NEW LOCATION
	                                               CMP                 END_SCREEN_RIGHT_FIRE,1
	                                               JZ                  END_MOVE_RIGHT_FIRE
	                                               SUB                 X_FIRE_LOC_RIGHT,1
	                                               DRAWMACRO           IMG_BOMB_L,IMGW_B,IMGH_B, X_FIRE_LOC_RIGHT ,Y_FIRE_LOC_RIGHT ,W,H,J6

	                                               JMP                 END_MOVE_RIGHT_FIRE

	EFFECT_ON_POWER_RIGHT_FIRE:                    
	                                               CALL                POWER_RIGHT_EFFECT
	                                               CALL                DRAW_LEFT_CANON
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,0
	                                               JMP                 END_MOVE_RIGHT_FIRE


	PROCESS_SHIELD_RIGHT_FIRE:                     
	;ERASE
	                                               PUSHA
	                                               MOV                 AX,BACKGROUND_COLOR
	                                               PUSH                AX
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	;IF SHIELDED NO REDRAW
	                                               CMP                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JZ                  RIGHT_INTERSECTED

	;IF INTERSECTED, ERASE WITH NO REDRAW
	                                               CALL                CHECK_INTERSECTION_OF_SHIELD_RIGHT_FIRE
	                                               CMP                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1
	                                               JZ                  EFFECT_ON_SHIELD_RIGHT_FIRE


	;REDRAW IN NEW LOCATION
	                                               SUB                 X_FIRE_LOC_RIGHT,1
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               JMP                 END_MOVE_RIGHT_FIRE

	EFFECT_ON_SHIELD_RIGHT_FIRE:                   
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,0
	                                               JMP                 END_MOVE_RIGHT_FIRE



	RIGHT_INTERSECTED:                             
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,0
	                                               MOV                 FIRED_RIGHT_PLAYER,0
	                                               JMP                 END_MOVE_RIGHT_FIRE

	END_MOVE_RIGHT_FIRE:                           
	                                               MOV                 END_SCREEN_RIGHT_FIRE,0
	                                               RET
MOVE_RIGHT_FIRE ENDP

POWER_LEFT_EFFECT PROC
	;ERASE
	                                               MOV                 DX,Y_POINT_OF_INTERSECTION_LEFT
	                                               MOV                 CX,X_POINT_OF_INTERSECTION_LEFT
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

	                                               ADD                 CX,10
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA


	                                               RET
POWER_LEFT_EFFECT ENDP

POWER_RIGHT_EFFECT PROC
	;ERASE
	                                               MOV                 DX,Y_POINT_OF_INTERSECTION_RIGHT
	                                               MOV                 CX,X_POINT_OF_INTERSECTION_RIGHT
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA

	                                               SUB                 CX,10
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA

	                                               RET
POWER_RIGHT_EFFECT ENDP

LEFT_NORMAL_FIRE_EFFECT PROC
	                                               MOV                 DX,Y_POINT_OF_INTERSECTION_LEFT
	                                               MOV                 CX,X_POINT_OF_INTERSECTION_LEFT
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               RET
LEFT_NORMAL_FIRE_EFFECT ENDP

RIGHT_NORMAL_FIRE_EFFECT PROC
	                                             
	                                               MOV                 DX,Y_POINT_OF_INTERSECTION_RIGHT
	                                               MOV                 CX,X_POINT_OF_INTERSECTION_RIGHT
	                                               MOV                 AH,0
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA

	                                               RET
RIGHT_NORMAL_FIRE_EFFECT ENDP

ERASE_CIRCLE_LEFT PROC
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               MOV                 CIRCLE_COLOR,AL
	                                               MOV                 CX,X_FIRE_LOC_LEFT
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               MOV                 XC,CX
	                                               MOV                 YC,DX
	                                               MOV                 R,5
	                                               CALL                DRAW_CIRCLE
	                                               RET
ERASE_CIRCLE_LEFT ENDP

ERASE_CIRCLE_RIGHT PROC
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               MOV                 CIRCLE_COLOR,AL
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               MOV                 XC,CX
	                                               MOV                 YC,DX
	                                               MOV                 R,5
	                                               CALL                DRAW_CIRCLE
	                                               RET
ERASE_CIRCLE_RIGHT ENDP

CHECK_INTERSECTION_OF_SHIELD_LEFT_FIRE PROC
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               MOV                 DI,20
	                                               MOV                 CX,X_FIRE_LOC_LEFT
	                                               ADD                 CX,11
	                                               MOV                 AH,0DH
	LOOP_Y_SHIELD_LEFT:                            
	                                               INT                 10H
	                                               CMP                 AL,HEALTH_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_SHIELD_LEFT_HEALTH
	                                               CMP                 AL,BOMB_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_SHIELD_LEFT_BOMB
	                                               CMP                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_SHIELD_LEFT_DEFENSE
	                                               
	                                               CMP                 CX, X_FIRE_LOC_RIGHT
	                                               JZ                  THERE_IS_INTERSECTION_SHIELD_LEFT
	                                               CMP                 CX,466D
	                                               JZ                  END_OF_SCREEN_LEFT
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_SHIELD_LEFT
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_LEFT

	INTERSECTION_SHIELD_LEFT_HEALTH:               
	;APPLY POWERUP
	                                               ADD                 HEALTH_PLAYER1 ,10
	;ERASE HEALTH
	                                               CALL                ERASE_HEALTH_POWERUP_FIRST
	                                               CALL                ERASE_HEALTH_POWERUP_SECOND
	                                               CALL                ERASE_HEALTH_POWERUP_THIRD

	;-------------------------------------------------------
	                                               CMP                 HEALTH_PLAYER1,100
	                                               JGE                 MAX_HEALTH_S_1
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_LEFT
	MAX_HEALTH_S_1:                                
	                                               MOV                 HEALTH_PLAYER1,100
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_LEFT

	INTERSECTION_SHIELD_LEFT_BOMB:                 

	;INCREMENT BOMB COUNT BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_S_1_B:                            

	                                               MOV                 AX,COUNT_POWER_AMUNITION_PLAYER_1
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_S_1_B
                                                
	                                               ADD                 COUNT_POWER_AMUNITION_PLAYER_1, 0100H
	                                               JMP                 CONTINUE_S_1_B

	INCREMENT_FIRST_DIGIT_1_S_1_B:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_1,AX
                                                

                                                
	CONTINUE_S_1_B:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_S_1_B

	                                               POP                 DI
	                                               POP                 AX

	;------------------------------------------------------------
	;ERASE BOMB
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y ,340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                ERASE_BOMB_POWERUP

	;-----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_LEFT
	INTERSECTION_SHIELD_LEFT_DEFENSE:              
	;INCREASE DEFENSE BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_S_1_D:                            

	                                               MOV                 AX,COUNT_SHIELD_AMUNITION_PLAYER_1
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_S_1_D
                                                
	                                               ADD                 COUNT_SHIELD_AMUNITION_PLAYER_1, 0100H
	                                               JMP                 CONTINUE_S_1_D

	INCREMENT_FIRST_DIGIT_1_S_1_D:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_1,AX
                                                

                                                
	CONTINUE_S_1_D:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_S_1_D

	                                               POP                 DI
	                                               POP                 AX

	;-----------------------------------------------
	;ERASE DEFENSE
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                   
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                  
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	                                               CALL                ERASE_DEFENSE_POWERUP
                                        
	;----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_LEFT




	THERE_IS_INTERSECTION_SHIELD_LEFT:             
	                                               CMP                 FIRED_RIGHT_PLAYER,0
	                                               JZ                  END_CHECK_INTERSECTION_SHIELD_LEFT
	                                               CMP                 FIRED_RIGHT_PLAYER,3
	                                               JZ                  END_CHECK_INTERSECTION_SHIELD_LEFT
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,1
	                                               MOV                 FIRED_LEFT_PLAYER,0
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_LEFT

	END_OF_SCREEN_LEFT:                            
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,1
	                                               MOV                 FIRED_LEFT_PLAYER,0

	END_CHECK_INTERSECTION_SHIELD_LEFT:            
	                                               RET



CHECK_INTERSECTION_OF_SHIELD_LEFT_FIRE ENDP

CHECK_INTERSECTION_OF_SHIELD_RIGHT_FIRE PROC
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               MOV                 DI,20
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               SUB                 CX,11
	                                               MOV                 AH,0DH

	LOOP_Y_SHIELD_RIGHT:                           
	                                               INT                 10H
	                                               CMP                 AL,HEALTH_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_SHIELD_RIGHT_HEALTH
	                                               CMP                 AL,BOMB_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_SHIELD_RIGHT_BOMB
	                                               CMP                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_SHIELD_RIGHT_DEFENSE
	                                               

	                                               CMP                 CX, X_FIRE_LOC_LEFT
	                                               JZ                  THERE_IS_INTERSECTION_SHIELD_RIGHT
	                                               CMP                 CX,174D
	                                               JZ                  END_OF_SCREEN_RIGHT
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_SHIELD_RIGHT
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_RIGHT


	INTERSECTION_SHIELD_RIGHT_HEALTH:              
	;APPLY POWERUP
	                                               ADD                 HEALTH_PLAYER2 ,10
	;ERASE HEALTH
	                                               CALL                ERASE_HEALTH_POWERUP_FIRST
	                                               CALL                ERASE_HEALTH_POWERUP_SECOND
	                                               CALL                ERASE_HEALTH_POWERUP_THIRD

	;-------------------------------------------------------
	                                               CMP                 HEALTH_PLAYER2,100
	                                               JGE                 MAX_HEALTH_S_2
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_RIGHT
	MAX_HEALTH_S_2:                                
	                                               MOV                 HEALTH_PLAYER2,100
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_RIGHT

	INTERSECTION_SHIELD_RIGHT_BOMB:                

	;INCREMENT BOMB COUNT BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_S_2_B:                            

	                                               MOV                 AX,COUNT_POWER_AMUNITION_PLAYER_2
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_S_2_B
                                                
	                                               ADD                 COUNT_POWER_AMUNITION_PLAYER_2, 0100H
	                                               JMP                 CONTINUE_S_2_B

	INCREMENT_FIRST_DIGIT_1_S_2_B:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_2,AX
                                                

                                                
	CONTINUE_S_2_B:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_S_2_B

	                                               POP                 DI
	                                               POP                 AX

	;------------------------------------------------------------
	;ERASE BOMB
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y ,340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                ERASE_BOMB_POWERUP

	;-----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_RIGHT
	INTERSECTION_SHIELD_RIGHT_DEFENSE:             
	;INCREASE DEFENSE BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_S_2_D:                            

	                                               MOV                 AX,COUNT_SHIELD_AMUNITION_PLAYER_2
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_S_2_D
                                                
	                                               ADD                 COUNT_SHIELD_AMUNITION_PLAYER_2, 0100H
	                                               JMP                 CONTINUE_S_2_D

	INCREMENT_FIRST_DIGIT_1_S_2_D:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_2,AX
                                                

                                                
	CONTINUE_S_2_D:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_S_2_D

	                                               POP                 DI
	                                               POP                 AX

	;-----------------------------------------------
	;ERASE DEFENSE
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                   
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                  
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	                                               CALL                ERASE_DEFENSE_POWERUP
                                        
	;----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_RIGHT







	THERE_IS_INTERSECTION_SHIELD_RIGHT:            
	                                               CMP                 FIRED_LEFT_PLAYER,0
	                                               JZ                  END_CHECK_INTERSECTION_SHIELD_RIGHT
	                                               CMP                 FIRED_LEFT_PLAYER,3
	                                               JZ                  END_CHECK_INTERSECTION_SHIELD_RIGHT
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1
	                                               MOV                 FIRED_RIGHT_PLAYER,0
	                                               JMP                 END_CHECK_INTERSECTION_SHIELD_RIGHT

	END_OF_SCREEN_RIGHT:                           
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1
	                                               MOV                 FIRED_RIGHT_PLAYER,0

	END_CHECK_INTERSECTION_SHIELD_RIGHT:           
	                                               RET
CHECK_INTERSECTION_OF_SHIELD_RIGHT_FIRE ENDP

CHECK_INTERSECTION_OF_POWER_LEFT_FIRE PROC
	;CHECK PIXEL COLORS IN THE NEXT LOCATION OF FIRE ( THE NEXT SQUARE )
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               INC                 DX
	                                               MOV                 CX,X_FIRE_LOC_LEFT
	                                               ADD                 CX,20

	                                               CMP                 CX,639
	                                               JZ                  END_SCREEN_POWER_LEFT
	                                               CMP                 CX,531
	                                               JZ                  CHECK_INTERSECTION_POWER_LEFT_KING
	END_CHECK_INTERSECTION_POWER_LEFT_KING:        


	                                               MOV                 DI,19
	                                               MOV                 AX,0D00H                                                                   	; FOR PIXEL COLOR

	LOOP_Y_LEFT_POWER_INTERSECTION:                
	                                               INT                 10H
	                                               CMP                 AL,BYTE PTR BLOCK_COLOR_RC                                                 	; AL STORES THE COLOR OF PIXEL
	                                               JZ                  THERE_IS_INTERSECTION_LEFT
	                                               CMP                 AL,BYTE PTR COLOR_CANON_RIGHT
	                                               JZ                  INTERSECTION_POWER_CANON_RIGHT
	                                               CMP                 AL,HEALTH_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_POWER_LEFT_HEALTH
	                                               CMP                 AL,BOMB_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_POWER_LEFT_BOMB
	                                               CMP                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_POWER_LEFT_DEFENSE

	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_LEFT_POWER_INTERSECTION
	                                               JMP                 END_CHECK_INTERSECTION_LEFT
	INTERSECTION_POWER_CANON_RIGHT:                
	                                               CALL                DRAW_RIGHT_CANON
	                                               JMP                 END_CHECK_INTERSECTION_LEFT

	INTERSECTION_POWER_LEFT_HEALTH:                
	;APPLY POWERUP
	                                               ADD                 HEALTH_PLAYER1 ,10
	;ERASE HEALTH
	                                               CALL                ERASE_HEALTH_POWERUP_FIRST
	                                               CALL                ERASE_HEALTH_POWERUP_SECOND
	                                               CALL                ERASE_HEALTH_POWERUP_THIRD

	;-------------------------------------------------------
	                                               CMP                 HEALTH_PLAYER1,100
	                                               JGE                 MAX_HEALTH_1_P
	                                               JMP                 END_CHECK_INTERSECTION_LEFT
	MAX_HEALTH_1_P:                                
	                                               MOV                 HEALTH_PLAYER1,100
	                                               JMP                 END_CHECK_INTERSECTION_LEFT

	INTERSECTION_POWER_LEFT_BOMB:                  

	;INCREMENT BOMB COUNT BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_P_1_B:                            

	                                               MOV                 AX,COUNT_POWER_AMUNITION_PLAYER_1
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_P_1_B
                                                
	                                               ADD                 COUNT_POWER_AMUNITION_PLAYER_1, 0100H
	                                               JMP                 CONTINUE_P_1_B

	INCREMENT_FIRST_DIGIT_1_P_1_B:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_1,AX
                                                

                                                
	CONTINUE_P_1_B:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_P_1_B

	                                               POP                 DI
	                                               POP                 AX

	;------------------------------------------------------------
	;ERASE BOMB
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y ,340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                ERASE_BOMB_POWERUP

	;-----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_LEFT
	INTERSECTION_POWER_LEFT_DEFENSE:               
	;INCREASE DEFENSE BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_P_1_D:                            

	                                               MOV                 AX,COUNT_SHIELD_AMUNITION_PLAYER_1
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_P_1_D
                                                
	                                               ADD                 COUNT_SHIELD_AMUNITION_PLAYER_1, 0100H
	                                               JMP                 CONTINUE_P_1_D

	INCREMENT_FIRST_DIGIT_1_P_1_D:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_1,AX
                                                

                                                
	CONTINUE_P_1_D:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_P_1_D

	                                               POP                 DI
	                                               POP                 AX

	;-----------------------------------------------
	;ERASE DEFENSE
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                   
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                  
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	                                               CALL                ERASE_DEFENSE_POWERUP
                                        
	;----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_LEFT





	THERE_IS_INTERSECTION_LEFT:                    
	; ANA DELWA2TI 3ANDI EL X FEL CX WEL Y FEL DX OF POINT OF INTERSECTION BAS MOMKEN TEB2A F AY 7ETA FEL BLOCK
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,1
	                                               MOV                 FIRED_LEFT_PLAYER,0
	                                               MOV                 DX, Y_FIRE_LOC_LEFT
	                                               ADD                 DX,19
	                                               MOV                 X_POINT_OF_INTERSECTION_LEFT,CX
	                                               MOV                 Y_POINT_OF_INTERSECTION_LEFT,DX
	                                               CMP                 FIRED_RIGHT_PLAYER,3
	                                               JZ                  THERE_IS_INTERSECTION_LEFT_WITH_SHIELD
	END_CHECK_INTERSECTION_POWER_SHIELD_LEFT:      
	;ADD       PLAYER_1_CURRENT_SCORE, 2
	                                               PUSH                AX
	                                               MOV                 AX,PLAYER_1_CURRENT_SCORE
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1
	                                               CMP                 AH,38H
	                                               JZ                  INCREMENT_FIRST_DIGIT_0
	                                               ADD                 PLAYER_1_CURRENT_SCORE, 0200H
	                                               JMP                 CONTINUE

	INCREMENT_FIRST_DIGIT_1:                       
	                                               INC                 AL
	                                               MOV                 AH,31H                                                                     	; EX: 19+2=21
	                                               MOV                 PLAYER_1_CURRENT_SCORE,AX
	                                               JMP                 CONTINUE

	INCREMENT_FIRST_DIGIT_0:                       
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 18+2=20
	                                               MOV                 PLAYER_1_CURRENT_SCORE,AX
	CONTINUE:                                      
	                                               POP                 AX

	;-------------------------------------------------
												   
	                                               PUSHA
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                IDENTIFY_RIGHT_LINE
	                                               POPA

	                                               CMP                 BOOL_LINE_IDENTIFIED,0
	                                               JZ                  END_CHECK_INTERSECTION_LEFT

	                                               MOV                 BX,OFFSET X_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],CX

	                                               MOV                 BX,OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],DX

	                                               MOV                 BX,OFFSET TYPE_OF_STICKER
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],1

	                                               MOV                 BX,OFFSET CURRENT_STATE_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 AX,CURRENT_STATE_BLOCKS
	                                               MOV                 [BX],AX

	                                               MOV                 BOOL_LINE_IDENTIFIED,0
	                                               ADD                 COUNT_STICKERS,2
	                                               JMP                 END_CHECK_INTERSECTION_LEFT

	THERE_IS_INTERSECTION_LEFT_WITH_SHIELD:        
	                                               MOV                 BX,Y_FIRE_LOC_RIGHT
	                                               SUB                 BX,20
	                                               CMP                 Y_FIRE_LOC_LEFT,BX                                                         	; YEB2A HOWA FO2O
	                                               JL                  END_CHECK_INTERSECTION_POWER_SHIELD_LEFT
	                                               MOV                 BX,Y_FIRE_LOC_RIGHT
	                                               CMP                 BX,Y_FIRE_LOC_LEFT                                                         	;SHELT MENO 11 W 19 W BARDO LESSA AKBAR MEN EL TANI , YEB2A HOWA TA7TO
	                                               JL                  END_CHECK_INTERSECTION_POWER_SHIELD_LEFT
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JMP                 END_CHECK_INTERSECTION_LEFT

	CHECK_INTERSECTION_POWER_LEFT_KING:            
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               CMP                 DX ,176
	                                               JG                  END_CHECK_INTERSECTION_NORMAL_LEFT_KING                                    	; EL TAL2A TA7T EL KING
	                                               ADD                 DX,19
	                                               CMP                 DX,134
	                                               JL                  END_CHECK_INTERSECTION_NORMAL_LEFT_KING                                    	; EL TAL2A FO2 EL KING
	                                               CMP                 HEALTH_PLAYER2,20
	                                               JLE                 WINNER_PLAYER_1
	                                               SUB                 HEALTH_PLAYER2,20
	                                               MOV                 HEALTH_PLAYER2_DECREASED,1
	END_SCREEN_POWER_LEFT:                         
	                                               MOV                 FIRED_LEFT_PLAYER,0
	                                               MOV                 END_SCREEN_LEFT_FIRE,1

	END_CHECK_INTERSECTION_LEFT:                   
	                                               RET
CHECK_INTERSECTION_OF_POWER_LEFT_FIRE ENDP

CHECK_INTERSECTION_OF_POWER_RIGHT_FIRE PROC
	;CHECK PIXEL COLORS IN THE NEXT LOCATION OF FIRE ( THE NEXT SQUARE )
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               INC                 DX
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               DEC                 CX
	                                               CMP                 CX,1
	                                               JZ                  END_SCREEN_POWER_RIGHT
	                                               CMP                 CX,109
	                                               JZ                  CHECK_INTERSECTION_POWER_RIGHT_KING
	END_CHECK_INTERSECTION_POWER_RIGHT_KING:       
	; BEC WE CHECK ON HE NEXT LOCATION OF FIRE
	                                               MOV                 DI,19
	                                               MOV                 AX,0D00H                                                                   	; FOR PIXEL COLOR

	LOOP_Y_RIGHT_POWER_INTERSECTION:               
	                                               INT                 10H
	                                               CMP                 AL,BYTE PTR BLOCK_COLOR_LC                                                 	; AL STORES THE COLOR OF PIXEL
	                                               JZ                  THERE_IS_INTERSECTION_RIGHT
	                                               CMP                 AL,BYTE PTR COLOR_CANON_LEFT
	                                               JMP                 INTERSECTION_POWER_CANON_LEFT
	                                               CMP                 AL,HEALTH_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_POWER_RIGHT_HEALTH
	                                               CMP                 AL,BOMB_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_POWER_RIGHT_BOMB
	                                               CMP                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_POWER_RIGHT_DEFENSE
	                                               
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_RIGHT_POWER_INTERSECTION
	                                               JMP                 END_CHECK_INTERSECTION_RIGHT

	INTERSECTION_POWER_CANON_LEFT:                 
	                                               CALL                DRAW_LEFT_CANON
	                                               JMP                 END_CHECK_INTERSECTION_RIGHT

	INTERSECTION_POWER_RIGHT_HEALTH:               
	;APPLY POWERUP
	                                               ADD                 HEALTH_PLAYER2 ,10
	;ERASE HEALTH
	                                               CALL                ERASE_HEALTH_POWERUP_FIRST
	                                               CALL                ERASE_HEALTH_POWERUP_SECOND
	                                               CALL                ERASE_HEALTH_POWERUP_THIRD

	;-------------------------------------------------------
	                                               CMP                 HEALTH_PLAYER2,100
	                                               JGE                 MAX_HEALTH_P_2
	                                               JMP                 END_CHECK_INTERSECTION_RIGHT
	MAX_HEALTH_P_2:                                
	                                               MOV                 HEALTH_PLAYER2,100
	                                               JMP                 END_CHECK_INTERSECTION_RIGHT

	INTERSECTION_POWER_RIGHT_BOMB:                 

	;INCREMENT BOMB COUNT BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_P_2_B:                            

	                                               MOV                 AX,COUNT_POWER_AMUNITION_PLAYER_2
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_P_2_B
                                                
	                                               ADD                 COUNT_POWER_AMUNITION_PLAYER_2, 0100H
	                                               JMP                 CONTINUE_P_2_B

	INCREMENT_FIRST_DIGIT_1_P_2_B:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_2,AX
                                                

                                                
	CONTINUE_P_2_B:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_P_2_B

	                                               POP                 DI
	                                               POP                 AX

	;------------------------------------------------------------
	;ERASE BOMB
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y ,340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                ERASE_BOMB_POWERUP

	;-----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_RIGHT
	INTERSECTION_POWER_RIGHT_DEFENSE:              
	;INCREASE DEFENSE BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_P_2_D:                            

	                                               MOV                 AX,COUNT_SHIELD_AMUNITION_PLAYER_2
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_P_2_D
                                                
	                                               ADD                 COUNT_SHIELD_AMUNITION_PLAYER_2, 0100H
	                                               JMP                 CONTINUE_P_2_D

	INCREMENT_FIRST_DIGIT_1_P_2_D:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_2,AX
                                                

                                                
	CONTINUE_P_2_D:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_P_2_D

	                                               POP                 DI
	                                               POP                 AX

	;-----------------------------------------------
	;ERASE DEFENSE
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                   
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                  
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	                                               CALL                ERASE_DEFENSE_POWERUP
                                        
	;----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_RIGHT





	THERE_IS_INTERSECTION_RIGHT:                   
	; ANA DELWA2TI 3ANDI EL X FEL CX WEL Y FEL DX OF POINT OF INTERSECTION BAS MOMKEN TEB2A F AY 7ETA FEL BLOCK
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1
	                                               MOV                 FIRED_RIGHT_PLAYER,0
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               ADD                 DX,19
	                                               MOV                 X_POINT_OF_INTERSECTION_RIGHT,CX
	                                               MOV                 Y_POINT_OF_INTERSECTION_RIGHT,DX
	                                               CMP                 FIRED_LEFT_PLAYER,3
	                                               JZ                  THERE_IS_INTERSECTION_RIGHT_WITH_SHIELD
	END_CHECK_INTERSECTION_POWER_SHIELD_RIGHT:     
	;ADD       PLAYER_2_CURRENT_SCORE,2
	                                               PUSH                AX
	                                               MOV                 AX,PLAYER_2_CURRENT_SCORE
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_2
	                                               CMP                 AH,38H
	                                               JZ                  INCREMENT_FIRST_DIGIT_0_2
	                                               ADD                 PLAYER_2_CURRENT_SCORE, 0200H
	                                               JMP                 CONTINUE_2

	INCREMENT_FIRST_DIGIT_1_2:                     
	                                               INC                 AL
	                                               MOV                 AH,31H                                                                     	; EX: 19+2=21
	                                               MOV                 PLAYER_2_CURRENT_SCORE,AX
	                                               JMP                 CONTINUE_2

	INCREMENT_FIRST_DIGIT_0_2:                     
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 18+2=20
	                                               MOV                 PLAYER_2_CURRENT_SCORE,AX
	CONTINUE_2:                                    
	                                               POP                 AX
	;--------------------------------------------------
	                                               PUSHA
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                IDENTIFY_LEFT_LINE
	                                               POPA
												   
	                                               CMP                 BOOL_LINE_IDENTIFIED,0
	                                               JZ                  END_CHECK_INTERSECTION_RIGHT

	                                               MOV                 BX,OFFSET X_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],CX

	                                               MOV                 BX,OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],DX

	                                               MOV                 BX,OFFSET TYPE_OF_STICKER
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],1

	                                               MOV                 BX,OFFSET CURRENT_STATE_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 AX,CURRENT_STATE_BLOCKS
	                                               MOV                 [BX],AX

	                                               ADD                 COUNT_STICKERS,2
	                                               MOV                 BOOL_LINE_IDENTIFIED,0

	                                               JMP                 END_CHECK_INTERSECTION_RIGHT

	THERE_IS_INTERSECTION_RIGHT_WITH_SHIELD:       
	                                               MOV                 BX,Y_FIRE_LOC_LEFT
	                                               SUB                 BX,20
	                                               CMP                 Y_FIRE_LOC_RIGHT,BX                                                        	; YEB2A HOWA FO2O
	                                               JL                  END_CHECK_INTERSECTION_POWER_SHIELD_RIGHT
	                                               MOV                 BX,Y_FIRE_LOC_RIGHT
	                                               CMP                 BX,Y_FIRE_LOC_RIGHT                                                        	;SHELT MENO 11 W 19 W BARDO LESSA AKBAR MEN EL TANI , YEB2A HOWA TA7TO
	                                               JL                  END_CHECK_INTERSECTION_POWER_SHIELD_RIGHT
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT
	CHECK_INTERSECTION_POWER_RIGHT_KING:           
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               CMP                 DX ,176
	                                               JG                  END_CHECK_INTERSECTION_POWER_RIGHT_KING                                    	; EL TAL2A TA7T EL KING
	                                               ADD                 DX,19
	                                               CMP                 DX,134
	                                               JL                  END_CHECK_INTERSECTION_POWER_RIGHT_KING                                    	; EL TAL2A FO2 EL KING
	                                               CMP                 HEALTH_PLAYER1,20
	                                               JLE                 WINNER_PLAYER_2
	                                               SUB                 HEALTH_PLAYER1,20
	                                               MOV                 HEALTH_PLAYER1_DECREASED,1

	END_SCREEN_POWER_RIGHT:                        
	                                               MOV                 FIRED_RIGHT_PLAYER,0
	                                               MOV                 END_SCREEN_RIGHT_FIRE,1

	END_CHECK_INTERSECTION_RIGHT:                  
	                                               RET

CHECK_INTERSECTION_OF_POWER_RIGHT_FIRE ENDP

CHECK_INTERSECTION_OF_NORMAL_LEFT_FIRE PROC

	                                               MOV                 CX, X_FIRE_LOC_LEFT
	                                               ADD                 CX,6
	                                               CMP                 CX,639
	                                               JZ                  END_SCREEN_NORMAL_LEFT
	                                               CMP                 CX,531
	                                               JZ                  CHECK_INTERSECTION_NORMAL_LEFT_KING
	END_CHECK_INTERSECTION_NORMAL_LEFT_KING:       
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               SUB                 DX,5
	                                               MOV                 AH,0DH
	                                               MOV                 DI,10
	LOOP_Y_LEFT_NORMAL_INTERSECTION:               

	                                               INT                 10H
	                                               CMP                 AL,BYTE PTR BLOCK_COLOR_RC
	                                               JZ                  THERE_IS_INTERSECTION_NORMAL_LEFT
	                                               CMP                 AL,BYTE PTR COLOR_CANON_RIGHT
	                                               JZ                  INTERSECTION_NORMAL_CANON_RIGHT

	                                               CMP                 AL,HEALTH_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_NORMAL_LEFT_HEALTH
	                                               CMP                 AL,BOMB_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_NORMAL_LEFT_BOMB
	                                               CMP                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_NORMAL_LEFT_DEFENSE
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_LEFT_NORMAL_INTERSECTION

	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT
	    
	INTERSECTION_NORMAL_CANON_RIGHT:               
	                                               CALL                DRAW_RIGHT_CANON
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT

	INTERSECTION_NORMAL_LEFT_HEALTH:               
	;APPLY POWERUP
	                                               ADD                 HEALTH_PLAYER1 ,10
	;ERASE HEALTH
	                                               CALL                ERASE_HEALTH_POWERUP_FIRST
	                                               CALL                ERASE_HEALTH_POWERUP_SECOND
	                                               CALL                ERASE_HEALTH_POWERUP_THIRD

	;-------------------------------------------------------
	                                               CMP                 HEALTH_PLAYER1,100
	                                               JGE                 MAX_HEALTH_1
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT
	MAX_HEALTH_1:                                  
	                                               MOV                 HEALTH_PLAYER1,100
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT


	INTERSECTION_NORMAL_LEFT_BOMB:                 

	;INCREMENT BOMB COUNT BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_1_B:                              

	                                               MOV                 AX,COUNT_POWER_AMUNITION_PLAYER_1
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_N_1_B
                                                
	                                               ADD                 COUNT_POWER_AMUNITION_PLAYER_1, 0100H
	                                               JMP                 CONTINUE_N_1_B

	INCREMENT_FIRST_DIGIT_1_N_1_B:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_1,AX
											    

												
	CONTINUE_N_1_B:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_1_B

	                                               POP                 DI
	                                               POP                 AX

	;------------------------------------------------------------
	;ERASE BOMB
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y ,340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                ERASE_BOMB_POWERUP

	;-----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT
	INTERSECTION_NORMAL_LEFT_DEFENSE:              
	;INCREASE DEFENSE BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_1_D:                              

	                                               MOV                 AX,COUNT_SHIELD_AMUNITION_PLAYER_1
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_N_1_D
                                                
	                                               ADD                 COUNT_SHIELD_AMUNITION_PLAYER_1, 0100H
	                                               JMP                 CONTINUE_N_1_D

	INCREMENT_FIRST_DIGIT_1_N_1_D:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_1,AX
											    

												
	CONTINUE_N_1_D:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_1_D

	                                               POP                 DI
	                                               POP                 AX


	;-----------------------------------------------
	;ERASE DEFENSE
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                ERASE_DEFENSE_POWERUP
	                                               
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	                                               CALL                ERASE_DEFENSE_POWERUP
	                                              
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	                                               CALL                ERASE_DEFENSE_POWERUP
	                                    
	;----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT

	THERE_IS_INTERSECTION_NORMAL_LEFT:             
	                                               MOV                 FIRED_LEFT_PLAYER,0
	                                               MOV                 BOOL_INTERSECTION_OF_LEFT_FIRE,1

	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               ADD                 DX,10
	                                               MOV                 X_POINT_OF_INTERSECTION_LEFT,CX                                            	; COORDINATES OF ERASED SQUARE
	                                               MOV                 Y_POINT_OF_INTERSECTION_LEFT,DX
	                                               CMP                 FIRED_RIGHT_PLAYER,3
	                                               JZ                  THERE_IS_INTERSECTION_LEFT_WITH_SHIELD

	END_CHECK_INTERSECTION_SHIELD_NORMAL_LEFT:     
	;ADD       PLAYER_1_CURRENT_SCORE,1
	                                               PUSH                AX
	                                               MOV                 AX,PLAYER_1_CURRENT_SCORE
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_N
                                                
	                                               ADD                 PLAYER_1_CURRENT_SCORE, 0100H
	                                               JMP                 CONTINUE_N

	INCREMENT_FIRST_DIGIT_1_N:                     
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 PLAYER_1_CURRENT_SCORE,AX
											    

												
	CONTINUE_N:                                    
	                                               POP                 AX
	;-------------------------------------------------------
	                                               SUB                 DX,5
	                                               PUSHA
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                IDENTIFY_RIGHT_LINE
	                                               POPA

	                                               CMP                 BOOL_LINE_IDENTIFIED,0
	                                               JZ                  END_CHECK_INTERSECTION_NORMAL_LEFT

	                                               MOV                 BX,OFFSET X_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],CX

	                                               MOV                 BX,OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],DX

	                                               MOV                 BX,OFFSET TYPE_OF_STICKER
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],0

	                                               MOV                 BX,OFFSET CURRENT_STATE_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 AX,CURRENT_STATE_BLOCKS
	                                               MOV                 [BX],AX

	                                               ADD                 COUNT_STICKERS,2
	                                               MOV                 BOOL_LINE_IDENTIFIED,0
												   
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT

	THERE_IS_INTERSECTION_LEFT_NORMAL_WITH_SHIELD: 
	                                               MOV                 BX,Y_FIRE_LOC_RIGHT
	                                               SUB                 BX,25
	                                               CMP                 Y_FIRE_LOC_LEFT,BX                                                         	; YEB2A HOWA FO2O
	                                               JL                  END_CHECK_INTERSECTION_SHIELD_NORMAL_LEFT
	                                               MOV                 BX,Y_FIRE_LOC_RIGHT
	                                               ADD                 BX,5
	                                               CMP                 BX,Y_FIRE_LOC_LEFT                                                         	;SHELT MENO 11 W 19 W BARDO LESSA AKBAR MEN EL TANI , YEB2A HOWA TA7TO
	                                               JL                  END_CHECK_INTERSECTION_SHIELD_NORMAL_LEFT
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_LEFT

	CHECK_INTERSECTION_NORMAL_LEFT_KING:           
	                                               MOV                 DX,Y_FIRE_LOC_LEFT
	                                               SUB                 DX,5
	                                               CMP                 DX ,176
	                                               JG                  END_CHECK_INTERSECTION_NORMAL_LEFT_KING                                    	; EL TAL2A TA7T EL KING
	                                               ADD                 DX,10
	                                               CMP                 DX,134
	                                               JL                  END_CHECK_INTERSECTION_NORMAL_LEFT_KING                                    	; EL TAL2A FO2 EL KING
	                                               CMP                 HEALTH_PLAYER2,10
	                                               JLE                 WINNER_PLAYER_1
	                                               SUB                 HEALTH_PLAYER2,10
	                                               MOV                 HEALTH_PLAYER2_DECREASED,1


	END_SCREEN_NORMAL_LEFT:                        
	                                               MOV                 FIRED_LEFT_PLAYER,0
	                                               MOV                 END_SCREEN_LEFT_FIRE,1
	
	END_CHECK_INTERSECTION_NORMAL_LEFT:            
	                                               RET
CHECK_INTERSECTION_OF_NORMAL_LEFT_FIRE ENDP

CHECK_INTERSECTION_OF_NORMAL_RIGHT_FIRE PROC
	                                               MOV                 CX,X_FIRE_LOC_RIGHT
	                                               SUB                 CX,6
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               SUB                 DX,5
	                                               CMP                 CX,1
	                                               JZ                  END_SCREEN_NORMAL_RIGHT
	                                               CMP                 CX,109
	                                               JZ                  CHECK_INTERSECTION_NORMAL_RIGHT_KING
	END_CHECK_INTERSECTION_NORMAL_RIGHT_KING:      
   
												   
	                                               MOV                 AH,0DH
	                                               MOV                 DI,10

	LOOP_Y_RIGHT_NORMAL_INTERSECTION:              
	                                               INT                 10H
	                                               CMP                 AL,BYTE PTR BLOCK_COLOR_LC
	                                               JZ                  THERE_IS_INTERSECTION_NORMAL_RIGHT
	                                               CMP                 AL,BYTE PTR COLOR_CANON_LEFT
	                                               JZ                  INTERSECTION_NORMAL_CANON_LEFT
	                                               CMP                 AL,HEALTH_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_NORMAL_RIGHT_HEALTH
	                                               CMP                 AL,BOMB_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_NORMAL_RIGHT_BOMB
	                                               CMP                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               JZ                  INTERSECTION_NORMAL_RIGHT_DEFENSE
	                                               
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_RIGHT_NORMAL_INTERSECTION
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT
	INTERSECTION_NORMAL_CANON_LEFT:                
	                                               CALL                DRAW_LEFT_CANON
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT
	    
	INTERSECTION_NORMAL_RIGHT_HEALTH:              
	;APPLY POWERUP
	                                               ADD                 HEALTH_PLAYER2 ,10
	;ERASE HEALTH
	                                               CALL                ERASE_HEALTH_POWERUP_FIRST
	                                               CALL                ERASE_HEALTH_POWERUP_SECOND
	                                               CALL                ERASE_HEALTH_POWERUP_THIRD

	;-------------------------------------------------------
	                                               CMP                 HEALTH_PLAYER2,100
	                                               JGE                 MAX_HEALTH_2
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT
	MAX_HEALTH_2:                                  
	                                               MOV                 HEALTH_PLAYER2,100
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT

	INTERSECTION_NORMAL_RIGHT_BOMB:                

	;INCREMENT BOMB COUNT BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_2_B:                              

	                                               MOV                 AX,COUNT_POWER_AMUNITION_PLAYER_2
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_N_2_B
                                                
	                                               ADD                 COUNT_POWER_AMUNITION_PLAYER_2, 0100H
	                                               JMP                 CONTINUE_N_2_B

	INCREMENT_FIRST_DIGIT_1_N_2_B:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_POWER_AMUNITION_PLAYER_2,AX
                                                

                                                
	CONTINUE_N_2_B:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_2_B

	                                               POP                 DI
	                                               POP                 AX

	;------------------------------------------------------------
	;ERASE BOMB
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250
	                                               CALL                ERASE_BOMB_POWERUP

	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y ,340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                ERASE_BOMB_POWERUP

	;-----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT
	INTERSECTION_NORMAL_RIGHT_DEFENSE:             
	;INCREASE DEFENSE BY 5
	                                               PUSH                AX
	                                               PUSH                DI
	                                               MOV                 DI,5
	REPEAT_COUNT_2_D:                              

	                                               MOV                 AX,COUNT_SHIELD_AMUNITION_PLAYER_2
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_N_2_D
                                                
	                                               ADD                 COUNT_SHIELD_AMUNITION_PLAYER_2, 0100H
	                                               JMP                 CONTINUE_N_2_D

	INCREMENT_FIRST_DIGIT_1_N_2_D:                 
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 COUNT_SHIELD_AMUNITION_PLAYER_2,AX
                                                

                                                
	CONTINUE_N_2_D:                                
	                                               DEC                 DI
	                                               JNZ                 REPEAT_COUNT_2_D

	                                               POP                 DI
	                                               POP                 AX

	;-----------------------------------------------
	;ERASE DEFENSE
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                   
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	                                               CALL                ERASE_DEFENSE_POWERUP
                                                  
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	                                               CALL                ERASE_DEFENSE_POWERUP
                                        
	;----------------------------------------------
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT




	THERE_IS_INTERSECTION_NORMAL_RIGHT:            
	                                               MOV                 FIRED_RIGHT_PLAYER,0
	                                               MOV                 BOOL_INTERSECTION_OF_RIGHT_FIRE,1

	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               ADD                 DX,10
	                                               MOV                 X_POINT_OF_INTERSECTION_RIGHT,CX
	                                               MOV                 Y_POINT_OF_INTERSECTION_RIGHT,DX
	                                               CMP                 FIRED_LEFT_PLAYER,3
	                                               JZ                  THERE_IS_INTERSECTION_RIGHT_NORMAL_WITH_SHIELD

	END_CHECK_INTERSECTION_SHIELD_NORMAL_RIGHT:    
	;ADD       PLAYER_2_CURRENT_SCORE,1
	                                               PUSH                AX
	                                               MOV                 AX,PLAYER_2_CURRENT_SCORE
	                                               CMP                 AH,39H
	                                               JZ                  INCREMENT_FIRST_DIGIT_1_N_2
                                                
	                                               ADD                 PLAYER_2_CURRENT_SCORE, 0100H
	                                               JMP                 CONTINUE_N_2

	INCREMENT_FIRST_DIGIT_1_N_2:                   
	                                               INC                 AL
	                                               MOV                 AH,30H                                                                     	; EX: 19+1=20
	                                               MOV                 PLAYER_2_CURRENT_SCORE,AX
											    

												
	CONTINUE_N_2:                                  
	                                               POP                 AX
	;----------------------------------------------------------
	                                               SUB                 DX,5
	                                               PUSHA
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                IDENTIFY_LEFT_LINE
	                                               POPA

	                                               CMP                 BOOL_LINE_IDENTIFIED,0
	                                               JZ                  END_CHECK_INTERSECTION_NORMAL_RIGHT

	                                               MOV                 BX,OFFSET X_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],CX

	                                               MOV                 BX,OFFSET Y_ARRAY_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],DX

	                                               MOV                 BX,OFFSET TYPE_OF_STICKER
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 [BX],0

	                                               MOV                 BX,OFFSET CURRENT_STATE_STICKERS
	                                               ADD                 BX,COUNT_STICKERS
	                                               MOV                 AX,CURRENT_STATE_BLOCKS
	                                               MOV                 [BX],AX

	                                               MOV                 BOOL_LINE_IDENTIFIED,0
	                                               ADD                 COUNT_STICKERS,2

	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT

	THERE_IS_INTERSECTION_RIGHT_NORMAL_WITH_SHIELD:
	                                               MOV                 BX,Y_FIRE_LOC_LEFT
	                                               SUB                 BX,25
	                                               CMP                 Y_FIRE_LOC_RIGHT,BX                                                        	; YEB2A HOWA FO2O
	                                               JL                  END_CHECK_INTERSECTION_SHIELD_NORMAL_RIGHT
	                                               MOV                 BX,Y_FIRE_LOC_RIGHT
	                                               ADD                 BX,5
	                                               CMP                 BX,Y_FIRE_LOC_RIGHT                                                        	;SHELT MENO 11 W 19 W BARDO LESSA AKBAR MEN EL TANI , YEB2A HOWA TA7TO
	                                               JL                  END_CHECK_INTERSECTION_SHIELD_NORMAL_RIGHT
	                                               MOV                 FLAG_SHIELD_FIRE_INTERSECTION,1
	                                               JMP                 END_CHECK_INTERSECTION_NORMAL_RIGHT

	CHECK_INTERSECTION_NORMAL_RIGHT_KING:          
	                                               MOV                 DX,Y_FIRE_LOC_RIGHT
	                                               SUB                 DX,5
	                                               CMP                 DX ,176
	                                               JG                  END_CHECK_INTERSECTION_NORMAL_RIGHT_KING                                   	; EL TAL2A TA7T EL KING
	                                               ADD                 DX,10
	                                               CMP                 DX,134
	                                               JL                  END_CHECK_INTERSECTION_NORMAL_RIGHT_KING                                   	; EL TAL2A FO2 EL KING
	                                               CMP                 HEALTH_PLAYER1,10
	                                               JLE                 WINNER_PLAYER_2
	                                               SUB                 HEALTH_PLAYER1,10
	                                               MOV                 HEALTH_PLAYER1_DECREASED,1


	END_SCREEN_NORMAL_RIGHT:                       
	                                               MOV                 FIRED_RIGHT_PLAYER,0
	                                               MOV                 END_SCREEN_RIGHT_FIRE,1

	END_CHECK_INTERSECTION_NORMAL_RIGHT:           
	                                               RET
CHECK_INTERSECTION_OF_NORMAL_RIGHT_FIRE ENDP

DRAW_AMMUNITION_SYMBOLS PROC

	;...........................................DRAW_BOMBS
	                                               DRAWMACRO           IMG_BOMB_L,IMGW_B,IMGH_B,X_BOMB_LEFT,Y_BOMB_LEFT,W,H,INDICATOR_LEFT_BOMB
	                                               DRAWMACRO           IMG_BOMB_R,IMGW_B,IMGH_B,X_BOMB_RIGHT,Y_BOMB_RIGHT,W,H,INDICATOR_RIGHT_BOMB
	;...........................................DRAW_TIMER

	                                               DRAWMACRO           IMG_CLK_L,IMGW_CLK,IMGH_CLK,X_CLK_LEFT,Y_CLK_LEFT,W,H,LEFT_CLK
	                                               DRAWMACRO           IMG_CLK_L,IMGW_CLK,IMGH_CLK,X_CLK_RIGHT,Y_CLK_RIGHT,W,H,RIGHT_CLK

	
	;...........................................DRAW_LEFT_CIRCLE
	                                               MOV                 CX, XC_NORM_LEFT
	                                               MOV                 XC,CX
	                                               MOV                 CX,YC_NORM_LEFT
	                                               MOV                 YC,CX
	                                               MOV                 R,5
	                                               MOV                 AL,COLOR_NORMAL_FIRE
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE

	;...........................................DRAW_RIGHT_CIRCLE
	                                               MOV                 CX, XC_NORM_RIGHT
	                                               MOV                 XC,CX
	                                               MOV                 CX,YC_NORM_RIGHT
	                                               MOV                 YC,CX
	                                               MOV                 R,5
	                                               MOV                 AL,COLOR_NORMAL_FIRE
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE

	;...........................................DRAW_LEFT_SHIELD
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               MOV                 CX, 25
	                                               PUSH                CX
	                                               MOV                 DX,47
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

	;...........................................DRAW_RIGHT_SHIELD
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                             
	                                               MOV                 CX,   489
	                                               PUSH                CX
	                                               MOV                 DX,47
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

	                                               RET
DRAW_AMMUNITION_SYMBOLS ENDP

REFUEL_NORMAL_INDICATOR_PLAYER_1 PROC

	                                              
	                                               CMP                 TIME_LEFT_REFUEL_PLAYER_1,3030H
	                                               JZ                  TERMINATE_1

	                                               MOV                 AH,2CH                                                                     	; TO GET CURRENT SEC
	                                               INT                 21H
												   
	                                               MOV                 BH,DH                                                                      	; DH= SEC , DL= SEC FRACTION (1/100
	                                               SUB                 DH,PLAYER_1_PREVIOUS_SEC
	                                               CMP                 DH, 1
	                                               MOV                 PLAYER_1_PREVIOUS_SEC,BH
	                                               JAE                 DECREMENT_TIME_LEFT
	                                               JMP                 TERMINATE_1

	DECREMENT_TIME_LEFT:                           
	;    MOV AX,0100H
	;    SUB TIME_LEFT_REFUEL_PLAYER_1,AX
                                                   
	                                               PUSH                BX
	                                               MOV                 BX, TIME_LEFT_REFUEL_PLAYER_1
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_T_1
	                                               JNZ                 NORMAL_DEC_T_1

	DEC_HIGH_T_1:                                  
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_T_1

	NORMAL_DEC_T_1:                                
	                                               DEC                 BH

	END_CALC_T_1:                                  
	                                               MOV                 TIME_LEFT_REFUEL_PLAYER_1,BX


	                                               POP                 BX
	                                               CMP                 TIME_LEFT_REFUEL_PLAYER_1,3030H
	                                               JZ                  IT_IS_TIME_1
	                                               JNZ                 TERMINATE_1
	                                          

												  
	IT_IS_TIME_1:                                                                                                                                 	; CURRENT TIME IS BELOW THE LIMIT
	                                               MOV                 AX,'02'                                                                    	; IT IS TIME TO REFUEL
	                                               MOV                 COUNT_NORMAL_AMUNITION_PLAYER_1,AX
	                                               JMP                 TERMINATE_1


	
	TERMINATE_1:                                   
	                                               RET
											   
REFUEL_NORMAL_INDICATOR_PLAYER_1 ENDP

REFUEL_NORMAL_INDICATOR_PLAYER_2 PROC

	                                              
	                                               CMP                 TIME_LEFT_REFUEL_PLAYER_2,3030H
	                                               JZ                  TERMINATE_2

	                                               MOV                 AH,2CH                                                                     	; TO GET CURRENT SEC
	                                               INT                 21H
												   
	                                               MOV                 BH,DH                                                                      	; DH= SEC , DL= SEC FRACTION (1/100
	                                               SUB                 DH,PLAYER_2_PREVIOUS_SEC
	                                               CMP                 DH, 1
	                                               MOV                 PLAYER_2_PREVIOUS_SEC,BH
	                                               JAE                 DECREMENT_TIME_LEFT_2
	                                               JMP                 TERMINATE_2

	DECREMENT_TIME_LEFT_2:                         
	;    MOV AX,0100H
	;    SUB TIME_LEFT_REFUEL_PLAYER_1,AX

	                                               PUSH                BX
	                                               MOV                 BX, TIME_LEFT_REFUEL_PLAYER_2
	                                               CMP                 BH,30H
	                                               JZ                  DEC_HIGH_T_2
	                                               JNZ                 NORMAL_DEC_T_2

	DEC_HIGH_T_2:                                  
	                                               DEC                 BL
	                                               MOV                 BH ,39H
	                                               JMP                 END_CALC_T_2

	NORMAL_DEC_T_2:                                
	                                               DEC                 BH

	END_CALC_T_2:                                  
	                                               MOV                 TIME_LEFT_REFUEL_PLAYER_2,BX


	                                               POP                 BX
	                                               CMP                 TIME_LEFT_REFUEL_PLAYER_2,3030H
	                                               JZ                  IT_IS_TIME_2
	                                               JNZ                 TERMINATE_2
	                                          

												  
	IT_IS_TIME_2:                                                                                                                                 	; CURRENT TIME IS BELOW THE LIMIT
	                                               MOV                 AX,'02'                                                                    	; IT IS TIME TO REFUEL
	                                               MOV                 COUNT_NORMAL_AMUNITION_PLAYER_2,AX
	                                               JMP                 TERMINATE_2


	
	TERMINATE_2:                                   
	                                               RET
											   
REFUEL_NORMAL_INDICATOR_PLAYER_2 ENDP
AMMUNITION_COUNT_INDICATOR PROC
	                                       
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,00111011B                                                               	; COLOR
                                                   
	;...........................................COUNT_PWR_LEFT
	                                               MOV                 CX,2                                                                       	; LENGTH OF STRING
	                                               MOV                 DL,6                                                                       	; X
	                                               MOV                 DH,2                                                                       	; Y
	                                               MOV                 BP,OFFSET COUNT_POWER_AMUNITION_PLAYER_1                                   	; OFFSET
                                                                                                                     	
	                                               
	                                               INT                 10H

	;...........................................COUNT_PWR_RIGHT
	                                               MOV                 CX,2
	                                               MOV                 DL,64
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET COUNT_POWER_AMUNITION_PLAYER_2
	                                               INT                 10H

	;...........................................COUNT_NORM_LEFT
	                                               MOV                 CX,2
	                                               MOV                 DL,12
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET COUNT_NORMAL_AMUNITION_PLAYER_1
	                                               INT                 10H


	;...........................................COUNT_NORM_RIGHT
	                                               MOV                 CX,2
	                                               MOV                 DL,70
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET COUNT_NORMAL_AMUNITION_PLAYER_2
	                                               INT                 10H


	;...........................................COUNT_SHIELD_LEFT
	                                               MOV                 CX,2
	                                               MOV                 DL,1
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET COUNT_SHIELD_AMUNITION_PLAYER_1
	                                               INT                 10H

	;...........................................COUNT_SHIELD_RIGHT
	                                               MOV                 CX,2
	; MOV       DL,75
	                                               MOV                 DL,59
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET COUNT_SHIELD_AMUNITION_PLAYER_2
	                                               INT                 10H


	;...........................................REFUEL INDICATOR FOR PLAYER 1
	                                               MOV                 CX,2
	                                               MOV                 DL,19
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET TIME_LEFT_REFUEL_PLAYER_1
	                                               INT                 10H


	;...........................................REFUEL INDICATOR FOR PLAYER 2
	                                               MOV                 CX,2
	; MOV       DL,58
	                                               MOV                 DL,77
	                                               MOV                 DH,2
	                                               MOV                 BP,OFFSET TIME_LEFT_REFUEL_PLAYER_2
	                                               INT                 10H



	                                               RET
AMMUNITION_COUNT_INDICATOR ENDP

DRAW_CIRCLE PROC
	                                               MOV                 X , 0
	                                               MOV                 Y , 0
	                                               MOV                 P , 0
	                                               MOV                 F,0
	                                               MOV                 N,0
	; READ CENTER(X,Y)
	                                
        
        
	;DRAW CIRCLE(MIDPOINT ALGORITHM)
	;Y=R
	                                               MOV                 AX,R
	                                               MOV                 Y,AX
        
	;PLOT INITIAL POINT
	                                               CALL                PLOT1
	;P=1-R
	                                               MOV                 AX,01
	                                               MOV                 DX,R
	                                               XOR                 DX,0FFFFH
	                                               INC                 DX
	                                               ADD                 AX,DX
	                                               MOV                 P,AX
        
	;WHILE(X<Y)
	LOOP1_C:                                       MOV                 AX,X
	                                               CMP                 AX,Y
	                                               JNC                 JUMP1_C
        
	;X++
	                                               INC                 X
        
	;IF(P<0)
	                                               MOV                 AX,P
	                                               RCL                 AX,01
	                                               JNC                 JUMP2_C
        
	;P+=2*X+1
	                                               MOV                 AX,X
	                                               RCL                 AX,01
	                                               INC                 AX
	                                               ADD                 AX,P
	                                               JMP                 JUMP3_C
        
	;ELSE
	;Y++
	;P+=2*(X-Y)+1;
	JUMP2_C:                                       DEC                 Y
	                                               MOV                 AX,X
	                                               MOV                 DX,Y
	                                               XOR                 DX,0FFFFH
	                                               INC                 DX
	                                               ADD                 AX,DX
	                                               RCL                 AX,01
	                                               JNC                 JUMP4_C
	                                               OR                  AX,8000H
	JUMP4_C:                                       INC                 AX
	                                               ADD                 AX,P
        
	JUMP3_C:                                       MOV                 P,AX
	;PLOT POINT
	                                               CALL                PLOT1
        
	                                               JMP                 LOOP1_C
	JUMP1_C:                                       

	                                               RET
DRAW_CIRCLE ENDP

DRAW_BACKGROUND_AND_DOORS PROC
	                                               MOV                 AH,0CH
	                                               MOV                 AL,BYTE PTR BACKGROUND_COLOR
	                                               MOV                 DX,23
	SQUARE_BACK:                                   

	                                               MOV                 CX,0

	LINE_BACK:                                     INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,640
	                                               JNZ                 LINE_BACK

	                                               INC                 DX

	                                               CMP                 DX,400
	                                               JNZ                 SQUARE_BACK

	                                               MOV                 AX,0C00H

	                                               MOV                 CX,63
	                                               MOV                 DX,336

	DRAW_DOOR_1_BIG:                               
	DRAW_DOOR_1:                                   
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,400
	                                               JNZ                 DRAW_DOOR_1

	                                               INC                 CX
	                                               MOV                 DX,336
	                                               CMP                 CX,110
	                                               JNZ                 DRAW_DOOR_1_BIG

	                                               MOV                 CX,530
	                                               MOV                 DX,336

	DRAW_DOOR_2_BIG:                               
	DRAW_DOOR_2:                                   
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,400
	                                               JNZ                 DRAW_DOOR_2

	                                               INC                 CX
	                                               MOV                 DX,336
	                                               CMP                 CX,578
	                                               JNZ                 DRAW_DOOR_2_BIG
	                                               RET

DRAW_BACKGROUND_AND_DOORS ENDP

CHECK_LEFT_CANON_MOVEMENT PROC
	                                               CMP                 COUNT_PRESSES_W,0
	                                               JNZ                 W_UP
	                                               CMP                 COUNT_PRESSES_S,0
	                                               JNZ                 S
	                                               JMP                 END_CHECK_MOVEMENT
	W_UP:                                          
	                                               DEC                 COUNT_PRESSES_W
	                                               JMP                 CHECK_RANGE_UP
	IN_RANGE_UP:                                   
	                                               MOV                 BX,BACKGROUND_COLOR
	                                               MOV                 COLOR_CANON_LEFT,BX
	                                               CALL                DRAW_LEFT_CANON


	                                               SUB                 START_CANON_LEFT_Y,24
	                                               SUB                 START_CANON_LEFT_Y_PLUS_HEIGHT,24


	                                               MOV                 COLOR_CANON_LEFT,8
	                                               CALL                DRAW_LEFT_CANON
	                                               JMP                 END_CHECK_MOVEMENT

								

	S:                                             
	                                               DEC                 COUNT_PRESSES_S
	                                               JMP                 CHECK_RANGE_DOWN

	IN_RANGE_DOWN:                                 
	                                               MOV                 BX,BACKGROUND_COLOR

	                                               MOV                 COLOR_CANON_LEFT,BX
	                                               CALL                DRAW_LEFT_CANON


	                                               ADD                 START_CANON_LEFT_Y,24
	                                               ADD                 START_CANON_LEFT_Y_PLUS_HEIGHT,24

	                                               MOV                 COLOR_CANON_LEFT,8
	                                               CALL                DRAW_LEFT_CANON
	                                               JMP                 END_CHECK_MOVEMENT

	CHECK_RANGE_DOWN:                              
	                                               CMP                 START_CANON_LEFT_Y_PLUS_HEIGHT,396
	                                               JNZ                 IN_RANGE_DOWN
	                                               JMP                 END_CHECK_MOVEMENT


	CHECK_RANGE_UP:                                
	                                               CMP                 START_CANON_LEFT_Y,112
	                                               JNZ                 IN_RANGE_UP
	                                               JMP                 END_CHECK_MOVEMENT

	                                     
	END_CHECK_MOVEMENT:                            

	                                               RET
CHECK_LEFT_CANON_MOVEMENT ENDP

CHECK_RIGHT_CANON_MOVEMENT PROC

	                                 
	                                               CMP                 COUNT_PRESSES_UP,0
	                                               JNZ                 UP
	                                               CMP                 COUNT_PRESSES_DOWN,0H
	                                               JNZ                 DOWN
	                                               JMP                 END_CHECK_MOVEMENT_RC
	UP:                                            
	                                               DEC                 COUNT_PRESSES_UP
	                                               JMP                 CHECK_RANGE_UP_RC
	IN_RANGE_UP_RC:                                
	                                               MOV                 BX,BACKGROUND_COLOR
	                                               MOV                 COLOR_CANON_RIGHT,BX
	                                               CALL                DRAW_RIGHT_CANON


	                                               SUB                 START_CANON_RIGHT_Y,24
	                                               SUB                 START_CANON_RIGHT_Y_PLUS_HEIGHT,24


	                                               MOV                 COLOR_CANON_RIGHT,8
	                                               CALL                DRAW_RIGHT_CANON
	                                               JMP                 END_CHECK_MOVEMENT_RC

								

	DOWN:                                          
	                                               DEC                 COUNT_PRESSES_DOWN
	                                               JMP                 CHECK_RANGE_DOWN_RC

	IN_RANGE_DOWN_RC:                              
	                                               MOV                 BX,BACKGROUND_COLOR

	                                               MOV                 COLOR_CANON_RIGHT,BX
	                                               CALL                DRAW_RIGHT_CANON


	                                               ADD                 START_CANON_RIGHT_Y,24
	                                               ADD                 START_CANON_RIGHT_Y_PLUS_HEIGHT,24

	                                               MOV                 COLOR_CANON_RIGHT,8
	                                               CALL                DRAW_RIGHT_CANON
	                                               JMP                 END_CHECK_MOVEMENT_RC

	CHECK_RANGE_DOWN_RC:                           
	                                               CMP                 START_CANON_RIGHT_Y_PLUS_HEIGHT,396
	                                               JNZ                 IN_RANGE_DOWN_RC
	                                               JMP                 END_CHECK_MOVEMENT_RC


	CHECK_RANGE_UP_RC:                             
	                                               CMP                 START_CANON_RIGHT_Y,112
	                                               JNZ                 IN_RANGE_UP_RC
	                                               JMP                 END_CHECK_MOVEMENT_RC
	END_CHECK_MOVEMENT_RC:                         

	                                               RET
CHECK_RIGHT_CANON_MOVEMENT ENDP

DRAW_INITAL_OBSTACLES PROC
	                                               MOV                 START_X_LINE_1,187
	                                               MOV                 START_Y_LINE_1,358

	                                               MOV                 START_X_LINE_2,209
	                                               MOV                 START_Y_LINE_2,337

	                                               MOV                 START_X_LINE_3,231
	                                               MOV                 START_Y_LINE_3,358

	                                               MOV                 START_X_LINE_4,253
	                                               MOV                 START_Y_LINE_4_UP,148
	                                               MOV                 START_Y_LINE_4_DOWN,400

	                                               MOV                 START_X_LINE_5,442
	                                               MOV                 START_Y_LINE_5,358

	                                               MOV                 START_X_LINE_6,420
	                                               MOV                 START_Y_LINE_6,337

	                                               MOV                 START_X_LINE_7,398
	                                               MOV                 START_Y_LINE_7,358

	                                               MOV                 START_X_LINE_8,376
	                                               MOV                 START_Y_LINE_8_UP,148
	                                               MOV                 START_Y_LINE_8_DOWN,400

	                                               CALL                DRAW_LEFT_OBSTACLES
	                                               CALL                DRAW_RIGHT_OBSTACLES
	                                               RET

DRAW_INITAL_OBSTACLES ENDP

DRAW_BLOCKS_STATE_ONE PROC

	                                               MOV                 START_Y_LINE_1,358

	                                               MOV                 START_Y_LINE_2,337

	                                               MOV                 START_Y_LINE_3,358

	                                               MOV                 START_Y_LINE_4_UP,148

	                                               MOV                 START_Y_LINE_4_DOWN,400

	                                               MOV                 START_Y_LINE_5,358

	                                               MOV                 START_Y_LINE_6,337

	                                               MOV                 START_Y_LINE_7,358

	                                               MOV                 START_Y_LINE_8_UP,148

	                                               MOV                 START_Y_LINE_8_DOWN,400

	                                               CALL                DRAW_LEFT_OBSTACLES
	                                               CALL                DRAW_RIGHT_OBSTACLES
	                                               RET
DRAW_BLOCKS_STATE_ONE ENDP

DRAW_BLOCKS_STATE_TWO PROC
	                                               MOV                 START_Y_LINE_1,400

	                                               MOV                 START_Y_LINE_2,337

	                                               MOV                 START_Y_LINE_3,358

	                                               MOV                 START_Y_LINE_4_UP,179
								
	                                               MOV                 START_Y_LINE_4_DOWN,369

	                                               MOV                 START_Y_LINE_5,400

	                                               MOV                 START_Y_LINE_6,337

	                                               MOV                 START_Y_LINE_7,358

	                                               MOV                 START_Y_LINE_8_UP,179
								
	                                               MOV                 START_Y_LINE_8_DOWN,369



	                                               CALL                DRAW_RIGHT_OBSTACLES
	                                               CALL                DRAW_LEFT_OBSTACLES
	                                               RET
DRAW_BLOCKS_STATE_TWO ENDP

DRAW_BLOCKS_STATE_THREE PROC

	                                               MOV                 START_Y_LINE_1,358

	                                               MOV                 START_Y_LINE_2,358

	                                               MOV                 START_Y_LINE_3,337

	                                               MOV                 START_Y_LINE_4_UP,211

	                                               MOV                 START_Y_LINE_4_DOWN,337

	                                               MOV                 START_Y_LINE_5,358

	                                               MOV                 START_Y_LINE_6,358

	                                               MOV                 START_Y_LINE_7,337

	                                               MOV                 START_Y_LINE_8_UP,211

	                                               MOV                 START_Y_LINE_8_DOWN,337


	                                               CALL                DRAW_RIGHT_OBSTACLES
	                                               CALL                DRAW_LEFT_OBSTACLES
	                                               RET
DRAW_BLOCKS_STATE_THREE ENDP

DRAW_BLOCKS_STATE_FOUR PROC
	                                               MOV                 START_Y_LINE_1,316

	                                               MOV                 START_Y_LINE_2,358

	                                               MOV                 START_Y_LINE_3,337

	                                               MOV                 START_Y_LINE_4_UP,179

	                                               MOV                 START_Y_LINE_4_DOWN,369

	                                               MOV                 START_Y_LINE_5,316

	                                               MOV                 START_Y_LINE_6,358

	                                               MOV                 START_Y_LINE_7,337

	                                               MOV                 START_Y_LINE_8_UP,179

	                                               MOV                 START_Y_LINE_8_DOWN,369

	                                               CALL                DRAW_RIGHT_OBSTACLES
	                                               CALL                DRAW_LEFT_OBSTACLES

	                                               RET
DRAW_BLOCKS_STATE_FOUR ENDP

DRAW_LEFT_OBSTACLES PROC

	; FIRST LINE
	                                               MOV                 CX,START_X_LINE_1
	                                               MOV                 DX,START_Y_LINE_1
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,21
	                                               MOV                 NUMBER_OF_BLOCKS, 14
	                                               MOV                 AX,LEFT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE

	;SECOND LINE
	                                               MOV                 CX,START_X_LINE_2
	                                               MOV                 DX,START_Y_LINE_2
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,42
	                                               MOV                 NUMBER_OF_BLOCKS,7
	                                               MOV                 AX,LEFT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE

	;THIRD LINE
	                                               MOV                 CX,START_X_LINE_3
	                                               MOV                 DX,START_Y_LINE_3
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,42
	                                               MOV                 NUMBER_OF_BLOCKS,7
	                                               MOV                 AX,LEFT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE

	; FOURTH LINE_DOWN
	                                               MOV                 CX, START_X_LINE_4
	                                               MOV                 DX, START_Y_LINE_4_DOWN
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,21
	                                               MOV                 NUMBER_OF_BLOCKS,6
	                                               MOV                 AX,LEFT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE
	; FOURTH LINE_UP
	                                               MOV                 CX, START_X_LINE_4
	                                               MOV                 DX, START_Y_LINE_4_UP
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,21
	                                               MOV                 NUMBER_OF_BLOCKS,6
	                                               MOV                 AX,LEFT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE
	                                               RET
DRAW_LEFT_OBSTACLES ENDP

DRAW_RIGHT_OBSTACLES PROC
	; FIFTH LINE
	                                               MOV                 CX,START_X_LINE_5
	                                               MOV                 DX,START_Y_LINE_5
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,21
	                                               MOV                 NUMBER_OF_BLOCKS, 14
	                                               MOV                 AX,RIGHT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE

	;SIXTH LINE
	                                               MOV                 CX,START_X_LINE_6
	                                               MOV                 DX,START_Y_LINE_6
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,42
	                                               MOV                 NUMBER_OF_BLOCKS,7
	                                               MOV                 AX,RIGHT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE

	;SEVENTH LINE
	                                               MOV                 CX,START_X_LINE_7
	                                               MOV                 DX,START_Y_LINE_7
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,42
	                                               MOV                 NUMBER_OF_BLOCKS,7
	                                               MOV                 AX,RIGHT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE

	; EIGTH LINE_DOWN
	                                               MOV                 CX, START_X_LINE_8
	                                               MOV                 DX, START_Y_LINE_8_DOWN
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,21
	                                               MOV                 NUMBER_OF_BLOCKS,6
	                                               MOV                 AX,RIGHT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE
	; EIGHT LINE_UP
	                                               MOV                 CX, START_X_LINE_8
	                                               MOV                 DX, START_Y_LINE_8_UP
	                                               MOV                 DISTANCE_BETWEEN_BLOCKS,21
	                                               MOV                 NUMBER_OF_BLOCKS,6
	                                               MOV                 AX,RIGHT_OBSTACLES_BLOCK_COLOR
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                DRAW_OBSTACLES_LINE
	                                               RET

DRAW_RIGHT_OBSTACLES ENDP

DRAW_LEFT_CANON PROC

	    
	;--------------------------------------------------------------------------------------------------
	; EL RECTANGE BETA3 AWEL MADFA3 (EL 3AL SHEMAL)
	                                               MOV                 AH,0CH
	                                               MOV                 AL,BYTE PTR COLOR_CANON_LEFT

	                                               MOV                 BX,START_CANON_LEFT_X
	                                               MOV                 DI,START_CANON_LEFT_X_PLUS_LENGTH
	                                               MOV                 DX,START_CANON_LEFT_Y
	SQUARE1_LC:                                    

	                                               MOV                 CX,BX

	LINE1_LC:                                      INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,DI
	                                               JNZ                 LINE1_LC

	                                               INC                 DX
	                                               CMP                 DX,START_CANON_LEFT_Y_PLUS_HEIGHT
	                                               JNZ                 SQUARE1_LC



	;--------------------------------------------------------------------------------------------------------
	; FAT7ET EL MADFA3 EL 3AL SHEMAL


	                                               MOV                 BX,START_CANON_LEFT_X_PLUS_LENGTH
	                                               ADD                 START_CANON_LEFT_X_PLUS_LENGTH,3
	                                               MOV                 DI,START_CANON_LEFT_X_PLUS_LENGTH
	                                               SUB                 START_CANON_LEFT_Y,4
	                                               MOV                 DX,START_CANON_LEFT_Y
	                                               ADD                 START_CANON_LEFT_Y_PLUS_HEIGHT,4
	SQUARE3_LC:                                    

	                                               MOV                 CX,BX

	LINE3_LC:                                      INT                 10H
	                                               INC                 CX
        
	                                               CMP                 CX,DI
        
	                                               JNZ                 LINE3_LC

	                                               INC                 DX

	                                               CMP                 DX,START_CANON_LEFT_Y_PLUS_HEIGHT
	                                               JNZ                 SQUARE3_LC
	                                               SUB                 START_CANON_LEFT_X_PLUS_LENGTH,3
	                                               ADD                 START_CANON_LEFT_Y,4
	                                               SUB                 START_CANON_LEFT_Y_PLUS_HEIGHT,4


	                                               RET
DRAW_LEFT_CANON ENDP

DRAW_RIGHT_CANON PROC


	                                               MOV                 AH,0CH
	                                               MOV                 AL,BYTE PTR COLOR_CANON_RIGHT


	;--------------------------------------------------------------------------------------------------
	; EL RECTANGE BETA3 AWEL MADFA3 (EL 3AL YEMIN)
	                                               MOV                 BX,START_CANON_RIGHT_X
	                                               MOV                 DI,START_CANON_RIGHT_X_PLUS_LENGTH
	                                               MOV                 DX,START_CANON_RIGHT_Y
	SQUARE1:                                       

	                                               MOV                 CX,BX

	LINE1:                                         INT                 10H
	                                               INC                 CX
        
	                                               CMP                 CX,DI
        
	                                               JNZ                 LINE1

	                                               INC                 DX
	                                               CMP                 DX,START_CANON_RIGHT_Y_PLUS_HEIGHT
	                                               JNZ                 SQUARE1



	;--------------------------------------------------------------------------------------------------------
	; FAT7ET EL MADFA3 EL 3AL YEMIN
 

	                                               MOV                 DI,START_CANON_RIGHT_X
	                                               SUB                 START_CANON_RIGHT_X,3
	                                               MOV                 BX,START_CANON_RIGHT_X
	                                               SUB                 START_CANON_RIGHT_Y,4
	                                               MOV                 DX,START_CANON_RIGHT_Y
	                                               ADD                 START_CANON_RIGHT_Y_PLUS_HEIGHT,4
	SQUARE3:                                       

	                                               MOV                 CX,BX

	LINE3:                                         INT                 10H
	                                               INC                 CX
        
	                                               CMP                 CX,DI
        
	                                               JNZ                 LINE3

	                                               INC                 DX

	                                               CMP                 DX,START_CANON_RIGHT_Y_PLUS_HEIGHT
	                                               JNZ                 SQUARE3

	                                               ADD                 START_CANON_RIGHT_X,3
	                                               ADD                 START_CANON_RIGHT_Y,4
	                                               SUB                 START_CANON_RIGHT_Y_PLUS_HEIGHT,4




	                                               RET
DRAW_RIGHT_CANON ENDP

STATUS_BAR PROC
	                                               PUSH                ES
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,00111011B

	                                               POP                 ES
	                                               MOV                 CX,NAME1ACTUALSIZE
	                                               MOV                 CH,0
	                                               MOV                 DL,15
	                                               MOV                 DH,0
	                                               MOV                 BP,OFFSET NAME1DATA
	                                               INT                 10H
	                                               PUSH                ES

	                                               POP                 ES
	                                               MOV                 CX,PLAYER_1_SCORE_LENGTH
	                                               MOV                 DL,27
	                                               MOV                 DH,0
	                                               MOV                 BP,OFFSET PLAYER_1_SCORE
	                                               INT                 10H
	                                               PUSH                ES

	                                               POP                 ES
	                                               MOV                 CX,2
	                                               MOV                 DL,34
	                                               MOV                 DH,0
	                                               MOV                 BP,OFFSET PLAYER_1_CURRENT_SCORE
	                                               INT                 10H
	                                               PUSH                ES


	                                               POP                 ES
	                                               MOV                 CX,NAME2ACTUALSIZE
	                                               MOV                 CH,0
	                                               MOV                 DL,45
	                                               MOV                 DH,0
	                                               MOV                 BP,OFFSET NAME2DATA
	                                               INT                 10H
	                                               PUSH                ES

	                                               POP                 ES
	                                               MOV                 CX,PLAYER_2_SCORE_LENGTH
	                                               MOV                 DL,57
	                                               MOV                 DH,0
	                                               MOV                 BP,OFFSET PLAYER_2_SCORE
	                                               INT                 10H
	                                               PUSH                ES

	                                               POP                 ES
	                                               MOV                 CX,2
	                                               MOV                 DL,64
	                                               MOV                 DH,0
	                                               MOV                 BP,OFFSET PLAYER_2_CURRENT_SCORE
	                                               INT                 10H
								



	                                               MOV                 AL, STARTING_X_1
	                                               MOV                 AH,0
	                                               MOV                 BL, ENDING_X_1
	                                               MOV                 BH,0
	                                               CALL                DRAW_HEALTH_BOX

	                                               MOV                 AX, STARTING_X_2
	                                               MOV                 BX, ENDING_X_2
	                                               CALL                DRAW_HEALTH_BOX
	;-------------------------------------------------------
	                                               PUSHA
	EMPTY_HEALTH_BAR_FOR_BOTH_PLAYERS:             
	                                               CMP                 HEALTH_PLAYER1_DECREASED,0
	                                               JZ                  END_ERASE_HEALTH_1
	                                               MOV                 AL,00H
	                                               MOV                 AH,0CH
	                                               MOV                 DX,3
	                                               MOV                 DI,17
	LOOP_Y_HEALTH_PLAYER_1:                        
	                                               MOV                 CX,WORD PTR STARTING_X_1
	                                               MOV                 CH,0
	                                               MOV                 SI,100

	LOOP_X_HEALTH_PLAYER_1:                        
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 SI
	                                               JNZ                 LOOP_X_HEALTH_PLAYER_1

	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_HEALTH_PLAYER_1
	                                               MOV                 HEALTH_PLAYER1_DECREASED,0
	END_ERASE_HEALTH_1:                            
	                                               CMP                 HEALTH_PLAYER2_DECREASED,0
	                                               JZ                  END_ERASE_HEALTH_2
	                                               MOV                 DX,3
	                                               MOV                 AL,00H
	                                               MOV                 AH,0CH
	                                               MOV                 DI,17


	LOOP_Y_HEALTH_PLAYER_2:                        
	                                               MOV                 CX,WORD PTR STARTING_X_2
	                                               MOV                 CH,0
	                                               MOV                 SI,100

	LOOP_X_HEALTH_PLAYER_2:                        
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 SI
	                                               JNZ                 LOOP_X_HEALTH_PLAYER_2
	                                               INC                 DX
	                                               DEC                 DI
	                                               JNZ                 LOOP_Y_HEALTH_PLAYER_2
	                                               MOV                 HEALTH_PLAYER2_DECREASED,0


	END_ERASE_HEALTH_2:                            

	                                               POPA
	;---------------------------------------------------
	                                               MOV                 CX,0
	                                               MOV                 CL, STARTING_X_1
	                                               INC                 CX
	                                               MOV                 BX, HEALTH_PLAYER1
	                                               CMP                 BX,0
	                                               JE                  PLAYER_1_HAS_NO_HEALTH

	DRAW_ALL_LINES_FOR_PLAYER_1:                   
	                                               PUSHA
	                                               CALL                DRAW_HEALTH_LINE
	                                               POPA
	                                               INC                 CX
	                                               DEC                 BX
	                                               CMP                 BX, 0
	                                               JNE                 DRAW_ALL_LINES_FOR_PLAYER_1


	PLAYER_1_HAS_NO_HEALTH:                        
	                                               MOV                 CX,0
	                                               MOV                 CX, STARTING_X_2
	                                               INC                 CX
	                                               MOV                 BX, HEALTH_PLAYER2
	                                               CMP                 BX,0
	                                               JE                  PLAYER_2_HAS_NO_HEALTH

	DRAW_ALL_LINES_FOR_PLAYER_2:                   PUSHA
	                                               CALL                DRAW_HEALTH_LINE
	                                               POPA
	                                               INC                 CX
	                                               DEC                 BX
	                                               CMP                 BX,0
	                                               JNE                 DRAW_ALL_LINES_FOR_PLAYER_2

	PLAYER_2_HAS_NO_HEALTH:                        
	                                               RET
STATUS_BAR ENDP

PRINT_PLAYER_NAME PROC
 
	                                               MOV                 AH,9
	                                               INT                 21H

	                                               RET
PRINT_PLAYER_NAME ENDP

DRAW_HEALTH_LINE PROC

	                                               MOV                 DX,3

	                                               MOV                 AL,04H
	                                               MOV                 AH,0CH

	LOOPSMALL:                                     
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,20D
	                                               JC                  LOOPSMALL

	                                               RET

DRAW_HEALTH_LINE ENDP

DRAW_HEALTH_BOX PROC
 

	                                               MOV                 CX,AX
	                                               MOV                 DX,2D
	                                               PUSH                AX

	                                               MOV                 AL,09H
	                                               MOV                 AH,0CH

	LOOP1_SB:                                      
	                                               INT                 10H
	                                               INC                 CX                                                                         	;DRAW THE UPPER HORIZONTAL LINE
	                                               CMP                 CX,BX
	                                               JC                  LOOP1_SB

	                                               POP                 AX
	                                               MOV                 CX, AX
	                                               MOV                 DX,2D

	                                               PUSH                AX

	                                               MOV                 AL,09H
	                                               MOV                 AH,0CH

	LOOP2:                                         
	                                               INT                 10H
	                                               INC                 DX                                                                         	;DRAW THE LEFT VERTICAL LINE
	                                               CMP                 DX,20D
	                                               JC                  LOOP2

	                                               MOV                 CX, BX
	                                               MOV                 DX,2D

	                                               MOV                 AL,09H
	                                               MOV                 AH,0CH

	LOOP3:                                         
	                                               INT                 10H
	                                               INC                 DX                                                                         	;DRAW THE RIGHT VERTICAL LINE
	                                               CMP                 DX,20D
	                                               JC                  LOOP3

	                                               POP                 AX

	                                               MOV                 CX, AX
	                                               MOV                 DX,20D

	                                               PUSH                AX

	                                               MOV                 AL,09H
	                                               MOV                 AH,0CH

	LOOP4:                                         
	                                               INT                 10H
	                                               INC                 CX                                                                         	;DRAW THE LOWER HORIZONTAL LINE
	                                               CMP                 CX,BX
	                                               JC                  LOOP4

	                                               POP                 AX

	                                               RET

DRAW_HEALTH_BOX ENDP

PLOT1 PROC
	                                               MOV                 AH,0CH
	                                               MOV                 AL,CIRCLE_COLOR
                
	                                               MOV                 CX,XC
	                                               ADD                 CX,X
	                                               MOV                 DX,YC
	                                               ADD                 DX,Y
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               ADD                 CX,X
	                                               MOV                 DX,YC
	                                               SUB                 DX,Y
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               SUB                 CX,X
	                                               MOV                 DX,YC
	                                               ADD                 DX,Y
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               SUB                 CX,X
	                                               MOV                 DX,YC
	                                               SUB                 DX,Y
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               ADD                 CX,Y
	                                               MOV                 DX,YC
	                                               ADD                 DX,X
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               ADD                 CX,Y
	                                               MOV                 DX,YC
	                                               SUB                 DX,X
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               SUB                 CX,Y
	                                               MOV                 DX,YC
	                                               ADD                 DX,X
	                                               INT                 10H
        
	                                               MOV                 CX,XC
	                                               SUB                 CX,Y
	                                               MOV                 DX,YC
	                                               SUB                 DX,X
	                                               INT                 10H
    
	                                               RET
PLOT1 ENDP

ONE_BLOCK_UP_TO_RIGHT PROC
	                                               POP                 BP                                                                         	; HOLDS IP
	                                               POP                 DX                                                                         	; DX HOLDS VALUE OF Y
	                                               POP                 CX                                                                         	; CX HOLDS VALUE OF X
	                                               POP                 AX
	                                               MOV                 BX,CX                                                                      	; BX HOLDS THE INITIAL VALUE OF X
	                                               MOV                 SI,HEIGHT
	                                               MOV                 AH,0CH                                                                     	;DRAW PIXEL
                    
	LOOP_ROW:                                      
	                                               MOV                 CX,BX                                                                      	; RETURN X TO ITS INITIAL VALUE
	                                               MOV                 DI,WIDTH
	LOOP_COLUMN:                                   
	                                               INT                 10H
	                                               INC                 CX                                                                         	; MOVE RIGHT
	                                               DEC                 DI
	                                               JNZ                 LOOP_COLUMN
	                                               DEC                 DX                                                                         	;MOVE UP
	                                               DEC                 SI
	                                               JNZ                 LOOP_ROW

	                                               PUSH                BP                                                                         	; RE PUSH IP
	                                               RET
ONE_BLOCK_UP_TO_RIGHT ENDP

ONE_BLOCK_UP_TO_LEFT PROC
	                                               POP                 BP                                                                         	; HOLDS IP
	                                               POP                 DX                                                                         	; DX HOLDS VALUE OF Y
	                                               POP                 CX                                                                         	; CX HOLDS VALUE OF X
	                                               POP                 AX
	                                               MOV                 BX,CX                                                                      	; BX HOLDS THE INITIAL VALUE OF X
	                                               MOV                 SI,HEIGHT
	                                               MOV                 AH,0CH                                                                     	;DRAW PIXEL
                    
	LOOP_ROW5:                                     
	                                               MOV                 CX,BX                                                                      	; RETURN X TO ITS INITIAL VALUE
	                                               MOV                 DI,WIDTH
	LOOP_COLUMN5:                                  
	                                               INT                 10H
	                                               DEC                 CX                                                                         	; MOVE LEFT
	                                               DEC                 DI
	                                               JNZ                 LOOP_COLUMN5
	                                               DEC                 DX                                                                         	;MOVE UP
	                                               DEC                 SI
	                                               JNZ                 LOOP_ROW5

	                                               PUSH                BP                                                                         	; RE PUSH IP
	                                               RET
ONE_BLOCK_UP_TO_LEFT ENDP

ONE_BLOCK_DOWN PROC
	                                               POP                 BP                                                                         	; PUSH IP
	                                               POP                 DX                                                                         	; DX HOLD VALUE OF Y
	                                               POP                 CX                                                                         	; CX HOLD VALUE OF X
	                                               POP                 AX
	                                               MOV                 BX,CX                                                                      	; BX HOLD THE INITIAL VALUE OF X
	                                               MOV                 SI,HEIGHT
                    
	LOOP_ROW1:                                     
	                                               MOV                 CX,BX                                                                      	; RETURN X TO ITS INITIAL VALUE
	                                               MOV                 DI,WIDTH
	LOOP_COLUMN1:                                  
	                                               MOV                 AH,0CH                                                                     	;DRAW PIXEL
	                                               INT                 10H
	                                               INC                 CX                                                                         	; MOVE RIGHT
	                                               DEC                 DI
	                                               JNZ                 LOOP_COLUMN1
	                                               INC                 DX                                                                         	;MOVE DOWN
	                                               DEC                 SI
	                                               JNZ                 LOOP_ROW1
	                                               PUSH                BP                                                                         	;RE-PUSH IP
	                                               RET
ONE_BLOCK_DOWN ENDP

ONE_BLOCK_RIGHT PROC

	                                               POP                 BP                                                                         	; HOLD IP
	                                               POP                 DX                                                                         	; DX HOLD VALUE OF Y
	                                               POP                 CX                                                                         	; CX HOLD VALUE OF X
	                                               POP                 AX
	                                               MOV                 BX,CX                                                                      	; BX HOLD THE INITIAL VALUE OF X
	                                               MOV                 SI,WIDTH
                    
	LOOP_ROW2:                                     
	                                               MOV                 CX,BX                                                                      	; RETURN X TO ITS INITIAL VALUE
	                                               MOV                 DI,HEIGHT
	LOOP_COLUMN2:                                  
	                                               MOV                 AH,0CH                                                                     	;DRAW PIXEL
	                                               INT                 10H
	                                               INC                 CX                                                                         	; MOVE RIGHT
	                                               DEC                 DI
	                                               JNZ                 LOOP_COLUMN2
	                                               DEC                 DX                                                                         	;MOVE UP
	                                               DEC                 SI
	                                               JNZ                 LOOP_ROW2

	                                               PUSH                BP                                                                         	; RE PUSH IP
	                                               RET
ONE_BLOCK_RIGHT ENDP

ONE_BLOCK_LEFT PROC
	                                               POP                 BP                                                                         	; HOLD IP
	                                               POP                 DX                                                                         	; DX HOLD VALUE OF Y
	                                               POP                 CX                                                                         	; CX HOLD VALUE OF X
	                                               POP                 AX
	                                               MOV                 BX,CX                                                                      	; BX HOLD THE INITIAL VALUE OF X
	                                               MOV                 SI,WIDTH
                    
	LOOP_ROW3:                                     
	                                               MOV                 CX,BX                                                                      	; RETURN X TO ITS INITIAL VALUE
	                                               MOV                 DI,HEIGHT
	LOOP_COLUMN3:                                  
	                                               MOV                 AH,0CH                                                                     	;DRAW PIXEL
	                                               INT                 10H
	                                               DEC                 CX                                                                         	; MOVE LEFT
	                                               DEC                 DI
	                                               JNZ                 LOOP_COLUMN3
	                                               DEC                 DX                                                                         	;MOVE UP
	                                               DEC                 SI
	                                               JNZ                 LOOP_ROW3

	                                               PUSH                BP                                                                         	; RE PUSH IP
	                                               RET
ONE_BLOCK_LEFT ENDP

DRAW_OBSTACLES_LINE PROC
	                                               POP                 BP
	                                               POP                 DX
	                                               POP                 CX
	                                               POP                 AX
	                                               MOV                 BX,CX
	                                               MOV                 DI, NUMBER_OF_BLOCKS                                                       	; HOLD THE NUMBER OF BLOCKS
								
	LOOP_OBSTACLE:                                 
	                                               MOV                 CX,BX
	                                               PUSHA
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
								
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

	                                               SUB                 DX,DISTANCE_BETWEEN_BLOCKS                                                 	; MOVE ONE UP
	                          
	                                               DEC                 DI
	                                               JNZ                 LOOP_OBSTACLE

	                                               PUSH                BP
	                                               RET
DRAW_OBSTACLES_LINE ENDP

DRAW_LEFT_CASTLE PROC
	                                               MOV                 CX,20                                                                      	; VALUE OF X
	                                               MOV                 DX,400                                                                     	; VALUE OF Y
	                                               MOV                 DI, CASTLE_HEIGHT_BLOCKS
	                                               MOV                 BL,0                                                                       	; COUNTS ITERATIONS
	                                               MOV                 BH,DOOR_HEIGHT_BLOCKS
	                                               INC                 BH
	                   


	LOOP_HEIGHT_CASTLE_LC:                         
	                  
	                                               MOV                 CX,20
	                                               CMP                 BL,0
	                                               JZ                  FIRST_ITERATION_LC
	                                               SUB                 DX, HEIGHT_PLUS_ONE                                                        	;MOVE ONE BLOCK UP VERTICAL
	                                               SUB                 DX, WIDTH_PLUS_ONE                                                         	; MOVED ONE BLOCK UP HORIZ
	FIRST_ITERATION_LC:                            
	                                               MOV                 SI, CASTLE_HALF_WIDTH_BLOCKS
	                                               MOV                 AL,3                                                                       	;THREE HALVES FOR WIDTH
	                                               CMP                 DX,202
	                                               JLE                 THERE_IS_KINGS_ROOM_LC
	                                               CMP                 BH,0
	                                               JZ                  LOOP_WIDTH_CASTLE_LC
	                                               DEC                 BH


	LOOP_WIDTH_CASTLE_LC:                          

	                                               PUSHA                                                                                          	; TO MAINTAIN VALUES IN REGISTERS
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               PUSH                CX                                                                         	; PUSH X VALUE FIRST
	                                               PUSH                DX                                                                         	; PUSH Y VALUE SECOND
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA

	                                               ADD                 CX,WIDTH_PLUS_ONE                                                          	; MOVE ONE BLOCK RIGHT

	                                               PUSHA                                                                                          	; TO MAINTAIN VALUES IN REGISTERS
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               PUSH                CX                                                                         	; PUSH Y VALUE SECOND
	                                               PUSH                DX                                                                         	; PUSH X VALUE FIRST
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
                       
	                                               SUB                 CX,WIDTH_PLUS_ONE                                                          	; MOVES BACK ONE BLOCK LEFT
	                                               SUB                 DX,HEIGHT_PLUS_ONE                                                         	; MOVE ONE BLOCK UP

	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_RIGHT
	                                               POPA

	                                               ADD                 DX,HEIGHT_PLUS_ONE                                                         	; MOVE ONE BLOCK DOWN
	                                               ADD                 CX,WIDTH_PLUS_ONE                                                          	; MOVE ONE BLOCK RIGHT
	                                               ADD                 CX,WIDTH_PLUS_ONE                                                          	; MOVE ONE BLOCK RIGHT
                        

	                                               SUB                 SI,2
	                                               JZ                  END_HALF_WIDTH_LC
	                                               JMP                 LOOP_WIDTH_CASTLE_LC

	LBL_LC:                                        
	                                               INC                 BL
	                                               DEC                 DI
	                                               JNZ                 LOOP_HEIGHT_CASTLE_LC
	                                               JMP                 END_CASTLE_LC
                    


	                   

	END_HALF_WIDTH_LC:                             
	                                               DEC                 AL
	                                               JZ                  LBL_LC

	                                               MOV                 SI, CASTLE_HALF_WIDTH_BLOCKS
	                                               CMP                 BH,0
	                                               JNZ                 THERE_IS_DOOR_LC


	                                               JMP                 LOOP_WIDTH_CASTLE_LC

	THERE_IS_DOOR_LC:                              
	                                               DEC                 AL
	                                               ADD                 CX,44
	                                               JMP                 LOOP_WIDTH_CASTLE_LC

	THERE_IS_KINGS_ROOM_LC:                        
	                                               MOV                 BH,DOOR_HEIGHT_BLOCKS
	                                               JMP                 LOOP_WIDTH_CASTLE_LC
	END_CASTLE_LC:                                 
	                                               MOV                 CX,10                                                                      	; RETURN TO INITAL POSITION
	                                               SUB                 DX,WIDTH_PLUS_ONE                                                          	; MOVE ONE UP
	                                               SUB                 DX,HEIGHT_PLUS_ONE
	                                               MOV                 SI,13                                                                      	; WIDTH
	                                               MOV                 BL,0                                                                       	; COUNTS BLOCKS

	UPPER1_LC:                                     
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               ADD                 CX,WIDTH_PLUS_ONE
	                                               INC                 BL
	                                               CMP                 BL,6
	                                               JZ                  THERE_IS_SPACE_LC
	LBL1_LC:                                       
	                                               DEC                 SI
	                                               JNZ                 UPPER1_LC
	                                               JMP                 END_UPPER1_LC


	THERE_IS_SPACE_LC:                             
	                                               ADD                 CX,WIDTH_PLUS_ONE
	                                               ADD                 CX,WIDTH_PLUS_ONE
	                                               DEC                 SI
	                                               JMP                 LBL1_LC

	END_UPPER1_LC:                                 
	                                               MOV                 CX,10
	                                               SUB                 DX,HEIGHT_PLUS_ONE
	                                               MOV                 SI,2
	                                               MOV                 DI,2

	UPPER2_LC:                                     
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               ADD                 CX,WIDTH_PLUS_ONE                                                          	; LEAVE ONE SPACE RIGHT
	                                               ADD                 CX,WIDTH_PLUS_ONE                                                          	; LEAVE ONE SPACE RIGHT
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_LC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_RIGHT
	                                               POPA
	                                               ADD                 CX,WIDTH_PLUS_ONE
	                                               DEC                 SI
	                                               JNZ                 UPPER2_LC

	                                               DEC                 DI
	                                               JZ                  END_UPPER_LC

	                                               ADD                 CX,WIDTH_PLUS_ONE
	                                               ADD                 CX,WIDTH_PLUS_ONE
	                                               MOV                 SI,2
	                                               JMP                 UPPER2_LC

	END_UPPER_LC:                                  

	                                               RET
DRAW_LEFT_CASTLE ENDP

DRAW_RIGHT_CASTLE PROC
	                                               MOV                 CX,620                                                                     	; VALUE OF X
	                                               MOV                 DX,400                                                                     	; VALUE OF Y
	                                               MOV                 DI, CASTLE_HEIGHT_BLOCKS
	                                               MOV                 BL,0                                                                       	; COUNTS ITERATIONS
	                                               MOV                 BH,DOOR_HEIGHT_BLOCKS
	                                               INC                 BH
	                   


	LOOP_HEIGHT_CASTLE_RC:                         
	                  
	                                               MOV                 CX,620
	                                               CMP                 BL,0
	                                               JZ                  FIRST_ITERATION_RC
	                                               SUB                 DX, HEIGHT_PLUS_ONE                                                        	;MOVE ONE BLOCK UP VERTICAL
	                                               SUB                 DX, WIDTH_PLUS_ONE                                                         	; MOVED ONE BLOCK UP HORIZ
	FIRST_ITERATION_RC:                            
	                                               MOV                 SI, CASTLE_HALF_WIDTH_BLOCKS
	                                               MOV                 AL,3                                                                       	;THREE HALVES FOR WIDTH
	                                               CMP                 DX,202
	                                               JLE                 THERE_IS_KINGS_ROOM_RC
	                                               CMP                 BH,0
	                                               JZ                  LOOP_WIDTH_CASTLE_RC
	                                               DEC                 BH


	LOOP_WIDTH_CASTLE_RC:                          

	                                               PUSHA                                                                                          	; TO MAINTAIN VALUES IN REGISTERS
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                               PUSH                CX                                                                         	; PUSH X VALUE FIRST
	                                               PUSH                DX                                                                         	; PUSH Y VALUE SECOND
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA

	                                               SUB                 CX,WIDTH_PLUS_ONE                                                          	; MOVE ONE BLOCK LEFT

	                                               PUSHA                                                                                          	; TO MAINTAIN VALUES IN REGISTERS
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                               PUSH                CX                                                                         	; PUSH Y VALUE SECOND
	                                               PUSH                DX                                                                         	; PUSH X VALUE FIRST
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
                       
	                                               ADD                 CX,WIDTH_PLUS_ONE                                                          	; MOVES BACK ONE BLOCK RIGHT
	                                               SUB                 DX,HEIGHT_PLUS_ONE                                                         	; MOVE ONE BLOCK UP

	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_LEFT
	                                               POPA

	                                               ADD                 DX,HEIGHT_PLUS_ONE                                                         	; MOVE ONE BLOCK DOWN
	                                               SUB                 CX,WIDTH_PLUS_ONE                                                          	; MOVE ONE BLOCK LEFT
	                                               SUB                 CX,WIDTH_PLUS_ONE                                                          	; MOVE ONE BLOCK LEFT
                        

	                                               SUB                 SI,2
	                                               JZ                  END_HALF_WIDTH_RC
	                                               JMP                 LOOP_WIDTH_CASTLE_RC

	LBL_RC:                                        
	                                               INC                 BL
	                                               DEC                 DI
	                                               JNZ                 LOOP_HEIGHT_CASTLE_RC
	                                               JZ                  END_CASTLE_RC
                    


	                   

	END_HALF_WIDTH_RC:                             
	                                               DEC                 AL
	                                               JZ                  LBL_RC

	                                               MOV                 SI, CASTLE_HALF_WIDTH_BLOCKS
	                                               CMP                 BH,0
	                                               JNZ                 THERE_IS_DOOR_RC


	                                               JMP                 LOOP_WIDTH_CASTLE_RC

	THERE_IS_DOOR_RC:                              
	                                               DEC                 AL
	                                               SUB                 CX,44
	                                               JMP                 LOOP_WIDTH_CASTLE_RC

	THERE_IS_KINGS_ROOM_RC:                        
	                                               MOV                 BH,DOOR_HEIGHT_BLOCKS
	                                               JMP                 LOOP_WIDTH_CASTLE_RC
	END_CASTLE_RC:                                 
	                                               MOV                 CX,630                                                                     	; RETURN TO INITAL POSITION
	                                               SUB                 DX,WIDTH_PLUS_ONE                                                          	; MOVE ONE UP
	                                               SUB                 DX,HEIGHT_PLUS_ONE
	                                               MOV                 SI,13                                                                      	; WIDTH
	                                               MOV                 BL,0                                                                       	; COUNTS BLOCKS

	UPPER1_RC:                                     
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               SUB                 CX,WIDTH_PLUS_ONE
	                                               INC                 BL
	                                               CMP                 BL,6
	                                               JZ                  THERE_IS_SPACE_RC
	LBL1_RC:                                       
	                                               DEC                 SI
	                                               JNZ                 UPPER1_RC
	                                               JMP                 END_UPPER1_RC


	THERE_IS_SPACE_RC:                             
	                                               SUB                 CX,WIDTH_PLUS_ONE
	                                               SUB                 CX,WIDTH_PLUS_ONE
	                                               DEC                 SI
	                                               JMP                 LBL1_RC

	END_UPPER1_RC:                                 
	                                               MOV                 CX,630
	                                               SUB                 DX,HEIGHT_PLUS_ONE
	                                               MOV                 SI,2
	                                               MOV                 DI,2

	UPPER2_RC:                                     
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               SUB                 CX,WIDTH_PLUS_ONE                                                          	; LEAVE ONE SPACE LEFT
	                                               SUB                 CX,WIDTH_PLUS_ONE                                                          	; LEAVE ONE SPACE LEFT
	                                               PUSHA
	                                               MOV                 AX,BLOCK_COLOR_RC
	                                               PUSH                AX
	                                               PUSH                CX
	                                               PUSH                DX
	                                               CALL                ONE_BLOCK_UP_TO_LEFT
	                                               POPA
	                                               SUB                 CX,WIDTH_PLUS_ONE
	                                               DEC                 SI
	                                               JNZ                 UPPER2_RC
	                                               DEC                 DI
	                                               JZ                  END_UPPER_RC

	                                               SUB                 CX,WIDTH_PLUS_ONE
	                                               SUB                 CX,WIDTH_PLUS_ONE
	                                               MOV                 SI,2
	                                               JMP                 UPPER2_RC
	END_UPPER_RC:                                  
	                                               RET
DRAW_RIGHT_CASTLE ENDP

DRAW_POWERUPS PROC

	;    MOV               AH,2CH
	;    INT               21H                                                                        	; RETURN CH=HOUR CL=MINUTE DH=SECOND DL=1/100 SECOND (CENTISECOND)
                                                   
												   
	;    CMP               CL,CURRENT_MINUTE
	;    JE                CHECK_BOMB_POWERUP_1
	;    MOV               CL,CURRENT_MINUTE
	;    MOV               TIME_TO_APPEAR_HEALTH_POWERUP_1,5
	;    MOV               TIME_TO_APPEAR_HEALTH_POWERUP_2,35
	;    MOV               TIME_TO_APPEAR_HEALTH_POWERUP_3,59
	;    MOV               TIME_TO_APPEAR_BOMB_POWERUP_1 , 10
	;    MOV               TIME_TO_APPEAR_BOMB_POWERUP_2 , 30
	;    MOV               TIME_TO_APPEAR_BOMB_POWERUP_3 , 24
	;    MOV               TIME_TO_APPEAR_DEFENSE_POWERUP_1,15
	;    MOV               TIME_TO_APPEAR_DEFENSE_POWERUP_2,45
	;    MOV               TIME_TO_APPEAR_DEFENSE_POWERUP_3,55


	CHECK_BOMB_POWERUP_1:                          
	                                               
	;    CMP               DH,TIME_TO_APPEAR_BOMB_POWERUP_1
	;    JNE               CHECK_BOMB_POWERUP_2
	;    MOV               BL,TIME_TO_APPEAR_BOMB_POWERUP_1
	;    MOV               PREVIOUS_TIME_BOMB_POWERUP_1,BL

	;    ADD               TIME_TO_APPEAR_BOMB_POWERUP_1,30
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 120

	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 340
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 140

	                                               CALL                DRAW_BOMB_POWERUP
	;    CALL              STATUS_BAR
												    

	CHECK_BOMB_POWERUP_2:                          
	;    CMP               DH,TIME_TO_APPEAR_BOMB_POWERUP_2
	;    JNE               CHECK_BOMB_POWERUP_3
	;    MOV               BL,TIME_TO_APPEAR_BOMB_POWERUP_2
	;    MOV               PREVIOUS_TIME_BOMB_POWERUP_2,BL

	;    ADD               TIME_TO_APPEAR_BOMB_POWERUP_2,30
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 300
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 230

	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 320
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 250

	                                               CALL                DRAW_BOMB_POWERUP
	;    CALL              STATUS_BAR

	CHECK_BOMB_POWERUP_3:                          
	;    CMP               DH,TIME_TO_APPEAR_BOMB_POWERUP_3
	;    JNE               CHECK_HEALTH_POWERUP_1
	;    MOV               BL,TIME_TO_APPEAR_BOMB_POWERUP_3
	;    MOV               PREVIOUS_TIME_BOMB_POWERUP_3,BL

	;    ADD               TIME_TO_APPEAR_BOMB_POWERUP_3,30
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_X , 290
	                                               MOV                 BOMB_POWERUP_BOX_STARTING_Y , 340

	                                               MOV                 BOMB_POWERUP_BOX_ENDING_X , 310
	                                               MOV                 BOMB_POWERUP_BOX_ENDING_Y, 360

	                                               CALL                DRAW_BOMB_POWERUP
	                                              
	;    CALL              STATUS_BAR
												   
	; CHECK_HEALTH_POWERUP_1:                        CMP               DH,TIME_TO_APPEAR_HEALTH_POWERUP_1
	;    JNE               CHECK_HEALTH_POWERUP_2
	;    MOV               BL,TIME_TO_APPEAR_HEALTH_POWERUP_1
	;    MOV               PREVIOUS_TIME_HEALTH_POWERUP_1,BL
	;    ADD               TIME_TO_APPEAR_HEALTH_POWERUP_1,35

	                                               CALL                DRAW_HEALTH_POWERUP_FIRST
	;    CALL              STATUS_BAR

	; CHECK_HEALTH_POWERUP_2:                        CMP               DH,TIME_TO_APPEAR_HEALTH_POWERUP_2
	;                                                JNE               CHECK_HEALTH_POWERUP_3
	;                                                MOV               BL,TIME_TO_APPEAR_HEALTH_POWERUP_2
	;                                                MOV               PREVIOUS_TIME_HEALTH_POWERUP_2,BL
	;                                                ADD               TIME_TO_APPEAR_HEALTH_POWERUP_2,35

	                                               CALL                DRAW_HEALTH_POWERUP_SECOND
	;    CALL              STATUS_BAR

												
	; CHECK_HEALTH_POWERUP_3:                        CMP               DH,TIME_TO_APPEAR_HEALTH_POWERUP_3
	;                                                JNE               CHECK_DEFENSE_POWERUP_1
	;                                                MOV               BL,TIME_TO_APPEAR_HEALTH_POWERUP_3
	;                                                MOV               PREVIOUS_TIME_HEALTH_POWERUP_3,BL
	;                                                ADD               TIME_TO_APPEAR_HEALTH_POWERUP_3,35

	                                               CALL                DRAW_HEALTH_POWERUP_THIRD
	;    CALL              STATUS_BAR

	; CHECK_DEFENSE_POWERUP_1:                       CMP               DH,TIME_TO_APPEAR_DEFENSE_POWERUP_1
	;                                                JNE               CHECK_DEFENSE_POWERUP_2
	;                                                MOV               BL,TIME_TO_APPEAR_DEFENSE_POWERUP_1
	;                                                MOV               PREVIOUS_TIME_DEFENSE_POWERUP_1,BL
	;                                                ADD               TIME_TO_APPEAR_DEFENSE_POWERUP_1,30
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	                                               CALL                DRAW_DEFENSE_POWERUP
	;    CALL              STATUS_BAR

	; CHECK_DEFENSE_POWERUP_2:                       CMP               DH,TIME_TO_APPEAR_DEFENSE_POWERUP_2
	;                                                JNE               CHECK_DEFENSE_POWERUP_3
	;                                                MOV               BL,TIME_TO_APPEAR_DEFENSE_POWERUP_2
	;                                                MOV               PREVIOUS_TIME_DEFENSE_POWERUP_2,BL
	;                                                ADD               TIME_TO_APPEAR_DEFENSE_POWERUP_2,30
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250

	                                               CALL                DRAW_DEFENSE_POWERUP
	;    CALL              STATUS_BAR

	; CHECK_DEFENSE_POWERUP_3:                       CMP               DH,TIME_TO_APPEAR_DEFENSE_POWERUP_3
	;                                                JNE               MAKE_BOMB_DISSAPEAR_1
	;                                                MOV               BL,TIME_TO_APPEAR_DEFENSE_POWERUP_3
	;                                                MOV               PREVIOUS_TIME_DEFENSE_POWERUP_3,BL
	;                                                ADD               TIME_TO_APPEAR_DEFENSE_POWERUP_3,30
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	                                               MOV                 DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370

	                                               CALL                DRAW_DEFENSE_POWERUP
	;    CALL              STATUS_BAR

	; MAKE_BOMB_DISSAPEAR_1:
	;                                                PUSHA
	;                                                MOV               BL,PREVIOUS_TIME_BOMB_POWERUP_1
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_BOMB_DISSAPEAR_2
	;                                                MOV               BOMB_POWERUP_BOX_STARTING_X , 320
	;                                                MOV               BOMB_POWERUP_BOX_STARTING_Y , 120

	;                                                MOV               BOMB_POWERUP_BOX_ENDING_X , 340
	;                                                MOV               BOMB_POWERUP_BOX_ENDING_Y, 140
	;                                                CALL              ERASE_BOMB_POWERUP
	;                                                POPA
	;                                                PUSHA
	;                                                CALL              STATUS_BAR
	;                                                POPA

	; MAKE_BOMB_DISSAPEAR_2:
	;                                                PUSHA
	;                                                MOV               BL,PREVIOUS_TIME_BOMB_POWERUP_2
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_BOMB_DISSAPEAR_3
	;                                                MOV               BOMB_POWERUP_BOX_STARTING_X , 300
	;                                                MOV               BOMB_POWERUP_BOX_STARTING_Y , 230

	;                                                MOV               BOMB_POWERUP_BOX_ENDING_X , 320
	;                                                MOV               BOMB_POWERUP_BOX_ENDING_Y, 250
	;                                                CALL              ERASE_BOMB_POWERUP
	;                                                POPA
	;                                                PUSHA
	;                                                CALL              STATUS_BAR
	;                                                POPA

	; MAKE_BOMB_DISSAPEAR_3:
	;                                                PUSHA
	;                                                MOV               BL,PREVIOUS_TIME_BOMB_POWERUP_3
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_HEALTH_DISSAPEAR_1
	;                                                MOV               BOMB_POWERUP_BOX_STARTING_X , 290
	;                                                MOV               BOMB_POWERUP_BOX_STARTING_Y ,340

	;                                                MOV               BOMB_POWERUP_BOX_ENDING_X , 310
	;                                                MOV               BOMB_POWERUP_BOX_ENDING_Y, 360

	;                                                CALL              ERASE_BOMB_POWERUP
	;                                                POPA
	;                                                PUSHA
	;                                                CALL              STATUS_BAR
	;                                                POPA
											   									   

	; MAKE_HEALTH_DISSAPEAR_1:                       MOV               BL,PREVIOUS_TIME_HEALTH_POWERUP_1
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_HEALTH_DISSAPEAR_2
												   
	;                                                CALL              ERASE_HEALTH_POWERUP_FIRST
	;                                                PUSH              ES
	;                                                CALL              STATUS_BAR
	;                                                POP               ES

	; MAKE_HEALTH_DISSAPEAR_2:                       MOV               BL,PREVIOUS_TIME_HEALTH_POWERUP_2
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_HEALTH_DISSAPEAR_3
	;                                                CALL              ERASE_HEALTH_POWERUP_SECOND
	;                                                PUSH              ES
	;                                                CALL              STATUS_BAR
	;                                                POP               ES

	; MAKE_HEALTH_DISSAPEAR_3:                       MOV               BL,PREVIOUS_TIME_HEALTH_POWERUP_3
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_DEFENSE_DISSAPEAR_1
												   
	;                                                CALL              ERASE_HEALTH_POWERUP_THIRD
	;                                                PUSH              ES
	;                                                CALL              STATUS_BAR
	;                                                POP               ES
						   

	; MAKE_DEFENSE_DISSAPEAR_1:                      MOV               BL,PREVIOUS_TIME_DEFENSE_POWERUP_1
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_DEFENSE_DISSAPEAR_2
	;                                                MOV               DEFENSE_POWERUP_CIRCLE_CENTER_X , 300
	;                                                MOV               DEFENSE_POWERUP_CIRCLE_CENTER_Y , 200
	;                                                CALL              ERASE_DEFENSE_POWERUP
	;                                                PUSH              ES
	;                                                CALL              STATUS_BAR
	;                                                POP               ES
									   			   
	; MAKE_DEFENSE_DISSAPEAR_2:                      MOV               BL,PREVIOUS_TIME_DEFENSE_POWERUP_2
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               MAKE_DEFENSE_DISSAPEAR_3
	;                                                MOV               DEFENSE_POWERUP_CIRCLE_CENTER_X , 350
	;                                                MOV               DEFENSE_POWERUP_CIRCLE_CENTER_Y , 250
	;                                                CALL              ERASE_DEFENSE_POWERUP
	;                                                PUSH              ES
	;                                                CALL              STATUS_BAR
	;                                                POP               ES

	; MAKE_DEFENSE_DISSAPEAR_3:                      MOV               BL,PREVIOUS_TIME_DEFENSE_POWERUP_3
	;                                                ADD               BL,15
	;                                                CMP               DH,BL
	;                                                JNE               START_GAME_LOOP
	;                                                MOV               DEFENSE_POWERUP_CIRCLE_CENTER_X , 280
	;                                                MOV               DEFENSE_POWERUP_CIRCLE_CENTER_Y , 370
	;                                                CALL              ERASE_DEFENSE_POWERUP
	;                                                PUSH              ES
	;                                                CALL              STATUS_BAR
	;                                                POP               ES

	START_GAME_LOOP:                               
	                                               RET
DRAW_POWERUPS ENDP

DRAW_BOMB_POWERUP PROC

	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               MOV                 AL, BOMB_POWERUP_BOX_COLOR
	                                               MOV                 AH,0CH
	DRAW_UPPERSIDE_BOMB:                           
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,BOMB_POWERUP_BOX_ENDING_X
	                                               JNZ                 DRAW_UPPERSIDE_BOMB

	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y

	DRAW_LEFTSIDE_BOMB:                            
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,BOMB_POWERUP_BOX_ENDING_Y
	                                               JNZ                 DRAW_LEFTSIDE_BOMB

	                                               MOV                 CX,BOMB_POWERUP_BOX_ENDING_X
	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y

	DRAW_RIGHTSIDE_BOMB:                           
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,BOMB_POWERUP_BOX_ENDING_Y
	                                               JNZ                 DRAW_RIGHTSIDE_BOMB

	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               MOV                 DX,BOMB_POWERUP_BOX_ENDING_Y

	DRAW_LOWERSIDE_BOMB:                           
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,BOMB_POWERUP_BOX_ENDING_X
	                                               JNZ                 DRAW_LOWERSIDE_BOMB


	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               INC                 CX

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,10

	                                               MOV                 AL,0EH
	                                               MOV                 AH,0CH
	DRAW_HORIZONTAL_LINE_1:                        
	                                               INT                 10H
	                                               INC                 CX
	                                               MOV                 BX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 BX,8
	                                               CMP                 CX,BX
	                                               JC                  DRAW_HORIZONTAL_LINE_1

	;-------------------------------------------------------------------------
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,12

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,10

	                                               MOV                 AL,0EH
	                                               MOV                 AH,0CH
	DRAW_HORIZONTAL_LINE_2:                        
	                                               INT                 10H
	                                               INC                 CX
	                                               MOV                 BX,BOMB_POWERUP_BOX_ENDING_X
  
	                                               CMP                 CX,BX
	                                               JC                  DRAW_HORIZONTAL_LINE_2

	;--------------------------------------------------------------------

	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,11

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,8

	DRAW_DIAGONAL_LINE_1:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 DX
	                                               MOV                 BX,BOMB_POWERUP_BOX_ENDING_X
	                                               SUB                 BX,1
	                                               CMP                 CX,BX
	                                               JC                  DRAW_DIAGONAL_LINE_1


	;----------------------------------------------------------------------
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,9

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,8

	DRAW_DIAGONAL_LINE_2:                          
	                                               INT                 10H
	                                               DEC                 CX
	                                               DEC                 DX
	                                               CMP                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               JNE                 DRAW_DIAGONAL_LINE_2
	;--------------------------------------------------------------------

	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,9

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,12

	DRAW_DIAGONAL_LINE_3:                          
	                                               INT                 10H
	                                               DEC                 CX
	                                               INC                 DX
	                                               CMP                 DX,BOMB_POWERUP_BOX_ENDING_Y
	                                               JNE                 DRAW_DIAGONAL_LINE_3
	;-------------------------------------------------------------------
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,11

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,12

	DRAW_DIAGONAL_LINE_4:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               INC                 DX
	                                               MOV                 BX,BOMB_POWERUP_BOX_ENDING_Y
	                                               SUB                 BX,4
	                                               CMP                 DX,BX
	                                               JNE                 DRAW_DIAGONAL_LINE_4
	;------------------------------------------------------------------------
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,10

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,8

	                                               MOV                 AL,0EH
	                                               MOV                 AH,0CH

	DRAW_VERTICAL_LINE_1:                          
	                                               INT                 10H
	                                               DEC                 DX
	                                               MOV                 BX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 BX,2
	                                               CMP                 DX,BX
	                                               JNE                 DRAW_VERTICAL_LINE_1
	;-------------------------------------------------------------------
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               ADD                 CX,10

	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y
	                                               ADD                 DX,12

	                                               MOV                 AL,0EH
	                                               MOV                 AH,0CH

	DRAW_VERTICAL_LINE_2:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               MOV                 BX,BOMB_POWERUP_BOX_ENDING_Y
	;ADD BX,2
	                                               CMP                 DX,BX
	                                               JNE                 DRAW_VERTICAL_LINE_2

	                                               RET
DRAW_BOMB_POWERUP ENDP

DRAW_HEALTH_POWERUP_FIRST PROC

	                                               PUSH                ES

	                                               MOV                 CX,317
	                                               MOV                 DX,190
	                                               MOV                 AL, HEALTH_POWERUP_BOX_COLOR
	                                               MOV                 AH,0CH
	DRAW_UPPERSIDE_FIRST:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,330
	                                               JNZ                 DRAW_UPPERSIDE_FIRST

	                                               MOV                 CX,317
	                                               MOV                 DX,190

	DRAW_LEFTSIDE_FIRST:                           
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,210
	                                               JNZ                 DRAW_LEFTSIDE_FIRST

	                                               MOV                 CX,330
	                                               MOV                 DX,190

	DRAW_RIGHTSIDE_FIRST:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,210
	                                               JNZ                 DRAW_RIGHTSIDE_FIRST

	                                               MOV                 CX,317
	                                               MOV                 DX,210

	DRAW_LOWERSIDE_FIRST:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,330
	                                               JNZ                 DRAW_LOWERSIDE_FIRST

	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,04H

	                                               POP                 ES
	                                               MOV                 CL,1
	                                               MOV                 CH,0
	                                               MOV                 DL,40
	                                               MOV                 DH,12
	                                               MOV                 BP,OFFSET HEART_SYMBOL
	                                               INT                 10H
	                                        

	                                               RET
DRAW_HEALTH_POWERUP_FIRST ENDP

DRAW_HEALTH_POWERUP_SECOND PROC

	                                               PUSH                ES

	                                               MOV                 CX,285
	                                               MOV                 DX,301
	                                               MOV                 AL, HEALTH_POWERUP_BOX_COLOR
	                                               MOV                 AH,0CH
	DRAW_UPPERSIDE_SECOND:                         
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,298
	                                               JNZ                 DRAW_UPPERSIDE_SECOND

	                                               MOV                 CX,285
	                                               MOV                 DX,301

	DRAW_LEFTSIDE_SECOND:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,321
	                                               JNZ                 DRAW_LEFTSIDE_SECOND

	                                               MOV                 CX,298
	                                               MOV                 DX,301

	DRAW_RIGHTSIDE_SECOND:                         
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,321
	                                               JNZ                 DRAW_RIGHTSIDE_SECOND

	                                               MOV                 CX,285
	                                               MOV                 DX,321

	DRAW_LOWERSIDE_SECOND:                         
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,298
	                                               JNZ                 DRAW_LOWERSIDE_SECOND

	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,04H

	                                               POP                 ES
	                                               MOV                 CL,1
	                                               MOV                 CH,0
	                                               MOV                 DL,36
	                                               MOV                 DH,19
	                                               MOV                 BP,OFFSET HEART_SYMBOL
	                                               INT                 10H
	                                        

	                                               RET
DRAW_HEALTH_POWERUP_SECOND ENDP
DRAW_HEALTH_POWERUP_THIRD PROC

	                                               PUSH                ES

	                                               MOV                 CX,357
	                                               MOV                 DX,125
	                                               MOV                 AL, HEALTH_POWERUP_BOX_COLOR
	                                               MOV                 AH,0CH
	DRAW_UPPERSIDE_THIRD:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,370
	                                               JNZ                 DRAW_UPPERSIDE_THIRD

	                                               MOV                 CX,357
	                                               MOV                 DX,125

	DRAW_LEFTSIDE_THIRD:                           
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,145
	                                               JNZ                 DRAW_LEFTSIDE_THIRD

	                                               MOV                 CX,370
	                                               MOV                 DX,125

	DRAW_RIGHTSIDE_THIRD:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,145
	                                               JNZ                 DRAW_RIGHTSIDE_THIRD

	                                               MOV                 CX,357
	                                               MOV                 DX,145

	DRAW_LOWERSIDE_THIRD:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,370
	                                               JNZ                 DRAW_LOWERSIDE_THIRD

	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,04H

	                                               POP                 ES
	                                               MOV                 CL,1
	                                               MOV                 CH,0
	                                               MOV                 DL,45
	                                               MOV                 DH,8
	                                               MOV                 BP,OFFSET HEART_SYMBOL
	                                               INT                 10H
	                                        

	                                               RET
DRAW_HEALTH_POWERUP_THIRD ENDP

DRAW_DEFENSE_POWERUP PROC

	                                               MOV                 AX,DEFENSE_POWERUP_CIRCLE_CENTER_X
	                                               MOV                 XC,AX
	                                               MOV                 BX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               MOV                 YC,BX
	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_RADIUS_1
	                                               MOV                 R,DX
	                                               MOV                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE

	                                               MOV                 AX,DEFENSE_POWERUP_CIRCLE_CENTER_X
	                                               MOV                 XC,AX
	                                               MOV                 BX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               MOV                 YC,BX
	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_RADIUS_2
	                                               MOV                 R,DX
	                                               MOV                 AL,DEFENSE_POWERUP_BOX_COLOR
	                                               MOV                 CIRCLE_COLOR,AL
	                                               CALL                DRAW_CIRCLE

	;---------------------------------------------------------------
	                                               MOV                 CX,DEFENSE_POWERUP_CIRCLE_CENTER_X

	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               MOV                 BX,6
	                                               MOV                 AL,0
	                                               MOV                 AH,0CH

	DRAW_DIAGONAL_LINE_DEFENSE_1:                  
	                                               INT                 10H
	                                               INC                 CX
	                                               DEC                 DX
	                                               DEC                 BX
	                                               CMP                 BX,0
	                                               JA                  DRAW_DIAGONAL_LINE_DEFENSE_1
	;---------------------------------------------------------------
	                                               MOV                 CX,DEFENSE_POWERUP_CIRCLE_CENTER_X

	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               MOV                 BX,6
	                                               MOV                 AL,0
	                                               MOV                 AH,0CH

	DRAW_DIAGONAL_LINE_DEFENSE_2:                  
	                                               INT                 10H
	                                               DEC                 CX
	                                               DEC                 DX
	                                               DEC                 BX
	                                               CMP                 BX,0
	                                               JA                  DRAW_DIAGONAL_LINE_DEFENSE_2
	;---------------------------------------------------------------
	                                               MOV                 CX,DEFENSE_POWERUP_CIRCLE_CENTER_X

	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               MOV                 BX,6
	                                               MOV                 AL,0
	                                               MOV                 AH,0CH

	DRAW_DIAGONAL_LINE_DEFENSE_3:                  
	                                               INT                 10H
	                                               DEC                 CX
	                                               INC                 DX
	                                               DEC                 BX
	                                               CMP                 BX,0
	                                               JA                  DRAW_DIAGONAL_LINE_DEFENSE_3

	;-------------------------------------------------------------------
	                                               MOV                 CX,DEFENSE_POWERUP_CIRCLE_CENTER_X

	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               MOV                 BX,6
	                                               MOV                 AL,0
	                                               MOV                 AH,0CH

	DRAW_DIAGONAL_LINE_DEFENSE_4:                  
	                                               INT                 10H
	                                               INC                 CX
	                                               INC                 DX
	                                               DEC                 BX
	                                               CMP                 BX,0
	                                               JA                  DRAW_DIAGONAL_LINE_DEFENSE_4
	                                               RET
DRAW_DEFENSE_POWERUP ENDP
ERASE_HEALTH_POWERUP_FIRST PROC

	                                               MOV                 AH,0CH
	                                               MOV                 AL,7
	                                               MOV                 CX,317
	                                               MOV                 DX,190

	BIG_SQUARE:                                    
	                                               MOV                 CX,317
	INSIDE_LINES:                                  
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,331
	                                               JNE                 INSIDE_LINES

	                                               INC                 DX
	                                               CMP                 DX,211
	                                               JNE                 BIG_SQUARE



	                                               RET
ERASE_HEALTH_POWERUP_FIRST ENDP

ERASE_HEALTH_POWERUP_SECOND PROC

	                                               MOV                 AH,0CH
	                                               MOV                 AL,7
	                                               MOV                 CX,285
	                                               MOV                 DX,301

	BIG_SQUARE_SECOND:                             
	                                               MOV                 CX,285
	INSIDE_LINES_SECOND:                           
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,299
	                                               JNE                 INSIDE_LINES_SECOND

	                                               INC                 DX
	                                               CMP                 DX,322
	                                               JNE                 BIG_SQUARE_SECOND



	                                               RET
ERASE_HEALTH_POWERUP_SECOND ENDP

ERASE_HEALTH_POWERUP_THIRD PROC

	                                               MOV                 AH,0CH
	                                               MOV                 AL,7
	                                               MOV                 CX,357
	                                               MOV                 DX,125

	BIG_SQUARE_THIRD:                              
	                                               MOV                 CX,357
	INSIDE_LINES_THIRD:                            
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,371
	                                               JNE                 INSIDE_LINES_THIRD

	                                               INC                 DX
	                                               CMP                 DX,146
	                                               JNE                 BIG_SQUARE_THIRD


	                                               RET
ERASE_HEALTH_POWERUP_THIRD ENDP

ERASE_BOMB_POWERUP PROC
	                                               MOV                 AH,0CH
	                                               MOV                 AL,7
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	                                               MOV                 DX,BOMB_POWERUP_BOX_STARTING_Y

	BIG_SQUARE_BOMB:                               
	                                               MOV                 CX,BOMB_POWERUP_BOX_STARTING_X
	INSIDE_LINES_BOMB:                             
	                                               INT                 10H
	                                               INC                 CX
	                                               MOV                 BX,BOMB_POWERUP_BOX_ENDING_X
	                                               INC                 BX
	                                               CMP                 CX,BX
	                                               JNE                 INSIDE_LINES_BOMB

	                                               INC                 DX
	                                               MOV                 BX,BOMB_POWERUP_BOX_ENDING_Y
	                                               INC                 BX
	                                               CMP                 DX,BX
	                                               JNE                 BIG_SQUARE_BOMB


	                                               RET
ERASE_BOMB_POWERUP ENDP

ERASE_DEFENSE_POWERUP PROC


	                                               MOV                 AH,0CH
	                                               MOV                 AL,7
	                                               MOV                 CX,DEFENSE_POWERUP_CIRCLE_CENTER_X
	                                               SUB                 CX,DEFENSE_POWERUP_CIRCLE_RADIUS_1

	                                               MOV                 DX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               SUB                 DX,DEFENSE_POWERUP_CIRCLE_RADIUS_1

	BIG_SQUARE_DEFENSE:                            
	                                               MOV                 CX,DEFENSE_POWERUP_CIRCLE_CENTER_X
	                                               SUB                 CX,DEFENSE_POWERUP_CIRCLE_RADIUS_1
	INSIDE_LINES_DEFENSE:                          
	                                               INT                 10H
	                                               INC                 CX
	                                               MOV                 BX,DEFENSE_POWERUP_CIRCLE_CENTER_X
	                                               ADD                 BX,DEFENSE_POWERUP_CIRCLE_RADIUS_1
	                                               INC                 BX
	                                               CMP                 CX,BX
	                                               JNE                 INSIDE_LINES_DEFENSE

	                                               INC                 DX
	                                               MOV                 BX,DEFENSE_POWERUP_CIRCLE_CENTER_Y
	                                               ADD                 BX,DEFENSE_POWERUP_CIRCLE_RADIUS_1
	                                               INC                 BX
	                                               CMP                 DX,BX
	                                               JNE                 BIG_SQUARE_DEFENSE

	                                               RET
ERASE_DEFENSE_POWERUP ENDP


MAIN_MENU PROC

	                                               PUSH                ES

	;    MOV       AH,0
	;    MOV       AL,3
	;    INT       10H
	                                               
	                                               MOV                 AX, 4F02H
	                                               mov                 BX,101H
	                                               INT                 10H

	                                               MOV                 CX,0
	                                               MOV                 DX,50

	                                               MOV                 AL, MAIN_MENU_BACKGROUND_COLOR
	                                               MOV                 AH,0CH

	PAINT_BACKGROUND:                              
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,640
	                                               JC                  PAINT_BACKGROUND

	                                               INC                 DX
	                                               MOV                 CX,0
	                                               CMP                 DX,480
	                                               JC                  PAINT_BACKGROUND


	                                               MOV                 AL,00H
	                                               MOV                 AH,0CH
	                   

												   
	                                               MOV                 CX, MAIN_MENU_BOX_1_STARING_X
	                                               MOV                 DX, MAIN_MENU_BOX_1_STARING_Y

	PAINT_BOX_1:                                   
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX, MAIN_MENU_BOX_1_ENDING_X
	                                               JC                  PAINT_BOX_1

	                                               INC                 DX
	                                               MOV                 CX, MAIN_MENU_BOX_1_STARING_X
	                                               CMP                 DX, MAIN_MENU_BOX_1_ENDING_Y
	                                               JC                  PAINT_BOX_1

	                                               MOV                 CX, MAIN_MENU_BOX_2_STARING_X
	                                               MOV                 DX, MAIN_MENU_BOX_2_STARING_Y

	                                               MOV                 AL,00H
	                                               MOV                 AH,0CH
	PAINT_BOX_2:                                   
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX, MAIN_MENU_BOX_2_ENDING_X
	                                               JC                  PAINT_BOX_2

	                                               INC                 DX
	                                               MOV                 CX, MAIN_MENU_BOX_2_STARING_X
	                                               CMP                 DX, MAIN_MENU_BOX_2_ENDING_Y
	                                               JC                  PAINT_BOX_2


	                                               MOV                 AL, 00H
	                                               MOV                 AH,0CH

	                                               MOV                 CX,MAIN_MENU_BOX_3_STARING_X
	                                               MOV                 DX,MAIN_MENU_BOX_3_STARING_Y
	;------------------
	PAINT_BOX_3:                                   
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX, MAIN_MENU_BOX_3_ENDING_X
	                                               JC                  PAINT_BOX_3

	                                               INC                 DX
	                                               MOV                 CX, MAIN_MENU_BOX_3_STARING_X
	                                               CMP                 DX, MAIN_MENU_BOX_3_ENDING_Y
	                                               JC                  PAINT_BOX_3


	                                               MOV                 CX,MAIN_MENU_BOX_1_STARING_X
	                                               MOV                 DX,MAIN_MENU_BOX_1_STARING_Y

	                                               MOV                 AH,0CH
	                                               MOV                 AL, 04H
	;-----------------------

	DRAW_BOX_1_UPPER_SIDE:                         

	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,MAIN_MENU_BOX_1_ENDING_X
	                                               JC                  DRAW_BOX_1_UPPER_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_1_STARING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_1_STARING_X

	DRAW_BOX_1_LEFT_SIDE:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,MAIN_MENU_BOX_1_ENDING_Y
	                                               JC                  DRAW_BOX_1_LEFT_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_1_ENDING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_1_STARING_X

	DRAW_BOX_1_LOWER_SIDE:                         
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,MAIN_MENU_BOX_1_ENDING_X
	                                               JC                  DRAW_BOX_1_LOWER_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_1_STARING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_1_ENDING_X

	DRAW_BOX_1_RIGHT_SIDE:                         
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,MAIN_MENU_BOX_1_ENDING_Y
	                                               JC                  DRAW_BOX_1_RIGHT_SIDE


	                                               MOV                 CX,MAIN_MENU_BOX_2_STARING_X
	                                               MOV                 DX,MAIN_MENU_BOX_2_STARING_Y

	DRAW_BOX_2_UPPER_SIDE:                         

	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX, MAIN_MENU_BOX_2_ENDING_X
	                                               JC                  DRAW_BOX_2_UPPER_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_2_STARING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_2_STARING_X

	DRAW_BOX_2_LEFT_SIDE:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,MAIN_MENU_BOX_2_ENDING_Y
	                                               JC                  DRAW_BOX_2_LEFT_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_2_ENDING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_2_STARING_X

	DRAW_BOX_2_LOWER_SIDE:                         
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,MAIN_MENU_BOX_2_ENDING_X
	                                               JC                  DRAW_BOX_2_LOWER_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_2_STARING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_2_ENDING_X

	DRAW_BOX_2_RIGHT_SIDE:                         
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,MAIN_MENU_BOX_2_ENDING_Y
	                                               JC                  DRAW_BOX_2_RIGHT_SIDE

	                                               MOV                 CX,MAIN_MENU_BOX_3_STARING_X
	                                               MOV                 DX,MAIN_MENU_BOX_3_STARING_Y

	;--------------------
	DRAW_BOX_3_UPPER_SIDE:                         

	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,MAIN_MENU_BOX_3_ENDING_X
	                                               JC                  DRAW_BOX_3_UPPER_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_3_STARING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_3_STARING_X

	DRAW_BOX_3_LEFT_SIDE:                          
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,MAIN_MENU_BOX_3_ENDING_Y
	                                               JC                  DRAW_BOX_3_LEFT_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_3_ENDING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_3_STARING_X

	DRAW_BOX_3_LOWER_SIDE:                         
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,MAIN_MENU_BOX_3_ENDING_X
	                                               JC                  DRAW_BOX_3_LOWER_SIDE

	                                               MOV                 DX,MAIN_MENU_BOX_3_STARING_Y
	                                               MOV                 CX,MAIN_MENU_BOX_3_ENDING_X

	DRAW_BOX_3_RIGHT_SIDE:                         
	                                               INT                 10H
	                                               INC                 DX
	                                               CMP                 DX,MAIN_MENU_BOX_3_ENDING_Y
	                                               JC                  DRAW_BOX_3_RIGHT_SIDE


	                                               MOV                 CX,MAIN_MENU_BOX_3_STARING_X
	                                               MOV                 DX,MAIN_MENU_BOX_3_STARING_Y

	;--------------------

	                                               POP                 ES

	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,71

	                                               MOV                 CL,17
	                                               MOV                 CH,0
	                                               MOV                 DL, 111
	                                               MOV                 DH, 17
	                                               MOV                 BP, OFFSET START_GAME_MESSAGE
	                                               INT                 10H

	                                               MOV                 CL,17
	                                               MOV                 CH,0
	                                               MOV                 DL, 111
	                                               MOV                 DH, 19
	                                               MOV                 BP, OFFSET QUIT_GAME_MESSAGE
	                                               INT                 10H

	                                               MOV                 CL,16
	                                               MOV                 CH,0
	                                               MOV                 DL, 111
	                                               MOV                 DH, 21
	                                               MOV                 BP, OFFSET CHATTING_GAME_MESSAGE
	                                               INT                 10H

	   DRAWMACRO    IMG_MAIN,IMGW_MAIN,IMGH_MAIN,XB,YB,W,H,BIRDS

	                                               MOV                 AL, CANON_BODY_COLOR
	                                               MOV                 AH, 0CH


	;--------------------------------------------------------------------------------------------------
	                                               MOV                 BX,30                                                                      	; EL RECTANGE BETA3 AWEL MADFA3 (EL 3AL SHEMAL)
	                                               MOV                 DI,70
	                                               MOV                 DX,440
	SQUARE13:                                      

	                                               MOV                 CX,BX

	LINE13:                                        INT                 10H
	                                               INC                 CX
	                                               DEC                 DX
        
	                                               CMP                 CX,DI
        
	                                               JNZ                 LINE13
	                                               ADD                 DX,40
	                                               INC                 DX
	                                               INC                 BX
	                                               INC                 DI
	                                               CMP                 DX,456
	                                               JNZ                 SQUARE13

	;-----------------------------------------------------------------------------------------------------------
	                                               MOV                 BX,557                                                                     	; EL RECTANGLE BETA3 TANY MADFA3 (EL 3AL YEMIN)
	                                               MOV                 DI,573
	                                               MOV                 DX,412
	SQUARE:                                        

	                                               MOV                 CX,BX

	LINE:                                          INT                 10H
	                                               INC                 CX
	                                               DEC                 DX
        
	                                               CMP                 CX,DI
        
	                                               JNZ                 LINE
	                                               ADD                 DX,16
	                                               INC                 DX
	                                               INC                 BX
	                                               INC                 DI
	                                               CMP                 DX,452
	                                               JNZ                 SQUARE

	;--------------------------------------------------------------------------------------------------------
	                                               MOV                 AL,CANON_TIP_COLOR                                                         	; FAT7ET EL MADFA3 EL 3AL SHEMAL
	                                               MOV                 CX,65D
	                                               MOV                 DX,395D
	X22:                                           INT                 16D
	                                               ADD                 DX,1D
	                                               SUB                 CX,1D
	                                               INT                 10H
	                                               SUB                 DX,1D
	                                               ADD                 CX,1D
	                                               INC                 DX
	                                               INC                 CX
	                                               CMP                 DX,420D
	                                               JNZ                 X22


	                                               MOV                 CX,65D
	                                               MOV                 DX,395D
	Y22:                                           INT                 16D
	                                               ADD                 CX,16D
	                                               ADD                 DX,16D
	                                               INT                 10H
	                                               SUB                 DX,16D
	                                               SUB                 CX,16D
	                                               INC                 DX
	                                               DEC                 CX
	                                               CMP                 DX,396D
	                                               JNZ                 Y22
	;-----------------------------------------------------------------------------------------------------------
	                                               MOV                 AL,CANON_TIP_COLOR                                                         	; FAT7ET EL MADFA3 EL 3AL YEMIN
	                                               MOV                 CX,575D
	                                               MOV                 DX,392D
	X12:                                           INT                 16D
	                                               ADD                 DX,16D
	                                               SUB                 CX,16D
	                                               INT                 10H
	                                               SUB                 DX,16D
	                                               ADD                 CX,16D
	                                               INC                 DX
	                                               INC                 CX
	                                               CMP                 DX,394D
	                                               JNZ                 X12

	                                               MOV                 CX,575D
	                                               MOV                 DX,392D
	Y11:                                           INT                 16D
	                                               ADD                 CX,1D
	                                               ADD                 DX,1D
	                                               INT                 10H
	                                               SUB                 DX,1D
	                                               SUB                 CX,1D
	                                               INC                 DX
	                                               DEC                 CX
	                                               CMP                 DX,416D
	                                               JNZ                 Y11

	;------------------------------------------------------------------------------------------------------------
	;READ CENTER(X,Y)                   ;3AGALET EL MADFA3 EL 3AL SHEMAL
       
        
	                                               MOV                 XC,38D
	                                               MOV                 YC,450D
	                                               MOV                 R,25D
        
	;DRAW CIRCLE(MIDPOINT ALGORITHM)
	;Y=R
	                                               MOV                 AX,R
	                                               MOV                 Y,AX
        
	;PLOT INITIAL POINT
	                                               CALL                PLOT1
	;P=1-R
	                                               MOV                 AX,01
	                                               MOV                 DX,R
	                                               XOR                 DX,0FFFFH
	                                               INC                 DX
	                                               ADD                 AX,DX
	                                               MOV                 P,AX
        
	;WHILE(X<Y)
	LOOP11:                                        MOV                 AX,X
	                                               CMP                 AX,Y
	                                               JNC                 JUMP11
        
	;X++
	                                               INC                 X
        
	;IF(P<0)
	                                               MOV                 AX,P
	                                               RCL                 AX,01
	                                               JNC                 JUMP22
        
	;P+=2*X+1
	                                               MOV                 AX,X
	                                               RCL                 AX,01
	                                               INC                 AX
	                                               ADD                 AX,P
	                                               JMP                 JUMP33
        
	;ELSE
	;Y++
	;P+=2*(X-Y)+1;
	JUMP22:                                        DEC                 Y
	                                               MOV                 AX,X
	                                               MOV                 DX,Y
	                                               XOR                 DX,0FFFFH
	                                               INC                 DX
	                                               ADD                 AX,DX
	                                               RCL                 AX,01
	                                               JNC                 JUMP44
	                                               OR                  AX,8000H
	JUMP44:                                        INC                 AX
	                                               ADD                 AX,P
        
	JUMP33:                                        MOV                 P,AX
	;PLOT POINT
	                                               CALL                PLOT1
	                                               JMP                 LOOP11
	JUMP11:                                        
        
	;------------------------------------------------------------------------------------------------------------
	; 3AGALET EL MADFA3 EL 3AL YEMIN
	                                               MOV                 X , 0
	                                               MOV                 Y , 0
	                                               MOV                 P , 0
	                                               MOV                 F,0
	                                               MOV                 N,0
	; READ CENTER(X,Y)
	                                               MOV                 XC,603D
	                                               MOV                 YC,450D
	                                               MOV                 R,25D
        
        
	;DRAW CIRCLE(MIDPOINT ALGORITHM)
	;Y=R
	                                               MOV                 AX,R
	                                               MOV                 Y,AX
        
	;PLOT INITIAL POINT
	                                               CALL                PLOT1
	;P=1-R
	                                               MOV                 AX,01
	                                               MOV                 DX,R
	                                               XOR                 DX,0FFFFH
	                                               INC                 DX
	                                               ADD                 AX,DX
	                                               MOV                 P,AX
        
	;WHILE(X<Y)
	LOOP1:                                         MOV                 AX,X
	                                               CMP                 AX,Y
	                                               JNC                 JUMP1
        
	;X++
	                                               INC                 X
        
	;IF(P<0)
	                                               MOV                 AX,P
	                                               RCL                 AX,01
	                                               JNC                 JUMP2
        
	;P+=2*X+1
	                                               MOV                 AX,X
	                                               RCL                 AX,01
	                                               INC                 AX
	                                               ADD                 AX,P
	                                               JMP                 JUMP3
        
	;ELSE
	;Y++
	;P+=2*(X-Y)+1;
	JUMP2:                                         DEC                 Y
	                                               MOV                 AX,X
	                                               MOV                 DX,Y
	                                               XOR                 DX,0FFFFH
	                                               INC                 DX
	                                               ADD                 AX,DX
	                                               RCL                 AX,01
	                                               JNC                 JUMP4
	                                               OR                  AX,8000H
	JUMP4:                                         INC                 AX
	                                               ADD                 AX,P
        
	JUMP3:                                         MOV                 P,AX
	;PLOT POINT
	                                               CALL                PLOT1
        
	                                               JMP                 LOOP1
		
	JUMP1:                                         

	                                               InitSerialPort
	Receive_loop_MAIN:                             

	                                               ReceiveChar
	                                               JZ                  WAIT_FOR_KEY_PRESSED
	                                               MOV                 ScanCodeReceivedChar,AL

	                                               CMP                 ScanCodeReceivedChar,F1_ScanCode
	                                               JNE                 NOT_F1_RECEIVED

	                                               CMP                 ScanCodeSentChar,F1_ScanCode
	                                               jE                  SENT_AND_RECEIVED_CHAT

	                                               MOV                 AH,13H
	                                               MOV                 AL,0
	                                               MOV                 BH,0
	                                               MOV                 BL,59
	                                               MOV                 CH,0

	                                               MOV                 CL,byte ptr OTHERNAMEACTUALSIZE
	                                               MOV                 DL, 0
	                                               MOV                 DH, 0
	                                               MOV                 BP, OFFSET OTHERNAMEDATA
	                                               INT                 10H

	                                               MOV                 CL,45
	                                               MOV                 DL,byte ptr OTHERNAMEACTUALSIZE
	                                               MOV                 DH, 0
	                                               MOV                 BP, OFFSET RECEIVED_CHAT_INVITAITON
	                                               INT                 10H
	                                               jmp                 WAIT_FOR_KEY_PRESSED
	SENT_AND_RECEIVED_CHAT:                        
	                                               mov                 dx,0
	PAINT_BACKGROUND_exit:                         
	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,640
	                                               JC                  PAINT_BACKGROUND_exit

	                                               INC                 DX
	                                               MOV                 CX,0
	                                               CMP                 DX,25
	                                               JC                  PAINT_BACKGROUND_exit
	                                               mov                 ScanCodeSentChar,0
	                                               mov                 ScanCodeReceivedChar,0
	                                               CALL                CHAT_ROOM

	                                               
			
	NOT_F1_RECEIVED:                               

	                                               CMP                 ScanCodeReceivedChar,3CH
	                                               JNE                 NOT_F2_RECEIVED

	                                               CMP                 ScanCodeSentChar,3CH
	                                               jE                  SENT_AND_RECEIVED_GAME
												   

	                                               MOV                 AH,13H
	                                               MOV                 AL,0
	                                               MOV                 BH,0
	                                               MOV                 BL,59
	                                               MOV                 CH,0

	                                               MOV                 CL,BYTE PTR OTHERNAMEACTUALSIZE
	                                               MOV                 DL, 0
	                                               MOV                 DH, 2
	                                               MOV                 BP, OFFSET OTHERNAMEDATA
	                                               INT                 10H
											
	                                               MOV                 CL,45
	                                               MOV                 DL,BYTE PTR OTHERNAMEACTUALSIZE
	                                               INC                 DL
	                                               MOV                 DH, 2
	                                               MOV                 BP, OFFSET RECEIVED_GAME_INVITAITON
	                                               INT                 10H
	                                               jmp                 WAIT_FOR_KEY_PRESSED
	SENT_AND_RECEIVED_GAME:                        
	                                               PUSHA
	                                               mov                 Current_player_NUMBER,1
	                                               MOV                 AX,CURRENTNAMEACTUALSIZE
	                                               MOV                 NAME1ACTUALSIZE,AX
	                                               MOV                 AL,CURRENTNAMEBUFFERSIZE
	                                               MOV                 NAME1BUFFERSIZE,AL
	                                               MOV                 CX,CURRENTNAMEACTUALSIZE
	                                               MOV                 SI,OFFSET CURRENTNAMEDATA
	                                               MOV                 DI,OFFSET NAME1DATA
	LOOP_SWITCH_NAME_PLAYER_ONE:                   
	                                               MOV                 AL,[SI]
	                                               MOV                 [DI],AL
	                                               INC                 SI
	                                               INC                 DI
	                                               LOOP                LOOP_SWITCH_NAME_PLAYER_ONE

	                                               MOV                 AX,WORD PTR OTHERNAMEACTUALSIZE
	                                               MOV                 NAME2ACTUALSIZE,AX
	                                               MOV                 AL, OTHERNAMEBUFFERSIZE
	                                               MOV                 NAME2BUFFERSIZE,AL
	                                               MOV                 CX,WORD PTR OTHERNAMEACTUALSIZE
	                                               MOV                 SI,OFFSET OTHERNAMEDATA
	                                               MOV                 DI,OFFSET NAME2DATA
	                                              
	LOOP_SWITCH_NAME_OTHER_PLAYER_ONE:             

	                                               MOV                 AL,[SI]
	                                               MOV                 [DI],AL
	                                               INC                 SI
	                                               INC                 DI
	                                               LOOP                LOOP_SWITCH_NAME_OTHER_PLAYER_ONE
	                                               POPA

	                                               CALL                EXIT_MAIN_MENU


	NOT_F2_RECEIVED:                               
	                                               CMP                 ScanCodeReceivedChar,27D
	                                               JNZ                 WAIT_FOR_KEY_PRESSED

	                                               JMP                 QUIT_OPTION
												   

	WAIT_FOR_KEY_PRESSED:                          
	                                               MOV                 AH,1
	                                               INT                 16H
	                                               JNZ                 IS_F2
	                                               JMP                 Receive_loop_MAIN

	IS_F2:                                         
	                                               CMP                 AH,3CH
	                                               JNZ                 IS_ESC
	                                               JMP                 START_OPTION

	IS_ESC:                                        
	                                               CMP                 AL,27D
	                                               JNZ                 IS_F1
	                                               JMP                 QUIT_OPTION

	IS_F1:                                         
	                                               CMP                 AH,F1_ScanCode
	                                               JNZ                 OTHER_KEY
	                                               JMP                 CHATTING_OPTION


	OTHER_KEY:                                     
	                                               MOV                 AH,0
	                                               INT                 16H
	                                               JMP                 Receive_loop_MAIN

	START_OPTION:                                  
	                                               mov                 ah,0
	                                               int                 16h
	                                               CMP                 ScanCodeReceivedChar,3CH
	                                               JNZ                 SEND_GANE_INVITATION
	                                               MOV                 ScanCodeSentChar,3CH
	                                               SENDCHAR            ScanCodeSentChar
	                                               mov                 ScanCodeReceivedChar,0

	                                               mov                 Current_player_NUMBER,2

	                                               MOV                 AX,CURRENTNAMEACTUALSIZE
	                                               MOV                 NAME2ACTUALSIZE,AX
	                                               MOV                 AL,CURRENTNAMEBUFFERSIZE
	                                               MOV                 NAME2BUFFERSIZE,AL
	                                               MOV                 CX,CURRENTNAMEACTUALSIZE
	                                               MOV                 SI,OFFSET CURRENTNAMEDATA
	                                               MOV                 DI,OFFSET NAME2DATA
	LOOP_SWITCH_NAME_PLAYER_TWO:                   
	                                               MOV                 AL,[SI]
	                                               MOV                 [DI],AL
	                                               INC                 SI
	                                               INC                 DI
	                                               LOOP                LOOP_SWITCH_NAME_PLAYER_TWO



	                                               MOV                 AX,WORD PTR OTHERNAMEACTUALSIZE
	                                               MOV                 NAME1ACTUALSIZE,AX
	                                               MOV                 AL,OTHERNAMEBUFFERSIZE
	                                               MOV                 NAME1BUFFERSIZE,AL
	                                               MOV                 CX, OTHERNAMEACTUALSIZE
	                                               MOV                 SI,OFFSET OTHERNAMEDATA
	                                               MOV                 DI,OFFSET NAME1DATA
	                                              
	LOOP_SWITCH_NAME_OTHER_PLAYER_TWO:             

	                                               MOV                 AL,[SI]
	                                               MOV                 [DI],AL
	                                               INC                 SI
	                                               INC                 DI
	                                               LOOP                LOOP_SWITCH_NAME_OTHER_PLAYER_TWO


	                                               JMP                 EXIT_MAIN_MENU

	                                              

	SEND_GANE_INVITATION:                          
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
		
	                                               MOV                 BL,59
	                                               MOV                 CH,0
	                                               MOV                 CL,30
	                                               MOV                 DL,0
	                                               MOV                 DH, 2
	                                               MOV                 BP, OFFSET SENT_GAME_INVITAITON
	                                               INT                 10H

	                                               MOV                 CL,BYTE PTR OTHERNAMEACTUALSIZE
	                                               MOV                 CH,0
	                                               MOV                 DL, 30
	                                               MOV                 DH, 2
	                                               MOV                 BP, OFFSET OTHERNAMEDATA
	                                               INT                 10H

	                                               
	                                               MOV                 SI,OFFSET CURRENTNAMEDATA
	                                               MOV                 CX,CURRENTNAMEACTUALSIZE

	                                               MOV                 ScanCodeSentChar,3CH
	                                               SENDCHAR            ScanCodeSentChar
												   
	                                         

	                                               JMP                 Receive_loop_MAIN

	                                               


	QUIT_OPTION:                                   

	                                               MOV                 ScanCodeSentChar,27D
	                                               SENDCHAR            ScanCodeSentChar

	                                               MOV                 CX,0
	                                               MOV                 DX,0

	                                               MOV                 AL, 0
	                                               MOV                 AH,0CH



                       
	;    INT       10H
	;    INC       CX
	;    CMP       CX,320
	;    JC        PAINT_BACKGROUND_QUIT

	;    INC       DX
	;    MOV       CX,0
	;    CMP       DX,200
	;    JC        PAINT_BACKGROUND_QUIT
	;    RET
	                                               MOV                 AX, 4F02H
	                                               MOV                 BX, 0101H
	                                               INT                 10H
	                                               MOV                 AH, 4CH
	                                               INT                 21H
	                                               RET

	CHATTING_OPTION:                               
	                                               mov                 ah,0
	                                               int                 16h

	                                               CMP                 ScanCodeReceivedChar,F1_ScanCode
	                                               JNZ                 SEND_CHAT_INVITATION
	                                               MOV                 ScanCodeSentChar,F1_ScanCode
	                                               SENDCHAR            ScanCodeSentChar

	                                               INT                 10H
	                                               INC                 CX
	                                               CMP                 CX,640
	                                               JC                  PAINT_BACKGROUND_exit

	                                               INC                 DX
	                                               MOV                 CX,0
	                                               CMP                 DX,25
	                                               JC                  PAINT_BACKGROUND_exit
	                                               mov                 ScanCodeReceivedChar,0
	                                               mov                 ScanCodeSentChar,0
	                                               CALL                CHAT_ROOM
	                                              

	SEND_CHAT_INVITATION:                          
	                                               MOV                 AH,13H
	                                               MOV                 BH,0
	                                               MOV                 BL,59
	                                               MOV                 CH,0
												   
	                                               MOV                 CL,30
	                                               MOV                 DL,0
	                                               MOV                 DH, 0
	                                               MOV                 BP, OFFSET SENT_CHAT_INVITAITON
	                                               INT                 10H

	                                               MOV                 CL,BYTE PTR OTHERNAMEACTUALSIZE
	                                               MOV                 CH,0
	                                               MOV                 DL, 30
	                                               MOV                 DH, 0
	                                               MOV                 BP, OFFSET OTHERNAMEDATA
	                                               INT                 10H

	                                               

	                                               MOV                 ScanCodeSentChar,F1_ScanCode
	                                               SENDCHAR            ScanCodeSentChar
												   
	                                         

	                                               JMP                 Receive_loop_MAIN
	                                               PUSHA


MAIN_MENU ENDP






END MAIN