.model small
.stack 256h

.data
    ;Colors
    land_color equ 01100000b 
    player_color equ 01101010b  
    player_color_nl equ 11001010b ;green on pink
    enemy_color equ 00001100b     ;red
    path_color equ 11000000b 
    score_color equ 00001000b 
    blackSymbol equ 00000111b
    game_over           dw      0C47h, 0C61h, 0C6Dh, 0C65h, 0C20h, 0C4Fh, 0C76h, 0C65h, 0C72h 
    game_win            dw      0A59h, 0A6Fh, 0A75h, 0A60h, 0A76h ,0A20h, 0A57h, 0A4Fh, 0A4Eh
    e_message           dw      0F50h, 0F72h, 0F65h, 0F73h, 0F73h, 0C20h,0F27h, 0F61h, 0F6Eh, 0F79h, 0F27h, 0C20h, 0F74h, 0F6Fh, 0C20h, 0F65h, 0F78h, 0F69h, 0F74h
    e_offset            dw      085Ch
                                                
    
    upKey		=	48h	
    downKey		=	50h		
    leftKey		=	4Bh		
    rightKey	=	4Dh		
    esc = 01h  
    
   
	x	dw	80		
	y	db	12		
	d_x	db	2		
	d_y	db	1
	
	x2	dw	80		
	y2	db	12		
	d_x2	db	-2		
	d_y2	db	-1	
	
	end_y db 23
	end_x dw 156	
	       
	pts dw 0
	
                          
    granica_len equ 160  
     
.code
;Left ,right ,Top, Bottom
drawRight proc
    push dx
    UpMove:
    add dx, 2
    call GetSymbol
    cmp ah, land_color
    je DrawRightEnd
    mov ah, path_color
    mov al, ' '
    call SetSymbol
    jmp UpMove
    DrawRightEnd:
    pop dx   
    ret
drawRight endp 

fillBlack proc
    push bx
    push dx  
    ;start
    mov bl, 1

    verticalLoop:
    inc bl
    cmp bl, end_y
    je  fillBlackEnd
    mov dx,2
    horizontLoop:
    add dx, 2 
    cmp dx, end_x
    je verticalLoop
    call getSymbol
    cmp  ah, blackSymbol
    jne horizontLoop
    mov ah, land_color
    mov al, ' '
    call setSymbol
    inc pts
    jmp horizontLoop 
    
    fillBlackEnd:
    pop dx
    pop bx
ret
fillBlack endp 

removeFilter proc 
    push bx
    push dx  
    ;start
    mov bl, 1

    verticalLoopFilter:
    inc bl
    cmp bl, end_y
    je  removeFilterEnd
    mov dx,2
    horizontLoopFilter:
    add dx, 2 
    cmp dx, end_x
    je verticalLoopFilter
    call getSymbol
    cmp  ah, path_color
    jne horizontLoopFilter
    mov ah, blackSymbol
    mov al, ' '
    call setSymbol
    jmp horizontLoopFilter 
    
    removeFilterEnd:
    pop dx
    pop bx
ret
removeFilter endp
    



drawRight4 proc
    push dx
    RightMove4:
    add dx,2 
    call GetSymbol
    cmp ah, path_color
    je RightMove4 
    cmp ah, land_color
    je drawRight4End
    mov ah, path_color
    mov al, ' '
    call SetSymbol
    call DrawTop4
    call DrawBottom4
    drawRight4End:
    pop dx
    ret        
drawRight4 endp

drawLeft4 proc
    push dx
    LeftMove4:
    sub dx, 2
    call GetSymbol  
    cmp ah, path_color
    je LeftMove4
    cmp ah, land_color
    je DrawLeft4End
    mov ah, path_color
    mov al, ' '
    call SetSymbol
    call DrawTop4
    call DrawBottom4
    jmp LeftMove4
    DrawLeft4End:
    pop dx   
    ret
drawLeft4 endp ;end

drawTop4 proc
    push bx
    TopMove4:
    dec bl
    call GetSymbol
    cmp ah, path_color
    je TopMove4
    cmp ah, land_color
    je DrawTop4End
    mov ah, path_color
    mov al, ' '
    call SetSymbol
    call drawLeft4
    call drawRight4
    jmp TopMove4
    DrawTop4End:
    pop bx   
    ret
drawTop4 endp 

drawBottom4 proc
    push bx
    BottomMove4:
    inc bl
    call GetSymbol
    cmp ah, path_color
    je BottomMove4
    cmp ah, land_color
    je DrawBottom4End
    mov ah, path_color
    mov al, ' '
    call SetSymbol
    call drawLeft4
    call drawRight4
    jmp BottomMove4
    DrawBottom4End:
    pop bx   
    ret
drawBottom4 endp


fillPath	proc
    push bx
    push cx
    push di
        mov di, 326
        mov cx, 3400
        mov al, path_color
        mov ah, land_color
        xor bx, bx
    nextSymbol:
        repne scasb       ;poka ne naidet path_color
        jne  exitPathFiller  ;esli cx=0 to v ccexit
        sub di, 2
        mov al, ' '
        stosw
        mov al, path_color
        sub di, 2
        inc bp
        jmp nextSymbol        
	exitPathFiller:
	pop di
	pop cx
	pop bx
		ret  
fillPath	endp

fillBlack2	proc
    push bx
    push cx
    push di
        mov di, 326
        mov cx, 3400
        mov al, blackSymbol
        mov ah, land_color
        xor bx, bx
    nextSymbol2:
        repne scasb       ;poka ne naidet path_color
        jne  exitPathFiller2  ;esli cx=0 to v ccexit
        sub di, 2
        mov al, ' '
        stosw
        mov al, blackSymbol
        sub di, 2
        inc bp
        jmp nextSymbol2        
	exitPathFiller2:
	pop di
	pop cx
	pop bx
		ret  
fillBlack2	endp 
      
     

fillArea  proc 
     
     
     mov ah, path_color
     mov al, ' '
     call SetSymbol
     
     call drawRight4
     call drawLeft4
     call drawTop4
     call drawBottom4 
     
             
     
     fillAreaEnd:
     ret 
    
fillArea endp    
  
GetSymbol proc
		call	SymbolCords	
		mov	ax, es:[di]	;
		ret
GetSymbol	endp


SetSymbol	proc
		call	SymbolCords	
		stosw			
		ret
SetSymbol	endp


SymbolCords	proc
		push bx
		push cx
		xor	bh,bh
		xor cx, cx 
		mov cx, bx
		xor bx, bx
		PixelSum:
		add bx, 160
		loop PixelSum
		mov di, bx 
		add	di, dx
		pop cx
		pop	bx
		ret
SymbolCords	endp

ShowScore	proc 
    push ax
    push bx
    push cx
    push dx
		mov	ax,[pts]
		add	ax,bp
		xor cx, cx
		mov	cl,0
		mov	bx,10		
	nextdigit:
		xor dx, dx			
		div	bx		
		push dx		
		inc	cx		
		or	ax,ax
		jnz	short nextdigit	

		mov ah, 0Eh
		mov al, 0Dh		
		int 10h
		mov	bl, score_color
	outdigit:
		pop	ax		
		mov	ah,0Eh
		add	al,'0'	
		int	10h		
		loop	outdigit	
	pop dx
    pop cx
    pop bx
    pop ax
		ret
  ShowScore	endp
  
  Pause proc
    push dx
    push ax
    push cx
    mov cx, 0
    mov dx, 65000 
    mov ah, 86h
    int 15h
    pop cx
    pop ax
    pop dx
    ret
  Pause endp  
  
  getKey	proc 
	next:
		mov	ah, 01h
		int	16h		
		jz	short nokeys	
		xor	ah,ah
		int	16h		
		mov ch, ah 	
	nokeys:
		ret
  getKey	endp
  
  
  
start:
; set segment registers:
    mov ax, @data
    mov ds, ax
    mov es, ax
    ; add your code here
    
    mov ah, 00   ;ustanovka 16 cvetovogo video reshima
    mov al, 03   
    int 10h    
    
    ;Otrisovka granic
    push 0B800h
    pop es 
    mov al, ' '                                      
    mov ah, land_color
    
    mov cx, granica_len/2          ;verh
    sub cx, 2
    mov di, granica_len+2 
    cld
    rep stosw 
     
    mov cx, granica_len/2          ;niz
    sub cx, 2
    mov di, granica_len*23
    add di, 2 
    cld
    rep stosw
    
    mov bx, 0
left:
    inc bx
    mov cx, bx 
    xor dx, dx
    left_pl:
    add dx, granica_len
    loop left_pl 
    mov di, dx 
    mov cx, 2
    cld                                                   
    rep stosw                                            
    cmp bx, 23
    jne left
    
    mov bx, 1
right:
    mov ah, land_color
    mov al, ' '
    inc bx
    mov cx, bx 
    xor dx, dx
    right_pl:
    add dx, granica_len
    loop right_pl 
    sub dx, 4
    mov di, dx 
    mov cx, 2
    cld    
    mov ah, land_color
    mov al, ' '                                                 
    rep stosw                                            
    cmp bx, 24
    jne right
      
;Spawn player
    mov bl, 1 
    mov bh, land_color
    mov dx, granica_len/2
    xor ax, ax  
    mov al, 04h
    mov ah, player_color
    call SetSymbol
    xor bp, bp  
    call ShowScore
    xor si, si
GameLoop:
        push cx
        call GetSymbol
        test ah, 10010101b                     
        jz short nextStep
        cmp bh, land_color
        jne nextStep
        mov si, di
    nextStep: 
		push dx		
		test ah, 10010101b
	    jz arrive  
	    mov ah, player_color_nl
		jmp	show_score
    arrive:
		mov	ah, player_color
		cmp bh, path_color  ;esli pred ne bil pole
		jne show_score  
		
		push ax
		push di
		call fillPath
		push dx
        push bx 
     
        mov dx, [x]
        mov bl, [y]  
		call fillArea
		
		mov dx, [x2]
		mov bl, [y2]		
		call fillArea
		
		pop bx
		pop dx
		 
		call fillBlack
		call removeFilter
		
		pop di
		pop ax 
		
		add [pts], bp
		xor bp, bp
		inc bp
	
	show_score:
	call ShowScore
	cmp [pts],1100
	jnae drawPlayer 
	jmp WIN


	
   drawPlayer:
    pop dx 
    mov al, 04h
    call SetSymbol
    push dx
    push bx
    push ax
    
    countCoord1:
    mov dx, [x]
    mov bl, [y]
    cmp dx, 0
    jne notBorder
    jmp printEnemy
    
    notBorder:
    call GetSymbol
    cmp ah, land_color
    jne stillAlive
    
    stillAlive:
    mov al, ' '
    mov ah, 00000111b
    call SetSymbol
    mov al, [d_x]    ;Smeshenie po X
    cbw
    add dx, ax
    xchg cx, ax
    mov al, [d_y]    ;Smeshenie po Y
    add bl, al
    mov bh, al 
    
   
    
      
    call GetSymbol
    cmp ah, path_color
    jne secondStep
    jmp LOSE
     
    
    secondStep:
    cmp ah,player_color_nl
    jne thirdStep
    jmp LOSE

    
    thirdStep: 
    cmp ah, 00000111b 
    jne cross
    jmp printEnemy 
    
    cross:
    shl cx,1
    sub dx,cx
    call GetSymbol
    cmp ah, 00000111b
    jz negdx 
    add dx,cx
    shl bh, 1
    sub bl,bh
    call GetSymbol
    cmp  ah, 00000111b
    jz negdy
    sub dx,cx
    neg d_y
    negdx:
    neg d_x
    jmp printEnemy
    negdy:
    neg d_y  
    
     printEnemy:
    mov [x], dx
    mov [y], bl
    mov al, 0Fh
    mov ah, enemy_color
    call SetSymbol 
    
    countCoord2:
    mov dx, [x2]
    mov bl, [y2]
    cmp dx, 0
    jne notBorder2
    jmp popPlayer
    
    notBorder2:
    call GetSymbol
    cmp ah, land_color
    jne stillAlive2
    
    stillAlive2:
    mov al, ' '
    mov ah, 00000111b
    call SetSymbol
    mov al, [d_x2]    ;Smeshenie po X
    cbw
    add dx, ax
    xchg cx, ax
    mov al, [d_y2]    ;Smeshenie po Y
    add bl, al
    mov bh, al 
    
   
    
      
    call GetSymbol
    cmp ah, path_color
    jne secondStep2
    jmp LOSE
     
    
    secondStep2:
    cmp ah,player_color_nl
    jne thirdStep2
    jmp LOSE

    
    thirdStep2: 
    cmp ah, 00000111b 
    jne cross2
    jmp printEnemy2 
    
    cross2:
    shl cx,1
    sub dx,cx
    call GetSymbol
    cmp ah, 00000111b
    jz negdx2 
    add dx,cx
    shl bh, 1
    sub bl,bh
    call GetSymbol
    cmp  ah, 00000111b
    jz negdy2
    sub dx,cx
    neg d_y2
    negdx2:
    neg d_x2
    jmp printEnemy2
    negdy2:
    neg d_y2
    
    
    
    printEnemy2:
    mov [x2], dx
    mov [y2], bl
    mov al, 0Fh
    mov ah, enemy_color
    call SetSymbol 
    
    
     
	popPlayer: 
	pop ax 
	pop bx 
	pop dx 
	
	call Pause    
	
	test ah, 10010000b
	jz  setLandColor
	mov ah, path_color
	jmp delPlayer 
	
	setLandColor:
	mov ah, land_color
	
	delPlayer:
	mov al, ' '
	mov bh, ah
	call SetSymbol
	pop cx
	mov cl, ch  
	
	test ah, 10010000b  ;na trave moshno prervat dvishenie
	jnz  click               ;vlevo na pravo
	xor cl,cl
	
	click:	
	call getKey
	cmp ch, esc
	je exit
	
	 
	
	cmp ch, upKey
	jne notUpKey
	cmp bl, 1
	jbe notUpKey
	cmp cl, downKey
	je  inverseStream 
	dec bx
	
	notUpKey:
	    cmp	ch,downKey                                        
		jne	notDownKey
		cmp	bl, 23		
		jae	notDownKey
		cmp cl, upKey     ;bila li proshlaya up
		je  inverseStream
		inc bx  
	notDownKey:
	    cmp ch, leftKey
	    jne notLeftKey 
	    cmp dx, 2
	    jbe notLeftKey
	    cmp cl, rightKey  ;bila li proshlaya right
	    je  inverseStream
	    sub dx, 2
	    
	
	notLeftKey:
	    cmp	ch,rightKey
		jne GameLoop
		cmp	dx, 156		
		jnb	GameLoop
		cmp cl, leftkey     
		je inverseStream
		add dx, 2
		jmp GameLoop
	
	inverseStream:
	mov ch, cl  
	jmp GameLoop
	
	
	
WIN:
         mov ax, 0003h
        int 10h 
        
        mov di, 07C6h
        mov si, offset game_win
        mov cx, 9
        rep movsw
        mov di, e_offset                                   
        mov si, offset e_message                           
        mov cx, 19
        rep movsw
        
        mov ah, 1
        int 21h 
         
        jmp exit
 

LOSE: 
        mov ax, 0003h
        int 10h 
        
        
        mov di, 07C6h
        mov si, offset game_over
        mov cx, 9
        rep movsw
        mov di, e_offset                                   
        mov si, offset e_message                           
        mov cx, 19
        rep movsw
        
        
        mov ah, 1
        int 21h 
        
        jmp exit  
        
	
	
		
exit: 
    
        mov ax, 0003h
        int 10h 
    
    mov ax, 4c00h ; exit to operating system.
    int 21h    
end start ;