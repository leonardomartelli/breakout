.model small

.stack 4000H

.data
    ;Cores;
	COLOR_BLACK EQU 0h
    COLOR_GREEN EQU 02h   
    COLOR_RED EQU 04h
    COLOR_CLEAR_RED EQU 0Ch 
    COLOR_YELLOW EQU 0Eh
	COLOR_CLEAR_GREY EQU 7h
    COLOR_WHITE EQU 0Fh
    COLOR_MAGENTA EQU 0Dh 

	BLOCK_COLORS db COLOR_RED, COLOR_CLEAR_RED, COLOR_GREEN, COLOR_YELLOW
    
    NAMES db 'Gregor e Leonardo'
    NAMES_SIZE EQU 17
    
    PLAY db 'Jogar'
    PLAY_SIZE EQU 5
    
    EXIT db 'Sair'
    EXIT_SIZE EQU 4
    
    SCORE db 'SCORE: '
    SCORE_SIZE EQU 7
    
    mLifes db 'VIDAS: '
    mLifes_SIZE EQU 7
                     
	mOpenCol db '['
	mCloseCol db ']'

	RACKET_Y_POS EQU 24

	; Coordenadas default
	RACKET_COORDINATES db 10h, RACKET_Y_POS
	CHOOSE_COORDINATES db 16, 15
	CLEAR_COORDINATES db 2 dup(0)
	BALL_COORDINATES db 16, 23
	HEADER_COORDINATES db 2, 0
    
	HEADER_VALUES dw 0, 0

    STRING_MODE EQU 1311h

	BLOCKS_CLEARED dw 0

	BALL_DIRECTION db 0

	BALL_SPEEDS dw 190h, 15eh, 12ch, 0fah, 64h, 64h, 64h
	
	RIGHT_LIMIT EQU 40
	RIGHT_RACKET_LIMIT EQU 35

	UP_LIMIT EQU 0
	DOWN_LIMIT EQU 25
    
    SCREEN EQU 0B800H
    
	; Caracteres
    BALL_CHAR EQU 254
    BLOCK_CHAR EQU 178

	; KEY
    ARROW_UP EQU 48h
    ARROW_LEFT EQU 4Bh
    ARROW_RIGHT EQU 4Dh
    ARROW_DOWN EQU 50H
	LF EQU 10
	CR EQU 13

	RACKET db BLOCK_CHAR, COLOR_MAGENTA, BLOCK_CHAR, COLOR_CLEAR_GREY, BLOCK_CHAR, COLOR_CLEAR_GREY, BLOCK_CHAR, COLOR_CLEAR_GREY, BLOCK_CHAR, COLOR_MAGENTA
	RACKET_SIZE EQU 10

	BALL db BALL_CHAR, COLOR_WHITE
	BALL_SIZE EQU 2

	IS_KICKED_RED db 0

    M_TITLE db ' ___              _            _', LF, CR,\
	         '  | _ )_ _ ___ __ _| |_____ _  _| |_', LF, CR,\
	         '  | _ | `_/ -_/ _` | / / _ | || |  _|', LF, CR,\
	         '  |___|_| \___\__,_|_\_\___/\_,_|\__|'
    
	TITLE_SIZE EQU 148 

	GAMEOVER db '  __ _            _', LF, CR,\
    	'         / _(_)_ __    __| |___'  , LF, CR,\
    	'        |  _| | `  \  / _` / -_)', LF, CR,\
    	'        |_| |_|_|_|_| \__,_\___|', LF, CR,\
    	'            _', LF, CR,\
    	'           (_)___ __ _ ___' , LF, CR,\
    	'           | / _ / _` / _ \'  , LF, CR,\
    	'          _/ \___\__, \___/' , LF, CR,\
    	'         |__/    |___/'
          
    GAMEOVER_SIZE EQU 245

.code

RANDOM proc  ; recebe em BX o valor maximo para gerar 
	push AX

   	xor AH, AH  
   	int 1aH          

   	mov AX, DX
    xor DX, DX
	inc BX
    div BX

	pop AX
	ret
endp
      
SET_CURSOR_POSITION proc ; Seta o cursor pra pos. DL x DH  
    push BX
    xor BX, BX
    mov AH, 2
    int 10h  
    pop BX
    ret
endp

SET_VIDEO_MODE proc ;Setar para o modo de video 01H com dimensao 40x25
    push AX
	push DX
	push CX
	
	mov AL, 1
	mov CX, 2607h ;esconder o cursor
	xor AH, AH
	int 10h

    mov DX, 0FFFFH
    call SET_CURSOR_POSITION

	pop DX	
	pop CX
    pop AX
	ret
endp

CALCULATE_BALL_SPEED proc
	push BX
	push CX
	push DX
	push DI
	push SI

	mov AX, @DATA
    mov ES, AX

	mov DI, offset IS_KICKED_RED
	cmp byte ptr[DI], 1
	jne GET_KICKED_BLOCKS_FROM_MEMORY

	mov AX, 24
	jmp DIVIDE_BLOCKS

	GET_KICKED_BLOCKS_FROM_MEMORY:
	mov DI, offset BLOCKS_CLEARED
	mov AX, [DI]

	DIVIDE_BLOCKS:
	xor DX, DX

	mov BX, 4
	div BX
	mov BX, 2
	mul BX

	mov SI, offset BALL_SPEEDS

	add SI, AX

	mov AX, [SI]

	pop SI
	pop DI
	pop DX
	pop CX
	pop BX
	ret
endp

AWAIT proc
	push AX
	push CX
	push DX

	mov AX, 8600h
	xor CX, CX
	mov DX, 1f4h

	int 15h

	pop DX
	pop CX
	pop AX
	ret
endp

CALCULATE_VIDEO_POS proc 
    push AX
    push BX
        
    xor AX,AX
         
    mov AL, 80
    mul DH
    mov BX,AX     
         
    mov AL, 2
    mul DL
    
    add AX, BX
    mov DX, AX     
    
    pop BX
    pop AX
    ret
endp

WRITE_CHAR proc ; Escreve caracter no registrador dl
    push AX
    mov AH, 02h
    int 21h
    pop AX
    ret
endp

WRITE_NUMBER proc ; Escreve valores no formato BCD decimal
    push AX 
    push BX
    push CX
    push DX

    mov BX, 0Ah
    mov CX, 0h
    mov AX, DX

    BUILD_NUMBER:    
        xor DX, DX
        div BX
        add DX, '0'
        push DX
        inc CX
        cmp AX, 0h
    ja BUILD_NUMBER    

    SHOW_NUMBER:
        pop DX
        call WRITE_CHAR
    loop SHOW_NUMBER
    
    pop AX
	pop BX
	pop CX
	pop DX
    ret
endp

WRITE_STRING proc  
    push AX 
    push BX
    push ES 
    push BP
                               
    mov BH, 00h

    mov AX, STRING_MODE
    int 10h
    
    pop BP
    pop ES
    pop BX
    pop AX
    ret
endp

WRITE_WITHOUT_INT_WITH_INFO proc
	push AX
	push ES
	push DI
	push SI	
	mov SI, AX                
    call CALCULATE_VIDEO_POS
	
	mov AX, SCREEN
	mov ES, AX	
	mov AX, DX	
	mov DI, AX

	REP MOVSB          
           
    pop SI
    pop DI
    pop ES
    pop AX
    
    ret
endp

WRITE_HEADER proc
	push AX
    push BX
    push CX
    push DX
    push ES
    
	mov AX, @DATA
    mov ES, AX
	mov DI, offset HEADER_COORDINATES

	mov BP, offset SCORE 
	mov CX, SCORE_SIZE 
	xor DX, DX
	mov BL, COLOR_WHITE
	call WRITE_STRING

	mov DI, offset HEADER_VALUES
    mov DX, [DI]
    mov BL, COLOR_GREEN
	call WRITE_NUMBER

	mov BP, offset mLifes
	mov CX, mLifes_SIZE 
	mov DL, 32
	xor DH, DH
	mov BL, COLOR_WHITE
	call WRITE_STRING

    mov DI, offset HEADER_VALUES
    mov DX, [DI + 2]
    mov BL, COLOR_GREEN
	call WRITE_NUMBER

	pop ES 
    pop DX
    pop CX
    pop BX
    pop AX 

	ret
endp

WRITE_COL proc
	push AX
    push BX
    push CX
    push DX
    push ES
	push DI
              
	mov DL, [DI]
	inc DI
    mov DH, [DI]
       
    mov AX, @DATA 
    mov ES, AX
	
	mov BP, offset mOpenCol 
	mov CX, 1 
	call WRITE_STRING 

	mov BP, offset mCloseCol 
	mov CX, 1 
	add DL, 6
	call WRITE_STRING 

	pop DI
    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
	ret
endp

WRITE_HOME_SCREEN proc
    push AX
    push BX
    push CX
    push DX
    push ES

	call SET_VIDEO_MODE
    
    mov AX, @DATA
    mov ES, AX 
	
	mov BP, offset M_TITLE 
	mov CX, TITLE_SIZE 
	mov DL, 2
	mov DH, 7
	mov BL, COLOR_GREEN
	call WRITE_STRING	 	
	
	mov BP, offset NAMES           
	mov CX, NAMES_SIZE 
	mov DL, 11
	mov DH, 12
	mov BL, COLOR_RED
	call WRITE_STRING
	
	mov BP, offset PLAY 
	mov CX, PLAY_SIZE 
	mov DL, 17
	mov DH, 15    
	mov BX, COLOR_WHITE
	call WRITE_STRING  
	   
	mov BP, offset EXIT 
	mov CX, EXIT_SIZE 
	mov DH, 16    
	call WRITE_STRING 

	call MENU
    
    pop ES 
    pop DX
    pop CX
    pop BX
    pop AX    
          
	ret
endp 

WRITE_GAMEOVER_SCREEN proc
    push AX
    push BX
    push CX
    push DX
    push ES
	push DI
       
    mov AX, @DATA
    mov ES, AX 
       
	mov BP, offset GAMEOVER
	mov CX, GAMEOVER_SIZE 
	mov DL, 8
	mov DH, 2
	mov BX, COLOR_GREEN
	call WRITE_STRING
		
	mov BP, offset SCORE 
	mov CX, SCORE_SIZE 
	mov DL, 9
	mov DH, 12
	mov BX, COLOR_RED
	call WRITE_STRING 

	mov DI, offset HEADER_VALUES
    mov DX, [DI]
	call WRITE_NUMBER

	mov AH, 00
	int 16h
	
	call WRITE_HOME_SCREEN
    
	pop DI
    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
	ret
endp

WRITE_BLOCK proc
	push AX
    push CX
    push ES
	push DI
	push SI
	
	mov AX, SCREEN
	mov ES, AX
	mov DI, 54h

	mov SI, offset BLOCK_COLORS

	mov AL, BLOCK_CHAR

	mov CX, 4
	BLOCK_LINE_LOOP:
		mov AH, [SI]
		push CX
		mov CX, 6
		ONE_BLOCK_LOOP:
			push CX
			mov CX, 5
			rep stosw
			add DI, 2
			pop CX
			loop ONE_BLOCK_LOOP
		pop CX
		add DI, 58h
		inc SI
		loop BLOCK_LINE_LOOP

	pop SI
	pop DI
    pop ES
    pop CX
    pop AX
	ret
endp

CLEAR proc
	push AX
	push ES
	push DI
	push SI	

	mov SI, AX                
    call CALCULATE_VIDEO_POS
	
	mov AX, SCREEN
	mov ES, AX	
	mov AX, DX	
	mov DI, AX
	
	xor AX, AX
	
	stosw        
           
    pop SI
    pop DI
    pop ES
    pop AX
    
    ret
endp

CLEAR_CHOOSE proc
	push AX
	push DX
	push DI

	mov DL, [DI]

	mov DH, [DI + 1]
	call CLEAR
	
	mov DL, [DI]
	mov DH, [DI + 1]

	add DL, 6
	call CLEAR
	
	pop DI
	pop DX
	pop AX

	ret
endp

CLEAR_BALL proc
	push SI
	push DX

	mov SI, offset BALL_COORDINATES	
	mov DL, [DI]
	mov DH, [DI+1]
	
	call CLEAR
	
	pop DX
	pop SI
	ret
endp

MENU proc
	push AX
	push BX
	push DI

	mov DI, offset CHOOSE_COORDINATES

	WRITE:
		mov BX, COLOR_WHITE
		call WRITE_COL

	CHOOSE_LOOP:
		mov AH, 0
		int 16h
		je CHOOSE_LOOP

		cmp AH, ARROW_DOWN
		je ARROW_DOWN_CLICK

		cmp AH, ARROW_UP
		je ARROW_UP_CLICK

		cmp AH, ARROW_RIGHT
		je ENTER_KEY
    jmp CHOOSE_LOOP

	ARROW_UP_CLICK:
        call CLEAR_CHOOSE
		mov byte ptr[DI + 1], 15
		jmp WRITE
	ARROW_DOWN_CLICK:
		call CLEAR_CHOOSE
		mov byte ptr[DI + 1], 16
		jmp WRITE
	ENTER_KEY:
		call CLEAR_CHOOSE
		cmp byte ptr[DI + 1], 15
		je PLAY_GAME_CALL
		call EXIT_PROG
	PLAY_GAME_CALL:
		call PLAY_GAME

	pop DI
	pop BX
	pop AX
	ret
endp

WRITE_RACKET proc
	push AX
    push CX
    push DX
	push DI
                    
	mov DI, offset RACKET_COORDINATES
	
	mov AX, offset RACKET 
	mov CX, RACKET_SIZE
	mov DL, [DI]
	mov DH, [DI + 1] 
	call WRITE_WITHOUT_INT_WITH_INFO 

	pop DI
    pop DX
    pop CX
    pop AX
	ret
endp

WRITE_BALL proc
	push AX
    push CX
    push DX
    push ES
	push DI
                    
    mov AX, @DATA 
    mov ES, AX
	mov DI, offset BALL_COORDINATES
	
	mov AX, offset BALL 
	mov CX, BALL_SIZE
	mov DL, [DI]
	mov DH, [DI + 1] 
	call WRITE_WITHOUT_INT_WITH_INFO 

	pop DI
    pop ES
    pop DX
    pop CX
    pop AX
	ret
endp

MOVE_RACKET proc
	push AX
	push BX
	push DX
	push DI

	CALL_WRITE_RACKET:
		call WRITE_RACKET

	READ_LOOP:
		mov AH, 1
		int 16h
		je POPPING_MOVE_RACKET
		xor AH, AH
		int 16h

		mov DI, offset RACKET_COORDINATES

		mov BL, [DI]
		mov BH, [DI + 1]
		
		cmp AH, ARROW_RIGHT
		je ARROW_RIGHT_CLICK

		cmp AH, ARROW_LEFT
		je ARROW_LEFT_CLICK

    jmp READ_LOOP

	ARROW_RIGHT_CLICK:
		cmp BL, RIGHT_RACKET_LIMIT
		je READ_LOOP
		mov DL, BL
		mov DH, BH
		call CLEAR
		inc  byte ptr[DI]
		jmp POPPING_MOVE_RACKET

	ARROW_LEFT_CLICK:
		dec BL
		js POPPING_MOVE_RACKET
		mov DL, BL
		add DL, 5
		mov DH, BH
		call CLEAR
		dec byte ptr[DI]

	POPPING_MOVE_RACKET:
	pop DX
	pop DI
	pop BX
	pop AX
	ret
endp

KICKED_DOWN_LIMIT proc
	push DI
	
	mov DI, offset HEADER_VALUES
	add DI, 2

	cmp word ptr[DI], 1
	jne CONTINUE_GAME 
	call END_GAME

	CONTINUE_GAME:
	dec word ptr[DI]
	call WRITE_HEADER
	call INITIALIZE_BALL_PARAMS

	pop DI
	ret
endp

GO_LEFT_UP proc
	call LOAD_INFO
	mov byte ptr[SI], 4
	jmp GOING_LEFT_UP
	ret
endp

GO_LEFT_DOWN proc
	call LOAD_INFO
	mov byte ptr[SI], 3
	call GOING_LEFT_DOWN
	ret
endp

GO_RIGHT_DOWN proc
	call LOAD_INFO
	mov byte ptr[SI], 2
	jmp GOING_RIGHT_DOWN
	ret
endp

GO_RIGHT_UP proc
	call LOAD_INFO
	mov byte ptr[SI], 1
	jmp GOING_RIGHT_UP
	ret
endp

LOAD_INFO proc
	mov SI, offset BALL_DIRECTION	
	mov BL, [DI]
	mov BH, [DI + 1]
	ret
endp

GOING_LEFT_DOWN proc
	push BX
	push AX

	inc BH
	cmp BH, DOWN_LIMIT
	je GLD_EXIT
	
	call GET_KICKED
	cmp AL, 1
	je GLD_GO_LEFT_UP
	cmp AL, 2
	je GLD_GO_RIGHT_UP
	
	dec BL
	js GLD_GO_RIGHT_DOWN
	
	call GET_KICKED
	cmp AL, 1
	je GLD_GO_LEFT_UP
	cmp AL, 2
	je GLD_GO_RIGHT_UP
	
	dec BH
	call GET_KICKED
	cmp AL, 1
	je GLD_GO_RIGHT_DOWN
	
	dec byte ptr[DI]
	inc byte ptr[DI + 1]
	jmp GLD_POPPING

	GLD_GO_LEFT_UP:
		call GO_LEFT_UP
		jmp GLD_POPPING

	GLD_GO_RIGHT_DOWN:
		call GO_RIGHT_DOWN
		jmp GLD_POPPING

	GLD_GO_RIGHT_UP:
		call GO_RIGHT_UP
		jmp GLD_POPPING

	GLD_EXIT:
		call KICKED_DOWN_LIMIT

	GLD_POPPING:
		pop AX
		pop BX

	ret
endp

GOING_RIGHT_DOWN proc
	push BX
	push AX

	inc BH
	cmp BH, DOWN_LIMIT
	je GRD_EXIT

	call GET_KICKED
	cmp AL, 1
	je GRD_GO_RIGHT_UP
	cmp AL, 2
	je GRD_GO_LEFT_UP

	inc BL
	cmp BL, RIGHT_LIMIT
	je GRD_GO_LEFT_DOWN

	call GET_KICKED
	cmp AL, 1
	je GRD_GO_RIGHT_UP
	cmp AL, 2
	je GRD_GO_LEFT_UP

	dec BH
	call GET_KICKED
	cmp AL, 1
	je GRD_GO_LEFT_DOWN

	inc byte ptr[DI]
	inc byte ptr[DI + 1]
	jmp GRD_POPPING

	GRD_GO_LEFT_UP:
		call GO_LEFT_UP
		jmp GRU_POPPING

	GRD_GO_LEFT_DOWN:
		call GO_LEFT_DOWN
		jmp GRU_POPPING

	GRD_GO_RIGHT_UP:
		call GO_RIGHT_UP
		jmp GRU_POPPING

	GRD_EXIT:
		call KICKED_DOWN_LIMIT

	GRD_POPPING:
		pop AX
		pop BX

	ret
endp 

GOING_RIGHT_UP proc
	push BX
	push AX
	
	dec BH
	cmp BH, UP_LIMIT
	je GRU_GO_RIGHT_DOWN
	
	call GET_KICKED
	cmp AL, 1
	je GRU_GO_RIGHT_DOWN		
	
	inc BL
	cmp BL, RIGHT_LIMIT
	je GRU_GO_LEFT_UP

	call GET_KICKED
	cmp AL, 1
	je GRU_GO_RIGHT_DOWN

	inc BH
	call GET_KICKED
	cmp AL, 1
	je GRU_GO_LEFT_UP
		
	inc byte ptr[DI]
	dec byte ptr[DI + 1]
	jmp GRU_POPPING

	GRU_GO_LEFT_UP:
		call GO_LEFT_UP
		jmp GRU_POPPING

	GRU_GO_LEFT_DOWN:
		call GO_LEFT_DOWN
		jmp GRU_POPPING

	GRU_GO_RIGHT_DOWN:
		call GO_RIGHT_DOWN
	
	GRU_POPPING:
		pop AX
		pop BX

	ret
endp 

GOING_LEFT_UP proc
	push BX
	push AX

	dec BH
	cmp BH, UP_LIMIT
	je GLU_GO_LEFT_DOWN

	call GET_KICKED
	cmp AL, 1
	je GLU_GO_LEFT_DOWN

	dec BL
	js GLU_GO_RIGHT_UP

	call GET_KICKED
	cmp AL, 1
	je GLU_GO_LEFT_DOWN

	inc BH
	call GET_KICKED
	cmp AL, 1
	je GLU_GO_RIGHT_UP

	dec byte ptr[DI]
	dec byte ptr[DI + 1]
	jmp GLU_POPPING

	GLU_GO_RIGHT_UP:
		call GO_RIGHT_UP
		jmp GLU_POPPING

	GLU_GO_LEFT_DOWN:
		call GO_LEFT_DOWN
		jmp GLU_POPPING

	GLU_GO_RIGHT_DOWN:
		call GO_RIGHT_DOWN
	
	GLU_POPPING:
		pop AX
		pop BX

	ret
endp 

CALCULATE_NEXT_BALL_POSITION proc
	push BX
	push DI
	push CX
	push SI
	
	mov SI, offset BALL_DIRECTION
	mov CL, [SI]

	mov DI, offset BALL_COORDINATES	
	mov BL, [DI]
	mov BH, [DI+1]

	call CLEAR_BALL

	cmp CL, 1
	je RIGHT_UP
	cmp CL, 2
	je RIGHT_DOWN
	cmp CL, 4
	je LEFT_UP

	LEFT_DOWN:
		call GOING_LEFT_DOWN
		jmp CALCULATE_END
	RIGHT_DOWN:
		call GOING_RIGHT_DOWN
		jmp CALCULATE_END
	RIGHT_UP:
		call GOING_RIGHT_UP
		jmp CALCULATE_END
	LEFT_UP:
		call GOING_LEFT_UP

	CALCULATE_END:
		pop SI
		pop DI
		pop CX
		pop BX

		ret
endp

VALIDATE_BLOCKS_CLEARED proc
	push SI

	mov SI, offset BLOCKS_CLEARED
	cmp word ptr[SI], 24
	jb END_VALIDATE

	call INITIALIZE_BLOCKS
	call CLEAR_BALL
	call INITIALIZE_BALL_PARAMS

	END_VALIDATE:
	pop SI
	ret
endp

CLEAR_BLOCK proc
	push CX
	push AX
	push DX
	push DI
	push SI

	xor AX, AX
	xor DX, DX

	mov AL, BL

	push BX

	mov SI, offset BLOCKS_CLEARED
	inc word ptr[SI]

	mov BX, 6
	div BX
	
	cmp DX, 0
	jne JUMP_TO_MUL
	dec AL
	
	JUMP_TO_MUL:
	mul BX
	pop BX
	add AL, 2

	mov DL, AL
	mov DH, BH
	call CALCULATE_VIDEO_POS

	mov AX, SCREEN 
    mov ES, AX

	mov DI, DX
	
	xor AX, AX
	mov CX, 5
	
	rep stosw 

	pop SI
	pop DI
	pop CX
	pop DX
	pop AX
	ret
endp

SET_KICKED_RED_BLOCK proc
	push SI

	mov SI, offset IS_KICKED_RED
	
	mov byte ptr[SI], 1

	pop SI
	ret
endp

GET_KICKED proc
	push DX
	push DI
	push ES

	mov DX, BX
                
    call CALCULATE_VIDEO_POS
	
	mov AX, SCREEN
	mov ES, AX	
	mov AX, DX	
	mov DI, AX

	xor AX,AX

	mov AX, ES:[DI]

	cmp AL, BLOCK_CHAR
	jne KICKED_POPPING

	cmp AH, COLOR_MAGENTA
	je KICKED_RACKET_MAGENTA
	
    mov AL, 1
	
	cmp AH, COLOR_GREEN
	je KICKED_GREEN_BLOCK
	
	cmp AH, COLOR_CLEAR_RED
	je KICKED_CLEAR_RED_BLOCK
	
	cmp AH, COLOR_RED
	je KICKED_RED_BLOCK
	
	cmp AH, COLOR_CLEAR_GREY  
	je KICKED_POPPING
	
	cmp AH, COLOR_YELLOW
	jne KICKED_POPPING

	KICKED_YELLOW_BLOCK:
		mov DI, offset  HEADER_VALUES
		inc word ptr[DI]
		jmp KICKED_BLOCK
	KICKED_RACKET_MAGENTA:
		mov AL, 2
		jmp KICKED_POPPING
	KICKED_GREEN_BLOCK:
		mov DI, offset  HEADER_VALUES
		add word ptr[DI], 3
		jmp KICKED_BLOCK
	KICKED_CLEAR_RED_BLOCK:
		mov DI, offset  HEADER_VALUES
		add word ptr[DI], 5
		call SET_KICKED_RED_BLOCK
		jmp KICKED_BLOCK
	KICKED_RED_BLOCK:
		mov DI, offset HEADER_VALUES
		add word ptr[DI], 7
		call SET_KICKED_RED_BLOCK
		jmp KICKED_BLOCK
	KICKED_BLOCK:
		push AX
		call CLEAR_BLOCK
		pop AX
		call WRITE_HEADER

	KICKED_POPPING:
		pop DX
		pop DI
		pop ES
	ret
endp

INITILIZE_RACKET_POS proc
	push DX
	push BX
	push SI
	
	mov BX, RIGHT_RACKET_LIMIT

	call RANDOM

	mov SI, offset RACKET_COORDINATES

	mov [SI], DL

	pop BX
	pop DX
	pop SI
	ret
endp

INITIALIZE_BALL_PARAMS proc
	push DX
	push BX
	push SI
	
	mov SI, offset RACKET_COORDINATES

	mov DX, [SI]

	add DX, 2

	mov SI, offset BALL_COORDINATES
	mov byte ptr[SI], DL
	mov byte ptr[SI + 1], 23

	mov BX, 4

	call RANDOM
	mov SI, offset BALL_DIRECTION

	mov [SI], DL

	pop BX
	pop DX
	pop SI
	ret
endp

INITIALIZE_HEADER_VALUES proc
	push SI

	mov SI, offset HEADER_VALUES

	mov word ptr[SI], 0
	mov word ptr[SI + 2], 3

	call WRITE_HEADER

	pop SI
	ret
endp

INITIALIZE_BLOCKS proc
	push SI

	mov SI, offset BLOCKS_CLEARED
	mov word ptr[SI], 0

	mov SI, offset IS_KICKED_RED
	mov byte ptr[SI], 0

	call WRITE_BLOCK

	pop SI
	ret
endp

INITIALIZE_ITEMS proc
	push SI

	call INITIALIZE_HEADER_VALUES
	call INITILIZE_RACKET_POS
	call INITIALIZE_BALL_PARAMS
	call INITIALIZE_BLOCKS

	pop SI
	ret
endp

PLAY_GAME proc
	push AX
	push CX

	call SET_VIDEO_MODE
	call INITIALIZE_ITEMS

	xor CX, CX

	PLAY_LOOP:
	call VALIDATE_BLOCKS_CLEARED
	call MOVE_RACKET
	call CALCULATE_BALL_SPEED
	cmp CX, AX
	jb CONTINUE_PLAY
	
	xor CX, CX

	call CALCULATE_NEXT_BALL_POSITION
	call WRITE_BALL
	
	CONTINUE_PLAY:
		call AWAIT
		inc CX
	jmp PLAY_LOOP

	pop CX
	pop AX
	ret
endp

END_GAME proc
	call SET_VIDEO_MODE
	call WRITE_GAMEOVER_SCREEN
endp

EXIT_PROG proc
	push AX

	mov AH, 4CH
	mov AL, 0
	int 21H

	pop AX
endp
       
START:
    mov AX, @DATA
    mov DS, AX

    call WRITE_HOME_SCREEN

end START