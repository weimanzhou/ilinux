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
FORWARD _PROTOTYPE (void init_mul_process_by_ot, (void) );


void ilinux_main(void){

    k_printf("#{flyanx_main}-->Hello OS!!!\n");

    /* 启动时钟驱动任务 */
    clock_task();

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

    k_printf("------1------");

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
    }

    k_printf("--------2-------");

    /* 启动 A */
    curr_proc = proc_addr(-3);
    /* 最后,main 的工作至此结束。它的工作到初始化结束为止。restart 的调用将启动第一个任务，
     * 控制权从此不再返回到main。
     *
     * restart 作用是引发一个上下文切换,这样 curr_proc 所指向的进程将运行。
     * 当 restart 执行了第一次时,我们可以说 Flyanx 正在运行-它在执行一个进程。
     * restart 被反复地执行,每当系统任务、服务器进程或用户进程放弃运行机会挂
     * 起时都要执行 restart,无论挂起原因是等待输入还是在轮到其他进程运行时将控制权转交给它们。
     */
    restart();


    while (TRUE) {} 
}


// void ilinux_main(void) 
// {
// 	display_position = (80 * 12 + 0) * 2;

// 	low_print("Hello C!!!\n");

// 	// clock_task();

// 	init_mul_process_by_me();

// 	low_print("hello2\n");

// 	curr_proc = proc_addr(-2);
// 	// assert(curr_proc == &sys_proc_table[0]);
	
// 	restart();

// 	low_print("------------------\n");

// 	while(1) {}
// }


PRIVATE void init_mul_process_by_me() {
	register process_t* process;
	register int logic_nr;
	k_printf("end: %d, sizeof(pro): %d", END_PROC_ADDR, sizeof(process_t*));
	for (process = BEG_PROC_ADDR, logic_nr = -NR_TASKS; process < END_PROC_ADDR; process++, logic_nr++) {
		// 系统服务和用户进程
		// if (logic_nr > 0) memcpy(process->name, "unused", 6); // process->name = "unused"; //strcpy(process->name, "unused");
		process->logic_nr = logic_nr;
		p_proc_addr[logic_nr_2_index(logic_nr)] = process;
		// k_printf("hello %ld", process);
	}

	low_print("hello1\n");

	sys_proc_t* sys_proc;
	reg_t sys_proc_stack_base = (reg_t) sys_proc_stack;
	u8_t privilege;
	u8_t rpl;
    for(logic_nr = -NR_TASKS; logic_nr <= LOW_USER; logic_nr++) {   /* 遍历整个系统进程 */
        process = proc_addr(logic_nr);                                 /* 拿到系统进程对应应该放在的进程指针 */
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
            process->priority = PROC_PRI_TASK;
            rpl = privilege = TASK_PRIVILEGE;
        } else {            /* 系统服务 */
            // if(sys_proc->stack_size > 0){
            //     /* 如果任务存在堆栈空间，设置任务的堆栈保护字 */
            //     proc->stack_guard_word = (reg_t*) sys_proc_stack_base;
            //     *proc->stack_guard_word = SYS_SERVER_STACK_GUARD;
            // }
            process->priority = PROC_PRI_SERVER;
            rpl = privilege = SERVER_PRIVILEGE;
        }
        /* 堆栈基地址 + 分配的栈大小 = 栈顶 */
        sys_proc_stack_base += sys_proc->stack_size;

        /* ================= 初始化系统进程的 LDT ================= */
        process->ldt[CS_LDT_INDEX] = gdt[TEXT_INDEX];  /* 和内核公用段 */
        process->ldt[DS_LDT_INDEX] = gdt[DATA_INDEX];
        /* ================= 改变DPL描述符特权级 ================= */
        process->ldt[CS_LDT_INDEX].access = (DA_CR | (privilege << 5));
        process->ldt[DS_LDT_INDEX].access = (DA_DRW | (privilege << 5));
        /* 设置任务和服务的内存映射 */
        process->map.base = KERNEL_TEXT_SEG_BASE;
        process->map.size = 0;     /* 内核的空间是整个内存，所以设置它没什么意义，为 0 即可 */
        /* ================= 初始化系统进程的栈帧以及上下文环境 ================= */
        process->regs.cs = ((CS_LDT_INDEX * DESCRIPTOR_SIZE) | SA_TIL | rpl);
        process->regs.ds = ((DS_LDT_INDEX * DESCRIPTOR_SIZE) | SA_TIL | rpl);
        process->regs.es = process->regs.fs = process->regs.ss = process->regs.ds;  /* C 语言不加以区分这几个段寄存器 */
        process->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK | rpl);       /* gs 指向显存 */
        process->regs.eip = (reg_t) sys_proc->initial_eip;                 /* eip 指向要执行的代码首地址 */
        process->regs.esp = sys_proc_stack_base;                           /* 设置栈顶 */
        process->regs.eflags = is_task_proc(process) ? INIT_TASK_PSW : INIT_PSW;

        /* 进程刚刚初始化，让它处于可运行状态，所以标志位上没有1 */
        process->flags = CLEAN_MAP;
    }

}


PRIVATE void init_mul_process_by_ot() {
   /* 进程表的所有表项都被标志为空闲;
     * 对用于加快进程表访问的 p_proc_addr 数组进行初始化。
     */
    register process_t *proc;
    register int logic_nr;
    for(proc = BEG_PROC_ADDR, logic_nr = -NR_TASKS; proc < END_PROC_ADDR; proc++, logic_nr++) {
        if(logic_nr > 0)    /* 系统服务和用户进程 */
            memcpy(proc->name, "unused", 6);
        proc->logic_nr = logic_nr;
        p_proc_addr[logic_nr_2_index(logic_nr)] = proc;
    }

    /* 初始化多任务支持
     * 为系统任务和系统服务设置进程表，它们的堆栈被初始化为数据空间中的数组
     */
    sys_proc_t *sys_proc;
    reg_t sys_proc_stack_base = (reg_t) sys_proc_stack;
    u8_t  privilege;        /* CPU 权限 */
    u8_t rpl;               /* 段访问权限 */
    for(logic_nr = -NR_TASKS; logic_nr <= LOW_USER; logic_nr++) {   /* 遍历整个系统进程 */
        proc = proc_addr(logic_nr);                                 /* 拿到系统进程对应应该放在的进程指针 */
        sys_proc = &sys_proc_table[logic_nr_2_index(logic_nr)];     /* 系统进程项 */
        strcpy(proc->name, sys_proc->name);                         /* 拷贝名称 */
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
    }

}

PUBLIC void test_task_a(void) {
	int i, j, k;
	k = 0;
	while (TRUE)
	{
		for (i = 0; i < 100; i++) {
			for (j = 0; j < 1000000; j++) {

			}
		}
		k_printf("#{A} -> %d", k++);
	}
	
}

PUBLIC void test_task_b(void) {
	int i, j, k;
	k = 0;
	while (TRUE)
	{
		for (i = 0; i < 100; i++) {
			for (j = 0; j < 1000000; j++) {

			}
		}
		k_printf("#{B} -> %d", k++);
	}
}

PUBLIC void test_task_c(void) {
	int i, j, k;
	k = 0;
	while (TRUE)
	{
		for (i = 0; i < 100; i++) {
			for (j = 0; j < 1000000; j++) {

			}
		}
		k_printf("#{C} -> %d", k++);
	}
}