/*************************************************************************
	> File Name: clock.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 26 Feb 2021 15:55:48 PM CST
 ************************************************************************/


#include "kernel.h"
#include "process.h"

#define TIMER0          0x40    // 定时器通道0的IO端口
#define TIMER1          0x41    // 定时器通道1的IO端口
#define TIMER2          0x42    // 定时器通道2的IO端口
#define TIMER_MODE      0x43    // 用于定时器模式控制的IO端口
#define RATE_GENERATOR  0x34    /*
                                 * 00-11-010-0
                                 * counter0 - LSB the MSB - rate generator - binary
                                 */
#define TIMER_FREQ      1193182L// clock frequency for timer in PC and AT
#define TIMER_COUNT     (TIMER_FREQ / HZ)
                                // initial value for counter
#define CLOCK_ACK_BIT   0x80    // PS/2 clock interrupt acknowledge bit


FORWARD _PROTOTYPE( void init_clock, (void) );
FORWARD _PROTOTYPE( int clock_handler, (int irq) );

PUBLIC void clock_task(void) {
    // 初始化 8253
    init_clock();

    // 打开中断
    interrupt_unlock();
}

PRIVATE clock_t count = 0;

PRIVATE int clock_handler(int irq) {

    count++;
    if(count % 100 == 0){
        k_printf(">");
        count++;
        curr_proc++;
        k_printf("%d", curr_proc);
        /* 超出我们的系统进程，拉回来 */
        if(curr_proc > proc_addr(LOW_USER)) {
            curr_proc = proc_addr(-NR_TASKS);
        }
    }


    // count++;
    // if (count % 100 == 0) k_printf(">");
    return ENABLE;
}

PRIVATE void init_clock(void) {
    // 写入模式
    out_byte(TIMER_MODE, RATE_GENERATOR);

    // 写入 counter0 的值
    out_byte(TIMER0, (u8_t) TIMER_COUNT);
    out_byte(TIMER0, (u8_t) (TIMER_COUNT >> 8));

    // 注册时钟中断，并打开中断
    put_irq_handler(CLOCK_IRQ, clock_handler);
    enable_irq(CLOCK_IRQ);
}

