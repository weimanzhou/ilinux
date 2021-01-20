; int 10h / ah = 0x13 document http://www.ablmcc.edu.hk/~scy/CIT/8086_bios_and_dos_interrupts.htm#int10h_13h
org 0x7c00
	jmp LABEL_BEGIN

%include	"pm.inc"	; 常量,宏,以及一些说明

[SECTION .gdt]
; GDT
LABEL_GDT:			descriptor 0, 0, 0		; 空描述符
; DA_C + DA_32 DA_C = 0x98 DA_32 = 0X4000
; DA_C + DA_32 = 1000000 10011000
; 意思: 这个段是存在的只执行的32位代码段,DPL=0
LABEL_DESC_CODE32:	descriptor 0, SEG_CODE32_LEN - 1, DA_C + DA_32
											; 代码段,32位
; 这个描述指向的是显存										
; 段基址为 0x0B8000	
; dw %1 & 0xffff		: 0xB8000 & 0xFFFF = 0x8000	保留低16位
; dw (%1 >> 16) & 0xFF	; ()0xB8000 >> 16) & 0xFF	保留高八位
; attr:
;	存在的可读写数据段
LABEL_DESC_VIDEO:	descriptor 0xB8000, 0xffff, DA_DRW
											; 显存首地址
; GDT END

GDT_LEN		equ $ - LABEL_GDT	; GDT长度
; ==========================================================================
; +------------------+------------+ 
; |		32位基地址	 |	16位界限  |
; +------------------+------------+
; ==========================================================================
GDT_PTR		dw GDT_LEN			; GDT界限
			dd 0				; GDT基地址

; GDT选择子
SELECTOR_CODE32		equ LABEL_DESC_CODE32	- LABEL_GDT
; 
SELECTOR_VIDEO		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END OF [SECTION .gdt]

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x0100

	; 初始化32位代码段描述符
	xor eax, eax
	mov ax, cs
	shl eax, 4
	; 将[SECTION .32]这个段的物理地址赋给eax
	add eax, LABEL_SEG_CODE32
	; 将 eax 的值分三部分赋值给 DESC_CODE32 中的响应位置.
	; 也就是将基址赋值给 DESC_CODE32
	mov word [LABEL_DESC_CODE32 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32 + 4], al
	mov byte [LABEL_DESC_CODE32 + 7], ah

	; 为加载gdtr做准备
	; 将 eax 寄存器清零
	xor eax, eax
	; 将 ds 寄存器的值移到 ax
	mov ax, ds
	; eax 左移四位
	shl eax, 4
	; 将 GDT 物理地址添加到 eax 寄存器中
	add eax, LABEL_GDT				; eax <- gdt 基地址
	; 将 eax 的值插入到 GDT_PTR 的基址属性中
	
	mov dword [GDT_PTR + 2], eax	; [GDT_PTR + 2] <- 基地址

	; 加载gdtr
	lgdt [GDT_PTR]

	; 关中断
	cli

	; 打开地址线a20
	in al, 0x92
	; 这里是否是需要更改位 00000001b
	or al, 00000010b
	out 0x92, al

	; 准备切换到保护模式
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	; 真正进入保护模式
	jmp dword SELECTOR_CODE32:0		; 执行这一句会把SELECT_CODE32
									; 装入CS,并跳转到SELECTOR_CODE32:0

[SECTION .s32]	; 32位代码段,由实模式跳入
[BITS 32]

LABEL_SEG_CODE32:
	; ======================================================================
	; 实现字符输出
	; ======================================================================
	mov ax, SELECTOR_VIDEO
	mov gs, ax						; 视频段选择子(目的)
									
	mov edi, (80 * 10 + 0) * 2		; 屏幕第10行,第0列
	mov ah, 0x0c					; 0000: 黑底 1100: 红字
	mov al, 'P'
	mov [gs:edi], ax

	; 到此停止

	jmp $

SEG_CODE32_LEN	equ $ - LABEL_SEG_CODE32

; END OF [SECTION .s32]
; ============================================================================
; time n m
;	n: 重复多少次
;	m: 重复的代码
; 	
;
; $	 : 当前地址
; $$ : 代表上一个代码的地址减去起始地址
; ============================================================================
times 382-($-$$) db 0	; 填充 0 
dw 0xaa55				; 可引导扇区标志,必须是 0xaa55,不然bios无法识别
