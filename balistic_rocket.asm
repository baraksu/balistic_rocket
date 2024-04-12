.MODEL small
.STACK 100h

.DATA

 
t0sec db ? ;t0, seconds
t0min db ? ;t0, minutes
seconds_passed db ? ;delta t, seconds
ms db ?  ;delta t, milliseconds
minutes_passed db 0 ;if the minute has changed, add 60 seconds before subtracting t0sec
t_sq dw 0 ; used to calculate t^2

vx db 35 ;x velocity
ay db 20 ;y acceleration
v0y db 55 ; initial y velocity
color db 15
x0 dw 10
y0 dw 150
x_coordinate dw 10
y_coordinate dw 150

y1 dw 150

.CODE

proc get_t0  ;puts the currrent time in t0sec and t0min
    push ax
    push cx
    push dx
    
    mov ah,2Ch
    int 21h
    
    mov t0sec,dh
    mov t0min,cl
    
    cmp dl,50    ;in order to get the most accurate t0sec, we need to round the seconds according to the milliseconds
    jb roundDown
    ;round up
    inc t0sec
     
    roundDown:
    
    pop dx
    pop cx
    pop ax
    ret
endp get_t0    
    
proc get_delta_t ;puts the number of seconds passed from t0 in seconds_passed and milliseconds in ms
    push ax
    push cx
    push dx
    
    mov ah,2Ch
    int 21h
    
    cmp cl,t0min
    
    je samemin
    mov minutes_passed,60
    
    samemin: 
    
    mov al,minutes_passed
    add al,dh
    sub al,t0sec
    
    mov seconds_passed,al
    mov ms,dl
    
    pop dx
    pop cx
    pop ax
    ret
endp get_delta_t

proc update_x_coordinate ; x(t) = x0 + vt
    push dx
    push ax
    push bx
    push cx
  
    mov dx,x0
    mov al,vx
    mul seconds_passed 
    add dx,ax
    
    xor ax,ax
    mov al,vx
    mul ms
    mov bl,100
    div bl 
    xor ah,ah
    add dx,ax
    
    pop cx
    pop bx
    
    mov bp,sp
    mov ax,[bp + 4]
    mov [bp + 4],dx
    
    xor ax,[bp + 2]
    xor [bp + 2],ax
    xor ax,[bp + 2]
    
    mov dx,ax
    pop ax
    
    ret
endp update_x_coordinate   ;sp points at the updated x coordinates

proc update_y_coordinate ;y(t) = y0 + v0y*t + 0.5at^2
    
    push dx
    push ax
    push bx
    
    ; y0
    mov dx,y0 
    
    ; v0y*t
    mov al,v0y 
    mul seconds_passed
    sub dx,ax
    
    xor ax,ax
    mov al,v0y
    mul ms
    mov bl,100
    div bl 
    xor ah,ah
    sub dx,ax
    
    ; 0.5at^2 , t^2 = sec^2 + 2*sec*ms + ms^2
    
    ;sec^2
    mov al,seconds_passed
    mul al
    mov t_sq,ax
    
    ;2*sec*ms
    mov al,seconds_passed
    mul ms
    mov bl,50
    div bl
    xor ah,ah
    add t_sq,ax
    
    ;ms^2 will be less than 1 anyway so it is pointless 
    
    ; 0.5at^2
    mov ax,t_sq
    mov bl,2
    div bl
    mul ay
    add dx,ax
    
    pop bx
    
    mov bp,sp
    mov ax,[bp + 4]
    mov [bp + 4],dx
    
    xor ax,[bp + 2]
    xor [bp + 2],ax
    xor ax,[bp + 2]
    
    mov dx,ax
    pop ax
    ret
endp update_y_coordinate    

proc draw_square
    push ax
    push cx
    push dx
    
    mov cx,x_coordinate
    mov dx,y_coordinate
    mov al,color
    mov ah,0Ch
    int 10h
    inc dx
    int 10h
    inc cx 
    int 10h
    dec dx
    int 10h

    pop dx
    pop cx
    pop ax
    ret
endp draw_square
             
start: 
 
mov ax,@DATA
mov ds, ax

mov ah,0 
mov al,13h
int 10h ;call graphics interrupt

call get_t0
call draw_square


redraw:
call get_delta_t
call update_x_coordinate
call update_y_coordinate

;erase old square
mov color,0 
call draw_square

;draw new
pop y_coordinate
pop x_coordinate   

mov color,15
call draw_square
jmp redraw



;==========================
readkey:
 mov ah,00
 int 16h ;wait for keypress
;==========================
exit:
 mov ah,00 ;again subfunc 0
 mov al,03 ;text mode 3
 int 10h ;call int
 mov ah,04ch
 mov al,00 ;end program normally
 int 21h 

END Start
