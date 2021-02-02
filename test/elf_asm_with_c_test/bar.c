/*************************************************************************
	> File Name: bar.c
	> Author: snowflake
	> Mail: 278121951@qq.com 
	> Created Time: Mon 01 Feb 2021 07:08:04 PM CST
 ************************************************************************/

void myprint(char *msg, int len);

int choose(int a, int b) 
{
	if (a >= b) 
	{
		myprint("the 1st one\n", 13);
	}
	else 
	{
		myprint("the 2nd two\n", 13);
	}

	return 0;
}
