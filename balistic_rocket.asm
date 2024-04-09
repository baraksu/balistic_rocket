.MODEL small
.STACK 100h

.DATA

xv db 10  ;x velocity
t0sec db ? ;t0, seconds
t0min db ? ;t0, minutes
seconds_passed db ? ;delta t, seconds
millis db ?  ;delta t, milliseconds
minutes_passed db 0 ;if the minute has changed, add 60 seconds before subtracting t0sec

color db 15
x_coordinate dw 10
y_coordinate dw 100

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
    
proc get_delta_t ;puts the number of seconds passed from t0 in seconds_passed and milliseconds in millis
    push ax
    push cx
    push dx
    
    mov ah,2Ch
    int 21h
    
    cmp cl,t0min
    
    je samemin
    add minutes_passed,60
    
    samemin: 
    
    mov al,minutes_passed
    add al,dh
    sub al,t0sec
    
    mov seconds_passed,al
    mov millis,dl
    
    pop dx
    pop cx
    pop ax
    ret
endp get_delta_t  

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

call draw_square

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
