
org	0100h

	jmp START

BASE_OF_STACK		equ 0x100

START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BASE_OF_STACK

	; 清屏操作
	mov	ax, 0600h		; AH = 6,  AL = 0h
	mov	bx, 0700h		; �ڵװ���(BL = 07h)
	mov	cx, 0			; ���Ͻ�: (0, 0)
	mov	dx, 0184fh		; ���½�: (80, 50)
	int	10h			; int 10h


	mov dh, 0
	call DISP_STR

	jmp	$		; Start


MESSAGE_LENGTH		equ 9
BOOT_MESSAGE:		db "HELLOWORD"

DISP_STR:
	mov ax, MESSAGE_LENGTH
	mul dh
	add ax, BOOT_MESSAGE
	mov bp, ax
	mov ax, ds
	mov es, ax
	mov cx, MESSAGE_LENGTH
	mov ax, 0x1301
	mov bx, 0x0007
	mov dl, 0
	int 10h
	ret
