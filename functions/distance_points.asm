;===============================================================

                    ; Fonction distance_points ;

;===============================================================

    ; Utilité :

;   - Calculer la distance entre deux points

;===============================================

    ; Prend en entrée 4 arguments :

;   - rdi -> [x1]
;   - rsi -> [y1]
;   - rdx -> [x2]
;   - rcx -> [y2]

;===============================================

; Renvoie la distance entre les deux points sous formes d'un entier

;===============================================

;   Exemple d'appel :

; mov rdi, 1 ; x1
; mov rsi, 3 ; y1
; mov rdx, 5 ; x2
; mov rcx, 6 ; y2
; call distance_points ; Return dans rax la ditance entre les deux points

;===============================================================

extern sqrt

;===============================================================

section .text
global distance_points:
distance_points:
    ; Debut de la fonction
    push rbp
    mov rbp, rsp

    ;=====================================

    sub rdi, rdx    ; rdi =  x1 - x2
    imul rdi, rdi   ; rdi = (x1 - x2)²

    sub rsi, rcx    ;  y1 - y2
    imul rsi, rsi   ; (y1 - y2)²

    ;=====================================

    add rdi, rsi    ; (x1-x2)² + (y1-y2)²

    ;=====================================
    
    cvtsi2sd xmm0, rdi  ; Convertie l'entier en double car sqrt attend un float

    call sqrt           ; sqrt( (x1-y1)² + (x2-y2)² )

    cvtsd2si rdi, xmm0 ; Convertie le résultat en entier arrondi

    ;=====================================

    mov rax, rdi    ; On return le resultat sur rax

    ;=====================================

    ; Fin de la fonction
    mov rsp, rbp
    pop rbp
    ret

;===============================================================