; Для каждой строки построить цифровую подпись
; посредством суммирования всех символов по модулю 2^64.

; Использовать полученные сигнатуры
; для проверки подлинности других строк.

model small
.stack 100h
.data
	main_string   db 255, ?, 255 dup("$") ; Главная строка
	tmp           db 2, ?, 2 dup(0) ; Хранение ввода пункта меню

	sum           dd 0b ; Хеши строк
	main_sum      dd 0b ; Хеш главной строки

	part1         dd 0b
	part2         dd 0b

	input_string  db 'Input string:',10,13,"$"

; ================================================================================

.code
.486

extrn print_menu:near
extrn print_result:near
extrn print_no_input:near
extrn print_no_string:near
extrn print_no_result:near

extrn io_file_read:near
extrn io_file_save:near

extrn io_result_true:near
extrn io_result_false:near

extrn flush:near

extrn buffer:byte

public work

start:
	mov ax, @data
	mov ds, ax

; =============== Контрольная позиция ===============

main:
	call print_menu ; Вызываем вывод меню на экран

	lea dx, tmp
	mov ah, 0ah
	int 21h

process: ; Обработка введенного пункта меню
	cmp tmp[2], '0'
	je exit
	cmp tmp[2], '1'
	je main
	cmp tmp[2], '2'
	je new_string
	cmp tmp[2], '3'
	je file_read
	cmp tmp[2], '4'
	je file_save
	cmp tmp[2], '5'
	je output

	call print_no_input
	jmp main

; =============== Ввод главной строки ===============

new_string:
	lea dx, input_string
	mov ah, 9
	int 21h

	lea dx, main_string
	mov ah, 0ah
	int 21h

	mov main_sum, 0b
	mov si, 2

new_string_loop:
	lodsb

	cmp al, 0Dh ; Проверка на конец строки
	je main

	call work_quadruple
	
	add main_sum, edx

	jmp new_string_loop

; =============== Обработка строк ===============

work proc near
	xor ax, ax
	xor si, si

	mov sum, 0

work_sign:
	mov al, buffer[esi]

	; Конец строки
	cmp ax, 0Dh
	je work_compare

	call work_quadruple
	
	add sum, edx

	inc si

	jmp work_sign

work_quadruple:
	cbw  ; al  -> ax
	cwde ; ax  -> eax
	cdq  ; eax -> edx:eax

	mov part1, eax
	mov part2, edx
	
	xor edx, edx

	add edx, part1
	add edx, part2

	ret

work_compare:
	mov eax, sum
	mov ebx, main_sum

	cmp eax, ebx
	jne work_write_false
	je work_write_true

work_write_true:
	call io_result_true
	ret
	
work_write_false:
	call io_result_false
	ret
work endp

; =============== Загрузка из файла ===============

file_read:
	cmp main_string[2], "$" ; Проверяем, есть ли  главная строка
	je no_string
	call io_file_read
	jmp main

; =============== Сохранение файла ===============

file_save:
	call io_file_save
	jmp main

; =============== Разное ===============

; Вывод результата на экран
output:
	call print_result
	jmp main

; Отсутствует главная строка
no_string:
	call print_no_string
	jmp main

; Отсутствует результат
no_result:
	call print_no_result
	jmp main

; =============== Конец программы ===============

exit:
	call flush
	mov ax, 4c00h
	int 21h

end