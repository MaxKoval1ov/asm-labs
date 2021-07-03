.model small
.data	

ARGUMENTS_COUNTER		db		2
CMP_FLAG				db		1

RAW_PATH				db		128 dup (0)
RAW_PATH_2				db		128 dup (0)

PATH 					db 		128 dup (0)
PATH_2					db		128 dup (0)

FILE_NAME				db		128 dup ('$')
FILE_NAME_2				db 		128 dup ('$')
FILE_DESCRIPTOR			dw		0
FILE_DESCRIPTOR_2		dw		0
FILE_SIZE				dd		0
FILE_SIZE_2				dd		0

CURRENT_POINTER			dd		0
BUFFER					db		?
BUFFER_2				db		?

NEW_DTA 				db 		50 dup (?)
NEW_DTA_2 				db 		50 dup (?)

TEXT_NOT_MATCH			db		"The directories don't match", 0Dh, 0Ah, '$'
TEXT_MATCH				db		"The directories are equals", 0Dh, 0Ah, '$'
WRONG_ARGS				db 		"Wrong args in cmd", 0Dh, 0Ah, '$'
DIR_ERROR				db		"Directory not found", 0Dh, 0Ah, '$'
ERROR_OF_OPENING		db		"Can't open file", 0Dh, 0Ah, '$'

TEXT_MATCH_STATUS		db		"	match", 0Dh, 0Ah, '$'
TEXT_NOT_MATCH_STATUS	db		"	not match", 0Dh, 0Ah, '$'

.code

start:
	mov 	ax, @data
	mov 	ds, ax
	
	call	SCAN_CMD	
	call	MODIFY_PATHS
	call	FIRST_SETUP
	
	;check file names
	FIRST_CHECK:
		mov		di, offset NEW_DTA
		call	GET_NEXT_FROM_DIR
		jc		CHECK_DIRECTORIES_EQUAL
		
		mov		di, offset NEW_DTA_2
		call	GET_NEXT_FROM_DIR
		jc		DIRECTORIES_NOT_EQUAL
		
		call	COMPARE_DTA
		cmp		CMP_FLAG, 0
		je		DIRECTORIES_NOT_EQUAL
		
		jmp 	FIRST_CHECK
		
	CHECK_DIRECTORIES_EQUAL:
		mov		di, offset NEW_DTA_2
		call	GET_NEXT_FROM_DIR
		jnc		DIRECTORIES_NOT_EQUAL
	
	;if files are equal, check data in files
	call	FIRST_SETUP
	SECOND_CHECK:
		mov		di, offset NEW_DTA
		call	GET_NEXT_FROM_DIR
		jc		DIRECTORIES_EQUAL
		
		mov		di, offset NEW_DTA_2
		call	GET_NEXT_FROM_DIR
		jc		DIRECTORIES_EQUAL
		
		call	COMPARE_FILES_DATA
		call	PRINT_STATUS
		cmp		CMP_FLAG, 0
		je		DIRECTORIES_NOT_EQUAL
		
		jmp 	SECOND_CHECK
	
	DIRECTORIES_NOT_EQUAL:
		mov		ah, 09h
		mov		dx, offset TEXT_NOT_MATCH
		int 	21h
		mov 	ax,4C00h
		int 	21h
	
	DIRECTORIES_EQUAL:
		mov		ah, 09h
		mov		dx, offset TEXT_MATCH
		int 	21h
		mov 	ax,4C00h
		int 	21h
		
;procedures
COMPARE_FILES_DATA PROC
	call	SCAN_FILES_NAMES
	call	OPEN_FILES
	call	COMPARE_FILES
	call	CLOSE_FILES
	ret
COMPARE_FILES_DATA ENDP

COMPARE_FILES PROC
	COMPARE_FILES_LOOP:
		call	GET_CHAR
		cmp		BUFFER, 0Dh	;CR
		jne		SKIP_CR_FIX
		call	GET_CHAR
		SKIP_CR_FIX:
		
		call	GET_CHAR_2
		cmp		BUFFER_2, 0Dh	;CR
		jne		SKIP_CR_FIX_2
		call	GET_CHAR_2
		SKIP_CR_FIX_2:
		
		mov		al, BUFFER
		cmp		al, BUFFER_2
		jne		COMPARE_FILES_FALSE

		call	GET_CURRENT_POINTER
		mov		ax, word ptr CURRENT_POINTER + 2
		cmp		ax, word ptr FILE_SIZE + 2
		jb		COMPARE_FILES_LOOP
		
		mov		ax, word ptr CURRENT_POINTER
		cmp		ax, word ptr FILE_SIZE
		jb		COMPARE_FILES_LOOP
	
	call	GET_CHAR
	call	GET_CHAR_2
	mov		al, BUFFER
	cmp		al, BUFFER_2
	jne		COMPARE_FILES_FALSE
	
	mov		CMP_FLAG, 1
	ret
	
	COMPARE_FILES_FALSE:
		mov		CMP_FLAG, 0
		ret
COMPARE_FILES ENDP

GET_CHAR PROC
	mov		ah, 3Fh
	mov		bx, FILE_DESCRIPTOR
	mov		cx, 1
	mov		dx, offset BUFFER
	int		21h
	ret
GET_CHAR ENDP

GET_CHAR_2 PROC
	mov		ah, 3Fh
	mov		bx, FILE_DESCRIPTOR_2
	mov		cx, 1
	mov		dx, offset BUFFER_2
	int		21h
	ret
GET_CHAR_2 ENDP

SCAN_FILES_NAMES PROC
	mov		di, 0
	SAVE_DIRECTORY_PATH_LOOP_1:
		cmp		RAW_PATH + di, 0
		je		END_SAVE_DIRECTORY_PATH_1
		mov		al, RAW_PATH + di
		mov		FILE_NAME + di, al
		inc		di
		jmp		SAVE_DIRECTORY_PATH_LOOP_1
	
	END_SAVE_DIRECTORY_PATH_1:
		mov 	bx, 1Eh
		
	SCAN_FILES_NAMES_LOOP_1:
		mov 	al, NEW_DTA + bx
		mov		FILE_NAME + di, al
		cmp 	al, 0
		jz 		SCAN_FILES_NAMES_END_1
		inc 	bx
		inc		di
		jmp 	SCAN_FILES_NAMES_LOOP_1
		
	SCAN_FILES_NAMES_END_1:
		mov		di, 0
	SAVE_DIRECTORY_PATH_LOOP_2:
		cmp		RAW_PATH_2 + di, 0
		je		END_SAVE_DIRECTORY_PATH_2
		mov		al, RAW_PATH_2 + di
		mov		FILE_NAME_2 + di, al
		inc		di
		jmp		SAVE_DIRECTORY_PATH_LOOP_2
	
	END_SAVE_DIRECTORY_PATH_2:
		mov 	bx, 1Eh
		
	SCAN_FILES_NAMES_LOOP_2:
		mov 	al, NEW_DTA_2 + bx
		mov		FILE_NAME_2 + di, al
		cmp 	al, 0
		jz 		SCAN_FILES_NAMES_END_2
		inc 	bx
		inc		di
		jmp 	SCAN_FILES_NAMES_LOOP_2
	SCAN_FILES_NAMES_END_2:
		ret
SCAN_FILES_NAMES ENDP

COMPARE_DTA PROC
	mov 	bx, 1Eh
	COMPARE_DTA_LOOP:
		mov 	al, NEW_DTA + bx
		cmp		al, NEW_DTA_2 + bx
		jne		COMPARE_FALSE
		cmp 	al, 0
		jz 		COMPARE_TRUE
		inc 	bx
		jmp 	COMPARE_DTA_LOOP
		
	COMPARE_TRUE:
		mov		CMP_FLAG, 1
		ret
	COMPARE_FALSE:
		mov		CMP_FLAG, 0
		ret
COMPARE_DTA ENDP

PRINT_STATUS PROC
	mov		di, offset NEW_DTA
	call	PRINT_NAME
	
	cmp		CMP_FLAG, 1
	je		STATUS_MATCH
	
	mov		ah, 09h
	mov		dx, offset TEXT_NOT_MATCH_STATUS
	int		21h
	ret
	
	STATUS_MATCH:
		mov		ah, 09h
		mov		dx, offset TEXT_MATCH_STATUS
		int		21h
		ret
PRINT_STATUS ENDP

PRINT_NAME PROC
	mov 	bx, 1Eh
	mov 	ah, 2
	PRINT_NAME_LOOP:
		mov 	dl, [di + bx]
		cmp 	dl,0
		jz 		END_OF_NAME
		int 	21h
		inc 	bx
		jmp 	PRINT_NAME_LOOP
	END_OF_NAME:
		ret
PRINT_NAME ENDP

GET_NEXT_FROM_DIR PROC
	lea 	dx,	[di]
	call	SET_DTA
	
	lea 	dx,	[di]
	call 	FIND_REMAINING_FILES
	ret
GET_NEXT_FROM_DIR ENDP

FIRST_SETUP PROC
	lea 	dx,	NEW_DTA
	call	SET_DTA
	lea 	dx, PATH
	call 	FIND_FIRST_FILE
	jc 		ERROR_FILE
	
	lea 	dx,	NEW_DTA_2
	call	SET_DTA
	lea 	dx, PATH_2
	call 	FIND_FIRST_FILE
	jc 		ERROR_FILE
	
	;skip file ..
	mov		di, offset NEW_DTA
	call	GET_NEXT_FROM_DIR
	
	mov		di, offset NEW_DTA_2
	call	GET_NEXT_FROM_DIR
	ret
	
	ERROR_FILE:
		mov		ah, 09h
		mov		dx, offset DIR_ERROR
		int		21h
		mov 	ax,4C00h
		int 	21h
FIRST_SETUP ENDP

SET_DTA	PROC
	mov 	ah,	1Ah
	int 	21h
	ret
SET_DTA	ENDP

FIND_FIRST_FILE PROC
	mov 	ah,	4Eh
	mov 	cx,	110101b
	int 	21h
	ret
FIND_FIRST_FILE ENDP

FIND_REMAINING_FILES proc
	mov 	ah, 4Fh
	int 	21h
	ret
FIND_REMAINING_FILES endp

SCAN_CMD PROC		
	mov		bx, 80h
	xor		ch ,ch	
	mov		cl, es:[bx]
	cmp		cl, 1
	jle		ERROR_SCAN_CMD
	mov		si, 81h
	
	SKIP_SPACES:
		cmp		byte ptr es:[si], 0Dh
		je		END_SCAN_CMD
		cmp		byte ptr es:[si], ' '
		jne		END_SKIP_SPACES
		inc		si
		jmp		SKIP_SPACES
		
	END_SKIP_SPACES:
		dec		ARGUMENTS_COUNTER
		
		mov		di, offset PATH
		cmp		ARGUMENTS_COUNTER, 1
		je		SCAN_ARGUMENT
		
		mov		di, offset PATH_2
		cmp		ARGUMENTS_COUNTER, 0
		je		SCAN_ARGUMENT
		
		jmp		ERROR_SCAN_CMD
		
	SCAN_ARGUMENT:
		cmp		byte ptr es:[si], 0Dh
		je		END_SCAN_CMD
		cmp		byte ptr es:[si], ' '
		je		SKIP_SPACES
		mov		dl, es:[si]
		mov		[di], dl
		inc		di
		inc		si
		jmp		SCAN_ARGUMENT
	
	END_SCAN_CMD:
		cmp		ARGUMENTS_COUNTER, 0
		jne		ERROR_SCAN_CMD
		ret		
		
	ERROR_SCAN_CMD:
		mov		ah, 09h
		mov		dx, offset WRONG_ARGS
		int		21h
		
		mov		ax, 4C00h
		int 	21h
SCAN_CMD ENDP

MODIFY_PATHS PROC
	mov		di, 0
	MODIFY_PATHS_LOOP:
		cmp		PATH + di, 0
		je		END_MODIFY_PATHS_LOOP
		
		mov		al, PATH + di
		mov		RAW_PATH + di, al
		
		inc		di
		jmp		MODIFY_PATHS_LOOP
		
	END_MODIFY_PATHS_LOOP:
		dec		di
		cmp		PATH + di, 5Ch 
		jne		MODIFY_PATHS_ERROR
		inc		di
		
		mov		PATH + di, '*'
		inc		di
		mov		PATH + di, '.'
		inc		di
		mov		PATH + di, '*'
		
	mov		di, 0
	MODIFY_PATHS_LOOP_2:
		cmp		PATH_2 + di, 0
		je		END_MODIFY_PATHS_LOOP_2
		
		mov		al, PATH_2 + di
		mov		RAW_PATH_2 + di, al
		
		inc		di
		jmp		MODIFY_PATHS_LOOP_2
		
	END_MODIFY_PATHS_LOOP_2:
		dec		di
		cmp		PATH_2 + di, 5Ch ;backslash
		jne		MODIFY_PATHS_ERROR
		inc		di
		
		mov		PATH_2 + di, '*'
		inc		di
		mov		PATH_2 + di, '.'
		inc		di
		mov		PATH_2 + di, '*'
	ret
	
	MODIFY_PATHS_ERROR:
		mov		ah, 09h
		mov		dx, offset WRONG_ARGS
		int		21h
		
		mov		ax, 4C00h
		int 	21h
MODIFY_PATHS ENDP

OPEN_FILES PROC
	;open first file
	mov		dx, offset FILE_NAME
	mov		ah, 3Dh
	mov		al, 2
	int 	21h
	jc		ERROR_OF_FILE_OPENING
	mov		FILE_DESCRIPTOR, ax
	
	;open second file
	mov		dx, offset FILE_NAME_2
	mov		ah, 3Dh
	mov		al, 2
	int 	21h
	jc		ERROR_OF_FILE_OPENING
	mov		FILE_DESCRIPTOR_2, ax
	
	;get the size of first file
	mov		ah, 42h
	mov		bx, FILE_DESCRIPTOR
	xor		cx, cx
	xor		dx, dx
	mov		al, 02h
	int		21h
	mov		word ptr FILE_SIZE + 2, dx
	mov		word ptr FILE_SIZE , ax
	
	mov		ah, 42h
	mov		al, 00h
	mov		bx, FILE_DESCRIPTOR
	xor		cx, cx
	xor		dx, dx
	int		21h
	
	;get the size of second file
	mov		ah, 42h
	mov		bx, FILE_DESCRIPTOR_2
	xor		cx, cx
	xor		dx, dx
	mov		al, 02h
	int		21h
	mov		word ptr FILE_SIZE_2 + 2, dx
	mov		word ptr FILE_SIZE_2, ax
	
	mov		ah, 42h
	mov		al, 00h
	mov		bx, FILE_DESCRIPTOR_2
	xor		cx, cx
	xor		dx, dx
	int		21h
	ret
	
	ERROR_OF_FILE_OPENING:
		mov		ah, 09h
		mov		dx, offset ERROR_OF_OPENING
		int		21h
		mov		ax, 4C00h
		int		21h
OPEN_FILES ENDP

CLOSE_FILES PROC
	mov		ah, 3Eh
	mov		bx, FILE_DESCRIPTOR
	int 	21h
	
	mov		ah, 3Eh
	mov		bx, FILE_DESCRIPTOR_2
	int 	21h
	ret
CLOSE_FILES ENDP

GET_CURRENT_POINTER PROC
	mov		ah, 42h
	mov		bx, FILE_DESCRIPTOR
	xor		cx, cx
	xor		dx, dx
	mov		al, 01h
	int		21h
	mov		word ptr CURRENT_POINTER + 2, dx
	mov		word ptr CURRENT_POINTER, ax
	ret
GET_CURRENT_POINTER ENDP

	end 	start