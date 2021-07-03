.model small
.stack 130h
  
 
.data 
maximalNumberOfElements equ 30
numberOfEnteredNumbers dw 0

 
stringPointer db 7		;7 = 1 – sign, 5 – digits, 1 – '$' 
stringSize db 0
string db 7 dup (?)  
mas dw 30 dup (0)  
numberOfMaxNumbers dw 0
max dw 0  
tempChar dw 30 dup (0)  
i dw 0 
index dw 0

negativeFlag db ?		;check for '-' in string 

tempDoubleWord dd 0

enterString db "Enter number in range [-32768, 32767], enter 'q' to stop.", 0Dh, 0Ah, '$'
enterNumberString db "Enter number: ", '$' 
outOfRangeString db "Out of range!", 0Dh, 0Ah, '$'
notDigitString db "Incorrect symbol detected!", 0Dh, 0Ah, '$'
resultString db "Incorrect symbol detected!", 0Dh, 0Ah, '$'	 
timesStr db "Times:", '$'
 
 
macro writeStringTo pointer 
    lea dx, pointer 
    
    mov bx, dx                                                                                                
    
    mov ax, 0A00h                  
    int 21h                                        
    
    mov al, [bx + 1]   
    mov ah, 0
    
    add bx, ax 
    mov [bx + 2], '$' 
endm     
                                              
macro readStringFrom pointer
    mov ax, 0900h  
    lea dx, pointer 
    int 21h
endm

macro carriageReturn 
    mov ah, 02h 
    mov dl, 0Ah  
    int 21h   
    mov dl, 0Dh                  
    int 21h  
endm

macro readNumber num
    mov ax, 0900h
    lea dx, num
    int 21h
endm 

macro print_number num
    local output_cycle1,output_cycle2       
    push cx
    push bx  
     
     mov ax,num
    xor cx, cx
    test ax, 8000h    
    je output_cycle1
    mov bx, ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    neg bx
    mov ax, bx
    
    output_cycle1:
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    inc cx
    
    cmp ax, 0
    jne output_cycle1
    
    output_cycle2:
    mov ah, 02h
    xor dx, dx
    pop dx
    add dx, '0'
    int 21h
    loop output_cycle2
    pop bx
    pop cx 
    
   endm

.code                          
start:
mov ax, @data                                                
mov ds, ax  
mov si,0
push si
readStringFrom enterString
 
enterNumber:
	mov cx, 0
	
 	cmp numberOfEnteredNumbers, maximalNumberOfElements		;if maximal number of elements reached 
    je main_fun
    
	readStringFrom enterNumberString
	writeStringTo stringPointer
	carriageReturn
	
	cmp string, 'q'			;stop enter 
    je main_fun     	
    
    cmp string, '-'
    je  negativeNumber 
    
	positiveNumber:
		cmp stringSize, 6 	;if positive number if bigger then 5 symbols
		je outOfRange
		
		lea si, string
		mov negativeFlag, 0
   	 jmp checkDigits
    
	negativeNumber: 
		lea si, string + 1
		mov negativeFlag, 1
		jmp checkDigits



	checkDigits:
		cmp [si], '$'		;if end of number
		je stoi
	
		cmp [si], '0'
		jl notDigit
	
		cmp [si], '9'
		ja notDigit
	
		inc cx
		inc si
	jmp checkDigits


	
stoi:
	sub si, cx
	mov ax, 0
	mov bh, 0
	
	stoiLoop: 
		mov dx, 10
		mul dx
		jc outOfRange 
		sub [si], '0' 
		mov bl, [si]
		add ax, bx
		jc outOfRange
		inc si	
	loop stoiLoop



check:
	cmp negativeFlag, 1
	je checkNegative	

	checkPositive: 	
		cmp ax, 32767
		ja outOfRange
		jmp addToStack
	
	checkNegative: 	
		cmp ax, 32768
		ja outOfRange
		neg ax
	
	addToStack:
	    pop si
	    xor bx,bx
	    mov bl,al
	    mov mas[si], bx
	    inc si
	    mov bl,ah
	    mov mas[si],bx  
	    inc si
	    push si  
		inc numberOfEnteredNumbers     
		
		jmp enterNumber
	


errors:
	notDigit:
		readStringFrom notDigitString
		jmp enterNumber

	outOfRange:
		readStringFrom outOfRangeString
		jmp enterNumber
 
 


main_fun:

    xor ax,ax
    mov dh,0
    mov si,0                   ;ind      
    mov di,si 
     
    inc di
    inc di
         
    mov cx,0                       ;old couner
    mov bl,0                       ;times of encounters 
    dec  numberOfEnteredNumbers                         
    cmp numberOfEnteredNumbers,0
    je  print_often
    mov cx,numberOfEnteredNumbers        
First:
    mov i,cx 
    mov ax,mas[si] 
   ; push ax 
;    print_number mas[si]
;    print_number mas[di]
;    carriageReturn
;    pop ax 
    inc bx     
Second:  
    mov dx,mas[di]      
    cmp ax,dx  
    je A
    inc di
    inc di
Third:
    loop Second    
    xor di,di       
    cmp bx,max       
    jg B
Fourth:
    inc si    
    inc si      
    mov di,si 
    inc di
    inc di
    xor bx,bx    
    mov cx,i        
    loop First     
    jmp print_often
A:  
    inc bx 
    inc di
    inc di
    jmp Third        
B:
    mov max,bx 
    mov ax,mas[si]
    mov tempChar,ax
    mov index,si
    ;mov ah,al
    jmp Fourth
         
        
print_often:          
        carriageReturn
        print_number tempChar 
        ;mov ah, 02h 
        ;mov dl, "-" 
        ;int 21h   
        ;print_number index
        carriageReturn
        readStringFrom timesStr
        print_number max     
			
end:   
   	mov ax, 4C00h
  	int 21h                      
                        
end start      