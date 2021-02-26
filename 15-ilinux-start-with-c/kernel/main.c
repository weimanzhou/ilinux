/*************************************************************************
	> File Name: main.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Sat 30 Jan 2021 10:07:03 PM CST
 ************************************************************************/

#include "kernel.h"
#include "protect.h" 

// 从第 10 行第 0 列开始显示

void low_print(char* str);

void ilinux_main(void) 
{

	display_position = (80 * 12 + 0) * 2;

	low_print("Hello C!!!");


	while(1) {}
}
