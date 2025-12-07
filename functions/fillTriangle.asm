%include "etapes/common.asm"

global fillTriangle
extern determinant

section .text

;===============================================================
; Fonction fillTriangle
;===============================================================
; Utilité : Remplit un triangle en utilisant l'algorithme
;           barycentrique avec déterminants (conforme au PDF)
;===============================================================
; Algorithme conforme au PDF du projet :
; 1. Déterminer si le triangle est direct (det < 0) ou indirect (det > 0)
;    en calculant le déterminant des vecteurs BA et BC
; 2. Pour chaque point P du rectangle englobant :
;    - Calculer det(AB, AP), det(BC, BP), det(CA, CP)
;    - Triangle DIRECT (det < 0) : si P à DROITE de tous (tous det > 0) → dessiner
;    - Triangle INDIRECT (det > 0) : si P à GAUCHE de tous (tous det < 0) → dessiner
;===============================================================
; Arguments :
;   Registres: rdi=display, rsi=window, rdx=gc
;   Pile: [rbp+16]=xA, [rbp+24]=yA, [rbp+32]=xB, [rbp+40]=yB, 
;         [rbp+48]=xC, [rbp+56]=yC
;===============================================================

fillTriangle:
    push rbp
    mov rbp, rsp
    sub rsp, 96                     ; Réserve de l'espace pour les variables locales
    
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
    
    ;=================================================================
    ; ÉTAPE 1 : Déterminer si le triangle est direct ou indirect
    ; Calcul du déterminant des vecteurs BA et BC
    ; BA = (xA - xB, yA - yB)
    ; BC = (xC - xB, yC - yB)
    ; det(BA, BC) = (xBA * yBC) - (xBC * yBA)
    ;=================================================================
    
    ; Calcule le vecteur BA
    mov eax, r12d                   ; xA
    sub eax, r14d                   ; xA - xB = xBA
    mov edi, eax                    ; edi = xBA
    
    mov eax, r13d                   ; yA
    sub eax, r15d                   ; yA - yB = yBA
    mov esi, eax                    ; esi = yBA
    
    ; Calcule le vecteur BC
    mov eax, dword[rbp-28]          ; xC
    sub eax, r14d                   ; xC - xB = xBC
    mov edx, eax                    ; edx = xBC
    
    mov eax, dword[rbp-32]          ; yC
    sub eax, r15d                   ; yC - yB = yBC
    mov ecx, eax                    ; ecx = yBC
    
    ; Appel determinant(xBA, yBA, xBC, yBC)
    call determinant
    mov [rbp-36], eax               ; Sauvegarde det_triangle
    
    ; Si déterminant = 0, triangle dégénéré
    cmp eax, 0
    je .fin
    
    ; Détermine le type de triangle et sauvegarde
    ; det < 0 → triangle DIRECT → cherche points à DROITE (det > 0)
    ; det > 0 → triangle INDIRECT → cherche points à GAUCHE (det < 0)
    xor ebx, ebx                    ; ebx = 0 par défaut (triangle direct)
    cmp eax, 0
    jl .triangle_direct
    mov ebx, 1                      ; ebx = 1 (triangle indirect)
.triangle_direct:
    mov [rbp-40], ebx               ; 0 = direct, 1 = indirect
    
    ;=================================================================
    ; ÉTAPE 2 : Trouver le rectangle englobant (bounding box)
    ;=================================================================
    
    ; min_x = min(xA, xB, xC)
    mov eax, r12d                   ; xA
    cmp eax, r14d
    jle .check_xC_min
    mov eax, r14d                   ; xB
.check_xC_min:
    cmp eax, dword[rbp-28]
    jle .got_min_x
    mov eax, dword[rbp-28]          ; xC
.got_min_x:
    mov [rbp-44], eax               ; min_x
    
    ; max_x = max(xA, xB, xC)
    mov eax, r12d                   ; xA
    cmp eax, r14d
    jge .check_xC_max
    mov eax, r14d                   ; xB
.check_xC_max:
    cmp eax, dword[rbp-28]
    jge .got_max_x
    mov eax, dword[rbp-28]          ; xC
.got_max_x:
    mov [rbp-48], eax               ; max_x
    
    ; min_y = min(yA, yB, yC)
    mov eax, r13d                   ; yA
    cmp eax, r15d
    jle .check_yC_min
    mov eax, r15d                   ; yB
.check_yC_min:
    cmp eax, dword[rbp-32]
    jle .got_min_y
    mov eax, dword[rbp-32]          ; yC
.got_min_y:
    mov [rbp-52], eax               ; min_y
    
    ; max_y = max(yA, yB, yC)
    mov eax, r13d                   ; yA
    cmp eax, r15d
    jge .check_yC_max
    mov eax, r15d                   ; yB
.check_yC_max:
    cmp eax, dword[rbp-32]
    jge .got_max_y
    mov eax, dword[rbp-32]          ; yC
.got_max_y:
    mov [rbp-56], eax               ; max_y
    
    ;=================================================================
    ; ÉTAPE 3 : Parcourir tous les points du rectangle
    ;=================================================================
    
    mov r8d, dword[rbp-52]          ; y = min_y
    
.loop_y:
    cmp r8d, dword[rbp-56]          ; y <= max_y ?
    jg .fin
    
    mov r9d, dword[rbp-44]          ; x = min_x
    
.loop_x:
    cmp r9d, dword[rbp-48]          ; x <= max_x ?
    jg .next_y
    
    ;=============================================================
    ; Pour le point P(r9d, r8d), calculer les 3 déterminants :
    ; 1. det(AB, AP)
    ; 2. det(BC, BP)
    ; 3. det(CA, CP)
    ;=============================================================
    
    ; --- Calcul 1 : det(AB, AP) ---
    ; AB = (xB - xA, yB - yA)
    ; AP = (xP - xA, yP - yA)
    
    mov edi, r14d                   ; xB
    sub edi, r12d                   ; xB - xA = xAB
    
    mov esi, r15d                   ; yB
    sub esi, r13d                   ; yB - yA = yAB
    
    mov edx, r9d                    ; xP
    sub edx, r12d                   ; xP - xA = xAP
    
    mov ecx, r8d                    ; yP
    sub ecx, r13d                   ; yP - yA = yAP
    
    push r8
    push r9
    call determinant                ; det(AB, AP)
    pop r9
    pop r8
    mov [rbp-60], eax               ; Sauvegarde det1
    
    ; --- Calcul 2 : det(BC, BP) ---
    ; BC = (xC - xB, yC - yB)
    ; BP = (xP - xB, yP - yB)
    
    mov edi, dword[rbp-28]          ; xC
    sub edi, r14d                   ; xC - xB = xBC
    
    mov esi, dword[rbp-32]          ; yC
    sub esi, r15d                   ; yC - yB = yBC
    
    mov edx, r9d                    ; xP
    sub edx, r14d                   ; xP - xB = xBP
    
    mov ecx, r8d                    ; yP
    sub ecx, r15d                   ; yP - yB = yBP
    
    push r8
    push r9
    call determinant                ; det(BC, BP)
    pop r9
    pop r8
    mov [rbp-64], eax               ; Sauvegarde det2
    
    ; --- Calcul 3 : det(CA, CP) ---
    ; CA = (xA - xC, yA - yC)
    ; CP = (xP - xC, yP - yC)
    
    mov edi, r12d                   ; xA
    sub edi, dword[rbp-28]          ; xA - xC = xCA
    
    mov esi, r13d                   ; yA
    sub esi, dword[rbp-32]          ; yA - yC = yCA
    
    mov edx, r9d                    ; xP
    sub edx, dword[rbp-28]          ; xP - xC = xCP
    
    mov ecx, r8d                    ; yP
    sub ecx, dword[rbp-32]          ; yP - yC = yCP
    
    push r8
    push r9
    call determinant                ; det(CA, CP)
    pop r9
    pop r8
    mov [rbp-68], eax               ; Sauvegarde det3
    
    ;=============================================================
    ; Test d'appartenance selon le type de triangle
    ;=============================================================
    
    cmp dword[rbp-40], 0            ; Triangle direct ?
    je .test_direct
    
.test_indirect:
    ; Triangle INDIRECT : P doit être à GAUCHE de tous les segments
    ; C'est-à-dire : det1 < 0 ET det2 < 0 ET det3 < 0
    cmp dword[rbp-60], 0
    jge .next_x                     ; det1 >= 0 → skip
    cmp dword[rbp-64], 0
    jge .next_x                     ; det2 >= 0 → skip
    cmp dword[rbp-68], 0
    jge .next_x                     ; det3 >= 0 → skip
    jmp .draw_point                 ; Tous < 0 → dessiner
    
.test_direct:
    ; Triangle DIRECT : P doit être à DROITE de tous les segments
    ; C'est-à-dire : det1 > 0 ET det2 > 0 ET det3 > 0
    cmp dword[rbp-60], 0
    jle .next_x                     ; det1 <= 0 → skip
    cmp dword[rbp-64], 0
    jle .next_x                     ; det2 <= 0 → skip
    cmp dword[rbp-68], 0
    jle .next_x                     ; det3 <= 0 → skip
    
.draw_point:
    ; Le point est dans le triangle, on le dessine
    mov rdi, qword[rbp-8]           ; display
    mov rsi, qword[rbp-16]          ; window
    mov rdx, qword[rbp-24]          ; gc
    mov ecx, r9d                    ; x
    mov r8d, r8d                    ; y
    push r8
    push r9
    call XDrawPoint
    pop r9
    pop r8
    
.next_x:
    inc r9d                         ; x++
    jmp .loop_x
    
.next_y:
    inc r8d                         ; y++
    jmp .loop_y
    
.fin:
    add rsp, 96
    pop rbp
    ret
