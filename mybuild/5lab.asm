.MODEL small
.STACK
.DATA

current_directory                   db 64 dup(0)
slovo                               db "This"
error_wrong_argc                    db "Two parameters should be passed", 0ah, 0dh, '$'
error_cant_find_first_file          db "Can't find first file", 0ah, 0dh, '$'
error_cant_chdir                    db "Can't change directory", 0ah, 0dh, '$'
error_cant_save_current_directory   db "Can't save current directory", 0ah, 0dh, '$'

.CODE


print_str macro string
    mov     ah, 09h
    lea     dx, string
    int     21h
endm
  
print_filename proc
    push    bx
    push    dx
    
    mov     bx, dx
    @@print_loop:
        mov     dl, byte ptr [bx]
        mov     ah, 06h             
        int     21h                 
        inc     bx
        cmp     byte ptr [bx], 0
    jne @@print_loop
    
    ; 
    mov     ah, 06h
    mov     dl, 0Ah
    int     21h
    mov     dl, 0Dh
    int     21h
    
    pop     dx
    pop     bx
    ret
print_filename endp


MAIN:  
    xor     ch, ch
    mov     cl, es:[80h]   ;dlinna stroki 
    jcxz    no_arguments    
   
    mov     bx, 81h        ;nachalo stroki
    mov     dx, bx           
    add     bx, cx          
    mov     es:[bx], byte ptr 0    ;remove cret
    
    mov     bx, 82h        
   
    count_args_loop:
        cmp     byte ptr [bx], ' '
        jne     count_next
        mov     byte ptr [bx], 0   
        push    bx                 
        inc     ax              
        count_next:
        inc     bx
    loop count_args_loop
    
    cmp     ax, 1
    jne     no_arguments    

    
     
    mov     ax, @data
    mov     ds, ax
    
    mov     ah, 19h            
    int     21h                
    add     al, 'A'             
    lea     si, current_directory
    mov     byte ptr [si], al   
    inc     si                 
    mov     [si], "\:"         
    add     si, 2              
    mov     ah, 47h     ;CWD - GET CURRENT DIRECTORY      ds:si 
    mov     dl, 0              
    int     21h                 
    
   
    
    jc      cant_save_current_directory    ;esli CF = 1 :err
    
    push es
    pop  ds
   
    
    mov     ah, 3Bh               ;smenit katalog   ds:dx
    mov     dx, 82h         
    int     21h
    jc      no_directory          ;error 
    

    ;Klushevoie slovo poiska
    
    
    pop     dx              
    inc     dx             

    mov     ah, 4Eh            ;naiti pervii file
    int     21h
    jc no_first_file_found  

    mov     dx, 9Eh        
    call print_filename
 
    search_file_loop:
        mov ah, 4Fh           ;whiel files 
        int 21h
        jc restore_directory   
        call print_filename
    jmp search_file_loop
restore_directory:  


    mov     ax, @data
    mov     ds, ax

    mov     ah, 3Bh         
    lea     dx, current_directory
    int     21h            
    
    pop     ds

    jc      no_directory   
    
    jmp end_main  
    
no_arguments:   
    mov     ax, @data
    mov     ds, ax
    print_str error_wrong_argc
    jmp     end_main  
    
cant_save_current_directory: 
    mov     ax, @data
    mov     ds, ax
    print_str error_cant_save_current_directory
    jmp     end_main  
    
no_directory:
    mov     ax, @data
    mov     ds, ax
    print_str error_cant_chdir
    jmp     end_main  
    
no_first_file_found:
    mov     ax, @data
    mov     ds, ax
    print_str error_cant_find_first_file
    jmp     restore_directory
end_main:
    mov ax, 4C00h
    int 21h
END MAIN
