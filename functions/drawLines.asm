%include "etapes/common.asm"

global drawLines

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

section .data

event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

drawLines:
    ; Sauvegarde du registre de base pour préparer les appels à printf
    push    rbp
    mov     rbp, rsp
	
    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    ; Vérifie si le display est valide
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
    mov     rdi,qword[display_name]   ; Place le display dans rdi
    mov     esi,dword[screen]         ; Place le numéro d'écran dans esi
    call XRootWindow                ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx,rax               ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi,qword[display_name]   ; display
    mov     rsi,rbx                   ; parent = root window
    mov     rdx,10                    ; position x de la fenêtre
    mov     rcx,10                    ; position y de la fenêtre
    mov     r8,LARGEUR                ; largeur de la fenêtre
    mov     r9,HAUTEUR           	; hauteur de la fenêtre
    push 0x000000                     ; couleur du fond (noir, 0x000000)
    push 0x00FF00                     ; couleur de fond (vert, 0x00FF00)
    push 1                          ; épaisseur du bord
    call XCreateSimpleWindow        ; Appel de XCreateSimpleWindow
	add rsp,24
	mov qword[window],rax           ; Stocke l'identifiant de la fenêtre créée dans window

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077                 ; Masque d'événements (ex. StructureNotifyMask + autres)
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
    mov rdi, qword[display_name]
    test rdi, rdi                ; Vérifie que display n'est pas NULL
    jz closeDisplay

    mov rsi, qword[window]
    test rsi, rsi                ; Vérifie que window n'est pas NULL
    jz closeDisplay

    xor rdx, rdx                 ; Aucun masque particulier
    xor rcx, rcx                 ; Aucune valeur particulière
    call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
    test rax, rax                ; Vérifie la création du GC
    jz closeDisplay              ; Si échec, quitte
    mov qword[gc], rax           ; Stocke le GC dans la variable gc
	
boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement

    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify (ex: redimensionnement)
    je      dessin                        ; Passe à la phase de dessin

    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle


;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0x00FFFF	; Couleur du crayon
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],200
	mov dword[y1],100
; Dessin d'un point	
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée en x
	mov r8d,dword[y1]	; coordonnée en y
	call XDrawPoint
; Fin Dessin d'un point

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0xFF00FF	; Couleur du crayon (violet)
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],100
	mov dword[y1],100
	mov dword[x2],200
	mov dword[y2],150
; Dessin d'une ligne
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée source en x
	mov r8d,dword[y1]	; coordonnée source en y
	mov r9d,dword[x2]	; coordonnée destination en x
	mov r14d,dword[y2]
	push r14		; coordonnée destination en y
	call XDrawLine
	add rsp,8
; Fin Dessin d'une ligne

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0xFFFF00	; Couleur du crayon (jaune)
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],200
	mov dword[y1],200
	mov dword[x2],50
	mov dword[y2],250
; Dessin d'une ligne
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée source en x
	mov r8d,dword[y1]	; coordonnée source en y
	mov r9d,dword[x2]	; coordonnée destination en x
	mov r14d,dword[y2]
	push r14		; coordonnée destination en y
	call XDrawLine
	add rsp,8
; Fin Dessin d'une ligne

; Changer la couleur de dessin
	mov rdi,qword[display_name]
	mov rsi,qword[gc]
	mov edx,0x00FFFF	; Couleur du crayon (cyan)
	call XSetForeground
; Fin Change la couleur de dessin

	mov dword[x1],250
	mov dword[y1],50
	mov dword[x2],150
	mov dword[y2],250
; Dessin d'une ligne
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[x1]	; coordonnée source en x
	mov r8d,dword[y1]	; coordonnée source en y
	mov r9d,dword[x2]	; coordonnée destination en x
	mov r14d,dword[y2]
	push r14		; coordonnée destination en y
	call XDrawLine
	add rsp,8
; Fin Dessin d'une ligne
dessin2:



; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
