;******************
; Programme Tetris
;******************

include libgfx.inc
include random.inc
include blocks.inc

pile    segment stack     ; Segment de pile
pile    ends

donnees segment public    ; Segment de donnees
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données pour "getColor"
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    pX DW 0
    pY DW 0
    retCol DB 0

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données pour "draw_block", "erase_block" et "colision_detector"
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    tabX DW 0           ; Coordonée X pour le dessin
    tabY DW 0           ; Coordonée Y pour le dessin
    tabWidth DW 0
    tabRow DW 0
    tabCurrentLenght DW 0
    tabLength DW 0
    tabCurrentWidth DW 0
    blockToDraw DW 0
    colorToDraw DB 0
    newColorToDraw DB 0
    isColision DB 0     ;detecte collision


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données pour "getColor"
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    nbLoop DB 0         ; nombre de tour de la pièce courante
    cWidth DB 0         ; current largeur
    cHeight DB 0        ; current hauteur
    loopY DW 0          ; coordonnée de comparaison
    loopX DW 0          ; coordonnée de comparaison
    previousIsColor DB 0

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données pour les fonction "move"
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    nbLoopMove DB 0
    oldCXX DW 0

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données sur le block courant
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cXX DW 150          ; Coordonée X  de la pièce courante
    cYY DW 25           ; Coordonée Y de la pièce courante
    cCol DB 42          ; Couleur de la pièce courante
    cBlocks DW 0        ; Block courant
    cBlocksWidth DB 0   ; Largeur du block courant
    cBlocksHeight DB 0  ; Hauteur du block courant
    cCodeBlock DB 0

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données sur le prochain block
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    fBlocks DW 0        ; Block futur
    fXX DW 257          ; Coordonée X  de la pièce future
    fYY DW 78           ; Coordonée Y de la pièce future
    fCodeBlock DB 0

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Données pour faire tourner les blocks
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    turnMul DB 0        ; Multiplicateur pour tourner les pièces
    turnMulResutl DB 0  ; Résultat de la multiplication pour faire tourner la pièce
donnees ends

code    segment public    ; Segment de code
assume  cs:code,ds:donnees,es:code,ss:pile

prog:
    mov AX, donnees
	mov DS, AX
    call Video13h
    call get_random_blocks
    call get_next_blocks
    call draw_next_block
    call drawLand

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Boucle principale du progralle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
boucle:
    call drawLand
    call drop_block
    call get_userinput
    mov tempo, 5
    call sleep
    jmp  boucle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Fin du programme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end_game:
    call VideoCMD
    mov AH,4Ch      ; 4Ch = fonction de fin de prog DOS
    mov AL,00h      ; code de sortie 0 (tout s'est bien passe)
    int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fait descendre le block s'il n'y a pas de colisions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drop_block:
    mov AX, cYY
    mov tabY, AX
    mov AX, cXX
    mov tabX, AX
    mov BX, cBlocks
    mov blockToDraw, BX
    inc tabY
    call colision_detector
    cmp isColision, 0
    je drop_block_move

    ; Prépare l'affichage du nouveau block courant
    cmp nbLoop, 1
    je end_game
    dec tabY
    call draw_block_update
    mov nbLoop, 0
    mov cXX, 150
    mov cYY, 25
    mov BX, fBlocks
    mov cBlocks, BX
    mov AL, fCodeBlock
    mov cCodeBlock, AL
    mov turnMul, 1

    ; Affiche le prochain block
    call erase_next_blocks
    call get_next_blocks
    call draw_next_block
    drop_block_move:
        inc nbLoop
        inc cYY
        call draw_block
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Execution des commandes saisies par le joueur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_userinput:
    call PeekKey
    cmp userinput, 'p'
    je end_game
    cmp userinput, 'q'
    je move_left
    cmp userinput, 'd'
    je move_right
    jmp turn_move
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Déplace le block à gauche
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
move_left:
    mov AX, cXX
    mov oldCXX, AX
    mov nbLoopMove, 0
    move_left_loop:
        inc nbLoopMove
        dec cXX
        mov AX, cYY
        mov tabY, AX
        mov AX, cXX
        mov tabX, AX
        mov BX, cBlocks
        mov blockToDraw, BX
        call colision_detector
        cmp isColision, 1
        je move_left_colision
        call draw_block
        cmp nbLoopMove, 5
        jne move_left_loop
        ret
    move_left_colision:
        mov AX, oldCXX
        mov cXX, AX
        mov isColision, 0
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Déplace le block à droite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
move_right:
    mov AX, cXX
    mov oldCXX, AX
    mov nbLoopMove, 0
    move_right_loop:
        inc nbLoopMove
        inc cXX
        mov AX, cYY
        mov tabY, AX
        mov AX, cXX
        mov tabX, AX
        mov BX, cBlocks
        mov blockToDraw, BX
        call colision_detector
        cmp isColision, 1
        je move_right_colision
        call draw_block
        cmp nbLoopMove, 5
        jne move_right_loop
        ret
    move_right_colision:
        mov AX, oldCXX
        mov cXX, AX
        mov isColision, 0
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Execution des commande pour tourner saisie par le joueur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
turn_move:
    cmp userinput, 'e'
    je turn_right
    cmp userinput, 'a'
    je turn_left
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tourne le block à gauche
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
turn_left:
    cmp turnMul, 0
    jae continue_turn_left ; ja: Supérieur ou égale (<=)
    mov turnMul, 3
    continue_turn_left:
        mov AL, 7
        mov BL, turnMul
        mul BL
        mov turnMulResutl, AL
        cmp turnMul, 0
        je reset_turn_left
        dec turnMul
        jmp turn
        reset_turn_left:
            mov turnMul, 3
            jmp turn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tourne le block à droite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
turn_right:
    cmp turnMul, 4
    jne continue_turn_right
    mov turnMul, 0
    continue_turn_right:
        mov AL, 7
        mov BL, turnMul
        mul BL
        mov turnMulResutl, AL
        inc turnMul
    jmp turn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tourne le block à droite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
turn:
    ; Efface le block
    mov AX, cXX
    mov tabX, AX
    mov AX, cYY
    mov tabY, AX
    mov BX, cBlocks
    mov blockToDraw, BX
    call erase_block

    ; Préparation des registre pour faire tourner la pièce
    mov AL, cCodeBlock
    add AL, turnMulResutl
    mov codeBlock, AL
    call get_block_from_code
    mov BX, block
    mov cBlocks, BX

    ; Récupération de la taille du tableau
    mov BX, cBlocks
    mov AX, [BX]
    mov cBlocksWidth, AL

    ; Récupération de la hauteur du tableau
    add BX, 2
    mov AX, [BX]
    mov CL, cBlocksWidth
    div CL
    mov cBlocksHeight, AL

    ; Récupération du code couleur
    add BX, 2
    mov AX, [BX]
    mov cCol, AL
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Imprime un pixel vert à la position (20,20). Utiliser pour les tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_color:
    mov cCX, 20
    mov cDX, 20
    mov col, 10
    call PaintPxl
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Affiche le rectangle avec les pièces qui y sont contenu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawLand:
    mov Rx, 130
    mov Ry, 20
    mov Rw, 61
    mov Rh, 160
    mov col, 7
    call Rectangle
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Affiche la prochaine pièce
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_next_block:
    ; Dessine le rectangle
    mov Rx, 252
    mov Ry, 70
    mov Rw, 30
    mov Rh, 25
    mov col, 7
    call Rectangle

    ; Dessine le nouveau block
    mov AX, fYY
    mov tabY, AX
    mov AX, fXX
    mov tabX, AX
    mov BX, fBlocks
    mov blockToDraw, BX
    call draw_block
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Récupère un block aléatoirement au début currentBlock
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_random_blocks:
    mov diviseur, 7
    call get_random
    mov AX, reste
    mov codeBlock, AL
    mov cCodeBlock, AL
    call get_block_from_code
    mov BX, block
    mov cBlocks, BX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Prépare un block aléatoirement et le stocke dans fBlocks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_next_blocks:
    mov diviseur, 7
    call get_random
    mov AX, reste
    mov codeBlock, AL
    mov fCodeBlock, AL
    call get_block_from_code
    mov BX, block
    mov fBlocks, BX    

    ;Récupération de la taille du tableau
    mov BX, cBlocks
    mov AX, [BX]
    mov cBlocksWidth, AL

    ;Récupération de la hauteur du tableau
    add BX, 2
    mov AX, [BX]
    mov CL, cBlocksWidth
    div CL
    mov cBlocksHeight, AL

    ; Récupération du code couleur
    add BX, 2
    mov AX, [BX]
    mov cCol, AL
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Efface le prochain block
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
erase_next_blocks:
    mov AX, fXX
    mov tabX, AX
    mov AX, fYY
    mov tabY, AX
    mov BX, fBlocks
    mov blockToDraw, BX
    call erase_block
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Récupère la couleur aux cordonnées pX et pY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_color:
    mov ah, 0Dh
    mov CX, pX
    mov DX, pY
    int 10H
    mov retCol, AL
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Détecte s'il y a une colision ou non
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
colision_detector:
    mov isColision, 0
    ; Récupération de la width du block
    mov BX, blockToDraw
    mov AX, [BX]
    mov tabWidth, AX

    ; Récupération du nombre total de caractère dans le block
    add BX, 2
    mov AX, [BX]
    mov tabLength, AX

    add BX, 2
    mov AX, [BX]
    mov colorToDraw, AL

    add BX, 2
    mov tabCurrentLenght, 0
    mov tabRow, 0
    mov tabCurrentWidth, 1
    loop_colision_detector:
        mov AX, [BX]
        cmp AL, 0
        jne colision_detector_color_pixel

        loop_colision_detector_afer_pixel_continue:
            mov AX, tabWidth
            cmp AX, tabCurrentWidth
            je colision_detector_jump
            inc tabCurrentWidth

        loop_colision_detector_afer_jump_continue:
            inc BX
            inc tabCurrentLenght
            mov AX, tabCurrentLenght
            cmp AX, tabLength
            jne loop_colision_detector
            ret

    colision_detector_jump:
        mov tabCurrentWidth, 1
        inc tabRow
        jmp loop_colision_detector_afer_jump_continue

    colision_detector_color_pixel:
        ; Coordonnées X
        mov AX, tabX
        add AX, tabCurrentWidth
        dec AX
        mov pX, AX
        ; Coordonnées Y
        mov AX, tabY
        add AX, tabRow
        mov pY, AX

        call get_color
        cmp retCol, 0
        je loop_colision_detector_afer_pixel_continue
        mov AL, colorToDraw
        cmp retCol, AL
        je loop_colision_detector_afer_pixel_continue
        mov isColision, 1
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Affiche le block courant
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_block:
    ; Récupération de la width du block
    mov BX, blockToDraw
    mov AX, [BX]
    mov tabWidth, AX

    ; Récupération du nombre total de caractère dans le block
    add BX, 2
    mov AX, [BX]
    mov tabLength, AX

    add BX, 2
    mov AX, [BX]
    mov colorToDraw, AL

    add BX, 2
    mov tabCurrentLenght, 0
    mov tabRow, 0
    mov tabCurrentWidth, 1
    loop_draw_block:
        mov AX, [BX]
        cmp AL, 0
        je draw_block_black_pixel
        call draw_block_draw_get_coordinates

        loop_draw_block_draw_prixel:
            call PaintPxl

        loop_draw_block_afer_pixel_continue:
            mov AX, tabWidth
            cmp AX, tabCurrentWidth
            je draw_block_jump
            inc tabCurrentWidth

        loop_draw_block_afer_jump_continue:
            inc BX
            inc tabCurrentLenght
            mov AX, tabCurrentLenght
            cmp AX, tabLength
            jne loop_draw_block
            ret

    draw_block_jump:
        mov tabCurrentWidth, 1
        inc tabRow
        jmp loop_draw_block_afer_jump_continue

    draw_block_black_pixel:
        call draw_block_draw_get_coordinates
        mov AX, cCX
        mov pX, AX
        mov AX, cDX
        mov pY, AX
        call get_color
        mov AL, colorToDraw
        cmp retCol, AL
        je loop_draw_block_draw_prixel
        cmp retCol, 0
        je loop_draw_block_draw_prixel
        jmp loop_draw_block_afer_pixel_continue

    draw_block_draw_get_coordinates:
        ; Ajout de la couleur
        mov col, AL
        ; Coordonnées X
        mov AX, tabX
        add AX, tabCurrentWidth
        dec AX
        mov cCX, AX
        ; Coordonnées Y
        mov AX, tabY
        add AX, tabRow
        mov cDX, AX
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Efface le block passé en paramètre
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
erase_block:
    ; Récupération de la width du block
    mov BX, blockToDraw
    mov AX, [BX]
    mov tabWidth, AX

    ; Récupération du nombre total de caractère dans le block
    add BX, 2
    mov AX, [BX]
    mov tabLength, AX

    add BX, 4
    mov tabCurrentLenght, 0
    mov tabRow, 0
    mov tabCurrentWidth, 1
    loop_erase_block:
        mov AX, [BX]
        cmp AL, 0
        call erase_block_draw_get_coordinates
        call PaintPxl
        mov AX, tabWidth
        cmp AX, tabCurrentWidth
        je erase_block_jump
        inc tabCurrentWidth

        loop_erase_block_afer_jump_continue:
            inc BX
            inc tabCurrentLenght
            mov AX, tabCurrentLenght
            cmp AX, tabLength
            jne loop_erase_block
            jmp erase_block_end

    erase_block_jump:
        mov tabCurrentWidth, 1
        inc tabRow
        jmp loop_erase_block_afer_jump_continue

    erase_block_end:
        ret

    erase_block_draw_get_coordinates:
        ; Ajout de la couleur
        mov col, 0
        ; Coordonnées X
        mov AX, tabX
        add AX, tabCurrentWidth
        dec AX
        mov cCX, AX
        ; Coordonnées Y
        mov AX, tabY
        add AX, tabRow
        mov cDX, AX
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update la couleur du block
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_block_update:
    ; Récupération de la width du block
    mov BX, blockToDraw
    mov AX, [BX]
    mov tabWidth, AX

    ; Récupération du nombre total de caractère dans le block
    add BX, 2
    mov AX, [BX]
    mov tabLength, AX

    add BX, 2
    mov AX, [BX]
    mov colorToDraw, AL
    mov newColorToDraw, AL
    add newColorToDraw, 8

    add BX, 2
    mov tabCurrentLenght, 0
    mov tabRow, 0
    mov tabCurrentWidth, 1
    loop_draw_block_update:
        mov AX, [BX]
        cmp AL, colorToDraw
        je draw_block_update_color


        loop_draw_block_update_afer_pixel_continue:
            mov AX, tabWidth
            cmp AX, tabCurrentWidth
            je draw_block_update_jump
            inc tabCurrentWidth

        loop_draw_block_update_afer_jump_continue:
            inc BX
            inc tabCurrentLenght
            mov AX, tabCurrentLenght
            cmp AX, tabLength
            jne loop_draw_block_update
            ret

    draw_block_update_jump:
        mov tabCurrentWidth, 1
        inc tabRow
        jmp loop_draw_block_update_afer_jump_continue

    draw_block_update_color:
        mov AL, newColorToDraw
        mov col, AL
        ; Coordonnées X
        mov AX, tabX
        add AX, tabCurrentWidth
        dec AX
        mov cCX, AX
        ; Coordonnées Y
        mov AX, tabY
        add AX, tabRow
        mov cDX, AX
        call PaintPxl
        jmp loop_draw_block_update_afer_pixel_continue


code    ends               ; Fin du segment de code
end prog                 ; Fin du programme