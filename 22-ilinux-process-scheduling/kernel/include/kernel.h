/*************************************************************************
	> File Name: t.h
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 05 Feb 2021 05:26:51 PM CST
	> 内核的主头文件
	>
	> 该文件包含内核所需要的所有定义
 ************************************************************************/

/*
 * _POSIX_SOURCE是POSIX标准自行定义的一个特征检测宏。
 * 作用是保证所有POSIX要求的符号和那些显式地允许但并不要求的符号将是可见的，
 * 同时隐藏掉任何POSIX非官方扩展的附加符号。
 */
#define _POSIX_SOURCE		1

/* 宏_ILINUX将为ILINUX所定义的扩展而"重载_POSIX_SOURCE"的作用 */
#define _ILINUX				1

/* 在编译系统代码时，如果要作与用户代码不同的事情，比如改变错误码的符号，则可以对_SYSTEM宏进行测试 */
#define _SYSTEM				1	/* tell headers that this is the kernel */

/* 以下内容非常简单，所有*.c文件都会自动获得它们。 */
#include <ilinux/config.h>      /* 这个头文件必须第一个引入 */
#include <ansi.h>               /* 必须第二个 */
#include <sys/types.h>
#include <ilinux/common.h>
#include <ilinux/const.h>
#include <ilinux/type.h>
#include <ilinux/syslib.h>

#include <string.h>
#include <limits.h>
#include <errno.h>

#include "const.h"
#include "type.h"
#include "global.h"
#include "prototype.h"