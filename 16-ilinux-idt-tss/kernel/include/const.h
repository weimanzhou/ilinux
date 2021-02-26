/*************************************************************************
	> File Name: const.h
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 05 Feb 2021 05:26:51 PM CST
	> Copyright (C) 2007 Free Software Foundation, Inc. 
	> See the copyright notice in the file /usr/LICENSE.
	>
	> 内核所需的常量定义
 ************************************************************************/

#ifndef ILINUX_CONST_H
#define ILINUX_CONST_H

/*
 * 当配置头文件config.h中CHIP是INTEL时生效
 * 这些值用于Intel的CPU芯片,但在别的硬件上编译时则可能不同。
 **/
#if (CHIP == INTEL)

/* 内核栈大小，系统任务将使用这么大的栈空间 */
#define K_STACK_BYTES   1024	/* 内核堆栈有多少字节 */

#define INIT_PSW		0x202	/* initial psw :IF=1, 位2一直是1 */
#define INIT_TASK_PSW	0x1202	/* initial psw for tasks (with IOPL 1) : IF=1, IOPL=1, 位2一直是1*/

#define HCLICK_SHIFT    4       /* log2 <- HCLICK_SIZE */
#define HCLICK_SIZE     16      /* 硬件段转换魔数 */
#if CLICK_SIZE >= HCLICK_SIZE
#define click_to_hclick(n) ((n) << (CLICK_SHIFT - HCLICK_SHIFT))
#else
#define click_to_hclick(n) ((n) >> (HCLICK_SHIFT - CLICK_SHIFT))
#endif /* CLICK_SIZE >= HCLICK_SIZE */
#define hclick_to_physb(n) ((phys_bytes) (n) << HCLICK_SHIFT)
#define physb_to_hclick(n) ((n) >> HCLICK_SHIFT)

/* BIOS中断向量 和 保护模式下所需的中断向量 */
#define INT_VECTOR_BIOS_IRQ0        0x00
#define INT_VECTOR_BIOS_IRQ8        0x10
#define	INT_VECTOR_IRQ0				0x20    // 32
#define	INT_VECTOR_IRQ8				0x28    // 40

/* 硬件中断数量 */
#define NR_IRQ_VECTORS      16      /* 中断请求的数量 */
/* 主8259A上的 */
#define	CLOCK_IRQ		    0       /* 时钟中断请求号 */
#define	KEYBOARD_IRQ	    1       /* 键盘中断请求号 */
#define	CASCADE_IRQ		    2	    /* 第二个AT控制器的级联启用 */
#define	ETHER_IRQ		    3	    /* 默认以太网中断向量 */
#define	SECONDARY_IRQ	    3	    /* RS232 interrupt vector for port 2  */
#define	RS232_IRQ		    4	    /* RS232 interrupt vector for port 1 */
#define	XT_WINI_IRQ		    5	    /* xt风格硬盘 */
#define	FLOPPY_IRQ		    6	    /* 软盘 */
#define	PRINTER_IRQ		    7       /* 打印机 */
/* 从8259A上的 */
#define REAL_CLOCK_IRQ      8       /* 实时时钟 */
#define DIRECT_IRQ2_IRQ     9       /* 重定向IRQ2 */
#define RESERVED_10_IRQ     10      /* 保留待用 */
#define RESERVED_11_IRQ     11      /* 保留待用 */
#define MOUSE_IRQ           12      /* PS/2 鼠标 */
#define FPU_IRQ             13      /* FPU 异常 */
#define	AT_WINI_IRQ		    14	    /* at风格硬盘 */
#define RESERVED_15_IRQ     15      /* 保留待用 */

/* 系统调用数量 */
#define NR_SYS_CALL         0

/* BIOS硬盘参数向量。 */
#define WINI_0_PARM_VEC     0x41
#define WINI_1_PARM_VEC     0x46

/* 8259A终端控制器端口 */
#define INT_M_CTL           0x20    /* I/O port for interrupt controller         <Master> */
#define INT_M_CTLMASK       0x21    /* setting bits in this port disables ints   <Master> */
#define INT_S_CTL           0xA0    /* I/O port for second interrupt controller  <Slave>  */
#define INT_S_CTLMASK       0xA1    /* setting bits in this port disables ints   <Slave>  */
/* 中断控制器的神奇数字EOI，可以用于控制中断的打开和关闭，当然，这个宏可以被类似功能的引用 */
#define EOI             0x20    /* EOI，发送给8259A端口1，以重新启用中断 */
#define DISABLE         0       /* 用于在中断后保持当前中断关闭的代码 */
#define ENABLE          EOI	    /* 用于在中断后重新启用当前中断的代码 */


/* === 常用的颜色代码  ===  */

/* 调色板
 * 例如： MAKE_COLOR(BLUE, RED)
 *       MAKE_COLOR(BLACK, RED) | BRIGHT
 *       MAKE_COLOR(BLACK, RED) | BRIGHT | FLASH
 */
#define BLACK   0x0     /* 0000 */
#define WHITE   0x7     /* 0111 */
#define RED     0x4     /* 0100 */
#define GREEN   0x2     /* 0010 */
#define BLUE    0x1     /* 0001 */
#define FLASH   0x80 << 8   /* 1000 0000 */
#define BRIGHT  0x08 << 8   /* 0000 1000 */
#define MAKE_COLOR(bg,fg) (((bg << 4) | fg) << 8)  /* MAKE_COLOR(背景色,前景色) */

/* Sizes of memory tables. */
/* 内存表的大小。 */
#define NR_MEMORY_CLICK            6	/* 内存块的数量 */

/* 其他的端口 */
#define PCR		0x65			/* 平面控制寄存器 */
#define PORT_B          0x61	/* 8255端口B的I/O端口(键盘，蜂鸣…) */

/* 固定系统调用向量。 */
#define INT_VECTOR_LEVEL0           0x66	    /* 用于系统任务提权到 0 的调用向量 */
#define INT_VECTOR_SYS_CALL         0x94        /* flyanx 386 系统调用向量 */

#endif /* (CHIP == INTEL) */

/*================================================================================================*/
/* 以下的定义是机器无关的，但他们被核心代码的许多部分用到。 */
/*================================================================================================*/
/* 下面定义了进程调度的三个优先级队列 */
#define TASK_QUEUE             0	/* 就绪的系统任务通过队列0调度 */
#define SERVER_QUEUE           1	/* 就绪的系统服务通过队列1调度 */
#define USER_QUEUE             2	/* 就绪的系统服务通过队列2调度 */
#define NR_PROC_QUEUE          3	/* 调度队列的数量 */

/* 在内核中，将printf的引用指向printk，注意：还没有实现printk，那么请别在内核中使用printf */
#define printf  k_printf

/* 
 * 将内核空间中的虚拟地址转换为物理地址。
 */
#define	vir2phys(vir)	((phys_bytes) (KERNEL_DATA_SEG_BASE) + (vir_bytes) (vir))

/* 秒 转化为 毫秒 */
#define sec2ms(s) 		(s * 1000)
/* 滴答 转换为 毫秒 */
#define tick2ms(t) 		(t * ONE_TICK_MILLISECOND)
/* 滴答 转化为 秒 */
#define tick2sec(t)   	((time_t) tick2ms(t) / 1000)
/* 字节 转换为 KB */
#define bytes2round_k(n) 	((unsigned) (((n + 512) >> 10)))

/* 为了消息通信调用的简洁 */
#define sen(n)              send(n, NIL_MESSAGE)
#define rec(n)              receive(n, NIL_MESSAGE)
#define sen_rec(n)          send_rec(n, NIL_MESSAGE)
#define io_box(vir)         in_outbox(vir, vir);


#endif // ILINUX_CONST_H
