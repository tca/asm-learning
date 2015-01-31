
section .data
digits: db  "0123456789",10
lparen: db "(",10
rparen: db ")",10
dot: db " . ",10

section .bss
        heap resb    72

section .text
global _start


end:
        xor rdi, rdi
        mov rax, 60
        syscall

print_string:
        mov rdi, 1
        mov rax, 1
        syscall
        ret

print_obj:
        mov rax, r10
        mov rbx, rax
        shr rbx, 4
        mov r10, rbx
        and rax, 0b1111
        cmp rax, 0
        je end
        cmp rax, 1
        je print_cons
        cmp rax, 2
        je print_number

print_cons:
        mov rdx, 1
        mov rsi, lparen
        call print_string
        mov r11, r10
        mov r10, r11
        call print_obj
        mov rdx, 3
        mov rsi, dot
        call print_string
        mov r10, qword [r11+8]
        call print_obj
        mov rdx, 1
        mov rsi, rparen
        call print_string
        ret

print_number:
        add rbx, digits
        mov rdx, 1
        mov rsi, rbx
        call print_string
        ret

_start:
        mov qword [heap+24], 7
        mov qword [heap+48], 8
        mov qword [heap+56], 9
        mov rax, 48
        add rax, heap
        shl rax, 4
        or rax, 0b0010
        mov rbx, 32
        add rbx, heap
        mov qword [rbx], rax
        mov rax, 56
        add rax, heap
        shl rax, 4
        or rax, 0b0010
        mov qword [heap+40], rax
        mov rax, 24
        add rax, heap
        shl rax, 4
        or rax, 0b0010
        mov rbx, 8
        add rbx, heap
        mov qword [rbx], rax
        mov rax, 32
        add rax, heap
        shl rax, 4
        or rax, 0b0001
        mov qword [heap+16], rax
        lea rax, [heap+8]
        shl rax, 4
        or rax, 0b0001
        mov qword [heap+0], rax
        mov r10, rax
        call print_obj
        jmp end
