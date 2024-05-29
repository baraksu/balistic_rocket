.MODEL small
.STACK 100h
.DATA    

logo db  "  ____        _ _ _     _   _        _____            _        _   ",13,10
logo1 db " |  _ \      | | (_)   | | (_)      |  __ \          | |      | | ",13,10
logo2 db " | |_) | __ _| | |_ ___| |_ _  ___  | |__) |___   ___| | _____| |_ ",13,10
logo3 db " |  _ < / _` | | | / __| __| |/ __| |  _  // _ \ / __| |/ / _ \ __|",13,10
logo4 db " | |_) | (_| | | | \__ \ |_| | (__  | | \ \ (_) | (__|   <  __/ |_ ",13,10
logo5 db " |____/ \__,_|_|_|_|___/\__|_|\___| |_|  \_\___/ \___|_|\_\___|\__|",13,10,"$"

createdby db "Created by Ori Rosenwasser",13,10,"$"

msg1 db 13,10,"Enter x velocity (00-99), (pixels per seconds): $"
msg2 db 13,10,"Enter initial y velocity (00-99), (pixels per seconds): $"

msg3 db "Enter space to start again, esc to exit program.",13,10,"$"

t0ms db ? ; t0, milliseconds
t0sec db ? ;t0, seconds
t0min db ? ;t0, minutes
seconds db ? ;delta t, seconds
ms db ?  ;delta t, milliseconds
minutes_passed db 0 ;if the minute has changed, add 60 seconds before subtracting t0sec
t_sq dw 0 ; used to calculate t^2

vx db ? ;x velocity
g db 5 ;gravity (gravity = 10 because if I divide it by two in 0.5at^2 it sometimes gives a divide error)
v0y db ? ; initial y velocity
color db 15 ; the color of the rocket
x0 dw 10 ; initial x coordinate
y0 dw 190 ; initial y coordinate
x_coordinate dw 10  ; current x coordinate 
y_coordinate dw 190 ; current y coordinate
y_value dw 0
x_value dw 5 ;r
decision dw ?

.CODE

proc get_velocity ; input: offset of a message and offset of where the entered input goes to. output: entered input.
    push bp
    mov bp,sp
    push ax
    push bx
    push dx
    
    mov dx, [bp + 6]
    mov ah,09h
    int 21h
    
    firstdigit:
    mov ah,00h
    int 16h
    
    cmp al,30h    ;check if valid
    jb firstdigit
    
    cmp al,39h
    ja firstdigit
    
    mov dl,al   ;valid
    mov ah,02h
    int 21h
    
    sub al,30h
    mov bl,10
    mul bl
    mov bx,[bp + 4]
    mov [bx],al
    
    seconddigit:
    mov ah,00h
    int 16h
    
    cmp al,30h    ;check if valid
    jb seconddigit
    
    cmp al,39h
    ja seconddigit
    
    mov dl,al   ;valid
    mov ah,02h
    int 21h
    
    ;mov ah,01h
    ;int 21h
    sub al,30h
    add [bx],al                
    
    pop dx
    pop bx
    pop ax
    pop bp
    ret
endp get_velocity    

proc get_t0 ;no input, output: the current time in t0sec and t0min
    push ax
    push cx
    push dx
    
    mov ah,2Ch
    int 21h
    
    mov t0sec,dh
    mov t0min,cl
    mov t0ms,dl
    
    mov minutes_passed,0
    
    pop dx
    pop cx
    pop ax
    ret
endp get_t0    
    
proc get_delta_t ;input: t0 (t0sec, t0min, t0ms). output: the number of seconds passed from t0 in seconds and milliseconds in ms
    push ax
    push cx
    push dx
    
    mov ah,2Ch
    int 21h
    
    cmp cl,t0min
    je same_minute
    mov minutes_passed,60
    
    same_minute:
    
    mov al,minutes_passed
    add al,dh
    sub al,t0sec
    
    mov seconds,al
    
    ; Adjust milliseconds
    cmp dl,t0ms
    jnb above
    
    below:
    add dl,64h  
    dec seconds
    
    above:
    sub dl,t0ms
    mov ms,dl
    
    pop dx
    pop cx
    pop ax
    ret
endp get_delta_t


proc update_x_coordinate ; input: delta t (seconds, ms). output: sp points at the updated x coordinates. 
    push dx
    push ax
    push bx
    push cx
  
    mov dx,x0   ;x(t) = x0 + vt
    mov al,vx
    mul seconds 
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
endp update_x_coordinate   

proc update_y_coordinate ;input: delta t (seconds, ms). output: sp points at the updated y coordinates.
    
    push dx
    push ax
    push bx
    
    ;y(t) = y0 + v0y*t + 0.5at^2
    
    ; y0
    mov dx,y0 
    
    ; v0y*t
    mov al,v0y 
    mul seconds
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
    mov al,seconds
    mul al
    mov t_sq,ax
    
    ;2*sec*ms
    mov al,seconds
    mul ms
    mov bl,50
    div bl
    xor ah,ah
    add t_sq,ax
    
    ;ms^2 will be less than 1 anyway so it is pointless 
    
    ; 0.5at^2
    mov ax,t_sq
    mul g
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

proc draw_circle
 
    push ax
    push bx
    push cx
    push dx
    push y_value
    push x_value 
    
    mov bx, x_value
    mov ax,2
    mul bx
    mov bx,3
    sub bx,ax ; E=3-2r
    mov decision,bx
    
    mov al,color ;color goes in al
    mov ah,0ch
    
    drawcircle:
    mov al,color ;color goes in al
    mov ah,0ch
    
    mov cx, x_value ;Octonant 1
    add cx, x_coordinate ;( x_value + x_coordinate,  y_value + y_coordinate)
    mov dx, y_value
    add dx, y_coordinate
    int 10h
    
    mov cx, x_value ;Octonant 4
    neg cx
    add cx, x_coordinate ;( -x_value + x_coordinate,  y_value + y_coordinate)
    int 10h
    ; 
    mov cx, y_value ;Octonant 2
    add cx, x_coordinate ;( y_value + x_coordinate,  x_value + y_coordinate)
    mov dx, x_value
    add dx, y_coordinate
    int 10h
    ; 
    mov cx, y_value ;Octonant 3
    neg cx
    add cx, x_coordinate ;( -y_value + x_coordinate,  x_value + y_coordinate)
    int 10h
    
    mov cx, x_value ;Octonant 8
    add cx, x_coordinate ;( x_value + x_coordinate,  -y_value + y_coordinate)
    mov dx, y_value
    neg dx
    add dx, y_coordinate
    int 10h
    ; 
    mov cx, x_value ;Octonant 5
    neg cx
    add cx, x_coordinate ;( -x_value + x_coordinate,  -y_value + y_coordinate)
    int 10h
    
    mov cx, y_value ;Octonant 7
    add cx, x_coordinate ;( y_value + x_coordinate,  -x_value + y_coordinate)
    mov dx, x_value
    neg dx
    add dx, y_coordinate
    int 10h
    ; 
    mov cx, y_value ;Octonant 6
    neg cx
    add cx, x_coordinate ;( -y_value + x_coordinate,  -x_value + y_coordinate)
    int 10h
    
    condition1:
    cmp decision,0
    jg condition2      
    ;e<0
    mov cx, y_value
    mov ax, 2
    imul cx ;2y
    add ax, 3 ;ax=2y+3
    mov bx, 2
    mul bx  ; ax=2(2y+3)
    add decision, ax
    mov bx, y_value
    mov dx, x_value
    cmp bx, dx
    ja readkey  
    inc y_value
    jmp drawcircle
    
    condition2:
    ;e>0
    mov cx, y_value 
    mov ax,2
    mul cx  ;cx=2y
    mov bx,ax
    mov cx, x_value
    mov ax, -2
    imul cx ;cx=-2x
    add bx,ax
    add bx,5;bx=5-2z+2y
    mov ax,2
    imul bx ;ax=2(5-2z+2y)       
    add decision,ax
    mov bx, y_value
    mov dx, x_value
    cmp bx, dx
    ja donedrawing
    dec x_value    
    inc y_value
    jmp drawcircle
    
    donedrawing:
    
    pop x_value
    pop y_value
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp draw_circle
    
proc delay
    pusha
    mov cx, 03h   ;High Word
    mov dx, 4240h ;Low Word
    mov ah, 86h   ;Wait
    int 15h
    popa
    ret
endp delay
             
start: 
 
mov ax,@DATA
mov ds, ax

lea dx,logo
mov ah,09h
int 21h

mov dx,offset createdby
int 21h

push offset msg1
push offset vx
call get_velocity

push offset msg2
push offset v0y
call get_velocity

mov ah,0 
mov al,13h
int 10h ;call graphics interrupt

mov cx,x0
mov dx,y0

mov x_coordinate,cx
mov y_coordinate,dx
mov color,15

call get_t0
call draw_circle
;call delg


redraw:
call get_delta_t
call update_x_coordinate
call update_y_coordinate

;erase old square
mov color,0 
call draw_circle

;draw new
pop y_coordinate
pop x_coordinate

cmp x_coordinate,315
ja stopanimation   

cmp y_coordinate,195
ja stopanimation

mov color,15
call draw_circle
call delay
jmp redraw

stopanimation:
mov ax,03h
int 10h

mov dl,t0ms
mov ah,02h
int 21h

lea dx,msg3
mov ah,09h
int 21h

readkey:
mov ah,01h
int 16h

jz readkey

mov ah,00
int 16h ;wait for keypress

cmp ax,3920h ;space
je start

cmp ax,011Bh  ;esc
je exit

jmp readkey 
 
;==========================
exit:
 mov ah,4ch
 int 21h 

END Start
