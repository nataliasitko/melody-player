program           segment
assume  cs:program, ds:data, ss:stack

start:          mov     ax,data
mov     ds,ax
mov     ax,stack
mov     ss,ax
mov     sp,offset top

;///////////////////////////////////////////////////////////////

menu:
    call reset_registers
    mov dx,offset new_line
    call print
    mov dx,offset next_task
    call print
    mov dx,offset instructions
    call print
    mov dx,offset new_line
    call print
    mov dx,offset max_number
    call enter_string
    ;call znacznik
    mov dx,offset new_line
    call print
    
    mov al,number[0]
    sbb al,30h
    
    cmp al,1
    jz play_melody
    
    cmp al,2
    jz file_handling
    
    cmp al,3
    jz end
    
    mov dx,offset incorrect_command
    call print
    jmp menu

print:
    mov ah,09h
    int 21h
    ret

print_char:
    mov ah,0eh
    int 10h
    ret  
    
print_note:
    cmp ax,0
    jnz note
    jz space
    ret
    note:
    mov al,0eh
    mov bl,2ah
    mov ah,0eh
    int 10h
    ret 
    space:
    mov al,0
    mov ah,0eh
    int 10h
    ret
    

enter_string:
    mov ah,0ah
    int 21h
    ret

reset_registers:
    xor ax,ax
    xor bx,bx
    xor dx,dx
    xor cx,cx
    ret

play_melody:
    call reset_registers

play:
    mov al,182
    out 43h,al
    mov ax,[note_arr+bx]

    out 42h,al
    mov al,ah
    out 42h,al
    in al,61h

    or al,00000011b
    out 61h,al

    mov ax,[pause_arr+bx]
    mov bx,25

    pause1:
    mov cx,ax
    pause2:
    dec cx
    jne pause2
    dec bx
    jne pause1
    in al,61h

    and al,11111100b
    out 61h,al
    add dx,2
    mov bx,dx

    add dx,2
    mov ax,[pause_arr+bx]
    add ax,0
    jnz play

    jmp menu

play_from_file:

    play2:
        call sum
        push ax
        call print_note
        call sum
        mov dx,ax
        pop ax
        mov bx,ax
        push bx
        cmp ax,0
        jz stop
        
        xor ah,ah
        
        mov al,182
        out 43h,al
        mov ax,bx

        out 42h,al
        mov al,ah
        out 42h,al
        
        in al,61h
        or al,00000011b
        out 61h,al
        
        stop:
        mov ax,dx
        mov bx,25

        pause12:
        mov cx,ax
        pause22:
        dec cx
        jne pause22
        dec bx
        jne pause12
        
        in al,61h
        and al,11111100b
        out 61h,al
        cmp si,sound_size
        jb play2

        add dx,2
        mov bx,dx

        add dx,2
        mov ax,[stop+bx]
        add ax,0
        jnz play2
        ret

    sum:
        xor ax,ax
        xor ch,ch
        xor bh,bh
        mov cl,4 
        next:
            mov dx,10
            mul dx
            jc overflow
            mov bl,sound_data[si]
            inc si
            cmp bl,0dh
            jz sum
            cmp bl,0ah
            jz sum
            cmp bl,'$'
            jz menu
            sub bl,'0'
            add ax,bx
            jc overflow
            ;mov sum,ax
            loop next
            ret

overflow:
        mov dx,offset overflow_error
        call print
        ret

file_handling:
    mov dx,offset filename_request
    call print
    mov dx,offset max_filename
    call enter_string
    call insert_0
    mov dx,offset new_line
    call print
    call open_file
    call read_from_file
    mov dx,offset new_line
    call print
    call play2
    call clear_arr
    jmp menu

open_file:
    clc
    mov ah,3dh
    mov al,0 ;tryby funkcji: 0-otworz,1-pisz,2-to i to
    mov dx, offset filename
    int 21h
    mov handle,ax ;funkcja zapisuje uchwyt do pliku w ax
    jc open_file_error
    ret

open_file_error:
    mov dx,offset open_file_error_message
    call print
    jmp menu

read_from_file:
    mov ah,3fh
    mov cx,sound_size ;liczba bajtow do przeczytania
    mov bx,ds:[handle]
    mov dx,offset sound_data
    mov bx,handle ;numer dojscia
    int 21h  ;przerwanie sluzy do wywolywania funkcji systemowych
    ret
    
insert_0:
    pusha
    xor ax,ax
    mov al,len_filename
    mov si,ax
    ;sub si,1
    mov filename[si],0
    xor si,si
    popa
    ret
    
clear_arr:
    mov cx,si
    czysc:
    xor si,si
    mov filename[si],0
    inc si
    loop czysc
    ret
    
    

;//////////////////////////////////////////////////////////////// 

end:
    mov     ah,4ch
    mov        al,0
    int        21h

program           ends


data              segment

    overflow_error db 'blad przepelnienia $'
    char_error db 'niepoprawny zapis w pliku $'

    sum_value dw 0

    sound_size dw 10000

    ;sound_data db 0,32,64,128,192,255 ;8-bit sound (0-255)

    sound_index dw 0

    ;filename db 'mario.txt',0

    handle dw 0

    sound_data db 10000 dup(?)

    new_line db 0dh,0ah,'$'

    next_task db 'co robimy?',0dh,0ah,'$'

    instructions db '1) odtworz przykladowa melodie z programu',0dh,0ah
    db '2) odtworz melodie z pliku',0dh,0ah,
    db '3) koniec',0dh,0ah,'$'

    filename_request db 'podaj nazwe pliku:',0dh,0ah,'$'

    open_file_error_message db 'blad otwarcia pliku',0dh,0ah,'$'

    incorrect_command db 'nie ma takiej opcji!',0dh,0ah,'$'

    max_number db 2
    len_number db ?
    number db 2 dup(0)

    max_filename db 20
    len_filename db ?
    filename db 20 dup(?)

    note_arr dw 6560,3000,1000,5764,4324,6655,43,7868,5433,3423
    pause_arr dw 6000,5747,3457,7856,4324,7867,2667,2967,5645,7868

data            ends

stack          segment
    dw    100h dup(0)
    top          Label word
stack          ends

end start
