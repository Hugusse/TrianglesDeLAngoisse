%include "etapes/common.asm"

global determinant

section .text

determinant:
    push rbp
    mov rbp, rsp
    
    ; On doit utiliser des registres différents pour éviter les écrasements
    
    ; Calcul de x_u * y_v
    movsxd rax, edi                 ; rax = x_u (extension de signe 32->64 bits)
    movsxd r8, ecx                  ; r8 = y_v
    imul rax, r8                    ; rax = x_u * y_v
    
    ; Calcul de x_v * y_u  
    movsxd r9, edx                  ; r9 = x_v
    movsxd r10, esi                 ; r10 = y_u
    imul r9, r10                    ; r9 = x_v * y_u
    
    ; Résultat final
    sub rax, r9                     ; rax = (x_u * y_v) - (x_v * y_u)
    
    ; Le résultat est déjà dans eax (partie basse de rax)
    
    pop rbp
    ret