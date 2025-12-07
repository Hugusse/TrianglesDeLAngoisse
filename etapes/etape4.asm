%include "etapes/common.asm"
global main
extern draw_one_triangle
extern random_number

%define NBTRI 5

section .bss
display_name:   resq    1
window_ptr:     resq    1
gc_ptr:         resq    1
screen:         resd    1
event:          resq    24

section .text
main:
    push rbp
    mov rbp, rsp
    
    ; Ouvre le display
    xor rdi, rdi
    call XDisplayName
    test rax, rax
    jz closeDisplay
    xor rdi, rdi
    call XOpenDisplay
    test rax, rax
    jz closeDisplay
    mov [display_name], rax
    
    ; Récupère root window
    mov rdi, qword[display_name]
    mov esi, dword[screen]
    call XRootWindow
    mov rbx, rax
    
    ; Crée la fenêtre
    mov rdi, qword[display_name]
    mov rsi, rbx
    mov rdx, 10
    mov rcx, 10
    mov r8, LARGEUR
    mov r9, HAUTEUR
    push 0x000000
    push 0x00FF00
    push 1
    call XCreateSimpleWindow
    add rsp, 24
    mov qword[window_ptr], rax
    
    ; Sélection événements
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    mov rdx, 131077
    call XSelectInput
    
    ; Map window
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    call XMapWindow
    
    ; Crée GC
    mov rdi, qword[display_name]
    test rdi, rdi
    jz closeDisplay
    mov rsi, qword[window_ptr]
    test rsi, rsi
    jz closeDisplay
    xor rdx, rdx
    xor rcx, rcx
    call XCreateGC
    test rax, rax
    jz closeDisplay
    mov qword[gc_ptr], rax

boucle:
    mov rdi, qword[display_name]
    test rdi, rdi
    je closeDisplay
    mov rsi, event
    call XNextEvent
    
    cmp dword[event], ConfigureNotify
    je dessin
    cmp dword[event], Expose
    je dessin
    cmp dword[event], KeyPress
    je closeDisplay
    jmp boucle

dessin:
    ; Dessine NBTRI triangles avec des couleurs aléatoires
    xor r12, r12

.loop_triangles:
    cmp r12, NBTRI
    jge .fin_dessin
    
    ; === Génération d'une couleur aléatoire (format 0xRRGGBB) ===
    
    ; Génère la composante ROUGE (0-255)
    mov edi, 256
    push r12
    call random_number
    pop r12
    shl eax, 16                     ; Décale vers les bits 16-23 (rouge)
    mov r13d, eax                   ; Sauvegarde dans r13d
    
    ; Génère la composante VERTE (0-255)
    mov edi, 256
    push r12
    push r13
    call random_number
    pop r13
    pop r12
    shl eax, 8                      ; Décale vers les bits 8-15 (vert)
    or r13d, eax                    ; Combine avec rouge
    
    ; Génère la composante BLEUE (0-255)
    mov edi, 256
    push r12
    push r13
    call random_number
    pop r13
    pop r12
    or r13d, eax                    ; Combine avec rouge et vert
    
    ; r13d contient maintenant la couleur complète 0xRRGGBB
    
    ; Prépare les arguments pour draw_one_triangle
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    mov rdx, qword[gc_ptr]
    mov ecx, r13d                   ; couleur aléatoire
    
    ; Appel de la fonction
    push r12
    push r13
    call draw_one_triangle
    pop r13
    pop r12
    
    inc r12
    jmp .loop_triangles

.fin_dessin:
    ; Force l'affichage
    mov rdi, qword[display_name]
    call XFlush
    
    ; Retourne à la boucle d'événements
    jmp boucle

closeDisplay:
    ; Ferme le display
    mov rdi, qword[display_name]
    test rdi, rdi
    jz .skip_close
    call XCloseDisplay
    
.skip_close:
    ; Quitte proprement
    mov rdi, 0
    call exit