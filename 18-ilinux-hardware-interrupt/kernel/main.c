/*************************************************************************
	> File Name: main.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Sat 30 Jan 2021 10:07:03 PM CST
 ************************************************************************/

#include "kernel.h"
#include "protect.h" 
#include "assert.h"

// 初始化断言，这个地方一定要初始化，才可以利用编译器的 __FILE__ 宏获取到文件名词
INIT_ASSERT				

// 从第 10 行第 0 列开始显示

void low_print(char* str);

void ilinux_main(void) 
{

	display_position = (80 * 12 + 0) * 2;

	low_print("Hello C!!!\n");

	clock_task();

	// test_int_0();

	// asm("int 0");

	// 测试零除错误
	// int a = 0;
	// int b = 5 / a;

	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");

	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");


	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");
	// low_print("Hello C!!!\n");

	// assert(1 == 3);

	while(1) {}
}
