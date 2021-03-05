/*************************************************************************
	> File Name: t.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 05 Feb 2021 05:00:17 PM CST
	> 
    > 本头文件是库使用的主标头。 lib子目录中的所有C文件一般都包括它。
 ************************************************************************/
#ifndef _LIB_H
#define _LIB_H

/*
 * _POSIX_SOURCE是POSIX标准自行定义的一个特征检测宏。
 * 作用是保证所有POSIX要求的符号和那些显式地允许但并不要求的符号将是可见的，
 * 同时隐藏掉任何POSIX非官方扩展的附加符号。
 */
#define _POSIX_SOURCE       1
/* 宏_FLYANX将为FLYANX所定义的扩展而"重载_POSIX_SOURCE"的作用 */
#define _FLYANX             1

/* 引入库应该所需要的头文件 */
#include <ilinux/config.h>
#include <sys/types.h>
#include <limits.h>
#include <errno.h>
#include <ansi.h>

#include <ilinux/const.h>
#include <ilinux/type.h>
#include <ilinux/caller.h>

#define MM                  0       /* 内存管理器 */
#define FS                  1       /* 文件系统 */
#define FLY                 2       /* 飞彦拓展器，其他调用都在这处理 */



#endif //_LIB_H
