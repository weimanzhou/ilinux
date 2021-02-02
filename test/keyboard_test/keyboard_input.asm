org 0x7c00

jmp LABEL_START


LABEL_START:
	mov ah, 0
	int 0x16			; 获取键盘输入



	mov ah, 0x0e
	int 0x10			; 显示字符
	
	jmp LABEL_START


times 510-($-$$) db 0
dw 0xaa55
