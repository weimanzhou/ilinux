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



	; 进行清屏操作
	mov ax, 0x0600
	mov bx, 0x0700
	mov cx, 0
	mov dx, 0x0184f
	int 0x10

	mov cx, 0x09
	push cs
	pop es
	mov bp, boot_message

	call print_string

    jmp $			; 跳转到当前地址，实现循环


%include "string.asm"

boot_message:   dd "Booting......", 0	; 定义一个字符串为 dd 类型，并且后要添加一个 0，表示字符串的结束
boot_message_len:	; boot_message_len - boot_message 刚好为字符串的大小


; ============================================================================
; time n m
;	n: 重复多少次
;	m: 重复的代码
; 	
;
; $	 : 当前地址
; $$ : 代表上一个代码的地址减去起始地址
; ============================================================================
times 510-($-$$) db 0	; 填充 0 
dw 0xaa55				; 可引导扇区标志,必须是 0xaa55,不然bios无法识别
