; int 10h / ah = 0x13 document http://www.ablmcc.edu.hk/~scy/CIT/8086_bios_and_dos_interrupts.htm#int10h_13h
org 0x7c00

jmp LABEL_START
nop


BS_OEMName		DB '---XX---'	; OEM string, 必须是 8 个字节
BPB_BytsPerSec	DW 0x0200		; 每扇区字节数
BPB_SecPerClus	DB 0x01			; 每簇多少个扇区
BPB_RsvdSecCnt	DW 0x01			; Boot 记录占用多少扇区
BPB_NumFATs		DB 0x02			; 共有多少 FAT 表
BPB_RootEntCnt	DW 0xe0			; 根目录文件最大数
BPB_TotSec16	DW 0x0b40		; 逻辑扇区总数
BPB_Media		DB 0xF0			; 媒体描述符
BPB_FATSz16		DW 0x09			; 每FAT扇区数
BPB_SecPerTrk	DW 0x12			; 每磁道扇区数
BPB_NumHeads	DW 0x02			; 磁头数（面数）
BPB_HiddSec		DD 0			; 隐藏扇区数
BPB_TotSec32	DD 0			; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
BS_DrvNum		DB 0			; 中断13的驱动器号
BS_Reserved1	DB 0			; 未使用
BS_BootSig		DB 0x29			; 扩展引导标记（29h）
BS_VolID		DD 0			; 卷序列号
BS_VolLab		DB 'snowflake01'; 卷标，必须11个字节
BS_FileSysType	DB 'FAT12'		; 文件系统类型，必须8个字节''''''

stack_base equ 0x7c00

LABEL_START:
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
