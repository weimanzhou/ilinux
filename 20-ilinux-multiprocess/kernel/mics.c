/*************************************************************************
	> File Name: mics.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Wed 24 Feb 2021 05:52:48 PM CST


    > 存放一些杂乱的库，提供给内核和
 ************************************************************************/


#include "kernel.h"
#include <stdarg.h>

void down_run();

/*************************************************************************
    > 格式化输出函数
    > 
	> @name k_printf
    > @param fmt 待格式化的字符串
    > @param ... 可变参数
 ************************************************************************/
PUBLIC int k_printf(const char* fmt, ...) {
    char* ap;
    int len;

    char buf[160];

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

/*************************************************************************
    > 断言函数
    > 
    > 该方法只有在 DEBUG 宏被定义为 TRUE 时，才进行编译，支持 assert.h 中的宏
	> @name bad_assertion
    > @param file 错误所在的文件名
    > @param line 错误所在的行
    > @param what 断言源代码
 ************************************************************************/
PUBLIC void bad_assertion(char* file, int line, char* what) {
    printf("\n*============================*\n");
    printf("* panic at file://%s(%d): assertion \"%s\" failed \n", file, line, what);
    printf("\n\n*============================*");

    panic("bad assertion", NO_NUM);
}


/*************************************************************************
    > 错误的断言比较处理
    > 
    > 该方法只有在 DEBUG 宏被定义为 TRUE 时，才进行编译，支持 assert.h 中的宏
	> @name bad_assertion
    > @param file 错误所在的文件名
    > @param line 错误所在的行
    > @param lhs
    > @param what 断言源代码
    > @param rhs
 ************************************************************************/
PUBLIC void bad_compare(char* file, int line, int lhs, char* what, int rhs) {

}

/*************************************************************************
    > 内核遇到了不可恢复的异常或错误，立即准备宕机
    > 
    > 当 ilinux 
    > 
	> @name bad_assertion
    > @param file 错误所在的文件名
    > @param line 错误所在的行
    > @param lhs
    > @param what 断言源代码
    > @param rhs
 ************************************************************************/
PUBLIC void panic(_CONST char* msg, int error_no) {
    if (msg != NIL_PTR) {
        printf("\n!***************** ilinux kernel panic: %s ****************!\n", msg);
        if (error_no != NO_NUM) {
            printf("\n!***************** ilinux kernel  code: %d ****************!\n", error_no);
        }
        printf("\n");
    }
    down_run();
}