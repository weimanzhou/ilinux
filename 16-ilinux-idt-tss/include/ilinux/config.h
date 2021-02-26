/*************************************************************************
	> File Name: config.h
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Thu 04 Feb 2021 10:56:18 PM CST
	>
	>
	> 该文件包含 ilinux 的编译首选项，同时也是编译器实际上第一个处理的文件
	>
	> ilinux 目前只支持 32 位的有保护模式的机器，我们怎么知道这个呢？我们通
	> 通过gcc编译器，如果是32，则 __i386__ 宏会被定义，64 则__x86_64__会被
	> 通过判断可用知道当前编译平台的机器位数。
 ************************************************************************/
#ifndef _ILINUX_CONFIG_H
#define _ILINUX_CONFIG_H

#define OS_RELEASE "0"
#define OS_VERSION "0.1"

#define MACHINE				IBM_PC	/* must be one of the names listed below */

#define IBM_PC				1		/* any base 8088 or 80x86-based system */
#define SUN_4				40	/* any sun SPARC-based system */
#define SUN_4_60			40	/* sun-4/60 */
#define ATARI				60	/*  */
#define AMIGA				61  /*  */
#define MACINTOSH			62	/*  */ 

/* 机器字大小（以字节为单位），等于sizeof(int)的常量 */
#if __ACK__		/* 确定是不是ACK编译器 */

#define _WORD_SIZE _EM_WSIZE

#endif // __ACK__

#if __GNUC__
#if __i386__
#define _WORD_SIZE 4				/* 32位机器 */
#elif __x86_64__
#define _WORD_SIZE 8				/* 64位机器 */
#endif // __i386__
#endif // __GNUC__

#if _WORD_SIZE != 4
#error 对不起，ilinux 暂时只支持32位编译器和32位机器
#endif

/* 内核代码段、数据段基地址
 * 注意：要和GDT中设置的值保持一致！
 */
#define KERNEL_TEXT_SEG_BASE    0
#define KERNEL_DATA_SEG_BASE    0

/*
 * 引导参数相关信息
 *
 * 引导参数由加载程序存储，它们应该放在内核正在运行时也不应该覆盖的地方
 *
 * 因为内核可能随时使用到它们
 *
 */  
#define BOOT_PARAM_ADDR		0x700
#define BOOT_PARAM_MAGIC	0x328
#define BP_MAGIC			0
#define BP_MEMORY_SIZE		1
#define BP_KERNEL_FILE		2

/* 进程表中的用户进程的个数，这个配置决定了 ilinux 同时允许的用户进程的最大数目 */

#define NR_PROCS			32

/* 控制器任务的数量，（/dev/cN设备类） */
#define NR_CONTROLLERS		1

/* 包括或者排除设备驱动程序，设置为1表示包含，设置为0表示排除 */

//#define ENABLE_AT_WINI		1
//#define ENABLE_ATAPI		1
//#define ENABLE_BIOS_WINI		1
//#define ENABLE_ESDI_WINI		1
//#define ENABLE_XT_WINI		1
//#define ENABLE_AT_WINI		1
//#define ENABLE_AT_WINI		1
//#define ENABLE_AT_WINI		1
//#define ENABLE_AT_WINI		1
//#define ENABLE_AT_WINI		1
//#define ENABLE_AT_WINI		1


/* 包括或排除设备驱动程序。设置为1示包含，设置为0表示排除。*/
//#define ENABLE_AT_WINI /* AT风修的硬动程年 */
//#define ENABLE_ATAPI	0 /* ATAPI支が到AT动程年 */
//#define ENABLE_BIOS_WIN		0 /* BIOS程序 */
//#define ENABLE_ESDI_WINI 0 /* Esor */
//#define ENABLE_XT_WINI0 /* XT的程 */
//#define ENABLE_AHA1540_SCSI		0 /* Adaptec 1540 SCSI */
//#define ENABLE_FATFILE0 /* FAT年。*/
//#define ENABLE_DOSFILE	0 /* 005/*/
//#define ENABLE_SB160 /* ( n */
//#define ENABLE_PRINTER0
//#define ENABLE_USER_BIOS0 /* 用户模式BIOS。*/ 

/* 启动或禁用网络驱动程序，默认关闭 */
#define ENABLE_DP8390		0	/* DP8390以太网驱动程序 */
#define ENABLE_WESTERN		1	/* 将 Western Digital MD8Ox3加到DP8390 */
#define ENABLE_NE2000		1	/* 将 Novell NE1000/ME2000声加到DP8390 */
#define ENABLE_3C503		1	/* 将3COM Etherlink II（3c503）添加到DP8390 */	

/* 内核配置参数 */
#define LINE_WRAP			1	/* 控制台选项，是否需要在第80列换行 */

/* ilinux 所启动的控制台的数量等定义 */
#define NR_CONSOLES			3	/* 系统控制台数量（0-9） */
#define NR_RS_LINES			0	/* rs232终端数量（0-2） */
#define NR_PTYS				0	/* 伪终端数量（0-64） */


/*************************************************************************
	> 在这一行之后没有用户可设置的参数
	> 
	> 
	> 
 ************************************************************************/
/* Set the CHIP type based on the machine selected. The symbol CHIP is actually
 * indicative of more than just the CPU.  For example, machines for which
 * CHIP == INTEL are expected to have 8259A interrrupt controllers and the
 * other properties of IBM PC/XT/AT/386 types machines in general. */
#define INTEL               1	/* CHIP type for PC, XT, AT, 386 and clones */
#define M68000              2	/* CHIP type for Atari, Amiga, Macintosh    */
#define SPARC               3	/* CHIP type for SUN-4 (e.g. SPARCstation)  */

/* Set the FP_FORMAT type based on the machine selected, either hw or sw    */
#define FP_NONE		        0	/* no floating point support                */
#define FP_IEEE		        1	/* conform IEEE floating point standard     */

#if (MACHINE == IBM_PC)
#define CHIP          INTEL
#endif

#ifndef FP_FORMAT
#define FP_FORMAT   FP_NONE
#endif

#ifndef MACHINE
error "编译前请在<include/ilinux/config.h>配置文件中定义你要编译的机器的宏(MACHINE)"
#endif

#ifndef CHIP
error "编译前请在<include/ilinux/config.h>配置文件中定义你要编译的机器的宏(MACHINE)"
#endif

#if (MACHINE == 0)
error "MACHINE的值不正确(0)"
#endif

#endif //_ILINUX_CONFIG_H
