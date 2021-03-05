/*************************************************************************
	> File Name: mics.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Wed 24 Feb 2021 05:52:48 PM CST


    > 存放一些杂乱的库，提供给内核和
 ************************************************************************/


#include "kernel.h"
#include <stdarg.h>

PUBLIC int k_printf(const char* fmt, ...) {
    char* ap;
    int len;

    char buf[256];

    // 准备访问可变参数
    va_start(ap, fmt);

    // 调用 vsprintf 格式化字符串
    len = vsprintf(buf, fmt, ap);

    // 输出格式化后的字符串
    low_print(buf);

    // 结束访问
    va_end(ap);

    return len;
}