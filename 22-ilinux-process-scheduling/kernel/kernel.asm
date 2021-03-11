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
extern irq_handler_table				; 硬件中断请求表
extern curr_proc
extern kernel_reenter
extern level0_func

; =====================================================================
; 导出的函数或变量
; ---------------------------------------------------------------------
global _start
global down_run
; global p_restart
global restart                      ; 进程恢复
global halt
global level0_sys_call


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


; 所有中断处理入口，一共16个(两个8259A)
; ---------------------------------------------------------------------
global	hwint00
global	hwint01
global	hwint02
global	hwint03
global	hwint04
global	hwint05
global	hwint06
global	hwint07
global	hwint08
global	hwint09
global	hwint10
global	hwint11
global	hwint12
global	hwint13
global	hwint14
global	hwint15

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
STACK_SPACE:		resb 2 * 1024 		; 4KB栈空间
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
	ltr ax									; load tss		

	; jmp 0x40:0							; 手动触发一个 General Protection 异常，测试异常机制
	; ud2									; 手动触发一个无效指令异常

	; int 32 + 3
	; int 32 + 9

	; int 48

	jmp ilinux_main						; 跳入到C语言的主函数

	; 永远不可能执行到
	jmp $

;======================================================================
;   硬件中断处理
; ---------------------------------------------------------------------

%macro hwint_master 1
	call save

	; 1. 屏蔽当前中断
	in al, INT_M_CTLMASK	; 取出 8259 的屏蔽位图
	or al, (1 << %1)		; 将该中断的屏蔽位置置位，表示屏蔽它
	out INT_M_CTLMASK, al	; 输出新的屏蔽位图，表示屏蔽当前中断

	; 2. 重新启用 8259a 和中断响应
	mov al, EOI
	out INT_M_CTL, al		; EOI位置位，重新启用 8259
	nop 
	sti 					; 打开中断响应

	; 3. 调用中断处理例程表中的例程
	push %1
	call [irq_handler_table + 4 * %1]
	add esp, 4

	; 4. 最后，判断中断处理例程的返回值，如果颂 DISABLE（0），我们就直接结束，如果不为0，那么我们
	; 重新启用当前中断
	cli 					; 先将中断关闭，这一步不能被其它中断影响
	cmp eax, 0
	je .0

	in al, INT_M_CTLMASK	; 取出 8259 屏蔽位图
	and al, ~(1 << %1)		; 将该位置0，启用中断
	out INT_M_CTLMASK, al	; 输出新的屏蔽位图，启用当前中断
.0:	
	ret
%endmacro

align	16
hwint00:		; Interrupt routine for irq 0 (the clock)，时钟中断
 	hwint_master	0

align	16
hwint01:		; Interrupt routine for irq 1 (keyboard)，键盘中断
 	hwint_master	1

align	16
hwint02:		; Interrupt routine for irq 2 (cascade!)
 	hwint_master	2

align	16
hwint03:		; Interrupt routine for irq 3 (second serial)
 	hwint_master	3

align	16
hwint04:		; Interrupt routine for irq 4 (first serial)
 	hwint_master	4

align	16
hwint05:		; Interrupt routine for irq 5 (XT winchester)
 	hwint_master	5

align	16
hwint06:		; Interrupt routine for irq 6 (floppy)，软盘中断
 	hwint_master	6

align	16
hwint07:		; Interrupt routine for irq 7 (printer)，打印机中断
 	hwint_master	7



%macro hwint_slave 1
	call save				; 

	; 1. 屏蔽当前中断
	in al, INT_M_CTLMASK	; 取出次 8259 的屏蔽位图
	or al, (1 << %1 - 8)	; 将该中断的屏蔽位置置位，表示屏蔽它
	out INT_M_CTLMASK, al	; 输出新的屏蔽位图，表示屏蔽当前中断

	; 2. 重新启用 8259a 和中断响应
	mov al, EOI
	out INT_M_CTL, al		; EOI位置位，重新启用主 8259
	nop 
	out INT_S_CTL, al		; EOI位置位，重新启用次 8259
	sti 					; 打开中断响应

	; 3. 调用中断处理例程表中的例程
	push %1
	call [irq_handler_table + (4 * %1)]
	add esp, 4

	; 4. 最后，判断中断处理例程的返回值，如果颂 DISABLE（0），我们就直接结束，如果不为0，那么我们
	; 重新启用当前中断
	cli 					; 先将中断关闭，这一步不能被其它中断影响
	cmp eax, 0
	je .0

	in al, INT_M_CTLMASK	; 取出 8259 屏蔽位图
	and al, ~(1 << (%1 - 8))	; 将该位置0，启用中断
	out INT_M_CTLMASK, al	; 输出新的屏蔽位图，启用当前中断
.0:	
	ret
%endmacro

align	16
hwint08:		; Interrupt routine for irq 8 (realtime clock).
 	hwint_slave	8

align	16
hwint09:		; Interrupt routine for irq 9 (irq 2 redirected)
 	hwint_slave	9

align	16
hwint10:		; Interrupt routine for irq 10
 	hwint_slave	10

align	16
hwint11:		; Interrupt routine for irq 11
 	hwint_slave	11

align	16
hwint12:		; Interrupt routine for irq 12
 	hwint_slave	12

align	16
hwint13:		; Interrupt routine for irq 13 (FPU exception)
 	hwint_slave	13

align	16
hwint14:		; Interrupt routine for irq 14 (AT winchester)
 	hwint_slave	14

align	16
hwint15:		; Interrupt routine for irq 15
 	hwint_slave	15

;======================================================================
;   软件中断处理
; ---------------------------------------------------------------------


;======================================================================
;   异常处理
; ---------------------------------------------------------------------
divide_error:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	0		    				; 中断向量号	= 0
	jmp	exception
single_step_exception:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	1		    				; 中断向量号	= 1
	jmp	exception
nmi:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	2		    				; 中断向量号	= 2
	jmp	exception
breakpoint_exception:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	3		    				; 中断向量号	= 3
	jmp	exception
overflow:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	4		    				; 中断向量号	= 4
	jmp	exception
bounds_check:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	5		    				; 中断向量号	= 5
	jmp	exception
inval_opcode:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	6		    				; 中断向量号	= 6
	jmp	exception
copr_not_available:
	call save
    
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	7		    				; 中断向量号	= 7
	jmp	exception				
double_fault:				
	call save
    				
	push	8		    				; 中断向量号	= 8
	jmp	exception				
copr_seg_overrun:				
	call save
    				
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	9		    				; 中断向量号	= 9
	jmp	exception				
inval_tss:				
	call save
    				
	push	10		    				; 中断向量号	= 10
	jmp	exception				
segment_not_present:				
	call save
    				
	push	11		    				; 中断向量号	= 11
	jmp	exception				
stack_exception:				
	call save
    				
	push	12		    				; 中断向量号	= 12
	jmp	exception				
general_protection:				
	call save
    				
	push	13		    				; 中断向量号	= 13
	jmp	exception				
page_fault:				
	call save
    				
	push	14		    				; 中断向量号	= 14
	jmp	exception				
copr_error:				
	call save
    				
	push	0xffffffff					; 没有错误代码，用0xffffffff表示
	push	16		    				; 中断向量号	= 16
	jmp	exception

exception:
	call	exception_handler
	add	esp, 4 * 2	    				; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
    ret                 				; 系统已将异常解决，继续运行！

; ;======================================================================
; ;   系统进入宕机
; ; ---------------------------------------------------------------------
; down_run:
; 	hlt
; 	jmp down_run


; ;======================================================================
; ;   保存进程栈帧
; ; ---------------------------------------------------------------------
; p_save:
; 	pushad						; 保存所有普通寄存器

; 	; 保存段寄存器
; 	push ds
; 	push es
; 	push fs
; 	push gs

; 	; 恢复内核数据段
; 	mov ax, ss
; 	mov ds, ax
; 	mov es, ax

; 	; 让 esi 指向进程的栈帧开始处
; 	mov esi, esp

; 	; 判读是否需要切换到内核堆栈
; 	inc byte [kernel_reenter]	; kernel_reenter + 1
; 	cmp byte [kernel_reenter], 0
; 	jnz	.reenter 

; 	mov esp, STACK_TOP			; 切换到内核段
; 	push p_restart
; 	jmp [esi + RETADDR - P_STACKBASE]			; ret

; ; 发生了中断重入
; .reenter:
; 	push p_restart_reenter
; 	jmp [esi + RETADDR - P_STACKBASE]			; ret

; ;======================================================================
; ;   恢复进程栈帧
; ; ---------------------------------------------------------------------
; p_restart:

; 	xchg bx, bx

; 	mov esp, [curr_proc - P_STACKBASE]		; 离开内核栈，esp -> 进程的栈帧结构
; 	lldt [esp + P_LDT_SEL]		; 每个进程有自己的 ldt，切换

; 	; 把进程的栈帧外 ldt_sel 的地址保存到 tss.sp0 作为下次 save 的栈顶，以便恢复
; 	lea eax, [esp + P_STACKTOP]
; 	mov dword [tss + TSS3_S_SP0], eax

; p_restart_reenter:
; 	; 恢复进程的时候 kernel_reenter - 1，标识一个中断已经完成
; 	dec byte [kernel_reenter]

; 	; 恢复进程的寄存器信息
; 	pop gs
; 	pop fs
; 	pop es
; 	pop ds
	
; 	popad						; 恢复普通寄存器信息

; 	add esp, 4					; 跳过 ret_addr 	
; 	iretd						; 中断返回



; ;============================================================================
; ;   保存所有寄存器，即栈帧；然后做一些堆栈切换的工作
; ; 执行中断或切换程序时，执行 save 保存 CPU 当前状态，保证之前的程序上下文环境
; ;----------------------------------------------------------------------------
; save:
; 	xchg bx, bx

;     ; 将所有的32位通用寄存器压入堆栈
;     pushad
;     ; 然后是特殊段寄存器
;     push ds
;     push es
;     push fs
;     push gs
;     ; 注意：以上的操作都是在操作进程自己的堆栈

;     ; ss 是内核数据段，设置 ds 和 es
;     mov dx, ss
;     mov ds, dx
;     mov es, dx
;     mov esi, esp    ; esi 指向进程的栈帧开始处

;     inc byte [kernel_reenter]  ; 发生了一次中断，中断重入计数++
;     ; 现在判断是不是嵌套中断，是的话就无需切换堆栈到内核栈了
; 	; cmp byte [kernel_reenter], 0
;     jnz .reenter                ; 嵌套中断
;     ; 从一个进程进入的中断，需要切换到内核栈
;     mov esp, STACK_TOP
;     push restart                ; 压入 restart 例程，以便一会中断处理完毕后恢复，注意这里压入到的是内核堆栈
;     jmp [esi + RETADDR - P_STACKBASE]   ; 回到 call save() 之后继续处理中断
; .reenter:
;     ; 嵌套中断，已经处于内核栈，无需切换
;     push restart_reenter        ; 压入 restart_reenter 地址，以便一会中断处理完毕后恢复，注意这里压入到的是内核堆栈
;     jmp [esi + RETADDR - P_STACKBASE]   ; 回到 call save() 之后继续处理中断

; ;============================================================================
; ;   中断处理完毕，回复之前挂起的进程
; ;----------------------------------------------------------------------------
; restart:
; 	mov esp, [curr_proc - P_STACKBASE]      ; 离开内核栈，指向运行进程的栈帧，现在的位置是 gs
; 	lldt [esp + P_LDT_SEL]              ; 每个进程有自己的 LDT，所以每次进程的切换都需要加载新的ldtr
; 	; 把该进程栈帧外 ldt_sel 的地址保存到 tss3.sp0 中，下次的 save 将保存所有寄存器到该进程的栈帧中
; 	lea eax, [esp + P_STACKTOP]
; 	mov dword [tss + TSS3_S_SP0], eax
; restart_reenter:
; 	; 在这一点上，kernel_reenter 被减1，因为一个中断已经处理完毕
; 	dec byte [kernel_reenter]
; 	; 将该进程的栈帧中的所有寄存器信息恢复
;     pop gs
;     pop fs
;     pop es
;     pop ds
; 	popad
; 	;* 修改栈指针，这样使调用 save 时压栈的 restart 或 restart_reenter 地址被忽略。
; 	add esp, 4
; 	; 中断返回：恢复eip cs eflags esp ss
; 	iretd



;============================================================================
;   系统进入宕机
;----------------------------------------------------------------------------
down_run:
    hlt
    jmp down_run
;============================================================================
;   保存所有寄存器，即栈帧；然后做一些堆栈切换的工作
; 执行中断或切换程序时，执行 save 保存 CPU 当前状态，保证之前的程序上下文环境
;----------------------------------------------------------------------------
save:
    ; 将所有的32位通用寄存器压入堆栈
    pushad
    ; 然后是特殊段寄存器
    push ds
    push es
    push fs
    push gs
    ; 注意：以上的操作都是在操作进程自己的堆栈

    ; ss 是内核数据段，设置 ds 和 es
    mov dx, ss
    mov ds, dx
    mov es, dx
    mov esi, esp    			; esi 指向进程的栈帧开始处

    inc byte [kernel_reenter]  	; 发生了一次中断，中断重入计数++
    ; 现在判断是不是嵌套中断，是的话就无需切换堆栈到内核栈了
    jnz .reenter                ; 嵌套中断
    ; 从一个进程进入的中断，需要切换到内核栈
    mov esp, STACK_TOP
    push restart                ; 压入 restart 例程，以便一会中断处理完毕后恢复，注意这里压入到的是内核堆栈
    jmp [esi + RETADDR - P_STACKBASE]   ; 回到 call save() 之后继续处理中断
.reenter:
    ; 嵌套中断，已经处于内核栈，无需切换
    push restart_reenter        ; 压入 restart_reenter 地址，以便一会中断处理完毕后恢复，注意这里压入到的是内核堆栈
    jmp [esi + RETADDR - P_STACKBASE]   ; 回到 call save() 之后继续处理中断
;============================================================================
;   中断处理完毕，回复之前挂起的进程
;----------------------------------------------------------------------------
restart:
    xchg bx, bx

	mov esp, [curr_proc - P_STACKBASE]	; 离开内核栈，指向运行进程的栈帧，现在的位置是 gs
	lldt [esp + P_LDT_SEL]	            ; 每个进程有自己的 LDT，所以每次进程的切换都需要加载新的ldtr
	; 把该进程栈帧外 ldt_sel 的地址保存到 tss3.sp0 中，下次的 save 将保存所有寄存器到该进程的栈帧中
	lea eax, [esp + P_STACKTOP]
	mov dword [tss + TSS3_S_SP0], eax
restart_reenter:
	; 在这一点上，kernel_reenter 被减1，因为一个中断已经处理完毕
	dec byte [kernel_reenter]
	; 将该进程的栈帧中的所有寄存器信息恢复
    pop gs
    pop fs
    pop es
    pop ds
	popad
	;* 修改栈指针，这样使调用 save 时压栈的 restart 或 restart_reenter 地址被忽略。
	add esp, 4
	; 中断返回：恢复eip cs eflags esp ss
	iretd

;============================================================================
;   休眠函数
;----------------------------------------------------------------------------
halt:
	sti							; 开中断，随时响应中断
	hlt 						; 处理处理器休眠，特权级0才可以使用
	cli							; 关中断

	ret 

;============================================================================
;   提权系统调用
;----------------------------------------------------------------------------
level0_sys_call:
	xchg bx, bx

	call save
	jmp [level0_func]			; 提权成功，直接跳转到提权成功的函数处理处
	ret
