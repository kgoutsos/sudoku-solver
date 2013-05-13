%ifndef BWORKS_ASM
%define BWORKS_ASM

[SECTION .text]
[BITS 16]

;------------------------------------------------
; Function short int load_file(char *file_name, char *board, int board_size)
; Opens the file with the given filename, reads its contents,
; copies them in the board and closes the file
; All pointer are near pointers (offset)
; Arguments:
;     file_name   = The string of the name of the file to be read -> 2 bytes offset
;     file_buffer = The buffer where the sudoku board will be read to -> 2 bytes offset
;     board_size = The size of the sudoku board -> 2 bytes
; Returns:
;     0x00 in ah if no error
;     0x01 in ah if error
; Requires:
;     nothing
; Destroys:
;     register AX
;------------------------------------------------
load_file:
        push bp
        mov bp, sp

        push bx
        push cx
        push dx		
		push di
		
		mov dx,[bp+4]
		
		mov ah,0x3d ; Call dos services
		mov al,0x00 ;Open a file
		int 0x21    
		jc err     ;Check file exist
		
		mov dx,[bp+6]
		mov cx,[bp+8]
		mov bx,ax
		mov ah,0x3f
		int 0x21     ;Read board from file
		jc err
		cmp ax,0     ; Dos return error code to ax
		jz err       ; if ax <>0 jmp to error
		pushf
		push ax
		mov ah,0x3e  ; close the file
		int 0x21
		pop ax
		popf
		jnc noerror
		
err:	mov ah,1
		jmp load_file_exit
noerror: 
		mov ah,0
load_file_exit:
		
		mov di,0
unascii_loop:
		sub byte [board+di],0x30 ;Subtracts 0x30 from the number because it is read in ASCII
		inc di
		cmp di,81
		jnz unascii_loop

		pop di
        pop dx
        pop cx
        pop bx

        pop bp
        ret

;----------------------------------------------------------
; Procedure void save_board()
;    Copies the contents of the board memory area to an equally sized one called board2
;	  Used to keep a backup of the board contents before the brute force method.
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;----------------------------------------------------------
		
save_board:
        mov byte [save],1
		push si
		push ax
		
		mov si,0
save_loop:
		mov al,[board+si]
		mov [board2+si],al
		inc si
		cmp si,82
		jnz save_loop
		
		pop ax
		pop si
		ret

;----------------------------------------------------------
; Procedure void restore_board()
;    Copies the contents of the board2 memory area to an equally sized one called board
;	  Used to restore the board contents after an unsuccessfull brute force method.
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;----------------------------------------------------------
		
restore_board:
		pushf
		push si
		push ax
		
		mov si,0
restore_loop:
		mov al,[board2+si]
		mov [board+si],al
		inc si
		cmp si,82
		jnz restore_loop		
		
		call cls_brute
		
		pop ax
		pop si
		popf
		ret


%endif

