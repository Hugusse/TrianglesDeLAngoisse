%include "etapes/common.asm"

global determinant

section .text

determinant:
    push rbp
    mov rbp, rsp
    
    ; Calcul : (x_u * y_v) - (x_v * y_u)
    mov eax, edi        ; eax = x_u
    imul eax, ecx       ; eax = x_u * y_v
    
    mov edx, edx        ; edx = x_v
    imul edx, esi       ; edx = x_v * y_u
    
    sub eax, edx        ; eax = (x_u * y_v) - (x_v * y_u)
    
    pop rbp
    ret

