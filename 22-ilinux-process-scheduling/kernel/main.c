/*************************************************************************
	> File Name: main.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Sat 30 Jan 2021 10:07:03 PM CST
 ************************************************************************/

#include "kernel.h"
#include "protect.h" 
#include "assert.h"
#include "process.h"

// 初始化断言，这个地方一定要初始化，才可以利用编译器的 __FILE__ 宏获取到文件名词
INIT_ASSERT				

// 从第 10 行第 0 列开始显示

void low_print(char* str);

FORWARD _PROTOTYPE (void init_mul_process_by_me, (void) );

void ilinux_main(void) 
{
    // 1. 设置光标位置
	display_position = (80 * 12 + 0) * 2;
    // 2. 输出提示信息
	k_printf("#ilinux_main: Hello C!!!\n");
    // 3. 启动时钟
	clock_task();
    // 4. 初始化多任务
	init_mul_process_by_me();
    // 5. 调用狩猎方法，选取一个进程执行
    lock_hunter();
    // 6. 执行线程
	restart();
    
	while(1) {}
}

PRIVATE void init_mul_process_by_me() {
        /* 进程表的所有表项都被标志为空闲;
     * 对用于加快进程表访问的 p_proc_addr 数组进行初始化。
     */
    register process_t *proc;
    register int logic_nr;
    for(proc = BEG_PROC_ADDR, logic_nr = -NR_TASKS; proc < END_PROC_ADDR; proc++, logic_nr++) {
        if(logic_nr > 0)    /* 系统服务和用户进程 */
            memcpy(proc->name, "unused", 6);
            // strcpy(proc->name, "unused");
        proc->logic_nr = logic_nr;
        p_proc_addr[logic_nr_2_index(logic_nr)] = proc;
    }

    /* 
	 * 初始化多任务支持
     * 为系统任务和系统服务设置进程表，它们的堆栈被初始化为数据空间中的数组
     */
    sys_proc_t *sys_proc;
    reg_t sys_proc_stack_base = (reg_t) sys_proc_stack;
    u8_t  privilege;        /* CPU 权限 */
    u8_t rpl;               /* 段访问权限 */
    for(logic_nr = -NR_TASKS; logic_nr <= LOW_USER; logic_nr++) {   /* 遍历整个系统进程 */
        proc = proc_addr(logic_nr);                                 /* 拿到系统进程对应应该放在的进程指针 */
        sys_proc = &sys_proc_table[logic_nr_2_index(logic_nr)];     /* 系统进程项 */
        // strcpy(proc->name, sys_proc->name);                         /* 拷贝名称 */
        /* 判断是否是系统任务还是系统服务 */
        if(logic_nr < 0) {  /* 系统任务 */
            // if(sys_proc->stack_size > 0){
            //     /* 如果任务存在堆t栈空间，设置任务的堆栈保护字 */
            //     proc->stack_guard_word = (reg_t*) sys_proc_stack_base;
            //     *proc->stack_guard_word = SYS_TASK_STACK_GUARD;
            // }
            /* 设置权限 */
            proc->priority = PROC_PRI_TASK;
            rpl = privilege = TASK_PRIVILEGE;
        } else {            /* 系统服务 */
            // if(sys_proc->stack_size > 0){
            //     /* 如果任务存在堆栈空间，设置任务的堆栈保护字 */
            //     proc->stack_guard_word = (reg_t*) sys_proc_stack_base;
            //     *proc->stack_guard_word = SYS_SERVER_STACK_GUARD;
            // }
            proc->priority = PROC_PRI_SERVER;
            rpl = privilege = SERVER_PRIVILEGE;
        }
        /* 堆栈基地址 + 分配的栈大小 = 栈顶 */
        sys_proc_stack_base += sys_proc->stack_size;

        /* ================= 初始化系统进程的 LDT ================= */
        proc->ldt[CS_LDT_INDEX] = gdt[TEXT_INDEX];  /* 和内核公用段 */
        proc->ldt[DS_LDT_INDEX] = gdt[DATA_INDEX];
        /* ================= 改变DPL描述符特权级 ================= */
        proc->ldt[CS_LDT_INDEX].access = (DA_CR | (privilege << 5));
        proc->ldt[DS_LDT_INDEX].access = (DA_DRW | (privilege << 5));
        /* 设置任务和服务的内存映射 */
        proc->map.base = KERNEL_TEXT_SEG_BASE;
        proc->map.size = 0;     /* 内核的空间是整个内存，所以设置它没什么意义，为 0 即可 */
        /* ================= 初始化系统进程的栈帧以及上下文环境 ================= */
        proc->regs.cs = ((CS_LDT_INDEX * DESCRIPTOR_SIZE) | SA_TIL | rpl);
        proc->regs.ds = ((DS_LDT_INDEX * DESCRIPTOR_SIZE) | SA_TIL | rpl);
        proc->regs.es = proc->regs.fs = proc->regs.ss = proc->regs.ds;  /* C 语言不加以区分这几个段寄存器 */
        proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK | rpl);       /* gs 指向显存 */
        proc->regs.eip = (reg_t) sys_proc->initial_eip;                 /* eip 指向要执行的代码首地址 */
        proc->regs.esp = sys_proc_stack_base;                           /* 设置栈顶 */
        proc->regs.eflags = is_task_proc(proc) ? INIT_TASK_PSW : INIT_PSW;

        /* 进程刚刚初始化，让它处于可运行状态，所以标志位上没有1 */
        proc->flags = CLEAN_MAP;

        if (!is_idle_hardware(logic_nr))
            ready(proc);
    }

}

PUBLIC void idle_task(void) 
{
    k_printf("3");

    while (1)
    {
        level0(halt);
    }
}
