%include "etapes/common.asm"
global draw_one_triangle
extern fillTriangle
extern random_number

section .text

draw_one_triangle:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Sauvegarde des paramètres dans des registres callee-saved
    mov r12, rdi                    ; display
    mov r13, rsi                    ; window
    mov r14, rdx                    ; gc
    mov r15d, ecx                   ; couleur
    
    ; Change la couleur
    mov rdi, r12                    ; display
    mov rsi, r14                    ; gc
    mov edx, r15d                   ; couleur (32 bits suffisent)
    call XSetForeground
    
    ; Génère les 6 coordonnées et les sauvegarde sur la pile
    sub rsp, 48                     ; 6 coordonnées × 8 octets
    
    ; x1
    mov edi, LARGEUR
    call random_number
    mov [rsp], eax
    
    ; y1
    mov edi, HAUTEUR
    call random_number
    mov [rsp+8], eax
    
    ; x2
    mov edi, LARGEUR
    call random_number
    mov [rsp+16], eax
    
    ; y2
    mov edi, HAUTEUR
    call random_number
    mov [rsp+24], eax
    
    ; x3
    mov edi, LARGEUR
    call random_number
    mov [rsp+32], eax
    
    ; y3
    mov edi, HAUTEUR
    call random_number
    mov [rsp+40], eax
    
    ; Prépare l'appel à fillTriangle
    mov rdi, r12                    ; display
    mov rsi, r13                    ; window
    mov rdx, r14                    ; gc
    
    ; Les coordonnées sont déjà sur la pile dans le bon ordre
    call fillTriangle
    
    ; Nettoie
    add rsp, 48
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret