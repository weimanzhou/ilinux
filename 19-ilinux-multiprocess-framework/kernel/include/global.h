/*************************************************************************
	> File Name: t.h
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 05 Feb 2021 05:26:51 PM CST
	> Copyright (C) 2007 Free Software Foundation, Inc. 
	> See the copyright notice in the file /usr/LICENSE.
	>
	> 内核所需要的全局变量
 ************************************************************************/
#ifndef ILINUX_GLOBAL_H
#define ILINUX_GLOBAL_H

/* 当该文件被包含在定义了宏_TABLE的 table.c中时，宏EXTERN的定义被取消。 */
#ifdef _TABLE
#undef EXTERN
#define EXTERN
#endif

/* GDT、IDT、etc.. */
extern seg_descriptor_t gdt[];
EXTERN u8_t gdt_ptr[6];                             /* GDT指针，0~15：Limit 16~47：Base */
EXTERN u8_t idt_ptr[6];                             /* IDT指针，同上 */
EXTERN int display_position;                        /* low_print函数需要它标识显示位置 */

/* 硬件中断请求处理例程表 */
EXTERN irq_handler_t irq_handler_table[NR_IRQ_VECTORS];
EXTERN struct process_s *held_head; /* 中断挂起队列头指针 */
EXTERN struct process_s *held_tail; /* 中断挂起队列尾指针 */

/* 内核内存 */
EXTERN phys_bytes data_base;		/* 内核数据段基地址 */
EXTERN memory_map_t kernel_map;     /* 内核内存映像 */

/* 多进程相关 */
EXTERN struct process_s *curr_proc; /* 当前正在运行的进程 */
// extern SysProc_t sys_proc_table[];  /* 系统进程表 */
// extern char *sys_proc_stack[];      /* 系统进程堆栈 */

/* 其他 */
EXTERN boot_params_t* boot_params;  /* 引导参数 */
EXTERN u8_t kernel_reenter;         /* 记录内核中断重入次数 */
EXTERN ILINUX_syscall_t level0_func;/* 提权成功的函数指针放在这里 */


#endif // ILINUX_GLOBAL_H
