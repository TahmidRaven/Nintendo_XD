.model small
.stack 100h
.data
    prompt_msg      db 'Enter R/P/S or 1/2/3 for Rock/Paper/Scissors: $'
    win_msg         db 'You won, I hate you.$'
    lose_msg        db 'You lose, dumbass.$'
    tie_msg         db "It's a tie.$"
    invalid_msg     db 'Invalid choice! Use R/P/S or 1/2/3.$'
    newline         db 13, 10, '$'
    you_chose       db 'You chose: $'
    computer_chose  db 'Computer chose: $'
    choices         db 'Rock$Paper$Scissors$'
    rps_rounds          db 0
    rps_current_round   db 1
    rps_player_wins     db 0
    rps_computer_wins   db 0
    rps_rounds_msg      db 'Enter number of rounds to play (1-9): $'
    rps_final_msg       db 'Final Results:$'
    rps_player_score    db 'Player wins: $'
    rps_computer_score  db 'Computer wins: $'
    rps_final_winner    db 'The winner is: $'
    rps_draw_msg        db 'The game is a draw!$'
    rps_player_msg      db 'Player!$'
    rps_computer_msg    db 'Computer!$'
    comp_choice         db ?
    player_choice       db ?
.code
main proc
    mov ax, @data
    mov ds, ax
    lea dx, rps_rounds_msg
    mov ah, 9
    int 21h
    mov ah, 1
    int 21h
    sub al, '0'
    mov rps_rounds, al
    lea dx, newline
    mov ah, 9
    int 21h
rps_game_loop:
    lea dx, newline
    mov ah, 9
    int 21h
    mov dl, rps_current_round
    add dl, '0'
    mov ah, 2
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    mov ah, 00h
    int 1ah
    mov ax, dx
    xor dx, dx
    mov cx, 3
    div cx
    add dl, 1
    mov comp_choice, dl
    lea dx, prompt_msg
    mov ah, 9
    int 21h
    mov ah, 1
    int 21h
    push ax
    lea dx, newline
    mov ah, 9
    int 21h
    pop ax
    mov player_choice, 0
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
    sub al, '0'
    cmp al, 1
    je rock_choice
    cmp al, 2
    je paper_choice
    cmp al, 3
    je scissors_choice
    jmp invalid
rock_choice:
    mov player_choice, 1
    jmp check_game
paper_choice:
    mov player_choice, 2
    jmp check_game
scissors_choice:
    mov player_choice, 3
check_game:
    mov al, player_choice
    mov bl, comp_choice
    cmp al, bl
    je tie
    cmp al, 1
    je check_rock
    cmp al, 2
    je check_paper
    jmp check_scissors
check_rock:
    cmp bl, 3
    je win
    jmp lose
check_paper:
    cmp bl, 1
    je win
    jmp lose
check_scissors:
    cmp bl, 2
    je win
    jmp lose
invalid:
    lea dx, invalid_msg
    mov ah, 9
    int 21h
    jmp rps_round_end
tie:
    lea dx, tie_msg
    mov ah, 9
    int 21h
    jmp rps_round_end
win:
    lea dx, win_msg
    mov ah, 9
    int 21h
    inc rps_player_wins
    jmp rps_round_end
lose:
    lea dx, lose_msg
    mov ah, 9
    int 21h
    inc rps_computer_wins
rps_round_end:
    lea dx, newline
    mov ah, 9
    int 21h
    inc rps_current_round
    mov al, rps_current_round
    cmp al, rps_rounds
    jle rps_game_loop
    lea dx, rps_final_msg
    mov ah, 9
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    lea dx, rps_player_score
    mov ah, 9
    int 21h
    mov dl, rps_player_wins
    add dl, '0'
    mov ah, 2
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    lea dx, rps_computer_score
    mov ah, 9
    int 21h
    mov dl, rps_computer_wins
    add dl, '0'
    mov ah, 2
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    lea dx, rps_final_winner
    mov ah, 9
    int 21h
    mov al, rps_player_wins
    cmp al, rps_computer_wins
    je draw
    jg player_wins
    lea dx, rps_computer_msg
    jmp display_winner
player_wins:
    lea dx, rps_player_msg
    jmp display_winner
draw:
    lea dx, rps_draw_msg
display_winner:
    mov ah, 9
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    jmp exit
exit:
    mov ah, 4ch
    int 21h
main endp
end main