; =====================================================================
; 导入的函数或变量
; ---------------------------------------------------------------------
extern ilinux_main

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
_start:								; 程序入口
	; reg reset
	; es = fs = ss = es， 在C语言中，它们是等同的
	mov ax, cs

	; TODO 不知道为啥，如果添加下面的语句就回报错

;	mov ss, ax
	mov es, ax
	mov fs, ax
	mov esp, STACK_TOP 

	jmp ilinux_main					; 跳入到C语言的主函数
		
	; 永远不可能执行到
	jmp $

