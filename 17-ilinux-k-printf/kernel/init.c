/*************************************************************************
	> File Name: init.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Wed 24 Feb 2021 05:52:48 PM CST
 ************************************************************************/

#include "kernel.h"
#include "protect.h" 


/*************************************************************************
	> 进入内核主函数前做一些初始化工作
    > 1. 保存内核数据段基地址
 *************************************************************************/
PUBLIC void ilinux_init(void) {

    // 1. 设置显示位置
    display_position = (80 * 6 + 2 * 0) * 2;

    low_print("------ init -----\n");

    // 2. 保存内核数据段基地址
    data_base = seg2phys(SELECTOR_KERNEL_DS);

    // 3. 初始化保护模式
    init_protect();

    // 4. 加载引导参数
    u32_t* p_boot_params = (u32_t*) BOOT_PARAM_ADDR;

    // 魔数错误
    if (p_boot_params[BP_MAGIC] != BOOT_PARAM_MAGIC) {
        // 魔数不对，引导参数有问题
        low_print("bad boot params, please reboot...\n");
        for (;;);
    }
    
    // 魔数正常，让引导参数指针指向它
    boot_params = (boot_params_t*) (BOOT_PARAM_ADDR + 4);

}