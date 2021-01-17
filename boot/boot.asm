org 0x7c00

jmp START
nop

stack_base equ 0x7c00

START:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, stack_base

    ; 打印字符 Booting...
    mov al, 1
    mov bh, 0
    mov bl, 0x07    ; 黑底白字
    mov cx, 0x09	; 9 个字符
    mov dl, 0x00
    mov dh, 0x00
    push cs
    pop es
    mov bp, boot_message
    mov ah, 0x13
    int 0x10
    jmp $

boot_message:   dd "Booting......", 0
boot_message_len:

times 510 - ($ - $$) db 0
dw 0xaa55
