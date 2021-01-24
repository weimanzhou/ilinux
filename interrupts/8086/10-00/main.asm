org 0x7c00

mov al, 00h
mov ah, 0
int 10h

times 510-($-$$) db 0
dw 0xaa55
