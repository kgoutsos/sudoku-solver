[ORG 0x100]
[BITS 16]

;----------------------------------------------------------
;                       CONSTANTS
;----------------------------------------------------------

;----------------------------------------------------------
;                         BSS
; Description:
;   Here we define our uninitialized variables
;   Most of the time, it is used for the stack
; Contains:
;   real mode stack 256 bytes long, aligned to 4-byte limit
;   (start address of stack can be divided by 4)
;   stack_end       -> pointer to the next memory address after the stack 
;----------------------------------------------------------
[SECTION .bss]
alignb 4

stack:      resb 256
stack_end:

[SECTION .data]
;----------------------------------------------------------
;                         DATA
; Description:
;   Here we define and reserve all of our global variables
;   
;----------------------------------------------------------

file_name:  db 'sudeasy.txt', eom

candidate_flag:db 0
exists_flag: db 0
last_found: db 0
change_flag: db 0
brute_error_flag: db 0
brute_last_cand: db 0
brute_last_cell:db 0
unsolved_flag: db 0
save: db 0
start_time: dw 0
brute_cell_count: db 0
brute_value_count: db 0

;----------------------------------------------------------
;                         TEXT
; Description:
;   The part of the file containing the code
; Functions:
;   start           -> entry point of the program
;   main            -> implements our algorithm
;----------------------------------------------------------

[SECTION .text]
[BITS 16]

jmp start

%include "display.asm"
%include "bworks.asm"
%include "checks.asm"

start:

; Initialize the stack pointer
        mov ax,cs
        mov ss,ax
        mov sp,stack_end
                
; Set DS register to current data segment
        mov ax,cs
        mov ds,ax
        
        call main
    
; Return to DOS
        mov ax,0x4C00
        int 0x21    

;----------------------------------------------------------
; Procedure void main()
;    controls the execution of the user tasks and performs task switching
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;----------------------------------------------------------

main:
		mov ax,vidmem
        mov es,ax

        mov ax, 0
        mov gs, ax	
		
		call cls			
				
		push word 81
		push word board
		push word file_name		
		call load_file
		add sp,6	
		cmp ah,1
		jz file_error
		
		call print_grid
		call print_board
		
		push ax
		push bx
		mov bx, 0x6c
		mov ax,0x40
        mov gs,ax
		mov ax,[gs:bx] ; At 0x40:0x6c is the dos-timer
		mov [start_time],ax ; store the start time
		pop bx
		pop ax
		
		call solution ;Try the analytic method first
		call check_zeros
		call green_to_brown
		cmp ax,1
		jnz all_done
		call save_board
		inc byte [brute_cell_count]
brute_problem:
		add sp,2
		mov byte [brute_error_flag],0
		call restore_board ; save the board before call the brute force
		call brute
		cmp byte [unsolved_flag],1
		jz print_unsolved
		call solution
		call check_zeros		
		cmp ax,1		
		jz brute_problem
		
all_done:	
		add di,22 ; Sudoku solved
		push word solved_message
		push di
		call printstr
		add sp,4
		jmp end_program

print_unsolved:
		add di,22 ;In case that sudoku can not be solved with one level brute force
		push word unsolved_message
		push di
		call printstr
		add sp,4
		jmp end_program
		
file_error:
		mov di,[line] 
		push word error_message
		push di
		call printstr
		add sp,4
		jmp abort
		
end_program:		
		mov eax,0
		mov bx, 0x6c
		mov ax,0x40
        mov gs,ax
		mov ax,[gs:bx]	   ; Mov to ax the dos timer
        cmp ax,[start_time] 
     	jg case1
		
        mov bx,ax      		
		mov ax,0xFFFF
		sub ax,[start_time]	  
        add ax,bx            
		jmp case2			
       
case1:  sub ax,[start_time]        
case2:	mov bl,18;1000/55      ;Number of dos-timer circles store in ax
		div  bl               ; Convert to seconds
		mov ah,0
		
		push eax
		push word time_message_end
		call hex2ASCII
		add sp,6		
		push word time_msg
		add di,116 ;Change line and center
		push di
		call printstr
		add sp,4
		
		cmp byte [brute_cell_count],0
		jz no_brute
		add di,100 ;Change line and center
		push word brute_message_a
		push di
		call printstr
		add sp,4
		mov ax,0
		mov al,[brute_cell_count]
		push ax
		push word brute_vmsg_end
		call hex2ASCII
		add sp,6
		push word brute_vmsg
		push di
		call printstr
		add sp,4
		
		mov ax,0
		mov al,[brute_value_count]
		push ax
		push word brute_cmsg_end
		call hex2ASCII
		add sp,6	
		push word brute_cmsg		
		push di
		call printstr
		add sp,4	
		jmp abort
		
no_brute:
		add di,110 ;Change line and center
		push word brute_no_message
		push di
		call printstr
		add sp,4	
	
abort:
		ret
		
;----------------------------------------------------------
; Procedure void solution()
;    Handles the solution algorithm by calling the appropriate functions for solving
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;----------------------------------------------------------
		
solution:
		mov byte [change_flag],0		
		call software_delay
		call red_to_green
		call solve			
		cmp byte [brute_error_flag],1
		jz sol_ret
		cmp byte [change_flag],0
		jnz solution	
sol_ret:	
		ret
		
;----------------------------------------------------------
; Procedure void brute()
;    Guesses the contents of a cell. The cell in question is the first empty cell after
;	 the brute_last_cell offset
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;----------------------------------------------------------		
		
brute:
		push si
		push cx
		
		call save_board
		inc byte [brute_value_count]
		mov si,[brute_last_cell]; The offeset of the last cell that brute check is store in brute_last_cell flag
br_solve_loop:                  
		cmp byte [board+si],0  ; Search the cells until it finds an empty cell
		jnz br_zero_cell	
		
		cmp byte [brute_last_cand],10 ; For every cell check all the numbers from 1-9
		jz br_exit_loop
		

		mov cl,[brute_last_cand]	
br_check_loop:			
		mov byte [exists_flag],0 ;Check column,line, square like solve
		push cx
		push si
		call check_line
		add sp,4
		cmp byte [exists_flag],1
		jz br_exists
		push cx
		push si
		call check_column
		add sp,4		
		cmp byte [exists_flag],1
		jz br_exists
		push cx
		push si
		call check_square
		add sp,4
		cmp byte [exists_flag],1
		jz br_exists
		
		mov [board+si],cl ;If the current number is acceptable store it in the board and return 
		
		push si
		push byte 3
		call print_cell ;Write the number in the VGA memory
		add sp,4		
		
		mov [brute_last_cand],cl
		inc byte [brute_last_cand]		
		jmp br_exit_solution

br_exists:		
		inc cl
		cmp cl,10
		jl br_check_loop
		
br_exit_loop:
		inc byte [brute_cell_count]	
br_zero_cell:		
		mov byte [brute_last_cand],0
		inc byte [brute_last_cell]	
		inc si		
		cmp si,81        
		jl br_solve_loop  		  ;If soduko have scan all cells without solve the sudoku
		mov byte [unsolved_flag],1 ;set usolved flag
br_exit_solution:		
		pop cx
		pop si		
		
		ret

;----------------------------------------------------------
; Procedure void solve()
;    Sweeps the whole board and fills in the empty cells using the analytical method
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;----------------------------------------------------------
		
solve:
		push si
		push cx		
		mov si,81			
		
solve_loop:		
		dec si
		cmp byte [board+si],0
		jnz near exit_loop
		mov byte [candidate_flag],0
		mov byte [last_found],0
		mov cl,1	
check_loop:		
		mov byte [exists_flag],0
		push cx
		push si
		call check_line      ; check if current number exist in an other cell at the same line
		add sp,4
		cmp byte [exists_flag],1 ; If exists go to the next number else check the column
		jz exists
		push cx
		push si
		call check_column		; check column
		add sp,4		
		cmp byte [exists_flag],1
		jz exists
		push cx
		push si
		call check_square       ; check square
		add sp,4
		cmp byte [exists_flag],1
		jz exists	
check_done:			
		mov byte [candidate_flag],1 ; If the number dos not exist in the line, column and square is a candidate number 
		cmp byte [last_found],0     ;If another number is legal to this cell then there are at least two possible number
		jnz solve_loop              ;and then we must jump to the next cell
		mov byte [last_found],cl			
		
exists:
		cmp cl,9
		jz check_end
		inc cl
		jmp check_loop
		
check_end:	
		cmp byte [candidate_flag],0 ;If candinate_flag equals to zero then the current cell is empty but all the number are illegal... 
		jz brute_error	            ; this can happend due to a wrong forecast of the brute function 
		mov cl,[last_found]			
		cmp cl,0
		jz exit_loop				
		mov [board+si],cl	
		mov byte [change_flag],cl ; At least one cell change
		push si
		push byte 4
		call print_cell
		add sp,4
		
		jmp exit_loop
brute_error:
		mov byte [brute_error_flag],1
		jmp exit_solution
exit_loop:		
		cmp si,0
		jg near solve_loop
exit_solution:		
		pop cx
		pop si
		ret
		
;----------------------------------------------------------
; Procedure void software_delay()
;    Delays by waiting for iterating over an empty loop for 64K times
;    Arguments:
;       none
;    Local Variables:
;       none
;    Returns:
;       nothing
;    Uses:
;           ecx
;----------------------------------------------------------

software_delay:
        push cx
        push dx
   
   
		mov dx, 0x0f15;two dummy  loop
loop_delay:  
        mov cx,0x4000
        loop $
        dec dx
		jne loop_delay
		pop dx
        pop cx
        ret

program_end:
