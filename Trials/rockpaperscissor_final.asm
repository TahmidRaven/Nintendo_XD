; Rock Paper Scissors Game
.model small
.stack 100h
.data
    prompt_msg      db 'Enter R/P/S or 1/2/3 for Rock/Paper/Scissors: $'
    win_msg         db 'you won, I hate you.$'
    lose_msg        db 'you loose dumbass$'
    tie_msg         db "it's a tie$"
    invalid_msg     db 'Invalid choice! Use R/P/S or 1/2/3$'
    newline         db 13, 10, '$'
    you_chose      db 'You chose: $'
    computer_chose  db 'Computer chose: $'
    choices         db 'Rock$Paper$Scissors$'
    comp_choice     db ?    ; Store computer's choice (1-3)
    player_choice   db ?    ; Store player's choice (1-3)

.code
main proc
    mov ax, @data
    mov ds, ax
    
game_loop:
    ; Generate random number for computer's choice
    mov ah, 00h     ; Get system time
    int 1ah         ; CX:DX = number of clock ticks since midnight
    mov ax, dx
    xor dx, dx
    mov cx, 3       ; Divide by 3 to get 0-2
    div cx
    add dl, 1       ; Add 1 to get 1-3
    mov comp_choice, dl
    
    ; Display prompt
    lea dx, prompt_msg
    mov ah, 9
    int 21h
    
    ; Get player's choice
    mov ah, 1
    int 21h
    
    ; Print newline
    push ax         ; Save input
    lea dx, newline
    mov ah, 9
    int 21h
    pop ax          ; Restore input
    
    ; Initialize player_choice to invalid value
    mov player_choice, 0
    
    ; Check for letter input (R/P/S)
    cmp al, 'R'
    je rock_choice
    cmp al, 'r'
    je rock_choice
    cmp al, 'P'
    je paper_choice
    cmp al, 'p'
    je paper_choice
    cmp al, 'S'
    je scissors_choice
    cmp al, 's'
    je scissors_choice
    
    ; Check for number input (1/2/3)
    sub al, '0'     ; Convert ASCII to number
    cmp al, 1
    je rock_choice
    cmp al, 2
    je paper_choice
    cmp al, 3
    je scissors_choice
    jmp invalid     ; If none of the above, invalid input
    
rock_choice:
    mov player_choice, 1
    jmp check_game
    
paper_choice:
    mov player_choice, 2
    jmp check_game
    
scissors_choice:
    mov player_choice, 3
    
check_game:
    ; Show player's choice
    lea dx, you_chose
    mov ah, 9
    int 21h
    
    mov bl, player_choice
    cmp bl, 1
    je show_player_rock
    cmp bl, 2
    je show_player_paper
    jmp show_player_scissors
    
show_player_rock:
    lea dx, choices
    jmp display_player_choice
show_player_paper:
    lea dx, choices+5
    jmp display_player_choice
show_player_scissors:
    lea dx, choices+11
display_player_choice:
    mov ah, 9
    int 21h
    
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Show computer's choice
    lea dx, computer_chose
    mov ah, 9
    int 21h
    
    mov bl, comp_choice
    cmp bl, 1
    je show_comp_rock
    cmp bl, 2
    je show_comp_paper
    jmp show_comp_scissors
    
show_comp_rock:
    lea dx, choices
    jmp show_comp_choice
show_comp_paper:
    lea dx, choices+5
    jmp show_comp_choice
show_comp_scissors:
    lea dx, choices+11
show_comp_choice:
    mov ah, 9
    int 21h
    
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Compare choices
    mov al, player_choice
    mov bl, comp_choice
    cmp al, bl          ; Compare player with computer
    je tie              ; If equal, it's a tie
    
    ; Check winning conditions
    ; Rock(1) beats Scissors(3)
    ; Scissors(3) beats Paper(2)
    ; Paper(2) beats Rock(1)
    
    cmp al, 1          ; Player chose Rock
    je check_rock
    cmp al, 2          ; Player chose Paper
    je check_paper
    jmp check_scissors
    
check_rock:
    cmp bl, 3          ; Computer chose Scissors
    je win
    jmp lose
    
check_paper:
    cmp bl, 1          ; Computer chose Rock
    je win
    jmp lose
    
check_scissors:
    cmp bl, 2          ; Computer chose Paper
    je win
    jmp lose
    
invalid:
    lea dx, invalid_msg
    mov ah, 9
    int 21h
    jmp game_end
    
tie:
    lea dx, tie_msg
    mov ah, 9
    int 21h
    jmp game_end
    
win:
    lea dx, win_msg
    mov ah, 9
    int 21h
    jmp game_end
    
lose:
    lea dx, lose_msg
    mov ah, 9
    int 21h
    
game_end:
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Play again (automatic)
    jmp game_loop
    
main endp
end main