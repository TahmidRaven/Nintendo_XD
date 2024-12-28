; View demo at: https://youtu.be/keHJUwLnDZ0

SPEED=0affh    ; the bigger the slower   
; ENUMS for directions 
  UP		= 1         
  DOWN	= 2 
  RIGHT	= 3 
  LEFT	= 4       
; ENUMS for grow_state 
  NO_CHANGE	= 0 
  BIGGER	= 1 
  SMALLER	= 2 
; scancodes 
  UP_SC	= 48h 
  DOWN_SC	= 50h 
  RIGHT_SC	= 4Dh 
  LEFT_SC	= 4Bh       
  EXIT_SC	= 10h ; 'Q' - for Quit 
  RESTART_SC= 13h ; 'R' - for Restart  
; misc       
  NSEOI_OCW2 = 00100001b    
  PC_PIC	 = 20h 
 
.model small 
.stack 100h 
 
.data  
; variables that are used for snake structure    
; 'snake' array: each item holds: x cord, y cord, ascii char and attribute (always black background)  
; its length is 80x25=2000 (dimenstions of screen) 
; 5 first items are inited to white '*'-s from (20,10) to (20,14)  
  snake DD 0d3a0a14h,0f2a0b14h,0f2a0c14h,0f2a0d14h,0f2a0e14h   
  snake2 DW 1995 DUP(?) ; the bug:        definition of double-word-array  doesn't work properly with 'dup'   
  snake3 DW 1995 DUP(?) ; the workaround: defining two word-arrays 
   
  length DW 5           ; current length of snake    

; variables used for random 
  food_x    DB 0					; cordinates of the next food 
  food_y    DB 0					; 
  attribute DB 15					; color of next food 
  char      DB 41h				; char of next food 
  food_type DB 1  	; type of next food,
				0: '-' (makes snake smaller), o.w: ABC char  

; variables for current food 
  cur_food_x         DB 0 
  cur_food_y         DB 0 
  cur_food_type      DB 0  
  cur_food_char      DB 0     
  cur_food_attribute DB 0  
; flags 
  to_exit 		DB 0					; exit flag 
  to_restart 	DB 0					; restart flag 
  game_over 	DB 0					; game over flag 
; misc   
  direction 	DB UP				; 1-up,2-down,3-right,4-left   
  loop_counter 	DB 0                         
  loop_counter2 	DW 0  
  loop_counter3 	DB 0 
   
  grow_state 	DB NO_CHANGE ; options: NO_CHANGE, BIGGER or SMALLER 
                                              
  ezer_word  	DW 0 
  ezer_byte  	DB 0 
  ezer_byte2 	DB 0  
  direction_for_next_cycle DB UP  	; contains the direction for next
						  cycle in main_loop 
  one_before 	DB 0		; flag to use in 'erase_tail' (see there) 
 










                                             
 
.code    
  mov ax,@data ; ds<-@data 
  mov ds,ax    
   
  call print_food 
  call change_key_stroke_interrupt   ; changes the adress of routine resposible to response to key-stroke  
                                     ; to perform 'update_direction' 
  main_loop:     
      mov loop_counter,0 
      call actions  ; performs all tasks for one movement: upadtes snake on screen, checks collision etc   
  ;delay loop 
        delay_loop:  
          ;inner delay_loop      
          inner_delay_loop:   
               cmp to_exit,1         ; checks whether to exit 
               jz program_end  
               cmp game_over,1       ; checks for game-over state 
               jz game_over_loop 
               cmp to_restart,1      ; checks whether to restart 
               jz program_restart 
             inc loop_counter2 
             cmp loop_counter2,SPEED 
          jnz inner_delay_loop 
          mov loop_counter2,0 
           
          inc loop_counter      
          cmp loop_counter,0ffh 
        jnz delay_loop 
  jmp main_loop 
 
  game_over_loop:                     ; loop for game-over state. no action until 'R' or 'Q' are pressed 
    cmp to_exit,1 
    jz program_end 
    cmp to_restart,1 
    jz program_restart 
  jmp game_over_loop  
   
  program_restart:                    ; restarts game 
    call restart_game    
  jmp main_loop 
                
  program_end:                        ; exits game 
    mov ah,4ch 
    int 21h    
     
; -- routines -- ;   
    
  actions: ; actions to perform after per one move   
     mov al,direction_for_next_cycle  
     mov direction,al         
     call inc_random_values ; increases the values that are used for random 
     call erase_tail        ; erases last part of snake in the screen 
     call update_snake      ; updates cordinates of each part 
     call update_head       ; updates cordinates if the first part according to 'direction'  
     call handle_grow_state ; responsible for makeing the snake bigger or smaller      
     call print_snake       ; prints the snake on screen       
     call check_eating      ; checks if the snake's head is on the food 
     call check_collision   ; checks for collision of sbake with itself   
  ret ; used in main loop 
   
  check_eating: ; checks if the snake's head is on the food 
      ; ([di],[bx]) <-- head's (x,y) 
        lea di,snake 
        mov bx,di     
        inc bx         
      ; checks ([di],[bx])==(cur_food_x,cur_food_y) 
        mov al,cur_food_x     
        cmp ds:[di],al 
        jnz check_eating_end 
        mov al,cur_food_y     
        cmp ds:[bx],al       
        jnz check_eating_end 
      ; performs suitable actions for eating (adds or removes part of the snake)     
        cmp cur_food_type,0 
        jnz check_eating_label1 
        call remove_part  
        jmp check_eating_end: 
        check_eating_label1: 
        call add_part  
      check_eating_end:   
  ret ; used by 'actions' 
   
  add_part: ; adds part of the snake (cordinates, char and attribute)   
      mov grow_state,BIGGER 
    ; [di]=last part ,[bx]=new part   
      lea bx,snake  
      mov ax,length 
      shl ax,2 
      add bx,ax     
      mov di,bx   
      sub di,4  
    ; new part's cords <-- last part's cords     
      mov ax,ds:[di] 
      mov ds:[bx],ax    
    ; char and attribute 
      add bx,2    
      mov al,cur_food_char 
      mov ds:[bx],al 
      inc bx  
      mov al,cur_food_attribute 
      mov ds:[bx],al       
  ret ; used by 'check_eating' 
   
  remove_part:  
      mov grow_state,SMALLER 
      mov one_before,1       ; signs 'erase_tail' to erase the one-before-last part 
      call erase_tail 
  ret ; used by 'check_eating' 
   
  print_food: ; prints food after prev food was eaten according to food_x and food_y values  
      mov al,food_x   
      mov ah,food_y  
      print_food_loop: ; loop that runs until a vacant cordinate is found (al,ah) 
        inc al 
        inc ah 
        cmp al,80 
        jnz print_food_label_1 
        mov al,0 
        print_food_label_1:  
        cmp ah,25 
        jnz print_food_label_2 
        mov ah,0    
        print_food_label_2: 
        call check_cover  
        cmp dl,1 
      jz print_food_loop 
      mov cur_food_x,al   
      mov cur_food_y,ah     
      mov al,char 
      mov cur_food_char,al   
      mov al,attribute 
      mov cur_food_attribute,al  
      ; selects char for food according to food_type 
        mov dh,food_type 
        mov cur_food_type,dh 
        cmp dh,0               ; if cur_food_type==h then '-' is printed 
        jnz print_food_label_3 
        mov ezer_byte,'-'    
        jmp print_food_label_4  
        print_food_label_3:  
        mov dh,char 
        mov ezer_byte,dh 
      print_food_label_4: 
      ; print 
        ; changing cursor place 
           mov dh,cur_food_y 
           mov dl,cur_food_x  
           mov bh,0 
           mov ah,2 
           int 10h 
        ; print 
          mov ah,9 
          mov al,ezer_byte 
          mov bh,0     
          mov bl,attribute 
          mov cx,1       
          int 10h 
  ret ; used by ' handle_grow_state ' 
   
  update_snake: ; updates 'snake' after one move: change cordinate of each part to next part cordinates    
    ; bx points to next item, di points to prev item 
      lea bx,snake  
      mov ax,length 
      shl ax,2 
      add bx,ax 
      sub bx,4      
      mov di,bx   
      sub di,4  
    ; loop to pass cordinate of each part to its prev part   
      mov cx,length 
      dec cx     
      update_snake_loop:    
        mov ax,ds:[di]    
        mov ds:[bx],ax 
        sub bx,4 
        sub di,4    
      loop update_snake_loop 
  ret ; used by: 'actions'   
   
  update_head: ; update head cordiantes by the direction  
      ; ([di],[bx]) <-- head's (x,y) 
        lea di,snake  
        mov bx,di    
        inc bx 
       
      cmp direction,UP 
      jnz update_head_label1     
      dec ds:[bx] 
      cmp ds:[bx],0ffh   
      jnz update_head_end  
      mov ds:[bx],024      ; 'jump' from top border to bottom border 
      jmp update_head_end 
      update_head_label1: 
      cmp direction,DOWN  
      jnz update_head_label2  
      inc ds:[bx]  
      cmp ds:[bx],25   
      jnz update_head_end  
      mov ds:[bx],0       ; 'jump' from bottom border to top border 
      jmp update_head_end 
      update_head_label2: 
      cmp direction,RIGHT   
      jnz update_head_label3  
      inc ds:[di]         
      cmp ds:[di],80   
      jnz update_head_end  
      mov ds:[di],0       ; 'jump' from right border to left border 
      jmp update_head_end 
      update_head_label3: 
      cmp direction,LEFT   
      jnz update_head_end  
      dec ds:[di]           
      cmp ds:[di],0ffh   
      jnz update_head_end  
      mov ds:[di],79       ; 'jump' from left border to right border 
      update_head_end:  
  ret ; used by 'actions'  
   
  check_collision: ; checks if the snake collided itself 
      ; ax<-head's cordinates 
        lea di,snake    
        mov al,ds:[di] 
        inc di 
        mov ah,ds:[di] 
        add di,3 
      ; loop. (it's like check_cover but without the head) 
        mov cx,length   
        dec cx  
        check_collision_loop:  
          cmp ds:[di],ax 
          jnz check_collision_continue 
          mov game_over,1    ; on collision, game_over is set to 1 
          mov cx,1 
          check_collision_continue:                                 
          add di,4 
        loop check_collision_loop   
        
  ret ; used by 'actions' 
              
  check_cover: ; checks if the snake covers the cordinate (x=al,y=ah). is so dl=1 else dl=0     
  lea di,snake 
  mov dl,0 
  mov cx,length   
        check_cover_loop:  
          cmp ds:[di],ax 
          jnz check_cover_continue
          mov dl,1    ; cover found 
          mov cx,1 
          check_cover_continue:                                 
          add di,4 
        loop check_cover_loop  
  ret ; used by 'print_food' 
   
  handle_grow_state:       
    cmp grow_state,BIGGER  
    jnz handle_grow_state_label1  
    inc length 
    call print_food 
    jmp handle_grow_state_end   
    handle_grow_state_label1:  
    cmp grow_state,SMALLER  
    jnz handle_grow_state_end       
    dec length 
    call print_food 
    handle_grow_state_end:   
    mov grow_state,NO_CHANGE 
  ret ; used by 'actions' 
   
  print_snake: ; prints the whole snake      
     mov cx,length 
     mov ezer_word,cx  
     mov cx,1  
     lea di,snake 
     print_snake_loop:  
       ; setting of cordinates 
         ; set cursor-x      
           mov ah,2     
           mov dl,ds:[di]  
         ; set cursor-y 
           inc di 
           mov dh,ds:[di]   
         mov bh,0 
         int 10h 
       ; print      
         inc di 
         mov al,ds:[di]     
         inc di   
         mov bl,ds:[di] 
         mov ah,9  
         mov bh,0 
         int 10h 
         inc di   
         dec ezer_word 
     cmp ezer_word,0  
     jnz print_snake_loop 
  ret ; used by 'actions'    
   
  
 
erase_tail: ; erases last part in snake. if one_before==1 then one before last part is erased 
     ; bx<-[last part]      
     lea bx,snake  
     mov ax,length 
     shl ax,2 
     add bx,ax 
     sub bx,4    
     ; if one_before=1 then one before last part is erased (used when '-' was eaten) 
       cmp one_before,1 
       jnz erase_tail_continue 
       sub bx,4     
       mov one_before,0 
       erase_tail_continue: 
     ; set cursor-x 
     mov dl,ds:[bx]  
     ; set cursor-y 
     inc bx 
     mov dh,ds:[bx]   
     mov bh,0   
     mov ah,2 
     int 10h 
     ; prints blank char  
     mov bh,0   
     mov cx,1 
     mov ah,9 
     mov al,' '  
     mov bl,0 
     int 10h 
  ret ; used by: 'actions'  
   
  inc_random_values: ; increases variables that are used for random 
                     ; food_x and food_y range: [0,80] and [0,25] respectively 
                     ; char and attribute range: [41h,5ah] and [1,ffh] respectively  
                     ; food_type range: [0,8] 
    inc food_x 
    inc food_y 
    inc char 
    inc attribute 
    cmp food_x,80 
    jnz IRV_label1 
    mov food_x,0 
    IRV_label1: 
    cmp food_y,25 
    jnz IRV_label2 
    mov food_y,0 
    IRV_label2: 
    cmp char,5bh 
    jnz IRV_label3 
    mov char,41h 
    IRV_label3: 
    cmp attribute,10000b 
    jnz IRV_label4 
    mov attribute,1 
    IRV_label4:     
    inc food_type 
    cmp food_type,9 
    jnz IRV_label5 
    mov food_type,0 
    IRV_label5: 
  ret ; used in main program in main_loop 
   
  update_direction:	; activated when key is pressed. this routine
				 changes direction, exit program, restarts game 
 				; or ignores the key-strore according to the
				 pressed key                               
    in al,60h 
    ; checks if exit button was pressed     
    cmp al,EXIT_SC 
    jnz restart_check:  
    mov to_exit,1 
    jmp update_direction_end   
    ; checks if restart button was pressed 
    restart_check:     
    cmp al,RESTART_SC 
    jnz left_arrow_check  
    mov to_restart,1 
    jmp update_direction_end  
    ; checks if left arrow was pressed      
    left_arrow_check: 
    cmp al,LEFT_SC 
    jnz right_arrow_check   
    cmp direction,RIGHT 
    jz update_direction_end ; LEFT is forbidden when the direction is RIGHT  
    mov direction_for_next_cycle,LEFT 
    jmp update_direction_end   
    ; checks if right arrow was pressed  
    right_arrow_check:    
    cmp al,RIGHT_SC 
    jnz up_arrow_check   
    cmp direction,LEFT 
    jz update_direction_end ; RIGHT is forbidden when the direction is LEFT  
    mov direction_for_next_cycle,RIGHT 
    jmp update_direction_end   
    ; checks if right arrow was pressed  
    up_arrow_check:    
    cmp al,UP_SC 
    jnz down_arrow_check   
    cmp direction,DOWN 
    jz update_direction_end ; UP is forbidden when the direction is DOWN  
    mov direction_for_next_cycle,UP 
    jmp update_direction_end   
    ; checks if right arrow was pressed  
    down_arrow_check:   
    cmp al,DOWN_SC 
    jnz update_direction_end   
    cmp direction,UP 
    jz update_direction_end ; DOWN is forbidden when the direction is UP  
    mov direction_for_next_cycle,DOWN 
    jmp update_direction_end 
    ; routine end    
    update_direction_end:    
    mov al,NSEOI_OCW2 ; instruction to the controller to perform Non Specific End Of Interrupt 
    out PC_PIC, al 
   iret ; used by main program in inner_inner_loop 
   
  change_key_stroke_interrupt: ; changes the address of key-stroke interruption (in IVT) 
                               ; to adress of 'update_direction' 
      mov ax,0 
      mov es,ax     
      mov di,09h*4    
      mov si,0a0h*4 
      lea ax,update_direction 
      mov es:[di],ax 
      mov es:[di+2],cs 
  ret ; called by main program 
   
  restart_game: ; restarts game. restores inital values of variables 
      mov game_over,0 
      mov to_restart,0    
      mov direction_for_next_cycle,UP 
      mov direction,UP 
      call clr_scr 
      ; restarts snake 
      mov length,5 
      lea bx,snake 
      mov ds:[bx],0a14h  
      add bx,2  
      mov ds:[bx],0d3ah  
      add bx,2 
      mov ds:[bx],0b14h  
      add bx,2  
      mov ds:[bx],0f2ah  
      add bx,2 
      mov ds:[bx],0c14h  
      add bx,2 
      mov ds:[bx],0f2ah  
      add bx,2 
      mov ds:[bx],0d14h  
      add bx,2   
      mov ds:[bx],0f2ah  
      add bx,2 
      mov ds:[bx],0e14h    
      add bx,2 
      mov ds:[bx],0f2ah 
      ; restarts food            
      mov food_x,0 
      mov food_y,0 
      mov attribute,15 
      mov food_type,1   
      mov char,41h 
      call print_food 
  ret ; used by main program in program_restart 
   
  clr_scr: ; clears screen 
     mov ezer_byte2,0 
     mov ezer_byte,0  
     mov bh,0  
     clr_scr_y_loop:   
       ; set cursor-x 
       mov dh,ezer_byte2  
       inc ezer_byte2 
       clr_scr_x_loop: 
         ; set cursor-y 
         mov dl,ezer_byte   
         inc ezer_byte  
         mov ah,2 
         int 10h 
         ; prints blank char   
         mov cx,1 
         mov ah,9 
         mov al,' '  
         mov bl,0 
         int 10h  
       cmp ezer_byte,80 
       jnz clr_scr_x_loop  
       mov ezer_byte,0    
     cmp ezer_byte2,25 
     jnz clr_scr_y_loop 
  ret ; used by 'restart_game' 
   
End 
