model small
.stack 100h
.data
	seed dw ?

.code 
.386

; Генератор на основе регистра сдвига с обратной связью 

public seed
public rand

rand proc 
    mov ah, 2 ; Получение текущего времени
    int 1Ah
    mov ah, 0
	
    ;mov ah, ch
	;mov ah, cl
	mov al, dh

	;add ax, 7
	;mov dx, 13
	;mul dx

    mov seed, ax 

    ret
rand endp

end