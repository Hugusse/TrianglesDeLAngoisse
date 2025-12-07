%include "etapes/common.asm"

global draw_one_triangle

extern fillTriangle
extern random_number

section .text

;===============================================================
; Fonction draw_one_triangle
;===============================================================
; Dessine UN triangle avec des coordonnées aléatoires
;===============================================================
; Arguments :
;   rdi = display
;   rsi = window
;   rdx = gc
;   ecx = couleur (format 0xRRGGBB)
;===============================================================

draw_one_triangle:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    ; Sauvegarde des paramètres
    mov [rbp-8], rdi                ; display
    mov [rbp-16], rsi               ; window
    mov [rbp-24], rdx               ; gc
    mov [rbp-28], ecx               ; couleur
    
    ; Change la couleur
    mov rdi, qword[rbp-8]
    mov rsi, qword[rbp-24]
    mov edx, dword[rbp-28]
    call XSetForeground
    
    ; Génère x1
    mov edi, LARGEUR
    call random_number
    mov [rbp-32], eax               ; x1
    
    ; Génère y1
    mov edi, HAUTEUR
    call random_number
    mov [rbp-36], eax               ; y1
    
    ; Génère x2
    mov edi, LARGEUR
    call random_number
    mov [rbp-40], eax               ; x2
    
    ; Génère y2
    mov edi, HAUTEUR
    call random_number
    mov [rbp-44], eax               ; y2
    
    ; Génère x3
    mov edi, LARGEUR
    call random_number
    mov [rbp-48], eax               ; x3
    
    ; Génère y3
    mov edi, HAUTEUR
    call random_number
    mov [rbp-52], eax               ; y3
    
    ; Appelle fillTriangle
    mov rdi, qword[rbp-8]           ; display
    mov rsi, qword[rbp-16]          ; window
    mov rdx, qword[rbp-24]          ; gc
    
    ; Push les coordonnées sur la pile
    push qword[rbp-52]              ; y3
    push qword[rbp-48]              ; x3
    push qword[rbp-44]              ; y2
    push qword[rbp-40]              ; x2
    push qword[rbp-36]              ; y1
    push qword[rbp-32]              ; x1
    
    call fillTriangle
    add rsp, 48
    
    add rsp, 64
    pop rbp
    ret