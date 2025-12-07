%include "etapes/common.asm"
global main
extern draw_one_triangle

%define NBTRI 5

section .bss
display_name:   resq    1
window_ptr:     resq    1
gc_ptr:         resq    1
screen:         resd    1
event:          resq    24      ; Réserve sans initialiser

section .data
colors:     dd  0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFF00FF
        dd  0x00FFFF, 0xFFA500, 0x800080, 0xFFC0CB, 0x808080

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
    ; Dessine NBTRI triangles
    xor r12, r12

.loop_triangles:
    cmp r12, NBTRI
    jge .fin_dessin
    
    ; Calcul de l'index de couleur (modulo 10)
    mov rax, r12
    xor rdx, rdx
    mov rcx, 10
    div rcx                         ; rdx = r12 % 10
    
    ; Sauvegarde l'index de couleur dans r13
    mov r13, rdx
    
    ; Prépare les arguments
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    mov rdx, qword[gc_ptr]          ; gc
    
    ; Récupère la couleur
    lea rax, [colors]
    mov ecx, dword[rax + r13*4]     ; ecx = couleur (utilise r13, pas rdx!)
    
    ; Appel de la fonction
    call draw_one_triangle
    
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