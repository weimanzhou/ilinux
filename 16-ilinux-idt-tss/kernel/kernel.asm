; =====================================================================
; 导入的函数或变量
; ---------------------------------------------------------------------
; 导入头文件
%include "asm_const.inc"

; 导入函数
extern ilinux_init						; 初始化一些事情，主要是改变GDT_PTR，让它指向新的GDT
extern ilinux_main						; 内核主函数
extern exception_handler				; 异常统一处理例程

; ---------------------------------------------------------------------
; 导入变量
extern gdt_ptr							; GDT指针
extern idt_ptr							; IDT指针
extern tss								; 任务状态段

; =====================================================================
; 导出的函数或变量
; ---------------------------------------------------------------------
global _start
; 异常处理函数
; ---------------------------------------------------------------------
global divide_error
global single_step_exception
global nmi
global breakpoint_exception
global overflow
global bounds_check
global inval_opcode
global copr_not_available
global double_fault
global copr_seg_overrun
global inval_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global copr_error


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

	jmp 0x40:0							; 手动触发一个 General Protection 异常，测试异常机制
	ud2									; 手动触发一个无效指令异常

	jmp ilinux_main						; 跳入到C语言的主函数

	; 永远不可能执行到
	jmp $



;======================================================================
;   异常处理
; ---------------------------------------------------------------------
divide_error:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	0		    				; 中断向量号	= 0
	jmp	exception
single_step_exception:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	1		    				; 中断向量号	= 1
	jmp	exception
nmi:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	2		    				; 中断向量号	= 2
	jmp	exception
breakpoint_exception:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	3		    				; 中断向量号	= 3
	jmp	exception
overflow:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	4		    				; 中断向量号	= 4
	jmp	exception
bounds_check:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	5		    				; 中断向量号	= 5
	jmp	exception
inval_opcode:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	6		    				; 中断向量号	= 6
	jmp	exception
copr_not_available:
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	7		    				; 中断向量号	= 7
	jmp	exception				
double_fault:				
    				
	push	8		    				; 中断向量号	= 8
	jmp	exception				
copr_seg_overrun:				
    				
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	9		    				; 中断向量号	= 9
	jmp	exception				
inval_tss:				
    				
	push	10		    				; 中断向量号	= 10
	jmp	exception				
segment_not_present:				
    				
	push	11		    				; 中断向量号	= 11
	jmp	exception				
stack_exception:				
    				
	push	12		    				; 中断向量号	= 12
	jmp	exception				
general_protection:				
    				
	push	13		    				; 中断向量号	= 13
	jmp	exception				
page_fault:				
    				
	push	14		    				; 中断向量号	= 14
	jmp	exception				
copr_error:				
    				
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	16		    				; 中断向量号	= 16
	jmp	exception

exception:
	call	exception_handler
	add	esp, 4 * 2	    				; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
    ret                 				; 系统已将异常解决，继续运行！
