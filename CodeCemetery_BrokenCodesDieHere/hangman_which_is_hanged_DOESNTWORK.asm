.model small
.stack 100h

.data
    prompt1 db "Welcome to Hangman! Guess the word: $"
    prompt2 db "Enter a letter: $"
    correct_msg db "Correct! $"
    incorrect_msg db "Incorrect! Try again. $"
    win_msg db "Congratulations! You won! $"
    lose_msg db "Game Over! You lost. $"
    word db "HELLO$"           ; Word to guess
    guessed_word db "_____ $"
    attempts db 0
    max_attempts db 6
    newline db 0Ah, 0Dh, "$"   ; New line for displaying results

.code
; Macro to display messages
DisplayMessage MACRO msg
    mov ah, 09h
    lea dx, msg
    int 21h
ENDM

; Macro to get user input
GetUserInput MACRO
    mov ah, 01h
    int 21h
    mov al, dl   ; Store the letter input in AL
ENDM

; Macro to replace underscore with the guessed letter in guessed_word
ReplaceChar MACRO
    lea si, word
    lea di, guessed_word
    mov cx, 5
    replace_loop:
        mov dl, [si]        ; Get the character from the word
        cmp dl, al          ; Compare it to the guessed letter
        jne skip_replace    ; If not a match, skip replacement
        mov [di], al        ; Replace underscore in guessed_word
    skip_replace:
        inc si
        inc di
        loop replace_loop
ENDM

; Macro to check if the word is fully guessed
CheckIfGuessed MACRO
    lea si, guessed_word
    lea di, word
    mov cx, 5
    xor dx, dx          ; Clear dx to track if all letters are guessed
    compare_words:
        mov dl, [si]
        cmp dl, [di]
        jne continue_check  ; If they don't match, continue checking
        inc si
        inc di
        loop compare_words
        ; If all characters match, player wins
        DisplayMessage win_msg
        jmp end_game
    continue_check:
        jmp game_loop       ; Continue the game if the word is not fully guessed
ENDM

main:
    ; Initialize the data segment
    mov ax, @data
    mov ds, ax

    ; Display welcome message
    DisplayMessage prompt1

game_loop:
    ; Display guessed word
    DisplayMessage guessed_word

    ; Get user input (letter)
    DisplayMessage prompt2
    GetUserInput

    ; Check if the letter is in the word
    lea si, word        ; Load the address of the word
    lea di, guessed_word   ; Load the address of guessed_word
    mov cx, 5           ; Loop over 5 letters of the word
    xor bx, bx          ; Clear bx, will be used for checking the position of the letter
    xor dx, dx          ; Clear dx to track if letter was found

check_letter:
    mov dl, [si]        ; Load letter from the word
    cmp dl, al          ; Compare letter with user input
    je correct_guess    ; Jump to correct_guess if they are equal
    inc si              ; Move to the next letter in the word
    inc bx              ; Increment position counter
    loop check_letter   ; Repeat for all letters in the word

    ; If the letter wasn't found
    DisplayMessage incorrect_msg

    ; Increment the number of attempts
    inc attempts
    mov al, attempts
    cmp al, max_attempts
    je game_over        ; If max attempts reached, end the game

    ; Loop back to guess again
    jmp game_loop

correct_guess:
    ; Replace the corresponding underscore in guessed_word with the correct letter
    ReplaceChar

    ; Display correct guess message
    DisplayMessage correct_msg

    ; Check if the word is fully guessed
    CheckIfGuessed

    ; Continue guessing
    jmp game_loop

game_over:
    ; Game over message
    DisplayMessage lose_msg
    jmp end_game

end_game:
    ; Exit the program
    mov ah, 4Ch
    int 21h
end
