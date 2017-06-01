; Модуль вывода меню

model small
.stack 100h
.data
	menu_space       db 10,13,10,13,"$"
	menu_exit        db '0. Exit',10,13,"$"
	menu_print       db '1. Print menu',10,13,"$"
	menu_enter       db '2. Enter string',10,13,"$"
	menu_load        db '3. Load strings from file',10,13,"$"
	menu_save        db '4. Save to file',10,13,"$"
	menu_output      db '5. Output',10,13,"$"
	menu_choose      db 'Select option:',10,13,"$"

	menu_error       db 'There are no such option in menu. Are you sure that you wrote correct number, man?',10,13,"$"
	menu_no_string   db 'Please input main string firstly.',10,13,"$"
	menu_no_result   db 'No result. Load strings from file and run again.',10,13,"$"

.code
.486

extrn result:byte

public print_menu
public print_result
public print_no_input
public print_no_string
public print_no_result

print_menu proc near
	mov dx, offset menu_space ; Пробел
	mov ah, 9
	int 21h
	mov dx, offset menu_exit ; Выход из программы
	mov ah, 9
	int 21h
	mov dx, offset menu_print ; Вывод меню
	mov ah, 9
	int 21h
	mov dx, offset menu_enter ; Ввод основной строки
	mov ah, 9
	int 21h
	mov dx, offset menu_load ; Загрузка строк из файла
	mov ah, 9
	int 21h
	mov dx, offset menu_save ; Сохранить в файл результат
	mov ah, 9
	int 21h
	mov dx, offset menu_output ; Вывод результата на экран
	mov ah, 9
	int 21h
	mov dx, offset menu_choose ; Выбор пункта меню
	mov ah, 9
	int 21h

	ret
print_menu endp

; =============== Вывод результата на экран ===============

print_result proc near
	cmp result[0], "$" ; Проверяем, есть ли результат
	je print_no_result

print_result_loop:
	mov ah, 9
	int 21h

	ret
print_result endp

; =============== Отсутствует главная строка ===============

print_no_string proc near
	mov dx, offset menu_space ; Пробел
	mov ah, 9
	int 21h

	mov dx, offset menu_no_string
	mov ah, 9
	int 21h

	ret
print_no_string endp

; =============== Отсутствует результат ===============

print_no_result proc near
	mov dx, offset menu_space ; Пробел
	mov ah, 9
	int 21h

	mov dx, offset menu_no_result
	mov ah, 9
	int 21h

	ret
print_no_result endp

; =============== В меню ничего не выбрано ===============

print_no_input proc near
	mov dx, offset menu_space ; Пробел
	mov ah, 9
	int 21h

	mov dx, offset menu_error
	mov ah, 9
	int 21h

	ret
print_no_input endp

exit:
	ret

end