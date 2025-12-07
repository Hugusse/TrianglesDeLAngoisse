%include "etapes/common.asm"

global main

extern random_number
extern fillTriangle

section .bss
display_name:	resq	1
window_ptr:		resq	1
gc_ptr:			resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
event:		times	24 dq 0

section .data
tri_x1:		dd	0
tri_y1:		dd	0
tri_x2:		dd	0
tri_y2:		dd	0
tri_x3:		dd	0
tri_y3:		dd	0

section .text

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
    push rbp
    mov rbp, rsp
    
    ; Génère les coordonnées du triangle
    call generate_triangle
    
    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    test    rax, rax          ; Teste si rax est NULL
    jz      closeDisplay      ; Si NULL, ferme le display et quitte

    ; Ouvre le display par défaut
    xor     rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
    call    XOpenDisplay      ; Appel de XOpenDisplay
    test    rax, rax          ; Vérifie si l'ouverture a réussi
    jz      closeDisplay      ; Si échec, ferme le display et quitte

    ; Stocke le display ouvert dans la variable globale display_name
    mov     [display_name], rax

    ; Récupère la fenêtre racine (root window) du display
    mov     rdi, qword[display_name]   ; Place le display dans rdi
    mov     esi, dword[screen]         ; Place le numéro d'écran dans esi
    call XRootWindow                   ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx, rax                   ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi, qword[display_name]   ; display
    mov     rsi, rbx                   ; parent = root window
    mov     rdx, 10                    ; position x de la fenêtre
    mov     rcx, 10                    ; position y de la fenêtre
    mov     r8, LARGEUR                ; largeur de la fenêtre
    mov     r9, HAUTEUR                ; hauteur de la fenêtre
    push 0x000000                      ; couleur du fond (noir, 0x000000)
    push 0x00FF00                      ; couleur de fond (vert, 0x00FF00)
    push 1                             ; épaisseur du bord
    call XCreateSimpleWindow           ; Appel de XCreateSimpleWindow
    add rsp, 24
    mov qword[window_ptr], rax             ; Stocke l'identifiant de la fenêtre créée

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    mov rdx, 131077                    ; Masque d'événements
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
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

boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement

    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify
    je      dessin                        ; Passe à la phase de dessin

    cmp     dword[event], Expose          ; Si l'événement est Expose
    je      dessin                        ; Passe à la phase de dessin

    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle


;#########################################
;#      DEBUT DE LA ZONE DE DESSIN       #
;#########################################
dessin:
    ; Récupère les coordonnées du triangle
    mov ecx, dword[tri_x1]
    mov r8d, dword[tri_y1]
    mov r9d, dword[tri_x2]
    mov r10d, dword[tri_y2]
    mov r11d, dword[tri_x3]
    mov r12d, dword[tri_y3]
    
    ; Stocke les coordonnées en mémoire globale pour fillTriangle (dans tri_x1, etc.)
    mov dword[tri_x1], ecx
    mov dword[tri_y1], r8d
    mov dword[tri_x2], r9d
    mov dword[tri_y2], r10d
    mov dword[tri_x3], r11d
    mov dword[tri_y3], r12d
    
    ; Appelle fillTriangle(display, window, gc)
    mov rdi, qword[display_name]
    mov rsi, qword[window_ptr]
    mov rdx, qword[gc_ptr]
    call fillTriangle
    
    ; Flush et retour à la boucle
    jmp flush

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################

flush:
    mov rdi, qword[display_name]
    call XFlush
    jmp boucle

closeDisplay:
    mov     rax, qword[display_name]
    mov     rdi, rax
    call    XCloseDisplay
    xor	    rdi, rdi
    call    exit
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
generate_triangle:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Génère 6 coordonnées aléatoires pour le triangle unique
    mov edi, LARGEUR
    call random_number
    mov dword[tri_x1], eax
    
    mov edi, HAUTEUR
    call random_number
    mov dword[tri_y1], eax
    
    mov edi, LARGEUR
    call random_number
    mov dword[tri_x2], eax
    
    mov edi, HAUTEUR
    call random_number
    mov dword[tri_y2], eax
    
    mov edi, LARGEUR
    call random_number
    mov dword[tri_x3], eax
    
    mov edi, HAUTEUR
    call random_number
    mov dword[tri_y3], eax
    
    add rsp, 32
    pop rbp
    ret
