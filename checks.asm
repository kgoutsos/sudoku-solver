%ifndef CHECKS_ASM
%define CHECKS_ASM

[SECTION .text]
[BITS 16]

;------------------------------------------------
; Function short int check_line(int numberKey, int boardOffset)
; Checks the line of the selected cell from start to end for the passed number. If it finds it, 
; it returns 1 in [exists_flag]
; Arguments:
;     numberKey = The number to look for in the selected line
;     boardOffset = The offset of the current cell in the board (zero-based)
; Returns:
;     1 in [exists_flag] if the number passed is found in the selected line
; Requires:
;     nothing
; Destroys:
;     nothing
;------------------------------------------------

check_line:
		push bp
		mov bp,sp		
		push bx	
		push cx
		push ax
		push di
		
		mov bx,0		
		mov cl,[bp+6]
		mov al,[bp+4]
		mov ah,0
		mov bl,9
		div bl ;This is the line of the current cell
		mov ah,0
		mul bl
		mov di,ax
		add ax,9
		dec di
line_loop:
		inc di
		cmp di,ax ; Ax is offset of the first cell in the next line
		jz cl_end
		cmp cl,[di+board]
		jnz line_loop		
		mov byte [exists_flag],1		
cl_end:		
		pop di
		pop ax
		pop cx
		pop bx
		pop bp
		ret
		
;------------------------------------------------
; Function short int check_column(int numberKey, int boardOffset)
; Checks the column of the selected cell from start to end for the passed number. If it finds it, 
; it returns 1 in [exists_flag]
; Arguments:
;     numberKey = The number to look for in the selected line
;     boardOffset = The offset of the current cell in the board (zero-based)
; Returns:
;     1 in [exists_flag] if the number passed is found in the selected line
; Requires:
;     nothing
; Destroys:
;     nothing
;------------------------------------------------

		
check_column:
		push bp
		mov bp,sp		
		push bx
		push dx
		push cx
		push ax
		push di
		
		mov cl,[bp+6]
		mov al,[bp+4]
		mov ah,0
		mov bl,9
		div bl ;This is the column of the current cell
		mov al,ah
		mov ah,0		
		mov di,ax ;di offeset of the first cell of the column		
		sub di,9
column_loop:
		add di,9  ;Move to the next line
		cmp di,81 
		jg cc_end
		cmp cl,[di+board]
		jnz column_loop
		mov byte [exists_flag],1		
cc_end:
		pop di
		pop ax
		pop cx
		pop dx
		pop bx
		pop bp
		ret

;------------------------------------------------
; Function short int check_square(int numberKey, int boardOffset)
; Checks the 3x3 square of the selected cell from start to end for the passed number. If it finds it, 
; it returns 1 in [exists_flag]
; Arguments:
;     numberKey = The number to look for in the selected line
;     boardOffset = The offset of the current cell in the board (zero-based)
; Returns:
;     1 in [exists_flag] if the number passed is found in the selected line
; Requires:
;     nothing
; Destroys:
;     nothing
;------------------------------------------------

		
check_square:
		push bp
		mov bp,sp		
		push bx
		push dx
		push cx
		push ax
		push di
		
		mov cl,[bp+6]
		mov al,[bp+4]
		
		mov bl,27
		div bl 
		mov ah,0		
		mul bl
		mov dl,al ;This is the vertical offset the square
	
		mov al,[bp+4]
		mov bl,9
		div bl
		mov al,ah
		mov ah,0
		mov bl,3
		div bl
		mov ah,0
		mul bl
		mov dh,al ;This is the horizontal offset the square
		;The top left cell of the square is in DX
		mov ax,dx
		add al,ah
		mov ah,0
		mov di,ax
		
		mov al,2	
		
ver_loop:
		mov ah,2		
	
hor_loop:	
		cmp cl,[di+board]
		jz cs_found		
		inc di
		dec ah
		cmp ah,0		
		jge hor_loop
		add di,6
		dec al
		cmp al,0
		jge ver_loop		
		jmp cs_end
		
cs_found:
		mov byte [exists_flag],1
cs_end:
		pop di
		pop ax
		pop cx
		pop dx
		pop bx
		pop bp
		ret

;------------------------------------------------
; Function short int check_zeros()
; Checks the whole board for empty cells (cells containing a zero)
; Arguments:
;    none
; Returns:
;    nothing
; Requires:
;     nothing
; Destroys:
;     nothing
;------------------------------------------------
		
check_zeros:
		push si		
		mov si,0
chz_loop:		
		cmp byte [board+si],0		
		jz chz_endz
		inc si
		cmp si,81
		jnz chz_loop
		mov ax,0
		jmp chz_endnz
chz_endz:
		mov ax,1
chz_endnz:		
		pop si
		ret

%endif
