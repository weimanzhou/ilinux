/*************************************************************************
	> File Name: c.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Fri 05 Feb 2021 06:14:15 PM CST
	>
	> protect.c包含与Intel处理器保护模式相关的例程。
	> 
	> 本文件的入口点是：
	>  - protect_init          保护模式初始化
	>  - init_segment_desc     初始化一个段描述符
	>  - seg2phys              由段名求其在内存中的物理地址
 ************************************************************************/
#include "kernel.h"
#include "protect.h"
#include "process.h"

/* 全局描述符表GDT */
PUBLIC seg_descriptor_t gdt[GDT_SIZE];
/* 中断描述符表IDT */
PRIVATE gate_t idt[IDT_SIZE];
/* 任务状态段TSS(Task-State Segment) */
PUBLIC Tss_t tss;

/* 中断门信息 */
struct gate_desc_s {
    u8_t vector;            // 中断向量号
    int_handler_t handler;  // 处理例程
    u8_t privilege;         // 门权限
} gate_desc_s;


/* 本地函数 */
FORWARD _PROTOTYPE( void init_gate, (u8_t vector, u8_t desc_type, int_handler_t  handler, u8_t privilege) );
FORWARD _PROTOTYPE( void test_soft_int, (void) );


/* 中断门信息表 */
struct gate_desc_s int_gate_table[] = {
        /* **************************** 异常 ****************************** */
        { INT_VECTOR_DIVIDE,		divide_error,			KERNEL_PRIVILEGE },
        { INT_VECTOR_DEBUG,			single_step_exception,	KERNEL_PRIVILEGE },
        { INT_VECTOR_NMI,			nmi,					KERNEL_PRIVILEGE },
        { INT_VECTOR_BREAKPOINT,	breakpoint_exception,	KERNEL_PRIVILEGE },
        { INT_VECTOR_OVERFLOW,		overflow,				KERNEL_PRIVILEGE },
        { INT_VECTOR_BOUNDS,		bounds_check,			KERNEL_PRIVILEGE },
        { INT_VECTOR_INVAL_OP,		inval_opcode,			KERNEL_PRIVILEGE },
        { INT_VECTOR_COPROC_NOT,	copr_not_available,		KERNEL_PRIVILEGE },
        { INT_VECTOR_DOUBLE_FAULT,	double_fault,			KERNEL_PRIVILEGE },
        { INT_VECTOR_COPROC_SEG,	copr_seg_overrun,		KERNEL_PRIVILEGE },
        { INT_VECTOR_INVAL_TSS,		inval_tss,				KERNEL_PRIVILEGE },
        { INT_VECTOR_SEG_NOT,		segment_not_present,	KERNEL_PRIVILEGE },
        { INT_VECTOR_STACK_FAULT,	stack_exception,		KERNEL_PRIVILEGE },
        { INT_VECTOR_PROTECTION,	general_protection,		KERNEL_PRIVILEGE },
        { INT_VECTOR_PAGE_FAULT,	page_fault,				KERNEL_PRIVILEGE },
        { INT_VECTOR_COPROC_ERR,	copr_error,				KERNEL_PRIVILEGE },
        /* ************************** 硬件中断 **************************** */
        { INT_VECTOR_IRQ0 + 0,		hwint00,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 1,		hwint01,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 2,		hwint02,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 3,		hwint03,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 4,		hwint04,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 5,		hwint05, 				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 6,		hwint06,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ0 + 7,		hwint07,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 0,		hwint08,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 1,		hwint09,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 2,		hwint10,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 3,		hwint11,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 4,		hwint12,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 5,		hwint13,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 6,		hwint14,				KERNEL_PRIVILEGE },
        { INT_VECTOR_IRQ8 + 7,		hwint15,				KERNEL_PRIVILEGE },
        /* ************************** 软件异常 **************************** */
        { 48,                       test_soft_int,          KERNEL_PRIVILEGE }
};

PRIVATE void test_soft_int(void) {
    k_printf("i am an soft int\n");
}

/*************************************************************************
	> init_protect
	> 保护模式初始化
 ************************************************************************/
PUBLIC void init_protect(void) {

    /*
     * 将 LOADER 中的 GDT 拷贝到内核中新的 GDT 中
     * 
     * & 取值，其实是取道相当于 ds 的偏移，所以需要使用 vir2phys 转换一下
     */
    memcpy(
        (void*) vir2phys(&gdt),                             // dest
        (void*) *((u32_t *) vir2phys(&gdt_ptr[2])),         // src
        *((u16_t *) vir2phys(&gdt_ptr[0])) + 1      // size
    );

    // 算出 gdt 的指针
    u16_t * p_gdt_limit = (u16_t *) vir2phys(&gdt_ptr[0]);
    u32_t * p_gdt_base  = (u32_t *) vir2phys(&gdt_ptr[2]);

    *p_gdt_limit = GDT_SIZE * DESCRIPTOR_SIZE - 1;
    *p_gdt_base  = vir2phys(&gdt);

    // 算出 idt 的指针
    u16_t * p_idt_limit = (u16_t *) vir2phys(&idt_ptr[0]);
    u32_t * p_idt_base  = (u32_t *) vir2phys(&idt_ptr[2]);

    *p_idt_limit = IDT_SIZE * sizeof(gate_t) - 1;
    *p_idt_base  = vir2phys(&idt);

    // 初始化任务状态段
    memset(&tss, 0, sizeof(tss));
    // 值使用到 ss0 和 ss3 ，所以不需要初始化其它的 ss 和 esp
    tss.ss0 = SELECTOR_KERNEL_DS;
    init_segment_desc(&gdt[TSS_INDEX], vir2phys(&tss), sizeof(tss) - 1, DA_386TSS);
    tss.iobase = sizeof(tss);                               // 空 IO 位图

    //  初始化中断向量门
    struct gate_desc_s * p_gate = &int_gate_table[0];
    for ( ; p_gate < &int_gate_table[sizeof(int_gate_table) / sizeof(gate_desc_s)]; p_gate++) {
        init_gate(
            p_gate->vector,
            DA_386I_GATE,
            p_gate->handler,
            p_gate->privilege
        );
    }

    // 为每个进程分配一个唯一的 LTD
    process_t* process = BEG_PROC_ADDR;
    int ldt_index = LDT_FIRST_INDEX;
    for (; process < END_PROC_ADDR; process++, ldt_index++) {
        memset(process, 0, sizeof(process_t));
        init_segment_desc(
            &gdt[ldt_index],
            vir2phys(process->ldt),
            sizeof(process->ldt) - 1,
            DA_LDT
        );
        process->ldt_sel = ldt_index * DESCRIPTOR_SIZE;
    }
}

/*=========================================================================*
 *				init_segment_desc				   *
 *				初始化段描述符
 *=========================================================================*/
PUBLIC void init_segment_desc(
        seg_descriptor_t *p_desc,
        phys_bytes base,
        phys_bytes limit,
        u16_t attribute
) {
    /* 初始化一个数据段描述符 */
    p_desc->limit_low	= limit & 0x0FFFF;			/* 段界限 1		(2 字节) */
    p_desc->base_low	= base & 0x0FFFF;			/* 段基址 1		(2 字节) */
    p_desc->base_middle	= (base >> 16) & 0x0FF;     /* 段基址 2		(1 字节) */
    p_desc->access		= attribute & 0xFF;         /* 属性 1 */
    p_desc->granularity = ((limit >> 16) & 0x0F) |  /* 段界限 2 + 属性 2 */
                          ((attribute >> 8) & 0xF0);
    p_desc->base_high	= (base >> 24) & 0x0FF;     /* 段基址 3		(1 字节) */
}

/************************************************************************
    > 初始化一个 386 门描述符
    > @name 	init_gate			
    > @param vector     中断向量号
    > @param desc_type  门描述符类型
    > @param handler    中断处理函数
    > @param privilege  特权等级
 ************************************************************************/
PRIVATE void init_gate(
        u8_t vector,
        u8_t desc_type,
        int_handler_t  handler,
        u8_t privilege
) {
    // 得到中断向量对应的门结构
    gate_t* p_gate = &idt[vector];
    // 取得处理函数的基地址
    u32_t base_addr = (u32_t)handler;
    // 一一赋值
    p_gate->offset_low = base_addr & 0xFFFF;
    p_gate->selector   = SELECTOR_KERNEL_CS;
    p_gate->dcount     = 0;
    p_gate->attr       = desc_type | (privilege << 5);
#if _WORD_SIZE == 4
    p_gate->offset_high = (base_addr >> 16) & 0xFFFF;
#endif
}

/************************************************************************
    > 由段名求其在内存中的物理地址
    > @name             seg2phys			
    > @param vector     中断向量号
    > @param desc_type  门描述符类型
    > @param handler    中断处理函数
    > @param privilege  特权等级
 ************************************************************************/
PUBLIC phys_bytes seg2phys(U16_t seg)
{
    seg_descriptor_t* p_dest = &gdt[seg >> 3];
    return (p_dest->base_high << 24 | p_dest->base_middle << 16 | p_dest->base_low);
}

