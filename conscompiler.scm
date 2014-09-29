;; csi conscompiler.scm > test1.asm
;; nasm -g -felf64 test1.asm && ld test1.o -o test1

(define *log* '())
(define (push! v) (set! *log* (cons v *log* )))

(define (tag! r n)
  (push! `(shl ,r 3))
  (push! `(or ,r ,n)))


(define (defunc x)
  (cond
   ((pair? x) (begin
                (defunc (cdr x))
                (defunc (car x))
                (push! `(mov rax rsp))
                (tag! 'rax 1)
                (push! `(push rax))))
   ((number? x) (begin
                  (push! `(push ,x))
                  (push! `(mov rax rsp))
                  (tag! 'rax 2)
                  (push! `(push rax))))
   (else (error "bad input"))))


(define (print-indent)
  (display "        "))

(define (print-asm x)
  (let ((h (car x)))
    (cond ((equal? 'label h) (print-label x))
          (else  (print-instr x)))))

(define (print-label x)
  (newline)
  (display (cadr x))
  (display ":")
  (newline))

(define (print-instr x)
  (let ((l (length x)))
    (cond
     ((= l 3) (begin
                (print-indent)
                (display (car x))
                (display " ")
                (display (cadr x))
                (display ", ")
                (display (caddr x))
                (newline)))
     ((= l 2) (begin
                (print-indent)
                (display (car x))
                (display " ")
                (display (cadr x))
                (newline)))
     ((= l 1) (begin
                (print-indent)
                (display (car x))
                (newline))))))



;;;;;;;;;;;;;;;;;;;;;

(define (jmp= n k)
  (push! `(cmp rax ,n))
  (push! `(je ,k)))

(define (get-tag! r)
  (push! `(and ,r 7)))

(define (get-data! r)
  (push! `(shr ,r 3)))

(define (print-string! s n)
  (push! `(push ,n))
  (push! `(push ,s))
  (push! `(jmp pop_print)))


(define (pop-print)
  (for-each push!
  (list
   `(label pop_print)
   `(pop rsi)        ; load str ptr
   `(pop rdx)        ; load str length
   `(mov rdi 1)      ; fd to write to
   `(mov rax 1)      ; load write syscall
   `(syscall)
   `(jmp run))))

(define (print-obj)
  (push! `(label print_obj))
  (push! `(mov rax "[r10]"))    ; load pointer stored in r10 into rax
  (push! `(mov rbx rax))        ; make backup coqpy of pointer
  (get-tag! 'rax)                ; get pointer tag to compare against
  (push! `(lea r10 "[r10-64]")) ; increment the traversal pointer r10
  (jmp= 0 'end)
  (jmp= 1 'print_cons)
  (jmp= 2 'print_number))

(define (print-cons)
  (push! `(label print_cons))
  (print-string! 'rparen 1)
  (push! `(push print_obj))
  (print-string! 'dot 3)
  (push! `(push print_obj))
  (print-string! 'lparen 1)
  (push! `(jmp run)))

;; rbx holds pointer
(define (print-number)
  (push! `(label print_number))
  (get-data! 'rbx)                ; shift of tag to get pointer
  (push! '(mov rax "[rbx]"))      ; load data at pointer
  (push! `(add rax digits))       ; calculate offset from 'digits'
  (print-string! 'rax 1)
  (push! `(jmp run)))
  

(define (run)
  (push! `(label run))
  (push! `(pop rax))
  (push! `(jmp rax)))

(define (end)
  (push! `(label end))
  (push! `(xor rdi rdi))
  (push! `(mov rax 60))
  (push! `(syscall)))


(define prelude "
section .data
digits: db  \"0123456789\",10
lparen: db \"(\",10
rparen: db \")\",10
dot: db \" . \",10

section .text
global _start

")

(end)
(run)
(pop-print)
(print-obj)
(print-cons)
(print-number)
(push! `(label _start))
(push! '(push 0))
(defunc (cons 1 (cons 2 3)))
(push! `(mov r10 rsp)) ;; init stack traversal pointer
(push! `(push print_obj)) ;; set first instruction to run
(push! `(jmp run)) ;; start program

(display prelude)
(for-each print-asm (reverse  *log*))


(quit)
