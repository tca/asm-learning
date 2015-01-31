;;; build a list in memory and print it out

;;; nasm -g -felf64 brkons.asm && ld brkons.o -o brkons && ./brkons
section .data

end: dq 0
        
digits: db  "0123456789",10
nil_str: db "()",10
lparen: db "(",10
rparen: db ")",10
dot: db " . ",10

nil_tag: equ 0
int_tag: equ 1
cons_tag: equ 2



section .text
    global _start

exit:
        xor     rdi,rdi
        mov     rax,60
        syscall
        
alloc:
        pop rax                 ; get amount to alloc
        push qword [end]
        add qword [end], rax
        mov rdi, [end]
        mov rax, 12
        syscall
        pop rax                 ; get ptr
        pop rdx                 ; get cont
        push rax
        jmp rdx
        
alloc_nil:
        pop rdx
        push 0
        jmp rdx
        
alloc_int:
        ;; allocate memory to hold int
        push alloc_int1
        push 16
        jmp alloc
alloc_int1:
        pop rax                         ; memory start
        pop rdx                         ; get continuation
        pop rbx                         ; get integer
        
        push rax                        ; push return value
        mov qword [rax], int_tag        ; set tag
        mov qword [rax+8], rbx          ; int size
        jmp rdx
        
alloc_cons:
;;;  build a cons on heap, return pointer to it
;;; tag = 8byte
;;; car = 8byte (pointer)
;;; cdr = 8byte (pointer)
        push qword [end]
        add qword [end], 24
        mov rdi, [end]
        mov rax, 12
        syscall
        pop rax                 ; memory start
        pop rdx                 ; get continuation
        pop rcx                 ; get cdr ptr
        pop rbx                 ; get car ptr
        push rax                ; push return value
        
        mov qword [rax], cons_tag     ; set tag
        mov [rax+8], rbx                ; set car
        mov [rax+16], rcx                ; set cdr
        jmp rdx

print_tree:
;;; takes cont and ptr
;;; descriminates on type of object ptr points to
;;; calls specialized printer for that object
        pop rdx                 ; get continuation
        pop rax                 ; get tree ptr
        push rdx                ; save continuation

        ;; nil
        test rax,rax
        jz print_nil
        push rax                ; save tree ptr
        mov rax, qword [rax]    ; mov tag to rax
        ;; int
        cmp rax, int_tag
        je print_int
        ;; cons
        cmp rax, cons_tag
        je print_cons

print_nil:
        mov rsi, nil_str        ; load char ptr
        mov rdx, 2              ; set length
        mov rdi, 1              ; fd
        mov rax, 1              ; write syscall
        syscall
        
        pop rdx
        jmp rdx

print_int:
        pop rbx                 ; get integer pointer
        pop rdx                 ; get cont
        
        mov rax, [rbx+8]        ; get integer value
        add rax, digits         ; get digit offset
        push rdx                ; save cont
        mov rsi, rax            ; load char ptr
        mov rdx, 1              ; set length
        mov rdi, 1              ; fd
        mov rax, 1              ; write syscall
        syscall
   
        pop rdx
        jmp rdx
        
print_cons:
;;;  recursively call print_tree on the car and cdr
        mov rsi, lparen         ; load char ptr
        mov rdx, 1              ; set length
        mov rdi, 1              ; fd
        mov rax, 1              ; write syscall
        syscall
        
        pop rax                    ; get cons
        push qword [rax+16]        ; push cdr
        push qword [rax+8]         ; push car
        push print_cons1           ; push cont
        jmp print_tree             ; cont, val
print_cons1:
        mov rsi, dot            ; load char ptr
        mov rdx, 3              ; set length
        mov rdi, 1              ; fd
        mov rax, 1              ; write syscall
        syscall

        push print_cons2        ; push cont
        jmp print_tree          ; cont, val
print_cons2:
        mov rsi, rparen         ; load char ptr
        mov rdx, 1              ; set length
        mov rdi, 1              ; fd
        mov rax, 1              ; write syscall
        syscall
        
        pop rdx                 ; get cont
        jmp rdx
        
_start:
        ;; get brk end addr
        mov rax,12    ;; brk
        xor rdi,rdi   ;; 0 (get end in rax)
        syscall
        mov qword [end], rax

start0:
        ;; 1
        push 1
        push start1
        jmp alloc_int
start1:
        ;; 1 | 2
        push 2
        push start2
        jmp alloc_int
start2:
        ;; 1 | 2 | ()
        push start3
        jmp alloc_nil
start3:
        ;; 1 | (2 . ())
        push start4
        jmp alloc_cons

start4:
        ;; (1 . (2 . ()))
        push start5
        jmp alloc_cons
start5:
        push start6
        jmp print_tree
start6: 
        jmp exit

 
