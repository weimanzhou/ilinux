


print_string:
	push ax
	push bx
	push cx
	push dx
	
	mov ax, 0x1301
	mov bx, 0x0007
	mov dx, 0x0000

	int 0x10

	pop dx
	pop cx
	pop bx
	pop ax

	ret


