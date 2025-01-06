; Wordle-like Game with Random Word Selection
; Guess a 4-letter word from a collection of words
; '*' means correct letter in correct position
; '+' means correct letter in wrong position
; '-' means letter not in word

.model small
.stack 100h
.data
    ; Array of 4-letter words
    word_array      db 'FOOD'
                    db 'FEET'
                    db 'HAIR'
                    db 'HEAD'
                    db 'EYES'
                    db 'LAMB'
                    db 'BATS'
                    db 'CODE'
    array_size      equ 8              ; Number of words in array
    target_word     db 4 dup(?)        ; Selected word to guess
    guess           db 5 dup('$')      ; Store player's guess
    input_prompt    db 'Enter a 4-letter word: $'
    correct_msg     db 'You won! $'
    result          db 5 dup('$')      ; Store result pattern
    newline         db 13, 10, '$'
    seed            dw 0               ; For random number generation
    
.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Initialize random seed using system timer
    mov ah, 00h
    int 1Ah         ; Get system time (CX:DX = number of clock ticks since midnight)
    mov seed, dx    ; Use lower word of clock ticks as seed
    
    ; Select random word
    mov ax, seed
    xor dx, dx
    mov cx, array_size
    div cx          ; DX contains remainder (0 to array_size-1)
    
    ; Copy selected word to target_word
    mov cx, 4       ; Word length
    mov si, dx      ; Selected index
    mov ax, 4       ; Multiply by 4 to get byte offset
    mul si
    mov si, ax
    lea di, target_word
    copy_word:
        mov al, word_array[si]
        mov [di], al
        inc si
        inc di
        loop copy_word
    
game_loop:
    ; Clear previous guess
    mov cx, 4
    lea si, guess
    mov al, '$'
    clear_guess:
        mov [si], al
        inc si
        loop clear_guess
    
    ; Show prompt
    lea dx, input_prompt
    mov ah, 9
    int 21h
    
    ; Get 4 letters
    mov cx, 4
    lea si, guess
    input_loop:
        mov ah, 1       ; Read character
        int 21h
        
        ; Convert to uppercase
        cmp al, 'a'
        jl store_char
        cmp al, 'z'
        jg store_char
        sub al, 32      ; Convert to uppercase
        
    store_char:
        mov [si], al
        inc si
        loop input_loop
    
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Compare guess with target
    mov cx, 4           ; Check 4 letters
    lea si, guess
    lea di, target_word
    lea bx, result
    
    ; First pass: Check for exact matches
    check_exact:
        mov al, [si]
        cmp al, [di]
        jne not_exact
        mov byte ptr [bx], '*'    ; Exact match
        jmp next_char
    not_exact:
        mov byte ptr [bx], '-'    ; No match yet
    next_char:
        inc si
        inc di
        inc bx
        loop check_exact
    
    ; Second pass: Check for letters in wrong position
    mov cx, 4
    lea si, guess
second_pass:
    cmp byte ptr result[si-guess], '*'  ; Skip if already matched
    je skip_letter
    
    push cx
    mov cx, 4
    lea di, target_word
check_letter:
    mov al, [si]
    cmp al, [di]
    jne continue_inner
    cmp byte ptr result[di-target_word], '*'  ; Skip if target letter already matched
    je continue_inner
    mov byte ptr result[si-guess], '+'  ; Letter exists in wrong position
continue_inner:
    inc di
    loop check_letter
    pop cx
    
skip_letter:
    inc si
    loop second_pass
    
    ; Print result pattern
    lea dx, result
    mov ah, 9
    int 21h
    
    ; Print newline
    lea dx, newline
    mov ah, 9
    int 21h
    
    ; Check if won (all stars)
    mov cx, 4
    lea si, result
    mov bl, 1          ; Flag for win
check_win:
    cmp byte ptr [si], '*'
    jne not_won
    inc si
    loop check_win
    jmp winner
    
not_won:
    jmp game_loop
    
winner:
    lea dx, correct_msg
    mov ah, 9
    int 21h
    
    ; Exit program
    mov ah, 4ch
    int 21h
    
main endp
end main