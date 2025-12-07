%include "etapes/common.asm"

global fillTriangle
extern determinant

section .text

fillTriangle:
    push rbp
    mov rbp, rsp
    
    ; Sauvegarde des registres callee-saved
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    sub rsp, 96                     ; Variables locales
    
    ; Sauvegarde des paramètres
    mov [rbp-8], rdi                ; display
    mov [rbp-16], rsi               ; window
    mov [rbp-24], rdx               ; gc
    
    ; Récupère les coordonnées du triangle ABC
    mov r12d, dword[rbp+16]         ; xA
    mov r13d, dword[rbp+24]         ; yA
    mov r14d, dword[rbp+32]         ; xB
    mov r15d, dword[rbp+40]         ; yB
    mov eax, dword[rbp+48]          ; xC
    mov [rbp-28], eax
    mov eax, dword[rbp+56]          ; yC
    mov [rbp-32], eax
    
    ; ÉTAPE 1 : Déterminer si le triangle est direct ou indirect
    ; Calcul du déterminant des vecteurs BA et BC
    
    ; Calcule le vecteur BA
    mov eax, r12d                   ; xA
    sub eax, r14d                   ; xA - xB = xBA
    mov edi, eax
    
    mov eax, r13d                   ; yA
    sub eax, r15d                   ; yA - yB = yBA
    mov esi, eax
    
    ; Calcule le vecteur BC
    mov eax, dword[rbp-28]          ; xC
    sub eax, r14d                   ; xC - xB = xBC
    mov edx, eax
    
    mov eax, dword[rbp-32]          ; yC
    sub eax, r15d                   ; yC - yB = yBC
    mov ecx, eax
    
    ; Aligne la pile avant l'appel
    push r12
    push r13
    push r14
    push r15
    
    call determinant
    
    pop r15
    pop r14
    pop r13
    pop r12
    
    mov [rbp-36], eax               ; Sauvegarde det_triangle
    
    ; Si déterminant = 0, triangle dégénéré
    cmp eax, 0
    je .fin
    
    ; Détermine le type de triangle
    xor ebx, ebx
    cmp eax, 0
    jl .triangle_direct
    mov ebx, 1
.triangle_direct:
    mov [rbp-40], ebx               ; 0 = direct, 1 = indirect
    
    ; ÉTAPE 2 : Trouver le rectangle englobant
    
    ; min_x = min(xA, xB, xC)
    mov eax, r12d
    cmp eax, r14d
    jle .check_xC_min
    mov eax, r14d
.check_xC_min:
    cmp eax, dword[rbp-28]
    jle .got_min_x
    mov eax, dword[rbp-28]
.got_min_x:
    mov [rbp-44], eax               ; min_x
    
    ; max_x = max(xA, xB, xC)
    mov eax, r12d
    cmp eax, r14d
    jge .check_xC_max
    mov eax, r14d
.check_xC_max:
    cmp eax, dword[rbp-28]
    jge .got_max_x
    mov eax, dword[rbp-28]
.got_max_x:
    mov [rbp-48], eax               ; max_x
    
    ; min_y = min(yA, yB, yC)
    mov eax, r13d
    cmp eax, r15d
    jle .check_yC_min
    mov eax, r15d
.check_yC_min:
    cmp eax, dword[rbp-32]
    jle .got_min_y
    mov eax, dword[rbp-32]
.got_min_y:
    mov [rbp-52], eax               ; min_y
    
    ; max_y = max(yA, yB, yC)
    mov eax, r13d
    cmp eax, r15d
    jge .check_yC_max
    mov eax, r15d
.check_yC_max:
    cmp eax, dword[rbp-32]
    jge .got_max_y
    mov eax, dword[rbp-32]
.got_max_y:
    mov [rbp-56], eax               ; max_y
    
    ; ÉTAPE 3 : Parcourir tous les points du rectangle
    
    mov r8d, dword[rbp-52]          ; y = min_y
    
.loop_y:
    cmp r8d, dword[rbp-56]          ; y <= max_y ?
    jg .fin
    
    mov r9d, dword[rbp-44]          ; x = min_x
    
.loop_x:
    cmp r9d, dword[rbp-48]          ; x <= max_x ?
    jg .next_y
    
    ; --- Calcul 1 : det(AB, AP) ---
    mov edi, r14d
    sub edi, r12d                   ; xAB
    
    mov esi, r15d
    sub esi, r13d                   ; yAB
    
    mov edx, r9d
    sub edx, r12d                   ; xAP
    
    mov ecx, r8d
    sub ecx, r13d                   ; yAP
    
    ; Sauvegarde des registres avant appel
    push r8
    push r9
    push r12
    push r13
    push r14
    push r15
    
    call determinant
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop r9
    pop r8
    
    mov [rbp-60], eax               ; det1
    
    ; --- Calcul 2 : det(BC, BP) ---
    mov edi, dword[rbp-28]
    sub edi, r14d                   ; xBC
    
    mov esi, dword[rbp-32]
    sub esi, r15d                   ; yBC
    
    mov edx, r9d
    sub edx, r14d                   ; xBP
    
    mov ecx, r8d
    sub ecx, r15d                   ; yBP
    
    push r8
    push r9
    push r12
    push r13
    push r14
    push r15
    
    call determinant
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop r9
    pop r8
    
    mov [rbp-64], eax               ; det2
    
    ; --- Calcul 3 : det(CA, CP) ---
    mov edi, r12d
    sub edi, dword[rbp-28]          ; xCA
    
    mov esi, r13d
    sub esi, dword[rbp-32]          ; yCA
    
    mov edx, r9d
    sub edx, dword[rbp-28]          ; xCP
    
    mov ecx, r8d
    sub ecx, dword[rbp-32]          ; yCP
    
    push r8
    push r9
    push r12
    push r13
    push r14
    push r15
    
    call determinant
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop r9
    pop r8
    
    mov [rbp-68], eax               ; det3
    
    ; Test d'appartenance
    cmp dword[rbp-40], 0
    je .test_direct
    
.test_indirect:
    cmp dword[rbp-60], 0
    jge .next_x
    cmp dword[rbp-64], 0
    jge .next_x
    cmp dword[rbp-68], 0
    jge .next_x
    jmp .draw_point
    
.test_direct:
    cmp dword[rbp-60], 0
    jle .next_x
    cmp dword[rbp-64], 0
    jle .next_x
    cmp dword[rbp-68], 0
    jle .next_x
    
.draw_point:
    mov rdi, qword[rbp-8]           ; display
    mov rsi, qword[rbp-16]          ; window
    mov rdx, qword[rbp-24]          ; gc
    mov ecx, r9d                    ; x
    mov r8d, r8d                    ; y
    
    push r8
    push r9
    push r12
    push r13
    push r14
    push r15
    
    call XDrawPoint
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop r9
    pop r8
    
.next_x:
    inc r9d
    jmp .loop_x
    
.next_y:
    inc r8d
    jmp .loop_y
    
.fin:
    add rsp, 96
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret