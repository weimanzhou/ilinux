[section .data]
str_hello		db "Hello, World!!!", 0
STRLEN			equ $ - str_hello

[section .text]
global _start
_start:
	mov edx, STRLEN
	mov ecx, str_hello
	mov ebx, 1
	mov eax, 4
	int 0x80
	mov ebx, 0
	mov eax, 1
	int 0x80
