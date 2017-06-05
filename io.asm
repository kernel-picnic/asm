; Модуль загрузки и сохранения из/в файл

model small
.stack 100h
.data
	buffer_size     equ 1600
	buffer          dw buffer_size, ?, buffer_size dup(?) ; Буффер
	result_exists   db 0

	handle1         dw 0 ; Дескриптор файла 1
	handle2         dw 0 ; Дескриптор файла 2

	file_length     equ 50 ; Длинна вводимого пути файлов
	input_file      db file_length, ?, file_length dup(0)
	output_file     db file_length, ?, file_length dup(0)
	result_file     db 12 dup(0) ; Temp файл для хранения результата

	file_input_str  db 'Input filename: ',10,13,"$"
	file_error_str  db 'Error while processing file. ;-(',10,13,"$" 

.code
.486

extrn work:near
extrn print_no_result:near
extrn rand:near
extrn seed:word

public flush
public buffer

public io_file_read
public io_file_save

public io_result_true
public io_result_false

public print_result

; =============== Загрузка строк из файла ===============

io_file_read proc near
	call flush
	
	; Создаем temp файл
	; Файл будет создан в текущей директории
	mov result_file[0], "."
	mov result_file[1], "/"

	mov ah, 5Ah
	lea dx, result_file
	int 21h
	mov bx, ax
	mov ah, 3Eh
	int 21h

	lea dx, file_input_str
	mov ah, 9
	int 21h

	lea dx, input_file
	mov ah, 0ah
	int 21h

	mov si, 1

; Удаляем enter, иначе файл не будет обработан
io_file_read_remove_enter:
	inc si
	cmp input_file[esi], 0Dh
	jne io_file_read_remove_enter

	mov input_file[esi], 0h
	xor si, si

	mov ax, 3d00h ; Открываем для чтения
	lea dx, input_file ; DS:DX указатель на имя файла
	add dx, 2
	int 21h ; В ax деcкриптор файла
	jc io_file_error ; Если поднят флаг С, то ошибка открытия

	mov handle1, ax ; Сохраняем указатель файла
	mov bx, handle1
	xor cx, cx
	xor dx, dx
	mov ax, 4200h
	int 21h ; Идем к началу файла
	lea dx, buffer
	lea si, buffer ; Нужно для lodsb

io_file_read_loop:
	mov ah, 3fh ; Будем читать из файла
	mov cx, 1 ; 1 байт
	int 21h

	cmp ax, cx ; Если достигнут EoF или ошибка чтения
	jnz io_file_read_close ; То закрываем файл

	lodsb

	cmp al, 0Dh
	je io_file_read_work ; Конец строки

	mov ax, 4200h
	inc dx

	jmp io_file_read_loop

io_file_read_work:
	push handle1

	call work

	; Восстанавливаем нужное место
    pop bx
	lea dx, buffer
	lea si, buffer
	
	; Пропускаем 0Ah (CL/RF)
	dec dx
	dec si

	jmp io_file_read_loop

io_file_read_close: ; Закрываем файл, после чтения
	mov result_exists, 1

	mov ah, 3eh
	mov bx, handle1
	int 21h

	; Самостоятельно записываем 0Dh,
	; иначе обработка не найдет конец строки
	mov ax, 000Dh
	mov [esi], eax
	call work

	ret
io_file_read endp

; =============== Сохранение файла ===============

io_file_save proc near
	cmp result_exists, 0 ; Проверяем, есть ли результат
	je print_result_error

	lea dx, file_input_str
	mov ah, 9
	int 21h

	lea dx, output_file
	mov ah, 0ah
	int 21h

	mov bx, 1

io_file_save_remove_enter:
	inc bx
	cmp output_file[ebx], 0Dh
	jne io_file_save_remove_enter

	mov output_file[ebx], 0h

	mov ah, 3Ch ; Функция DOS 3Ch (создание файла)
	lea dx, output_file
	add dx, 2
	xor cx, cx ; Нет атрибутов - обычный файл
	int 21h ; Обращение к функции DOS
	jc io_file_error

	mov handle1, ax

	mov ax, 3d00h
	lea dx, result_file
	int 21h

	mov handle2, ax

io_file_save_process:
	; Считали
    mov ah, 3Fh
    mov cx, 1
	mov bx, handle2
	lea dx, buffer
    int 21h
	
	cmp ax, cx ; Если достигнут EoF или ошибка чтения
	jc io_file_save_close ; То закрываем файл

	; Записали
	mov ah, 40h
	mov cx, 1
	mov bx, handle1
	int 21h

	jmp io_file_save_process

io_file_save_close:
	; Закрыли все файлы
	mov ah, 3eh
	mov bx, handle1
	int 21h

	mov ah, 3eh
	mov bx, handle2
	int 21h

	ret
io_file_save endp

; =============== Ошибка обработки файла ===============

io_file_error:
	lea dx, file_error_str
	mov ah, 9
	int 21h

	ret
	
; =============== Сохранение и выгрузка результата ===============

io_result_true proc near
	call io_result_open
	lea dx, buffer
	mov buffer[0], 31h
	call io_result_write

	ret
io_result_true endp

io_result_false proc near
	call io_result_open
	lea dx, buffer
	mov buffer[0], 30h
	call io_result_write

	ret
io_result_false endp

io_result_open:
	mov ax, 3D01h ; Открываем для записи
	lea dx, result_file
	int 21h

	mov bx, ax

	mov ax, 4202h
	xor dx, dx
	xor cx, cx
	int 21h

	ret
	
io_result_write:
	mov ah, 40h ; Функция DOS 40h (запись в файл)
	mov cx, 1
	int 21h

	mov ah, 3Eh ; Закрытие файла
	int 21h

	ret

; =============== Вывод результата на экран ===============

print_result proc near
	cmp result_exists, 0 ; Проверяем, есть ли результат
	je print_result_error

	mov ax, 3d00h ; Открываем для чтения
	lea dx, result_file ; DS:DX указатель на имя файла
	int 21h

	mov handle1, ax

print_result_loop:
    mov ah, 3Fh ; Чтение из файла
    mov cx, 1
	mov bx, handle1
	mov dx, buffer
    int 21h

	cmp ax, cx ; Если достигнут EoF или ошибка чтения
	jc print_result_close ; То закрываем файл

	mov ah, 9
    int 21h ; Вывод

	jmp print_result_loop

print_result_error:
	call print_no_result
	ret

print_result_close:
	mov ah, 3eh
	mov bx, handle1
	int 21h
	ret
print_result endp

; =============== Очистка результата ===============

flush proc near
	mov result_exists, 0

	; Удаляем temp файл
	mov ah, 41h
	lea dx, result_file
	int 21h

	xor si, si
	mov cx, 12

flush_result:
	mov result_file[si], 0h
	inc si
	loop flush_result

	mov cx, buffer_size
	xor si, si

flush_buffer:
	mov buffer[si], 03h
	inc si
	loop flush_buffer

	mov cx, file_length
	mov si, 2

flush_input_file:
	mov input_file[si], 0h
	inc si
	loop flush_input_file

	mov cx, file_length
	mov si, 2

flush_output_file:
	mov output_file[si], 0h
	inc si
	loop flush_output_file

	ret
flush endp

exit:
	ret

end