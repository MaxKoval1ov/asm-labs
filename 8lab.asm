; ��������

; ---------- macro ----------
output_string macro out_str   ; output string of character
    mov dx, offset out_str+2
    mov ah, 40h
    mov bx, 01h
    mov cx, 0
    mov cl, out_str[1]
    int 21h
endm

input_string macro str       ; input string of character
    lea dx, str
    mov ah, 0Ah
    int 21h
endm

pr_msg macro string             ; output message
    mov dx, offset string
    mov ah, 09h
    int 21h
endm

print_symb macro symb
    mov dl, symb
    mov ah, 06h
    int 21h
endm

bcdToInt macro
    
    xor ax, ax
    mov al, [si];currHour
    and al, 0fh
    add al, '0'
    mov [di], al;timeForOut[2], al
    sub di, 2
    mov al, [si];currHour
    shr al, 4 
    and al, 0fh
    add al, '0'
    mov [di], al ;timeForOut[0], al

endm

outputTime macro
    push es
    mov ax, 0B800h
    mov es, ax
    mov di, cooroutTime
    mov cx, 8
    mov si, offset timeForOut
    rep movsw
    
    pop es
endm
; --------------- TASK -------------------------
; �������� ����������� ��������� "����"
; ���������� ������ ������ �������� �������� ��� ������ ���������
; in cmd         
.model tiny
; --------------- CODE -------------------------
.code
    org 100h
start:
    jmp main
; --------------- DATA -------------------------
MAXPATHSIZE    equ 124
CMDstring      db MAXPATHSIZE, 00h, MAXPATHSIZE dup (0Dh), (0Dh)
CMDsize        db ?
coordinates    db 5, 00h, 5 dup (?)
readElement    db 2, 02h, 2 dup (?)
old_2fh dd 0
; messages
cmdParamAsk     db 'cmd: XX:YY (XX <= 72, YY <= 23, count from 0)', 0Dh, 0Ah, '$'
strEndOfProgram db 09h, 'END OF PROGRAM', 0Dh, 0Ah, '$'
nextOne         db 0Dh, 0Ah, '$'
CMDcorrectNumberOfParams db 0Dh, 0Ah, 'Correct number of parametrs in cmd', 0Dh, 0Ah, '$'
CMDwrong                 db 0Dh, 0Ah, 'Wrong parametrs in cmd', 0Dh, 0Ah, '$'
NumberCorrect            db 0Dh, 0Ah, 'Number', 0Dh, 0Ah, '$'
ERROR_emptyCMD           db 0Dh, 0Ah, 'EMPTY CMD', 0Dh, 0Ah, '$'
ERROR_wrongStringNumber  db 0Dh, 0Ah, 'WRONG NUMBER', 0Dh, 0Ah, '$'
ERROR_cantreadtime       db 0Dh, 0Ah, 'Can not read time', 0Dh, 0Ah, '$'
prAlreadyResedent        db 0Dh, 0Ah, 'This program is already resedent.', 0Dh, 0Ah, '$'
programStart:
OldVector      dd ?
coorX          db ?
coorY          db ?
cooroutTime    dw ?
currHour       db ?
currMin        db ?
currSec        db 0
;                  0         2                   6         8                   12        14
;                  h         h                   m         m                   s         s
timeForOut     db '0', 07h, '0', 07h, ':', 07h, '0', 07h, '0', 07h, ':', 07h, '0', 07h, '0', 07h ;8/16
magic_word dw 1234h
getTime proc
    pushf
    push    ds
    push    es
	push    ax
	push    bx
    push    cx
    push    dx
	push    di

	push cs
	pop ds
    
rtcrdy:
    mov al, 0Ah
	out 70h, al
	in al, 71h
	and al, 10000000b
	jnz good_getTime_end
    
    mov al, 00h
	out 70h, al
	in al, 71h    
    cmp al, currSec
    je good_getTime_end
    
    mov currSec,  al
    mov si, offset currSec
    mov di, offset timeForOut[14]
    bcdToInt
     
	mov al, 04h
	out 70h, al
	in al, 71h
	mov currHour, al
	mov si, offset currHour
    mov di, offset timeForOut[2]
    bcdToInt
    
	mov al, 02h
	out 70h, al
	in al, 71h
	mov currMin, al
	mov si, offset currMin
    mov di, offset timeForOut[8]
    bcdToInt
       
;    xor ax, ax
;    mov ah, 02h
;    int 1Ah
;    jc Error
    
    ;mov currHour, ch
;    mov currMin,  cl
;    mov currSec,  dh
;    
;    mov si, offset currHour
;    mov di, offset timeForOut[2]
;    bcdToInt
;    
;    mov si, offset currMin
;    mov di, offset timeForOut[8]
;    bcdToInt
;    
;    mov si, offset currSec
;    mov di, offset timeForOut[14]
;    bcdToInt
    
    ; ������ � �����������
    outputTime
    
    jmp good_getTime_end    
    Error:
    pr_msg ERROR_cantreadtime

good_getTime_end:
    pop     di
	pop     dx
	pop     cx
	pop     bx
	pop     ax
	pop     es
	pop     ds	
popf
jmp dword ptr cs:OldVector
iret ;iret
endp

programLenth:

; ---------- proc -----------
; si - ������ �����
; di - ���� �����
; cx - ������ �� ����� ������
getWord proc    
    ; ���������� �������, ���� ��� ����    
    mov bx, di
    mov di, si
    
    ;cmp [di], ' '
    ;jne noSpaces
    xor ax, ax
    mov al, ' '
    repe scasb
    dec di
    inc cx
    noSpaces:
        mov si, di
        mov di, bx
        cmp cx, 0
        je getWordError
        xor dx, dx
        mov dl, cl
            
    getWordLoop:
        lodsb
        cmp al, ' '
        je wordIsReady
        cmp al, 0Dh
        je wordIsReady
        stosb
    loop getWordLoop
         
    wordIsReady:        
        sub dl, cl ; ����� word
        sub di, dx ; ���������� ��������� ���������, ����� �������� ����� ������
        dec di
        mov [di], dl
    getWordFine:
       clc
       jmp getWordEnd 
    getWordError:
       stc
getWordEnd:    
ret
endp 

; �������� �� 1 �������� � ������
checkCMD proc
    xor cx, cx
    mov cl, CMDsize
    ; ��������� ����
    mov si, offset CMDstring[2]
    mov di, offset coordinates[2]
    call getWord
    jc wrongCMD
    
    ; ���������, ���� �� ��� ���-�� � ������
    ; ���� -> wrongCMD
    ; ���  -> correctCMD
    cmp cx, 0
    jne wrongCMD
    
    mov cl, coordinates[1]
    cmp cl, 5
    jne wrongCMD
    
    mov al, coordinates[4]
    cmp al, ':'
    jne wrongCMD
    
    correctCMD:
        clc
        pr_msg CMDcorrectNumberOfParams
        jmp endOfcheckCMD   
    wrongCMD:
        stc
        pr_msg CMDwrong
        pr_msg cmdParamAsk    
endOfcheckCMD:
ret
endp
; ������� ������ � �����
atoi proc                          
    xor ax, ax
    mov cx, 2
    number:                        ; �������� ASCII ��� �� �������� �������� �������
        mov al,[si]                    ; ������� �������� � ������� �l
        sub al, 30h                    ; �������� �� ������� �����
        mov [si], al                   ; ������ ����� �������� ������� � ������
        inc si                         ; ����������� ������
        loop number
    xor dx, dx                    ; �������� dx
    sub si, 2
    mov dl, [si]
    inc si
    multiply:
        mov ax, 10
        imul dx                        ; �������� �������� ����� �� 10. ��������� � ��
        jo errorExit
        mov dx, [si]                  ; ��������� ��������� �����-������
        mov dh, 0                     ; ����������� ����� � ������� �����
        add ax, dx                    ; ��������� � ����������� �����
    
    correct:                     ; ���������� �������������� ������
    clc
    jmp endAtoiret
    errorExit:                   ; ������������ ����
    stc
endAtoiret:
ret
endp

; �������� ��������� �������� ������ �� ������������
checkString proc                
    xor ax, ax                            ; �������� ��, ��
    checkNumerals:        
        mov al, [si]                      ; ��������� ��������
        cmp al, 3Ah                       ; ���� ASCII ��� ������ 39h(������ 9)
        jge wrongInput                    ; �� ������ �����
        cmp al, 2Fh                       ; ���� ASCII ��� ������ 30h(������ 0)
        jle wrongInput                    ; �� ������ �����
        inc si                            ; ��������� �� ��������� �������
        loop checkNumerals
    
    correctInput:
        clc                             ; "������", ��� ������ ������� �����
        jmp endcheckString
    wrongInput:        
        pr_msg ERROR_wrongStringNumber
        pr_msg nextOne
        pr_msg cmdParamAsk
        stc                             ; "������", ��� ������ ������� �������
endcheckString:
ret
endp

setNewVect proc
    cli
    push es
    mov ah, 35h
    mov al, 1Ch
    int 21h
    ; ��������� ������ ��������� ����������
    mov word ptr OldVector, bx
    mov word ptr OldVector + 2, es   
    mov ax, es:[bx]-2
    ; ��������������� �������� ��������
    pop es

    ;cmp ax, magic_word
    ;jne set_new_vector
    ;mov ax, -1
    ;sti
    ;ret
    
    set_new_vector:
        ; ������������� ����� ������
        mov ah, 25h
        mov al, 1Ch
        mov dx, offset getTime
        int 21h
        
sti
xor ax, ax         
ret
endp    
; ----------- PROGRAM START --------------------
main:
    mov ax, @data
    mov es, ax
    mov ds, ax
              
    xor ch, ch    
    mov cl, ds:[80h]
    cmp cl, 0
    je ERROR_EMPTY
    push ds
    mov ds, ax
    mov CMDsize, cl
    mov CMDstring[1], cl
    pop ds        
    ; ����������� ��������� ������ � �������� ���������� ������
    mov di, offset CMDstring[2]
    mov si, 81h
    rep movsb
    mov ds, ax    
    
    ; ���������, ��� ���� �������� � ������
    call checkCMD      
    jc endOfProgram 
    ; ���������, ��� ��������� ������ - �����
    xor cx, cx
    mov cl, 2
    mov si, offset coordinates[2]
    call checkString
    jc endOfProgram    
    xor cx, cx
    mov cl, 2
    mov si, offset coordinates[5]
    call checkString
    jc endOfProgram    
    pr_msg NumberCorrect
    ; ���� ��� �����, �� ��������� �� ������ � �����
    mov si, offset coordinates[2]
    call atoi
    jc ERROR_WRONGNUMBER
    cmp al, 72
    ja ERROR_WRONGNUMBER
    mov coorX, al
    mov si, offset coordinates[5]
    call atoi
    jc ERROR_WRONGNUMBER    
    cmp al, 23
    ja ERROR_WRONGNUMBER
    mov coorY, al
    ; ���������� ������ ����� ��������
    mov ax, 160
    xor bx, bx
    mov bl, coorY
    mul bx
    mov bl, coorX
    add ax, bx
    add ax, bx
    mov cooroutTime, ax    
    ; ����� ������� ������ ������� ����������
    call setNewVect
    cmp ax, 0
    jne alreadyResedent    
    
    mov ax, 3100h
;    mov dx, (programLenth - programStart + 100h)/16 + 1
    mov dx, (programLenth - start + 100h + 15)/16 + 1
    int 21h
    
    jmp _end
    ERROR_EMPTY:
        mov ax, @data
        mov ds, ax
        pr_msg ERROR_emptyCMD
        pr_msg cmdParamAsk
        jmp endOfProgram
    ERROR_WRONGNUMBER:
        pr_msg ERROR_wrongStringNumber
        pr_msg cmdParamAsk
        jmp endOfProgram
    alreadyResedent:
        mov ax, @data
        mov ds, ax
        pr_msg prAlreadyResedent
        jmp endOfProgram
; ���������� ���������
endOfProgram:
pr_msg nextOne
pr_msg strEndOfProgram
 mov ax, 4c00h
 int 21h
;ret
_end:
end start        