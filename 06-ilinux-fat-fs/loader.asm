org 0100h
	mov ax, 0xB800
	mov gs, ax
	mov ah, 0x0F
	mov al, 'L'				; 0000:黑底 1111:白字
	mov [gs:((80 * 0 + 39) * 2)], ax	; 屏幕第0行，第39列
	jmp $					; 到此停住
