org 7c00h
mov dx, msg
mov ah, 9
int 21h
ret
msg db "hello world $"


times 510-($-$$) db 0
dw 0xaa55
