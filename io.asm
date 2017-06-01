; Модуль загрузки и сохранения из/в файл

model small
.stack 100h
.data
	buffer          db 255, ?, 255 dup('$') ; Буффер

	input_file      db 'C:\strings', 0h
	output_file     db 'output.txt', 0h

	file_error_str  db 'Error while processing file. ;-(',10,13,"$"

.code
.486

extrn result:byte
extrn result_size:abs

public buffer
public io_file_read
public io_file_save

; =============== Загрузка строк из файла ===============

io_file_read proc near
	mov ax, 3d00h ; Открываем для чтения
	lea dx, input_file ; DS:DX указатель на имя файла
	int 21h ; В ax деcкриптор файла
	jc file_error ; Если поднят флаг С, то ошибка открытия

	mov bx, ax ; Копируем в bx указатель файла
	xor cx, cx
	xor dx, dx
	mov ax, 4200h
	int 21h ; Идем к началу файла
	lea dx, buffer

	jmp flush

file_read_loop:
	mov ah, 3fh ; Будем читать из файла
	mov cx, 1 ; 1 байт
	int 21h

	inc dx

	cmp ax, cx ; Если достигнуть EoF или ошибка чтения
	jnz file_read_close ; То закрываем файл закрываем файл

	jmp file_read_loop

file_read_close: ; Закрываем файл, после чтения
	mov ah, 3eh
	int 21h

	ret
io_file_read endp

; =============== Сохранение файла ===============

io_file_save proc near
	mov ah, 3Ch ; Функция DOS 3Ch (создание файла)
	lea dx, output_file
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
	mov buffer[si], "$"
	inc si
	loop flush_buffer

	jmp file_read_loop
flush endp

exit:
	ret

end