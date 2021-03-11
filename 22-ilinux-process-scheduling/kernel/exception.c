/*************************************************************************
	> File Name: exception.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 26 Feb 2021 15:55:48 PM CST
 ************************************************************************/

#include "kernel.h"

/* 异常信息表 */
PRIVATE char* exception_table[] = {
        "#DE Divide Error",                                 /* 除法错误 */
        "#DB RESERVED",                                     /* 调试异常 */
        "—   NMI Interrupt",                                /* 非屏蔽中断 */
        "#BP Breakpoint",                                   /* 调试断点 */
        "#OF Overflow",                                     /* 溢出 */
        "#BR BOUND Range Exceeded",                         /* 越界 */
        "#UD Invalid Opcode (Undefined Opcode)",            /* 无效(未定义的)操作码 */
        "#NM Device Not Available (No Math Coprocessor)",   /* 设备不可用(无数学协处理器) */
        "#DF Double Fault",                                 /* 双重错误 */
        "    Coprocessor Segment Overrun (reserved)",       /* 协处理器段越界(保留) */
        "#TS Invalid TSS",                                  /* 无效TSS */
        "#NP Segment Not Present",                          /* 段不存在 */
        "#SS Stack-Segment Fault",                          /* 堆栈段错误 */
        "#GP General Protection",                           /* 常规保护错误 */
        "#PF Page Fault",                                   /* 页错误 */
        "—   (Intel reserved. Do not use.)",                /* Intel保留，不使用 */
        "#MF x87 FPU Floating-Point Error (Math Fault)",    /* x87FPU浮点数(数学错误) */
        "#AC Alignment Check",                              /* 对齐校验 */
        "#MC Machine Check",                                /* 机器检查 */
        "#XF SIMD Floating-Point Exception",                /* SIMD浮点异常 */
};


/*************************************************************************
	> 中断处理函数
    > 
    > @author snowflake
    > @email 278121951@qq.com
    > @param int_vector_no  中断向量号
    > @param error_no       中断返回的错误码
 *************************************************************************/
PUBLIC void exception_handler(int int_vector_no, int error_no) {

    // 如果是非屏蔽中断，忽略它
    if (int_vector_no == 2) {
        k_printf(exception_table[int_vector_no]);
        k_printf("\n");
        return;
    }

    // 如果确实发生了中断，则打印信息并宕机
    if (exception_table[int_vector_no] == NIL_PTR) {
        panic("!****** exception not exist ******!", NO_NUM);
    } else {
        panic(exception_table[int_vector_no], error_no != 0xFFFFFFFF ? error_no : NO_NUM);
    }

    // for (;;) {}
}