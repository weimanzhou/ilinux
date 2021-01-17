; int 10h / ah = 0x13 document http://www.ablmcc.edu.hk/~scy/CIT/8086_bios_and_dos_interrupts.htm#int10h_13h
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
    mov al, 1		; write mode bit1: string contains attribute[包含属性的字符串[颜色等]]
    mov bh, 0		; page number
    mov bl, 0x07    ; 黑底白字
    mov cx, 0x09	; 9 个字符
    mov dl, 0x00	; column[首字符出现的列]
    mov dh, 0x00	; row[首字符出现的行]
    push cs			; es:bp points to string to be printed
    pop es
    mov bp, boot_message
    mov ah, 0x13
    int 0x10		; 调用中断，实现文字显示
    jmp $			; 跳转到当前地址，实现循环

boot_message:   dd "Booting......", 0	; 定义一个字符串为 dd 类型，并且后要添加一个 0，表示字符串的结束
boot_message_len:	; boot_message_len - boot_message 刚好为字符串的大小

times 510 - ($ - $$) db 0	; 填充 0 ，$ 代表当前地址，$$ 代表上一个代码的地址减去结尾地址
dw 0xaa55			; 标志这个扇区为一个启动扇区
