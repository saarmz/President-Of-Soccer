IDEAL
MODEL small
STACK 100h


FILE_NAME_CHAR1 equ 'TrumpBMP.bmp'
FILE_NAME_CHAR2 equ 'lin.bmp'
FILE_NAME_CHAR3 equ 'FieldTop.bmp' ;3 background pictures for smoothness
FILE_NAME_CHAR4 equ 'FieldBL.bmp' ;bottom left
FILE_NAME_CHAR5 equ 'FieldBR.bmp' ;bottom right
FILE_NAME_CHAR6 equ 'ball.bmp'
FILE_NAME_CHAR7 equ 'TrumpWin.bmp'
FILE_NAME_CHAR8 equ 'LinWin.bmp'
FILE_NAME_CHAR9 equ 'MenuPic.bmp'


DATASEG
; --------------------------
	
	;BMP parameters
	ScrLine     db 320 dup (0)  ; One picture line read buffer
	
    FileHandle    dw ?
    Header         db 54 dup(0)
    Palette     db 400h dup (0)
	FileName1 	db FILE_NAME_CHAR1 ,0
	FileName2 db FILE_NAME_CHAR2 ,0
	FileName3 db FILE_NAME_CHAR3 ,0
	FileName4 db FILE_NAME_CHAR4 ,0
	FileName5 db FILE_NAME_CHAR5 ,0
	FileName6 db FILE_NAME_CHAR6 ,0
	FileName7 db FILE_NAME_CHAR7 ,0
	FileName8 db FILE_NAME_CHAR8 ,0
	FileName9 db FILE_NAME_CHAR9 ,0
	
    BMPLeft dw ?
    BmpTop dw ?
    BmpColSize dw ?
    BmpRowSize dw ?
	
	;Random parameters
	RndCurrentPos dw 0
	
	;Program parameters
	xpos dw 0
	ypos dw 0
	color db 0
	width_ dw 0
	length_ dw 0
	
	char1x dw 30
	char2x dw 260
	ballX dw 150
	ballY dw 60
	ballXSpeed dw 3
	ballYSpeed dw 3
	
	moneTime1 dw 0 ;To make the ball move every selected time
	moneTime2 dw 0
	moneTime3 dw 0
	
	limit dw -10
	xLimit dw -6
	
	;flag variables
	xFlag db 0
	jmpFlag1 db 0
	jmpFlag2 db 0
	cleanLeftFlag1 db 0
	cleanLeftFlag2 db 0
	cleanFlagBall db 0 ;if it's 0 - left is clean. if it's 1 - right is clean
	timeFlag1 db 0
	timeFlag2 db 0
	goalFlag db 0
	ColTopFlag db 0 ;check if there's a need to change both x and y velocities
	charFlag db 0 ;check which character was hit
	continueFlag db 0 ;check if the players want to keep playing
	resetRoundFlag db 0 ;check if there was a goal scored and the round needs to reset
	
	;Player's scores
	score1 db 0
	score2 db 0
	
	gravityFlag db 0
; --------------------------




;Cycles=max in the DOSBox




CODESEG
start:
	mov ax, @data
	mov ds, ax
; --------------------------
	
	mov ax, 13h ;Set graphics mode
	int 10h
	

	call Menu
	cmp [continueFlag], 2 ;check if the player/s want to exit the game
	je MainFinishMidJump2
	
	call Random
	call DrawScreen
	mov ah, 7 ;wait for input
	int 21h
	
KeyboardLP:
	;check if there's a winner - if someone reached 8 goals
	cmp [score2], 8
	je Player2Won
	
	cmp [score1], 8
	jne CheckReset
	
Player1Won:
	call EndGame1
	cmp [continueFlag], 2 ;don't continue
	je MainFinishMidJump
	
	call ResetAll
	call DrawScreen
	mov ah, 7 ;wait for input
	int 21h
	
	jmp KeyboardLP
	
MainFinishMidJump2:
	jmp MainFinishMidJump
	
Player2Won:
	call EndGame2
	cmp [continueFlag], 2
	je MainFinishMidJump
	
	call ResetAll
	jmp KeyboardLP

CheckReset:
	cmp [resetRoundFlag], 1
	jne GameLoop
	
	call ResetRound
	mov [resetRoundFlag], 0
	
GameLoop:
	;check how much time has passed since the last time the ball moved
	cmp [timeFlag1], 1
	je @@MoneTime2
	
	inc [moneTime1]
	cmp [moneTime1], 65535
	jb MainLoop
	
	mov [timeFlag1], 1
	
@@MoneTime2:
	cmp [timeFlag2], 1
	je @@MoneTime3
	
	inc [moneTime2]
	cmp [moneTime2], 65535
	jb MainLoop
	
	mov [timeFlag2], 1
@@MoneTime3:
	inc [moneTime3]
	cmp [moneTime3], 65535
	jb MainLoop
	
	call ResetTimeVars
	jmp MoveBall
	
MidJump2: ;jump to the start from the end due to relative jumps
	jmp KeyboardLP
	
MainFinishMidJump:
	jmp MainFinish

MoveBall: ;move the ball while taking into account physics
	call BallMovement
	cmp [goalFlag], 1
	je NewRound
	call Collision
	
	
	inc [xFlag] ;Slow down the X axis speed to simulate heat energy and friction
	cmp [xFlag], 40
	jb MainLoop
	
	mov [xFlag], 0
	cmp [ballXSpeed], 0
	jl AddX
	jg SubX
	je ResetX
	
	dec [ballXSpeed]
	jmp MainLoop

AddX:
	inc [ballXSpeed]
	jmp MainLoop
	
SubX:
	dec [ballXSpeed]
	jmp MainLoop
	
ResetX:
	mov [ballXSpeed], 0
	jmp MainLoop
	
MainLoop:
	mov ah, 1
	int 16h
	jz MidJump2
	mov ah, 0
	int 16h

	;check if the right keys were pressed
CheckLeft1:
	cmp ah, 1Eh ;key 'a'
	jne CheckRight1
	cmp [char1x], 10
	jle CheckKick1
	jmp Character1Left
	
CheckRight1:
	cmp ah, 20h ;key 'd'
	jne CheckKick1
	cmp [char1x], 280
	jge CheckEnd
	
	jmp Character1Right
	
CheckKick1: ;check if the first player wants to kick
	cmp ah, 11h
	jne CheckLeft2
	call Kick1
	
	jmp KeyboardLP
	
	;if the right keys were pressed, move the players
Character1Left:
	call Char1Left
	
	jmp CheckEnd
Character1Right:
	call Char1Right
	
	jmp CheckLeft2
	
MidJump: ;jump to the finish from the middle due to relative jumps
	jmp KeyboardLP
	
NewRound:
	mov [resetRoundFlag], 1
	jmp MidJump2
	
CheckLeft2:
	cmp ah, 4Bh ;left arrow
	jne CheckRight2
	cmp [char2x], 10
	jle CheckEnd
	
	jmp Character2Left
CheckRight2:
	cmp ah, 4Dh ;right arrow
	jne CheckKick2
	cmp [char2x], 288
	jge CheckEnd
	
	jmp Character2Right
	
CheckKick2: ;check if the second player wants to kick
	cmp ah, 48h
	jne CheckEnd
	call Kick2
	
	jmp KeyboardLP
	
Character2Left:
	call Char2Left
	
	jmp CheckEnd
Character2Right:
	call Char2Right
	
	jmp CheckEnd
	
CheckEnd:
	cmp ah, 1h ;escape
	jne MidJump
	
MainFinish:
	mov ax, 2 ;text mode
	int 10h
; --------------------------
exit:
	mov ax, 4c00h
	int 21h


;------------------------
;Reset all the variables
;------------------------
proc ResetAll
	
	mov [moneTime1], 0
	mov [moneTime2], 0
	mov [moneTime3], 0
	mov [xpos], 0
	mov [ypos], 0
	mov [color], 0
	mov [width_], 0
	mov [length_], 0
	mov [char1x], 30
	mov [char2x], 260
	mov [ballX], 150
	mov [ballY], 60
	call Random
	mov [limit], -10
	mov [xLimit], -6
	mov [xFlag], 0
	mov [jmpFlag1], 0
	mov [jmpFlag2], 0
	mov [cleanLeftFlag1], 0
	mov [cleanLeftFlag2], 0
	mov [cleanFlagBall], 0
	mov [timeFlag1], 0
	mov [timeFlag2], 0
	mov [goalFlag], 0
	mov [ColTopFlag], 0
	mov [charFlag], 0
	mov [score1], 0
	mov [score2], 0
	
	call DrawScreen
	mov ah, 7
	int 21h
	
	ret
endp ResetAll

;----------------------------------------------
;Reset most of the variables, except for score
;----------------------------------------------
proc ResetRound
	mov [moneTime1], 0
	mov [moneTime2], 0
	mov [moneTime3], 0
	mov [xpos], 0
	mov [ypos], 0
	mov [color], 0
	mov [width_], 0
	mov [length_], 0
	mov [char1x], 30
	mov [char2x], 260
	mov [ballX], 150
	mov [ballY], 60
	call Random
	mov [limit], -10
	mov [xLimit], -6
	mov [xFlag], 0
	mov [jmpFlag1], 0
	mov [jmpFlag2], 0
	mov [cleanLeftFlag1], 0
	mov [cleanLeftFlag2], 0
	mov [cleanFlagBall], 0
	mov [timeFlag1], 0
	mov [timeFlag2], 0
	mov [goalFlag], 0
	mov [ColTopFlag], 0
	mov [charFlag], 0
	
	mov [gravityFlag], 1
	
	call DrawScreen
	mov ah, 7
	int 21h
	ret
endp ResetRound

;-------------------------
;Reset the time variables
;-------------------------
proc ResetTimeVars
	mov [moneTime1], 0
	mov [moneTime2], 0
	mov [moneTime3], 0
	mov [timeFlag1], 0
	mov [timeFlag2], 0
	
	ret
endp ResetTimeVars

;-------------------------------------------------------------------------------
;If player 1 presses the S key and the ball is in the right area, kick the ball
;-------------------------------------------------------------------------------
proc Kick1
		push [char1X]
		push bx
		
		;check if the ball is near the player
		
		mov bx, [ballY]
		cmp bx, 145
		jbe @@Finish
		
		mov bx, [ballX]
		add [char1X], 38
		cmp bx, [char1X]
		ja @@Finish
		
		sub [char1X], 11
		cmp bx, [char1X]
		jb @@Finish
		
		;change the ball's speed and direction
		mov [ballXSpeed], 5
		mov [xLimit], -6
		mov [ballYSpeed], 9
		mov [limit], -10
		sub [ballY], 50
		add [ballX], 6
		
	@@Finish:
		
		pop bx
		pop [char1X]
		ret
endp Kick1

;-------------------------------------------------------------------------------
;If player 2 presses the S key and the ball is in the right area, kick the ball
;-------------------------------------------------------------------------------
proc Kick2
		push [char2X]
		push bx
		
		;check if the ball is near the player
		
		mov bx, [ballY]
		cmp bx, 145
		jbe @@Finish
		
		mov bx, [ballX]
		sub [char2X], 35
		cmp bx, [char2X]
		jb @@Finish
		
		add [char2X], 45
		cmp bx, [char2X]
		ja @@Finish
		
		;change the ball's speed and direction
		mov [ballXSpeed], -5
		mov [xLimit], -6
		mov [ballYSpeed], 9
		mov [limit], -10
		sub [ballY], 50
		sub [ballX], 6
		
	@@Finish:
		
		pop bx
		pop [char2X]
		ret
endp Kick2

;------------------------------------------------------------------------------------------------
;check if a goal was scored. if so, move the characters and the ball to their starting positions
;------------------------------------------------------------------------------------------------
proc Goals 
		cmp [ballY], 110
		jbe @@Finish
		
		cmp [ballX], 300
		jae @@Char1Goal
		
		cmp [ballX], 8
		jae @@Finish
		
		inc [score2]
		mov [goalFlag], 1
		jmp @@Finish
		
	@@Char1Goal:
		inc [score1]
		mov [goalFlag], 1
		
	@@Finish:
		ret
endp Goals

;-------------------------------------------
;check if the ball collided with the player
;-------------------------------------------
proc Collision 
		push ax
		push bx
		push cx
		push [char1X]
		push [char2X]
		
	@@CheckY:
		mov ax, [char1X] ;backup
		mov cx, [char2X] ;backup
		
		;Check Y axis positions
		mov bx, [ballY]
		cmp bx, 110
		jbe @@MidJump
		
		
	@@CheckX:
		;check if the ball is not close to the players
		mov bx, [ballX]
		sub [char1X], 6
		cmp bx, [char1X]
		jb @@MidCheckChar2Jump
		
		add [char1X], 37
		cmp bx, [char1x]
		ja @@MidCheckChar2Jump
		
		mov [charFlag], 1
		;check hit with player 1
		
		sub [char1X], 8
		cmp bx, [char1x]
		jae @@CharSide
		
		sub [char1X], 10
		cmp bx, [char1x]
		jae @@CharTopSide
		
		sub [char1X], 10
		cmp bx, [char1X]
		jae @@CharTopMidJump
		
		sub [char1X], 6
		jb @@MidCheckChar2Jump
		
		sub [ballXSpeed], 1
		
	@@MidJump:
		jmp @@Finish
		
	@@MidCheckChar2Jump:
		jmp @@CheckChar2
		
	@@CharSide: ;ball hit the side of a character
		cmp [ballXSpeed], 0
		jle @@MinusXSpeedJump
		
		add [ballXSpeed], 1
		neg [ballXSpeed]
		jmp @@OutOfHitBox
		
	@@CharTopMidJump:
		jmp @@CharTop
		
	@@CharTopSide: ;ball hit the top-side of a character
		sub [ballY], 10
		mov [ColTopFlag], 1
		cmp [ballXSpeed], 0
		jle @@MinusXSpeedJump
		
		add [ballXSpeed], 1
		neg [ballXSpeed]
		jmp @@Finish
		
	@@CharTop: ;ball hit the top of a character
		sub [ballY], 10
		cmp [ballYSpeed], 0
		jl @@MinusYSpeedJump
		
		add [ballYSpeed], 1
		neg [ballYSpeed]
		jmp @@Finish
	
	@@MinusXSpeedJump:
		jmp @@MinusXSpeed
		
	@@CharSideJump:
		jmp @@CharSide
		
	@@MinusYSpeedJump:
		jmp @@MinusYSpeed
	
	@@CheckChar2:
		;check if the ball is far from the characters
		mov bx, [ballX]
		sub [char2X], 21
		cmp bx, [char2x]
		jb @@MidJump2
		
		add [char2X], 50
		cmp bx, [char2x]
		ja @@MidJump2
		
		mov [charFlag], 2
		;check hit with player 2
		
		sub [char2X], 44
		cmp bx, [char2x]
		jbe @@CharSideJump
		
		add [char2X], 15
		cmp bx, [char2x]
		jbe @@CharTopSide
		
		add [char2X], 13
		cmp bx, [char2X]
		jbe @@CharTop
		
		add [char2X], 8
		jbe @@CharSideJump
		
		jmp @@Finish
	
	@@MidJump2: ;due to relative jumps :(
		jmp @@Finish
	
	@@OutOfHitBox: ;place the ball out of the first character's hitbox
		cmp [charFlag], 2
		je @@OutOfHitBox2
		
		add ax, 12 ;put it in the middle to test which side
		
		cmp ax, [ballX]
		jb @@AddBallX1
		
		sub ax, 35
		mov [ballX], ax
		
		jmp @@Finish
		
	@@OutOfHitBox2: ;place the ball out of the second character's hitbox
		cmp cx, [ballX]
		jb @@AddBallX2
		
		sub cx, 35
		mov [ballX], cx
		
		jmp @@Finish
	@@AddBallX2:
		add cx, 16
		mov [ballX], cx
		
		jmp @@Finish
	
	@@OutOfHitBoxJump:
		jmp @@OutOfHitBox
	
	@@AddBallX1:
		add ax, 24
		mov [ballX], ax
		
		jmp @@Finish
		
		;taking into account the ball's speed might be negative
	@@MinusYSpeed:
		sub [ballYSpeed], 1
		neg [ballYSpeed]
		jmp @@OutOfHitBox
		
	@@MinusXSpeed:
		neg [ballXSpeed]
		add [ballXSpeed], 1
		
		mov [xFlag], 0 ;so the ball doesn't stop unrealistically
		
		cmp [ColTopFlag], 0
		je @@OutOfHitBoxJump
		
		mov [ColTopFlag], 0
		;change y speed as well
		cmp [ballYSpeed], 0
		jl @@MinusYSpeed
		
		add [ballYSpeed], 1
		neg [ballYSpeed]
		jmp @@Finish
	
	
	@@Finish:
		mov [charFlag], 0
		
		
		pop [char2X]
		pop [char1X]
		pop cx
		pop bx
		pop ax
		ret
endp Collision



;-------------------------
;Show the full background
;-------------------------
proc ShowBackground
	
	call BackgroundTop
	call BackgroundBottomLeft
	call BackgroundBottomRight
	
	ret
endp ShowBackground

;------------------------------------
;Show the top half of the background
;------------------------------------
proc BackgroundTop
	push ax
	push bx
	push cx
	push dx
	
	mov dx, offset FileName3
	mov [BMPLeft], 0
	mov [BmpTop], 0
	mov [BmpColSize], 320
	mov [BmpRowSize], 100
	
	call OpenBmpFile	
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBmp

	call CloseBmpFile
	
	call ShowScore ;Showing the score
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp BackgroundTop

;-----------------------------------------------
;Show the bottom left quarter of the background
;-----------------------------------------------
proc BackgroundBottomLeft
	push ax
	push bx
	push cx
	push dx
	
	mov dx, offset FileName4
	mov [BMPLeft], 0
	mov [BmpTop], 100
	mov [BmpColSize], 160
	mov [BmpRowSize], 100
	
	call OpenBmpFile	
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBmp

	call CloseBmpFile
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp BackgroundBottomLeft

;------------------------------------------------
;Show the bottom right quarter of the background
;------------------------------------------------
proc BackgroundBottomRight
	push ax
	push bx
	push cx
	push dx
	
	mov dx, offset FileName5
	mov [BMPLeft], 160
	mov [BmpTop], 100
	mov [BmpColSize], 160
	mov [BmpRowSize], 100
	
	call OpenBmpFile	
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBmp

	call CloseBmpFile
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp BackgroundBottomRight

;--------------------------------------------------
;Show the player's scores in the top of the screen
;--------------------------------------------------
proc ShowScore
	;Player 1's score
	mov ah, 2
	mov bh, 0
	mov dh, 2 ;ypos
	mov dl, 17 ;xpos
	int 10h
	
	mov al, [score1]
	xor ah, ah
	call ShowAxDecimal
	
	; print :
	mov ah, 2
	mov bh, 0
	mov dh, 2 ;ypos
	mov dl, 19 ;xpos
	int 10h
	
	mov dl, ':'
	mov ah, 2
	int 21h
	
	;Player 2's score
	mov ah, 2
	mov bh, 0
	mov dh, 2 ;ypos
	mov dl, 21 ;xpos
	int 10h
	
	mov al, [score2]
	xor ah, ah
	call ShowAxDecimal
	
	ret
endp ShowScore

;-------------------------------------------
;Show the first character - Donald TrumpBMP
;-------------------------------------------
proc ShowTrump 
		push ax
		push bx
		push cx
		push dx
		
		;print the player
		mov dx, offset FileName1
		mov ax, [char1x]
		mov [BMPLeft], ax
		mov [BmpTop], 130
		mov [BmpColSize], 25
		mov [BmpRowSize], 50
	
		call OpenBmpFile	
	
		call ReadBmpHeader
	
		call ReadBmpPalette
	
		call CopyBmpPalette
	
		call ShowBmp

		call CloseBmpFile
		
		pop dx
		pop cx
		pop bx
		pop ax
		ret
endp ShowTrump

;--------------------------------------------
;Show the second character - Abraham Lincoln
;--------------------------------------------
proc ShowLin
		push ax
		push bx
		push cx
		push dx
	
		;print the player
		mov dx, offset FileName2
		mov ax, [char2x]
		mov [BmpLeft], ax
		mov [BmpTop], 130
		mov [BmpColSize], 21
		mov [BmpRowSize], 50
	
		call OpenBmpFile	
	
		call ReadBmpHeader
	
		call ReadBmpPalette
	
		call CopyBmpPalette
	
		call ShowBmp

		call CloseBmpFile
		
		pop dx
		pop cx
		pop bx
		pop ax
		ret
endp ShowLin

;---------------------------------------------------------
;Move the ball realistically, taking into account gravity
;---------------------------------------------------------
proc BallMovement
		push ax
		push bx
		push cx
		
		call Gravity
		jmp @@CheckRight
	@@Reset:
		mov [ballYSpeed], 0
		jmp @@Draw
		
		;check if the ball hit the grass
	@@CheckBottom:
		mov cx, 170
		add cx, [limit]
		cmp [ballY], cx
		jb @@Draw
		
		mov [ballY], 170
		jmp @@SwitchY
		
		;check if the ball is in the left edge of the screen, and if a goal is scored
	@@CheckLeft:
		cmp [ballX], 6
		ja @@CheckTop
		call Goals ;check goals
		
		cmp [goalFlag], 1
		jne @@SwitchX
		
		jmp @@Finish
	
	@@LimitX: ;limit the ball's X axis speed so the ball won't move too fast
		mov bx, [xLimit]
		neg bx
		
		mov [ballXSpeed], bx
		
	@@MinusLimitX:
		mov bx, [xLimit]
		mov [ballXSpeed], bx
		
		;check if the ball is in the left edge of the screen, and if a goal is scored
	@@CheckRight:
		cmp [ballX], 300
		jb @@CheckLeft
		
		call Goals
		
		cmp [goalFlag], 1
		jne @@SwitchX
		
		jmp @@Finish
		
	@@SwitchX: ;turn the ball's X axis speed to the other direction
		neg [ballXSpeed]
		
	@@CheckTop: ;check if the ball hit the "ceiling"
		cmp [ballY], 20
		ja @@CheckBottom
		
	@@SwitchY: ;turn the ball's Y axis speed to the other direction
		neg [ballYSpeed]
		add [limit], 2
		cmp [ballY], 146
		jbe @@Draw
		
		cmp [ballYSpeed], 1
		jbe @@Reset
		
	@@Draw: ;draw the ball, if the ball is moving
		call CleanBall ;clean the ball's last location
		xor ah, ah
		mov ax, [ballXSpeed] ;move x
		cmp ax, 6
		jg @@LimitX
		
		cmp ax, -6
		jl @@MinusLimitX
		
		add [ballX], ax
		mov ax, [ballYSpeed]
		sub [ballY], ax ;move y
		call ShowBall
		
	@@Finish:
		call Collision ;check if the ball collided with the players
	
		pop cx
		pop bx
		pop ax
		ret
endp BallMovement

;--------------------------------------------------------------------------
;Clean the ball's last location, while making sure no character was erased
;--------------------------------------------------------------------------
proc CleanBall
		jmp @@CheckYSpeedZero
		
	@@CheckZero:
		cmp [ballXSpeed], 0
		jne @@CheckBall
		
		cmp [ballY], 165
		jae @@MidJump
		
		jmp @@CheckBall
		
	@@BothCleaned:
		call BackgroundBottomRight
		call ShowTrump
		call ShowLin
		jmp @@Finish
	
	@@MidJump:
		jmp @@Finish
	
	@@CheckYSpeedZero:
		cmp [ballYSpeed], 0
		je @@CheckZero
		
	@@CheckBall:
		
		cmp [ballY], 100 ;if the ball is in the top half, clean in and finish
		jbe @@CleanTop
	
	@@CheckBottom:
		cmp [ballY], 85
		jb @@Finish
		
		;Check ball's location on the X axis
		cmp [ballX], 160 
		jae @@CleanRight
		call BackgroundBottomLeft
		
		cmp [ballX], 145
		ja @@BothCleaned
		
	@@CheckChar1: ;Check if the characters were deleted and show them if they were
		cmp [char1x], 160
		jbe @@Char1Left
		
		cmp [cleanFlagBall], 1 ;1 if the bottom right part was cleaned
		jne @@CheckChar2
		
		call ShowTrump
		jmp @@CheckChar2
		
	@@Char1Left:
		cmp [cleanFlagBall], 0 ;0 if the bottom left part was cleaned
		jne @@CheckChar2
		
		call ShowTrump
		
	@@CheckChar2:
		cmp [char2x], 160
		jbe @@Char2Left
		
		cmp [cleanFlagBall], 1
		jne @@Finish
		
		call ShowLin
		jmp @@Finish
		
	@@Char2Left:
		cmp [cleanFlagBall], 0
		jne @@Finish
		call ShowLin
		jmp @@Finish
	
	@@CleanRight:
		call BackgroundBottomRight
		mov [cleanFlagBall], 1
		jmp @@CheckChar1
	
	@@CleanTop:
		call BackgroundTop
		jmp @@CheckBottom
		
	@@Finish:
		mov [cleanFlagBall], 0
		
		ret
endp CleanBall

;----------------------------
;Show the ball's BMP picture
;----------------------------
proc ShowBall ;Draw the ball
	push cx
	push dx
	push di
	push ax
	push bx
	
	mov dx, offset FileName6
	mov ax, [ballX]
	mov [BMPLeft], ax
	mov bx, [ballY]
	mov [BmpTop], bx
	mov [BmpColSize], 15
	mov [BmpRowSize], 15
	
	call OpenBmpFile	
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBmp

	call CloseBmpFile
	
	pop bx
	pop ax
	pop di
	pop dx
	pop cx
	ret
endp ShowBall

;------------------------------
;move the first character left
;------------------------------
proc Char1Left
		;clean the part of the screen
		cmp [char1x], 160
		jae @@CleanRight
		
		call BackgroundBottomLeft
		cmp [char1x], 135
		jb @@CheckChar2Left
		
		mov [cleanLeftFlag1], 1
	@@CleanRight:
		call BackgroundBottomRight
		cmp [char2x], 139
		jbe @@CheckChar2Left
		
		call ShowLin
		cmp [cleanLeftFlag1], 0
		je @@DisplayChar1
		
	@@CheckChar2Left: ;Make sure character 2 isn't deleted as well on the left
		cmp [char2x], 160
		ja @@DisplayChar1
		call ShowLin
		
	@@DisplayChar1:
		sub [char1x], 8
		call ShowTrump
		mov [cleanLeftFlag1], 0
		
		call Collision
	ret
endp Char1Left

;-------------------------------
;move the first character right
;-------------------------------
proc Char1Right
	;clean the part of the screen
		cmp [char1x], 160
		jae @@CleanRight
		
		call BackgroundBottomLeft
		cmp [char1x], 135
		jb @@CheckChar2Left
		
		mov [cleanLeftFlag1], 1
	@@CleanRight:
		call BackgroundBottomRight
		cmp [char2x], 139
		jbe @@CheckChar2Left
		
		call ShowLin
		cmp [cleanLeftFlag1], 0
		je @@DisplayChar1
		
	@@CheckChar2Left: ;Make sure character 2 isn't deleted as well on the left
		cmp [char2x], 160
		ja @@DisplayChar1
		call ShowLin
		
	@@DisplayChar1:
		add [char1x], 8
		call ShowTrump
		mov [cleanLeftFlag1], 0
		
		call Collision
	ret
endp Char1Right

;-------------------------------
;move the second character left
;-------------------------------
proc Char2Left
	;clean the part of the screen
		cmp [char2x], 160
		jae @@CleanRight
		
		call BackgroundBottomLeft
		cmp [char2x], 139
		jb @@CheckChar1Left
		
		mov [cleanLeftFlag2], 1
	@@CleanRight:
		call BackgroundBottomRight
		cmp [char1x], 135
		jbe @@CheckChar1Left
		
		call ShowTrump
		cmp [cleanLeftFlag2], 0
		je @@DisplayChar2
		
	@@CheckChar1Left: ;Make sure character 1 isn't deleted as well on the left
		cmp [char1x], 160
		ja @@DisplayChar2
		call ShowTrump
		
	@@DisplayChar2:
		sub [char2x], 8
		call ShowLin
		mov [cleanLeftFlag2], 0
		
		call Collision
	ret
endp Char2Left

;--------------------------------
;move the second character right
;--------------------------------
proc Char2Right
	;clean the part of the screen
		cmp [char2x], 160
		jae @@CleanRight
		
		call BackgroundBottomLeft
		cmp [char2x], 139
		jb @@CheckChar1Left
		
		mov [cleanLeftFlag2], 1
	@@CleanRight:
		call BackgroundBottomRight
		cmp [char1x], 135
		jbe @@CheckChar1Left
		
		call ShowTrump
		cmp [cleanLeftFlag2], 0
		je @@DisplayChar2
		
	@@CheckChar1Left: ;Make sure character 1 isn't deleted as well on the left
		cmp [char1x], 160
		ja @@DisplayChar2
		call ShowTrump
		
	@@DisplayChar2:
		add [char2x], 8
		call ShowLin
		mov [cleanLeftFlag2], 0
		
		call Collision
	ret
endp Char2Right

;-------------------------------------------------------
;Simulate gravity to help moving the ball realistically
;-------------------------------------------------------
proc Gravity
		push ax
		
		cmp [gravityFlag], 1
		je @@Finish
		
		mov ax, [limit]
		cmp [ballYSpeed], ax
		jle @@Finish
		
		dec [ballYSpeed]
	@@Finish:
		pop ax
		ret
endp Gravity

;-------------------------------------------------------------------------------------
;Display the end screen if player 1 won and give the players an option to play again or exit the game
;-------------------------------------------------------------------------------------
proc EndGame1
		call TrumpWon
		mov ax, 0 ;reset mouse
		int 33h
		mov ax, 1 ;display mouse
		int 33h
		
	@@MouseLP:
		mov ax, 3 ;get mouse info
		int 33h
	
		shr cx, 1
		sub dx, 1
		
		cmp bx, 01h
		jne @@MouseLP
		
		;check ypos
		cmp dx, 153
		jb @@MouseLP
		
		cmp dx, 180
		ja @@MouseLP
		
		;check xpos
		cmp cx, 153
		jb @@MouseLP
		
		cmp cx, 223
		jbe @@Continue
		
		cmp cx, 232
		jb @@MouseLP
		
		cmp cx, 302
		jbe @@Exit
		
		jmp @@MouseLP
	@@Continue:
		mov [continueFlag], 1
		jmp @@Finish
		
	@@Exit:
		mov [continueFlag], 2
		
	@@Finish:
		mov ax, 2 ;remove mouse
		int 33h
		
		ret
endp EndGame1

;-------------------------------------------------------------------------------------
;Display the end screen if player 2 won and give the players an option to play again or exit the game
;-------------------------------------------------------------------------------------
proc EndGame2
		call LinWon
		mov ax, 0 ;reset mouse
		int 33h
		mov ax, 1 ;display mouse
		int 33h
		
	@@MouseLP:
		mov ax, 3 ;get mouse info
		int 33h
	
		shr cx, 1
		sub dx, 1
		
		cmp bx, 01h
		jne @@MouseLP
		
		;check ypos
		cmp dx, 147
		jb @@MouseLP
		
		cmp dx, 168
		ja @@MouseLP
		
		;check xpos
		cmp cx, 21
		jb @@MouseLP
		
		cmp cx, 91
		jbe @@Continue
		
		cmp cx, 108
		jb @@MouseLP
		
		cmp cx, 178
		jbe @@Exit
		
		jmp @@MouseLP
		
	@@Continue:
		mov [continueFlag], 1
		jmp @@Finish
		
	@@Exit:
		mov [continueFlag], 2
		
	@@Finish:
		mov ax, 2 ;remove mouse
		int 33h
		
		ret
endp EndGame2

;---------------------------------
;Show end picture if player 1 one
;---------------------------------
proc TrumpWon
	push dx
	
	mov dx, offset FileName7
	mov [BmpLeft], 0
	mov [BmpTop], 0
	mov [BmpColSize], 320
	mov [BmpRowSize], 200
	
	call OpenBmpFile	
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBmpAll

	call CloseBmpFile
	
	pop dx
	ret
endp TrumpWon

;---------------------------------
;Show end picture if player 2 one
;---------------------------------
proc LinWon
	push dx
	
	mov dx, offset FileName8
	mov [BmpLeft], 0
	mov [BmpTop], 0
	mov [BmpColSize], 320
	mov [BmpRowSize], 200
	
	call OpenBmpFile	
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBmpAll

	call CloseBmpFile
	
	pop dx
	ret
endp LinWon

;-------------------------------------------------------------------
;Display the main menu before starting the game, and wait for input
;-------------------------------------------------------------------
proc Menu 
		;display the picture
		mov dx, offset FileName9 
		mov [BmpLeft], 0
		mov [BmpTop], 0
		mov [BmpColSize], 320
		mov [BmpRowSize], 200
	
		call OpenBmpFile	
	
		call ReadBmpHeader
	
		call ReadBmpPalette
	
		call CopyBmpPalette
	
		call ShowBmpAll

		call CloseBmpFile
	
	
	;wait for mouse input
		mov ax, 0 ;reset mouse
		int 33h
		mov ax, 1 ;display mouse
		int 33h
		
	@@MouseLP:
		mov ax, 3 ;get mouse info
		int 33h
	
		shr cx, 1
		sub dx, 1
		cmp bx, 01h
		jne @@MouseLP
		
		;check ypos
		cmp dx, 6 ;exit button ypos
		jb @@MouseLP
		cmp dx, 28
		jb @@CheckExitX
		
		cmp dx, 123 ;play button ypos
		jb @@MouseLP
		
		cmp dx, 170
		ja @@MouseLP
		
		;check xpos
		cmp cx, 103
		jb @@MouseLP
		
		cmp cx, 216
		ja @@MouseLP
		
		jmp @@Finish ;start playing
		
	@@CheckExitX:
		cmp cx, 292
		jb @@MouseLP
		
		cmp cx, 314
		ja @@Finish
		
		mov [continueFlag], 2
		
	@@Finish:
		mov ax, 2 ;remove mouse
		int 33h
		ret
endp Menu

;---------------------------------------------------------------------------------
;Draw everything on the screen in the game at once (background, characters, ball)
;---------------------------------------------------------------------------------
proc DrawScreen
	call ShowBackground
	call ShowTrump
	call ShowLin
	call ShowBall
	
	ret
endp DrawScreen

;-------------------------
;Generate a random number
;-------------------------
proc Random
	push ax
	push bx
	push dx
	
	;randomize
	mov bx, -2
	mov dx, 2
	call RandomByCsWord
	mov [ballXSpeed], ax
	mov bx, -2
	mov dx, 2
	call RandomByCsWord
	mov [ballYSpeed], ax
	
	pop dx
	pop bx
	pop ax
	ret
endp Random

; Description  : get RND between any bl and bh includs (max 0 -255)
; Input        : 1. BX = min (from 0) , DX, Max (till 64k -1)
; 			     2. RndCurrentPos a  word variable,   help to get good rnd number
; 				 	Declre it at DATASEG :  RndCurrentPos dw ,0
;				 3. EndOfCsLbl: is label at the end of the program one line above END start		
; Output:        AX - rnd num from bx to dx  (example 50 - 1550)
; More Info:
; 	BX  must be less than DX 
; 	in order to get good random value again and again the Code segment size should be 
; 	at least the number of times the procedure called at the same second ... 
; 	for example - if you call to this proc 50 times at the same second  - 
; 	Make sure the cs size is 50 bytes or more 
; 	(if not, make it to be more) 
proc RandomByCsWord
    push es
	push si
	push di
 
	
	mov ax, 40h
	mov	es, ax
	
	sub dx,bx  ; we will make rnd number between 0 to the delta between bl and bh
			   ; Now bh holds only the delta
	cmp dx,0
	jz @@ExitP
	
	push bx
	
	mov di, [word RndCurrentPos]
	call MakeMaskWord ; will put in si the right mask according the delta (bh) (example for 28 will put 31)
	
@@RandLoop: ;  generate random number 
	mov bx, [es:06ch] ; read timer counter
	
	mov ax, [word cs:di] ; read one word from memory (from semi random bytes at cs)
	xor ax, bx ; xor memory and counter
	
	; Now inc di in order to get a different number next time
	inc di
	inc di
	cmp di,(EndOfCsLbl - start - 2)
	jb @@Continue
	mov di, offset start
@@Continue:
	mov [word RndCurrentPos], di
	
	and ax, si ; filter result between 0 and si (the nask)
	
	cmp ax,dx    ;do again if  above the delta
	ja @@RandLoop
	pop bx
	add ax,bx  ; add the lower limit to the rnd num
		 
@@ExitP:
	
	pop di
	pop si
	pop es
	ret
endp RandomByCsWord

; make mask acording to bh size 
; output Si = mask put 1 in all bh range
; example  if bh 4 or 5 or 6 or 7 si will be 7
; 		   if Bh 64 till 127 si will be 127
Proc MakeMaskWord    
    push dx
	
	mov si,1
    
@@again:
	shr dx,1
	cmp dx,0
	jz @@EndProc
	
	shl si,1 ; add 1 to si at right
	inc si
	
	jmp @@again
	
@@EndProc:
    pop dx
	ret
endp  MakeMaskWord

;----------------
;Open a BMP file
;----------------
; input dx filename to open
proc OpenBmpFile
	mov ah, 3Dh
	xor al, al
	int 21h
	mov [FileHandle], ax
	ret
endp OpenBmpFile

;-----------------
;Close a BMP file
;-----------------
; input [FileHandle]
proc CloseBmpFile
	push bx
	
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	
	pop bx
	ret
endp CloseBmpFile


; Read and skip first 54 bytes the Header
proc ReadBmpHeader						
	push cx
	push dx
	
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpHeader

; Read BMP file color palette, 256 colors * 4 bytes (400h)
; 4 bytes for each color BGR (3 bytes) + null(transparency byte not supported)	
proc ReadBmpPalette  		
	push cx
	push dx
	
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	
	pop dx
	pop cx
	
	ret
endp ReadBmpPalette


; Will move out to screen memory the pallete colors
; video ports are 3C8h for number of first color (usually Black, default)
; and 3C9h for all rest colors of the Pallete, one after the other
; in the bmp file pallete - each color is defined by BGR = Blue, Green and Red
proc CopyBmpPalette							
										
	push cx
	push dx
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.(4 bytes for each color BGR + null)				
								
	loop CopyNextColor
	
	pop dx
	pop cx
	
	ret
endp CopyBmpPalette

;------------------------------------------------------------------------
;Show a BMP file. Making sure that if a pixel is pink, it won't be shown
;------------------------------------------------------------------------
proc ShowBMP 

; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpRowSize lines in VGA format),
; displaying the lines from bottom to top.
    push cx
    push bx

    mov bx, [FileHandle]

    mov ax, 0A000h
    mov es, ax

    mov cx,[BmpRowSize]

 
    mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
    xor dx,dx
    mov si,4
    div si
    cmp dx,0
    mov bp,0
    jz @@row_ok
    mov bp,4
    sub bp,dx

@@row_ok:
    mov dx,[BmpLeft]

@@NextLine:
    push cx
    push dx

    mov di,cx  ; Current Row at the small bmp (each time -1)
    add di,[BmpTop] ; add the Y on entire screen

 
    ; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
    mov cx,di
    shl cx,6
    shl di,8
    add di,cx
    add di,dx

    ; small Read one line
    mov ah,3fh
    mov cx,[BmpColSize]
    add cx,bp  ; extra  bytes to each row must be divided by 4
    mov dx,offset ScrLine
    int 21h
    ; Copy one line into video memory
    cld ; Clear direction flag, for movsb
    mov cx,[BmpColSize]
    mov si,offset ScrLine
    ;Pink Screen Loop
@@LoopBMP:
    mov dl, [si]
    cmp dl, 0EFh ;Check for pink
    jne @@PrintByte ;If it isn't pink then print
    inc si
    inc di
    jmp @@EndOfLoopBmp
@@PrintByte:
    movsb
@@EndOfLoopBmp:
    loop @@LoopBMP

    pop dx
    pop cx

    loop @@NextLine

    pop bx
    pop cx
    ret
endp ShowBMP

;------------------------------------------------------------------------
;Show a BMP file. Pink won't be transparent. Used for the menus
;------------------------------------------------------------------------
proc ShowBMPAll
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpRowSize lines in VGA format),
; displaying the lines from bottom to top.
	push cx
	
	mov ax, 0A000h
	mov es, ax
	
	mov cx,[BmpRowSize]
	
 
	mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx,dx
	mov si,4
	div si
	cmp dx,0
	mov bp,0
	jz @@row_ok
	mov bp,4
	sub bp,dx

@@row_ok:	
	mov dx,[BmpLeft]
	
@@NextLine:
	push cx
	push dx
	
	mov di,cx  ; Current Row at the small bmp (each time -1)
	add di,[BmpTop] ; add the Y on entire screen
	
 
	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
	mov cx,di
	shl cx,6
	shl di,8
	add di,cx
	add di,dx
	 
	; small Read one line
	mov ah,3fh
	mov cx,[BmpColSize]  
	add cx,bp  ; extra  bytes to each row must be divided by 4
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,[BmpColSize]  
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
	
	pop dx
	pop cx
	 
	loop @@NextLine
	
	pop cx
	ret
endp ShowBMPAll

;------------------------
;Show AX's decimal value
;------------------------
proc ShowAxDecimal
       push ax
	   push bx
	   push cx
	   push dx
	   
	   ; check if negative
	   test ax,08000h
	   jz PositiveAx
			
	   ;  put '-' on the screen
	   push ax
	   mov dl,'-'
	   mov ah,2
	   int 21h
	   pop ax

	   neg ax ; make it positive
PositiveAx:
       mov cx,0   ; will count how many time we did push 
       mov bx,10  ; the divider
   
put_mode_to_stack:
       xor dx,dx
       div bx
       add dl,30h
	   ; dl is the current LSB digit 
	   ; we cant push only dl so we push all dx
       push dx    
       inc cx
       cmp ax,9   ; check if it is the last time to div
       jg put_mode_to_stack

	   cmp ax,0
	   jz pop_next  ; jump if ax was totally 0
       add al,30h  
	   mov dl, al    
  	   mov ah, 2h
	   int 21h        ; show first digit MSB
	       
pop_next: 
       pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	   mov dl, al
       mov ah, 2h
	   int 21h        ; show all rest digits
       loop pop_next
		
   
	   pop dx
	   pop cx
	   pop bx
	   pop ax
	   
	   ret
endp ShowAxDecimal


EndofCsLbl:
END start