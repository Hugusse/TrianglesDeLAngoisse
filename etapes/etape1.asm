%include "etapes/common.asm"

extern random_number
extern drawLines

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32             ; Réserve de l'espace sur la pile pour l'alignement
    
    ; Génère 3 coordonnées aléatoires pour les points du triangle
    
    ; Point 1 (x1, y1)
    mov edi, LARGEUR
    call random_number
    mov r12d, eax           ; r12d = x1
    
    mov edi, HAUTEUR
    call random_number
    mov r13d, eax           ; r13d = y1
    
    ; Point 2 (x2, y2)
    mov edi, LARGEUR
    call random_number
    mov r14d, eax           ; r14d = x2
    
    mov edi, HAUTEUR
    call random_number
    mov r15d, eax           ; r15d = y2
    
    ; Point 3 (x3, y3)
    mov edi, LARGEUR
    call random_number
    mov r8d, eax            ; r8d = x3
    
    mov edi, HAUTEUR
    call random_number
    mov r9d, eax            ; r9d = y3
    
    ; Appelle drawLines avec les 6 paramètres:
    ; rdi=x1, rsi=y1, rdx=x2, rcx=y2, r8=x3, r9=y3
    mov edi, r12d           ; x1
    mov esi, r13d           ; y1
    mov edx, r14d           ; x2
    mov ecx, r15d           ; y2
    ; r8d et r9d sont déjà définis pour x3 et y3
    call drawLines
    
    mov rsp, rbp
    pop rbp
    xor rax, rax            ; return 0
    ret
