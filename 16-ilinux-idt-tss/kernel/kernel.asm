; =====================================================================
; 导入的函数或变量
; ---------------------------------------------------------------------
; 导入头文件
%include "asm_const.inc"

; 导入函数
extern ilinux_init						; 初始化一些事情，主要是改变GDT_PTR，让它指向新的GDT
extern ilinux_main						; 内核主函数

; ---------------------------------------------------------------------
; 导入变量
extern gdt_ptr							; GDT指针
extern idt_ptr							; IDT指针
extern tss								; 任务状态段

; =====================================================================
; 导出的函数或变量
; ---------------------------------------------------------------------
global _start

; =====================================================================
; kernel data segment
; ---------------------------------------------------------------------
[section .data]
bits 32

	nop

; =====================================================================
; kernel stack segment
; ---------------------------------------------------------------------
[section .stack]
STACK_SPACE:		times 4 * 1024 db 0	; 4KB栈空间
STACK_TOP:								; 栈顶

; =====================================================================
; 内核代码段
; ---------------------------------------------------------------------
[section .text]
_start:									; 程序入口
	; reg reset
	; es = fs = ss = es， 在C语言中，它们是等同的
	mov ax, ds

	; TODO 不知道为啥，如果添加下面的语句就回报错

	mov ss, ax
	mov es, ax
	mov fs, ax							; es = fs = ss = 内核数据段
	mov esp, STACK_TOP 

	; 将GDT拷贝到内核中
	sgdt [gdt_ptr]						; 将 LOADER 中的 GDT 指针保存到 gdt_ptr

	call ilinux_init					; 初始化工作

	lgdt [gdt_ptr]						
	lidt [idt_ptr]				

	jmp _init

_init:
	; 加载任务状态段 TSS
	xor eax, eax
	mov ax, SELECTOR_TSS
	ltr ax								; load tss		


	jmp ilinux_main						; 跳入到C语言的主函数

	; 永远不可能执行到
	jmp $

