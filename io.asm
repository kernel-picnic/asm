; Модуль загрузки и сохранения из/в файл

model small
.stack 100h
.data
	buffer          dd 1000, ?, 1000 dup(?) ; Буффер

	input_file      db 20, ?, 20 dup(0)
	output_file     db 20, ?, 20 dup(0)

	file_input_str  db 'Input filename: ',10,13,"$"
	file_error_str  db 'Error while processing file. ;-(',10,13,"$"

.code
.486

extrn result:byte
extrn result_size:abs

public empty_buffer
public buffer
public io_file_read
public io_file_save

; =============== Загрузка строк из файла ===============

io_file_read proc near
	jmp flush

io_file_read_continue:
	lea dx, file_input_str
	mov ah, 9
	int 21h

	lea dx, input_file
	mov ah, 0ah
	int 21h

	mov si, 2

io_file_read_remove_enter:
	inc si
	cmp input_file[esi], 0Dh
	je io_file_read_remove_enter_do
	jne io_file_read_remove_enter

io_file_read_remove_continue:
	mov ax, 3d00h ; Открываем для чтения
	lea dx, input_file ; DS:DX указатель на имя файла
	add dx, 2
	int 21h ; В ax деcкриптор файла
	jc file_error ; Если поднят флаг С, то ошибка открытия

	mov bx, ax ; Копируем в bx указатель файла
	xor cx, cx
	xor dx, dx
	mov ax, 4200h
	int 21h ; Идем к началу файла
	lea dx, buffer

file_read_loop:
	mov ah, 3fh ; Будем читать из файла
	mov cx, 1 ; 1 байт
	int 21h

	inc dx

	cmp ax, cx ; Если достигнуть EoF или ошибка чтения
	jnz file_read_close ; То закрываем файл закрываем файл

	jmp file_read_loop

io_file_read_remove_enter_do:
	mov input_file[esi], 0h
	;mov input_file[0], 0h
	;mov input_file[1], 0h
	jmp io_file_read_remove_continue

file_read_close: ; Закрываем файл, после чтения
	mov ah, 3eh
	int 21h

	ret
io_file_read endp

; =============== Сохранение файла ===============

io_file_save proc near
	lea dx, file_input_str
	mov ah, 9
	int 21h

	lea dx, output_file
	mov ah, 0ah
	int 21h

	mov bx, 2

io_file_save_remove_enter:
	inc bx
	cmp output_file[ebx], 0Dh
	je io_file_save_remove_enter_do
	jne io_file_save_remove_enter

io_file_save_remove_continue:
	mov ah, 3Ch ; Функция DOS 3Ch (создание файла)
	lea dx, output_file
	add dx, 2
	xor cx, cx ; Нет атрибутов - обычный файл
	int 21h ; Обращение к функции DOS
	jnc file_save_process ; Если нет ошибки, то продолжаем
	jmp file_error

file_save_process:
	mov bx, ax ; Дескриптор файла
	mov cx, 1 ; Размер данных
	xor dx, dx
	xor di, di

file_save_process_loop:
	mov ah, 40h ; Функция DOS 40h (запись в файл)
	mov dx, si ; Данные
	int 21h

	jc file_error ; Вывод сообщения об ошибке

	inc di

	cmp result[di], "$"
	je file_save_close

	inc si

	jmp file_save_process_loop

io_file_save_remove_enter_do:
	mov output_file[ebx], 0h
	;mov output_file[0], 0h
	;mov output_file[1], 0h
	jmp io_file_save_remove_continue
 
file_save_close:
	mov ah, 3Eh ; Функция DOS 3Eh (закрытие файла)
	int 21h
	jnc exit ; Если нет ошибки, то выход из программы
	jmp file_error ; Вывод сообщения об ошибке
io_file_save endp

; =============== Ошибка обработки файла ===============

file_error:
	lea dx, file_error_str
	mov ah, 9
	int 21h

	ret

; =============== Очистка результата ===============

flush proc near
	mov cx, result_size
	xor si, si

flush_result:
	mov result[si], "$"
	inc si
	loop flush_result

	mov cx, 255
	xor si, si

flush_buffer:
	mov buffer[si], 03h
	inc si
	loop flush_buffer

	mov cx, 18
	mov si, 2

flush_input_file:
	mov input_file[si], 0h
	inc si
	loop flush_input_file

	mov cx, 18
	mov si, 2

flush_output_file:
	mov output_file[si], 0h
	inc si
	loop flush_output_file

	jmp io_file_read_continue
flush endp

empty_buffer proc near
empty_buffer_loop:
	mov buffer[esi], 03h
	inc esi
	loop empty_buffer_loop

	ret
empty_buffer endp

exit:
	ret

end