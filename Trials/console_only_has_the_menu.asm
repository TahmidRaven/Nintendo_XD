; Multi-Game Menu System
.model small
.stack 100h
.data
    ; Menu and name prompts
    welcome_msg     db 'Welcome to the Game Center!$'
    name_prompt     db 'Enter your name: $'
    menu_msg        db 13, 10, 'Choose a game:', 13, 10
                    db '1. Wordle', 13, 10
                    db '2. Rock Paper Scissors', 13, 10
                    db '3. Number Guess (1-99)', 13, 10
                    db 'Your choice: $'
    player_name     db 30 dup('$')     ; Store player name
    newline         db 13, 10, '$'
    invalid_choice  db 'Invalid choice! Please select 1-3$'
    play_again_msg  db 'Play again? (Y/N): $'
    goodbye_msg     db 'Goodbye, $'

    ; Number Guessing Game Data
    num_prompt      db 'Guess a number (1-99): $'
    num_high        db 'Too high!$'
    num_low         db 'Too low!$'
    num_win         db 'You got it!$'
    target_num      db ?               ; Random number to guess
    player_num      db ?               ; Player's guessed number
    
    ; Rock Paper Scissors Data
    rps_prompt      db 'Enter R/P/S or 1/2/3 for Rock/Paper/Scissors: $'
    rps_win         db 'you won, I hate you.$'
    rps_lose        db 'you loose dumbass$'
    rps_tie         db "it's a tie$"
    rps_invalid     db 'Invalid choice! Use R/P/S or 1/2/3$'
    you_chose       db 'You chose: $'
    computer_chose  db 'Computer chose: $'
    choices         db 'Rock$Paper$Scissors$'
    comp_choice     db ?
    player_choice   db ?

    ; Wordle Data
    word_array      db 'FOOD', 'FEET', 'HAIR', 'HEAD', 'EYES', 'LAMB', 'BATS', 'CODE'
    array_size      equ 8
    target_word     db 4 dup(?)
    guess           db 5 dup('$')
    wordle_prompt   db 'Enter a 4-letter word: $'
    correct_msg     db 'You won! $'
    result          db 5 dup('$')
    seed            dw 0

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Display welcome message
    lea dx, welcome_msg
    mov ah, 9
    int 21h
    
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Get player name
    lea dx, name_prompt
    mov ah, 9
    int 21h
    
    ; Read name
    lea si, player_name
    mov cx, 29          ; Max 29 chars + enter
read_name:
    mov ah, 1
    int 21h
    cmp al, 13         ; Check for enter key
    je name_done
    mov [si], al
    inc si
    loop read_name
name_done:
    mov byte ptr [si], '$'  ; Terminate string
    
main_menu:
    ; Display menu
    lea dx, menu_msg
    mov ah, 9
    int 21h
    
    ; Get choice
    mov ah, 1
    int 21h
    
    ; Print newline
    push ax             ; Save choice
    lea dx, newline
    mov ah, 9
    int 21h
    pop ax             ; Restore choice
    
    ; Process choice
    sub al, '0'        ; Convert to number
    
    cmp al, 1
    je start_wordle
    cmp al, 2
    je start_rps
    cmp al, 3
    je start_numguess
    
    ; Invalid choice
    lea dx, invalid_choice
    mov ah, 9
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    jmp main_menu

start_wordle:
    call wordle_game
    jmp check_play_again
    
start_rps:
    call rps_game
    jmp check_play_again
    
start_numguess:
    call numguess_game
    jmp check_play_again
    
check_play_again:
    ; Ask to play again
    lea dx, play_again_msg
    mov ah, 9
    int 21h
    
    mov ah, 1
    int 21h
    
    ; Print newline
    push ax
    lea dx, newline
    mov ah, 9
    int 21h
    pop ax
    
    cmp al, 'Y'
    je main_menu
    cmp al, 'y'
    je main_menu
    
    ; Say goodbye with name
    lea dx, goodbye_msg
    mov ah, 9
    int 21h
    lea dx, player_name
    mov ah, 9
    int 21h
    
    ; Exit program
    mov ah, 4ch
    int 21h

main endp

; Include your existing Wordle game code here
wordle_game proc
    ; Initialize random seed
    mov ah, 00h
    int 1Ah
    mov seed, dx
    
    ; Select random word
    mov ax, seed
    xor dx, dx
    mov cx, array_size
    div cx
    
    ; Copy selected word
    mov cx, 4
    mov si, dx
    mov ax, 4
    mul si
    mov si, ax
    lea di, target_word
    copy_word:
        mov al, word_array[si]
        mov [di], al
        inc si
        inc di
        loop copy_word
        
    ; Your existing Wordle game loop here
    ret
wordle_game endp

; Include your existing Rock Paper Scissors game code here
rps_game proc
    ; Your existing RPS game code here
    ret
rps_game endp

; New Number Guessing game
numguess_game proc
    ; Generate random number 1-99
    mov ah, 00h
    int 1Ah
    mov ax, dx
    xor dx, dx
    mov cx, 99
    div cx
    inc dx          ; Make it 1-99 instead of 0-98
    mov target_num, dl
    
numguess_loop:
    ; Show prompt
    lea dx, num_prompt
    mov ah, 9
    int 21h
    
    ; Get first digit
    mov ah, 1
    int 21h
    sub al, '0'
    mov bl, 10
    mul bl          ; First digit * 10
    mov bl, al      ; Save in bl
    
    ; Get second digit
    mov ah, 1
    int 21h
    sub al, '0'
    add bl, al      ; Add second digit
    mov player_num, bl
    
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Compare numbers
    mov al, target_num
    cmp player_num, al
    je numguess_win
    jg numguess_high
    jmp numguess_low
    
numguess_high:
    lea dx, num_high
    mov ah, 9
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    jmp numguess_loop
    
numguess_low:
    lea dx, num_low
    mov ah, 9
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    jmp numguess_loop
    
numguess_win:
    lea dx, num_win
    mov ah, 9
    int 21h
    lea dx, newline
    mov ah, 9
    int 21h
    ret
    
numguess_game endp

end main