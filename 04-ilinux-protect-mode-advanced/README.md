保护模式进阶


nasm 宏定义

多行宏 %macro:

``assemlby
`%macro foo 2
    push rax
    push rbx
    mov rax,%1
    mov rbx,%2
    pop rbx
    pop rax
%endmacro
```
宏名称后的数字代表宏参数的个数，宏主体中的%1和%2分别代表实际的参数。使用如下方式调用:

foo 0x11,0x22

