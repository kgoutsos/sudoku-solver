%ifndef DISPLAY_ASM
%define DISPLAY_ASM

;----------------------------------------------------------
;                       CONSTANTS
;----------------------------------------------------------
vidmem          equ 0xb800
default_color   equ 7       ;default_color
scrw            equ 80*25   ;25=lines 80=chars per line
eom             equ '*'


[SECTION .data]
line:           dw 162            ; offset from start of vidmem where we print
new_line_count: dw 86
board:    times 81 db 0
board_end: db eom
board2:    times 81 db 0
board2_end: db eom

cell_color: dw 7

error_message:  db 'File Error! Exiting to DOS...', eom
solved_message: db 'Sudoku Solved!!!',eom
unsolved_message: db 'Sudoku not solved',eom
time_msg: db 'Completed in '
time_message: times 5 db 0
time_message_end: db 0 
sec_message: db ' seconds',eom
brute_message_a: db 'Brute force ran on ',eom
brute_vmsg: times 5 db 0
brute_vmsg_end:db 0
brute_message_b: db ' cells and tried ',eom
brute_cmsg: times 5 db 0
brute_cmsg_end:db 0
brute_message_c: db ' values',eom
brute_no_message: db 'Brute force was not used',eom

[SECTION .text]
[BITS 16]

;----------------------------------------------------------
; Procedure void cls()
;    Clears the screen
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Destroys:
;       none
;----------------------------------------------------------

cls:
        push eax
        push ecx
        push edi

        mov di, 0
        mov al, ' '
        mov ah, default_color
        mov cx, scrw
        rep stosw

        pop edi
        pop ecx
        pop eax
        ret
		
;----------------------------------------------------------
; Procedure void print_grid(char *board)
;    Prints the sudoku board on screen, by writing in video memory
;    Starts printing from offset 'line'
;    Arguments:
;       the start of the board is passed from the stack
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Uses:
;       es, esi, edi, eax, bp, ecx, edx
;----------------------------------------------------------
print_grid:
		push bp        
        mov  bp, sp
		push dx
		push cx        
		push ax
        mov  ax, [bp + 4]   ; Take the start of the board
        mov  si, ax  

        mov di,[line]		
	
		sub di,2	
		push word 201
		push word 205
		push word 209
		push word 203
		push word 187
		call draw
		add sp,10

		mov bx,9
row_print:		
		mov cx,3
sq_print:		
		mov byte [es:di],186		
		add di,8
		mov byte [es:di],179
		add di,8
		mov byte [es:di],179
		add di,8
		mov byte [es:di],186	
		loop sq_print		
		
		add di,[new_line_count]
		add di,2
		
		dec bx
		cmp bx,0
		jz prints_exit
		
		push word 199
		cmp bx,6
		jz thick_line
		cmp bx,3
		jz thick_line
		push word 196
		push word 197
		push word 186
		push word 182
				
		jmp draw_mid
thick_line:
		push word 205
		push word 216
		push word 206
		push word 182
		
draw_mid:	
		call draw
		add sp,10		
		
		jmp row_print
	
prints_exit:		
		
		push word 200
		push word 205
		push word 207
		push word 202
		push word 188
		call draw
		add sp,10

pend:		
		pop ax		
		pop cx
		pop dx
		pop bp
        ret 

;----------------------------------------------------------
; Procedure void print_cell(int cell_index, int color)
;    Prints the sudoku board on screen, by writing in video memory
;    Starts printing from offset 'line'
;    Arguments:
;       the start of the board is passed from the stack
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Uses:
;       es, esi, edi, eax, bp, ecx, edx
;----------------------------------------------------------		

print_cell:
		push bp        
        mov  bp, sp
		push di
		push ax
		push bx
		push cx
		push si
        mov ax,[bp + 6] ;Cell index
		mov bx,[bp + 4] ;Color
        mov si, ax  

        mov di,[line]
		
		mov ah,0
		mov dl,9
		div dl ;This is the line of the current cell
		push ax
		mov ah,0
		inc al
		add al,al
		dec al
		mov dl,160
		mul dl		
		add di,ax
		add di,2
		pop ax
		mov al,ah
		mov ah,0
		mov dl,8
		mul dl
		add di,ax
		
		mov al,[board+si]
		cmp al,0
		jz pc_skip
		add al,0x30
		mov [es:di],al
		inc di
		mov byte [es:di],bl

pc_skip:		
		pop si
		pop cx
		pop bx
		pop ax
		pop di
		pop bp
		ret

;----------------------------------------------------------
; Procedure void print_board()
;    Prints the whole board contents on the screen in white color.
;    Ignores zeros.
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Destroys:
;       none
;----------------------------------------------------------
		
print_board:
		push di
		push si
		
		mov word [cell_color],7
		
		mov di,[line]
		mov si,0
		
pb_loop:		
		push si
		push word [cell_color]
		call print_cell
		add sp,4
		inc si
		cmp si,81
		jnz pb_loop
		
		pop si
		pop di
		ret

;----------------------------------------------------------
; Procedure void red_to_green()
;    Sweeps the area of the VGA memory where the board is printed
;	  and turns every red(4) character to green(2)
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Destroys:
;       none
;----------------------------------------------------------
		
red_to_green:
		push di
		push si
		
		mov di,[line]
		dec di
		mov si,0
rtb_loop:		
		cmp byte [es:di],4
		jnz rtb_next
		mov byte [es:di],2
rtb_next:
		add di,2
		inc si
		cmp si,1480 ;The character count of the board on the screen
		jnz rtb_loop
		
		pop si
		pop di
		ret

;----------------------------------------------------------
; Procedure void green_to_brown()
;    Sweeps the area of the VGA memory where the board is printed
;	  and turns every green(2) or red(4) character to brown(6)
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Destroys:
;       none
;----------------------------------------------------------
		
green_to_brown:
		push di
		push si
		
		mov di,[line]
		dec di
		mov si,0
gto_loop:		
		cmp byte [es:di],4
		jnz gto_next
		mov byte [es:di],6
		
gto_next:
        cmp byte [es:di],2
		jnz gto_end
		mov byte [es:di],6
gto_end:
		add di,2
		inc si
		cmp si,1480 ;The character count of the board on the screen
		jnz gto_loop
		
		pop si
		pop di
		ret	

;----------------------------------------------------------
; Procedure void cls_brute()
;    Sweeps the area of the VGA memory where the board is printed
;	  and deletes every character that is green (2) or cyan (3)
;	  in order to hide the results of an unsuccessful brute.
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Destroys:
;       none
;----------------------------------------------------------
		
cls_brute:
		push di
		push si
		
		mov di,[line]
		dec di
		mov si,0
clsb_loop:		
		cmp byte [es:di],2
		jnz clsb_next
		mov byte [es:di],0
clsb_next:
        cmp byte [es:di],3
	    jnz clsb_end
		mov byte [es:di],0

		
clsb_end:		
		add di,2
		inc si
		cmp si,1480
		jnz clsb_loop
		
		pop si
		pop di
		ret

;----------------------------------------------------------
; Procedure void draw(char startChar, char middleChar, char delimeterChar, char thickChar, char endChar)
;    Draws a line screen, by writing in video memory and using the ascii characters that are passed from the stack
;    Starts printing from offset 'line'
;    Arguments:
;       the characters that make the line is passed from the stack
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Uses:
;       es, esi, edi, eax, bp, ecx, edx
;----------------------------------------------------------		
draw:
		push bp   
        mov  bp, sp
		push ax
		push cx
		push dx		

		mov byte al,[bp+12]  
		mov [es:di],al
		add di,2
		
		mov dx,9
		mov cl,2
ln_loop:		
		
		mov byte al,[bp+10]  
		mov byte [es:di],al
		add di,2	
		mov byte [es:di],al
		add di,2
		mov byte [es:di],al
		add di,2		
		cmp cl,0
		jz deli
		mov byte al,[bp+8]  
		dec cl
		jmp print_char
deli:	
		mov byte al,[bp+6]  
		mov cl,2
print_char:
		mov byte [es:di],al
		add di,2
		dec dx
		jnz ln_loop
		
		sub di,2
		mov byte al,[bp+4]  
		mov byte [es:di],al
		add di,2
		add di,[new_line_count]		
		
		pop dx
		pop cx
		pop ax
		pop bp
		ret		
				
;----------------------------------------------------------
; Procedure void prinstr(char *message)
;    Prints a string buffer (message) on screen, by writing in video memory
;    Starts printing from offset 'line'
;    Arguments:
;       a string variable from the data segment is passed from the stack
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Uses:
;           es, esi, edi, eax
;----------------------------------------------------------
printstr:

        push bp             ; save bp           
        mov  bp, sp
        mov  ax, [bp + 6]   ; take the variable 
        mov  si, ax         ; initialize si
		
		mov di,[bp+4]        

printstr_loop:
        cmp byte [si],eom
        je printstr_exit
        movsb
        inc di
        jmp printstr_loop

printstr_exit:
        pop  bp             ; restore bp
        ret                 

;----------------------------------------------------------
; Procedure char *hex2ASCII(int value, char *str)
;    Converts a hex value to a ascii string.
;    Gets one by one the decimal digits of the value,
;    converts them to ascii characters 
;    and writes them in a string buffer (str)
;    Because we evaluate digits starting from the least significant
;    we start writing characters at the string buffer's end, 
;    and we move towards its start.
;    Arguments:
;       int value: the value to be converted
;       char *str: the address where the string buffer ends
;    Local Variables:
;       none
;    Returns:
;       the string's start address
;    Uses:
;       eax. Everything else is saved and restored.
;----------------------------------------------------------
hex2ASCII:
        push bp             ; Save old Frame Pointer
        mov bp, sp          ; Create new Frame
                    
                            ; Save Register State
        push ebx            ; BX will be our divisor
        push edx            ; DX will keep our remainder
        push edi            ; DI will point to where we write our character
        
        mov eax,[bp + 6]    ; AX will keep the dividend. Initialized to the hex value
        mov di,[bp + 4]     ; Pointer in string initialized to string's end
        mov ebx,10          ; Divisor initialized to 10

hex2ASCII_loop:
        cmp eax, 0          ; while (dividend != 0){
        jz hex2ASCII_exit

        mov edx,0           ; Clear dx -> edx:eax == eax   
        div ebx             ; Quotient in ax, remainder in dx
                            ; Remainder is the decimal digit
                            ; Quotient will be the next dividend
        
        add dl,0x30         ; Decimal digit + 0x30 = Digit ASCII char
        dec di              ; Point to previous byte in string
        mov [ds:di],dl      ; Write char in string
        jmp hex2ASCII_loop  ; }
hex2ASCII_exit:
        mov ax,di           ; Put return value in eax

        pop edi             ; Restore State and stack frame
        pop edx
        pop ebx

        pop bp
        ret	
		
%endif

