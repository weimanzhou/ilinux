/*************************************************************************
	> File Name: i8259.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Wed 24 Feb 2021 05:52:48 PM CST
 ************************************************************************/

#include "kernel.h"
#include "protect.h"
#include "assert.h"

INIT_ASSERT


FORWARD _PROTOTYPE(int default_irq_handler, (int irq) );

/*************************************************************************
    > 初始化硬件中断，8259a
    > 
    > ICW4(对应端口21h和A1h)
    > [7][6][5][4][3][2][1]
    >  |  |  |  |  |  |  |
    >  |  |  |  |  |  |  +---- [1=80x86模式，0=MCS 80/85]
    >  |  |  |  |  |  +------- [1=自动EOI，0=正常EOI]
    >  |  |  |  |  +---------- [主/从缓冲模式]
    >  |  |  |  +------------- [1=SFNM模式，0=sequential模式]
    >  |  |  +---------------- [0]
    >  |  +------------------- [0]
    >  +---------------------- [0]
    >
    > @name init_interrupt
 ************************************************************************/
PUBLIC void init_interrupt(void) {
    // 1. 向端口 0x20 （主片）和 0xa0 （从片）写入 ICW1
    // 00010001
    out_byte(INT_M_CTL, 17);
    out_byte(INT_S_CTL, 17);

    // 2. 向端口 0x21 （主片）和 0xa1 （从片）写入 ICW2
    // 前5位是：分配给8259A的中断向量 后三位：000
    out_byte(INT_M_CTLMASK, 32);        // IRQ0 -- 32, IRQ1 -- 33 ...
    out_byte(INT_S_CTLMASK, 40);        // IRQ0 -- 32, IRQ1 -- 33 ...

    // 3. 向端口 0x21 （主片）和 0xa1 （从片）写入 ICW3
    out_byte(INT_M_CTLMASK, 32);        // 00000100
    out_byte(INT_S_CTLMASK, 40);        // 00000010 - IRQ2

    // 4. 向端口 0x21 （主片）和 0xa1 （从片）写入 ICW4
    // 00000001
    out_byte(INT_M_CTLMASK, 32);
    out_byte(INT_S_CTLMASK, 40);

    // 屏蔽所有中断请求
    out_byte(INT_M_CTLMASK, 0XFF);
    out_byte(INT_S_CTLMASK, 0XFF);

    int i = 0;
    for (; i < NR_IRQ_VECTORS; i++) {
        irq_handler_table[i] = default_irq_handler;
    }

    interrupt_unlock();
}


/*************************************************************************
    > 添加中断处理函数
    > 
	> @name put_irq_handler
    > @param irq 中断向量号
 ************************************************************************/
PUBLIC void put_irq_handler(int irq, irq_handler_t handler) {
    
    assert(irq >= 0 && irq < NR_IRQ_VECTORS);

    // 如果注册过了，则返回
    if (irq_handler_table[irq] == handler) return;
    // 确定该中断被注册为默认的中断处理函数
    assert(irq_handler_table[irq] == default_irq_handler);

    // 关中断
    interrupt_lock();

    irq_handler_table[irq] = handler;

    // 开中断
    interrupt_unlock();
}

/*************************************************************************
    > 格式化输出函数
    > 
	> @name default_irq_handler
    > @param irq 中断向量号
 ************************************************************************/
PRIVATE int default_irq_handler(int irq) {
    k_printf("interrupt, int %d\n", irq);
    // 响应完毕后不重新开启中断
    return DISABLE;
}