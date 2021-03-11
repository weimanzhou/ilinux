; =====================================================================
; 文件：asm_const.inc
; 作用：内核文件"kernel.asm"需要的常量
; 作者：snowflake
; 联系：
;   qq: 278121951
;   we: 278121951
; =====================================================================

; =====================================================================
; 自定义的一些常量
; ---------------------------------------------------------------------


; =====================================================================
; 与光标控制的一些常量
; ---------------------------------------------------------------------

VIDEO_INDEX_PORT    EQU 0X3D4           ; 索引寄存器的端口号
VIDEO_DATA_PORT     EQU 0X3D5           ; 数据端口 0x3d5

CURSOR_POS_HIG8_INDEX   EQU 0XE         ; 高八位
CURSOR_POS_LOW8_INDEX   EQU 0XF         ; 低八位

; =====================================================================
; 保护模式相关
; ---------------------------------------------------------------------


; =====================================================================
; 多进程相关
; ---------------------------------------------------------------------
; stackframe 栈帧结构中每个属性的偏移
P_STACKBASE         equ 0               ; 栈基地址
GSREG               equ P_STACKBASE     ; GS段寄存器
FSREG               equ GSREG + 4       ; FS段寄存器
ESREG               equ FSREG + 4       ; ES段寄存器
DSREG               equ ESREG + 4       ; DS段寄存器(数据段寄存器)
EDIREG              equ DSREG + 4       ; EDI寄存器
ESIREG              equ EDIREG + 4      ; ESI寄存器
EBPREG              equ ESIREG + 4      ; EBP寄存器
KERNELESPREG        equ EBPREG + 4      ; 内核ESP寄存器
EBXREG              equ KERNELESPREG + 4; EBX
EDXREG              equ EBXREG + 4      ; EDX
ECXREG              equ EDXREG + 4      ; ECX
EAXREG              equ ECXREG + 4      ; EAX
RETADDR             equ EAXREG + 4      ; 返回地址
PCREG               equ RETADDR + 4     ; PC
CSREG               equ PCREG + 4       ; CS
PWSREG              equ CSREG + 4
ESPREG              equ PWSREG + 4
SSREG               equ ESPREG + 4
P_STACKTOP          equ SSREG + 4       ; 栈顶
P_LDT_SEL           equ P_STACKTOP      ; LDT选择子
P_LDT               equ P_LDT_SEL + 4   ; LDT
; TSS::SP0 的偏移
TSS3_S_SP0          equ 4

; 软件中断
; 固定系统调用向量。 
INT_VECTOR_LEVEL0     equ      43	    ; 用于系统任务提权到 0 的调用向量 
INT_VECTOR_SYS_CALL   equ      47       ; flyanx 386 系统调用向量 


; 硬件中断相关
; 8259A终端控制器端口
INT_M_CTL           EQU 0x20        ; I/O port for interrupt controller         <Master>
INT_M_CTLMASK       EQU 0x21        ; setting bits in this port disables ints   <Master>
INT_S_CTL           EQU 0xA0        ; I/O port for second interrupt controller  <Slave> 
INT_S_CTLMASK       EQU 0xA1        ; setting bits in this port disables ints   <Slave> 
; 中断控制器的神奇数字EOI，可以用于控制中断的打开和关闭，当然，这个宏可以被类似功能的引用
EOI                 EQU 0x20        ; EOI，发送给8259A端口1，以重新启用中断
DISABLE             EQU 0           ; 用于在中断后保持当前中断关闭的代码
ENABLE              EQU EOI	        ; 用于在中断后重新启用当前中断的代码


; 以下选择字必须与 protect.h 保持一致
SELECTOR_TEXT       equ 8               ; LOADER 里面已经确定了的
SELECTOR_DATA       equ 16              ; LOADER 里面已经确定了的，可读写数据段
SELECTOR_TSS        equ 32              ; TSS（任务状态段选择字）, 从外层
                                        ; 调到内存时 SS 和 ESP 的值从里面获得

SELECTOR_KERNEL_CS  equ SELECTOR_TEXT   ; 内核代码段
SELECTOR_KERNEL_DS  equ SELECTOR_DATA   ; 内核数据段
; =====================================================================

