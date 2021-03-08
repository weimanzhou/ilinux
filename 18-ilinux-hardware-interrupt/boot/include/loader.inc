; 内核挂载点
; 注意：1. 必须与MAKEFILE中参数-Ttext的值相等
;		2. 这是个物理地址而不仅仅是个偏移，如果-Ttext的值为0x328000，则他的值也应该为0x328000
KERNEL_ENTRY_POINT_PHY_ADDR		equ 0x1000

; 页目录开始地址:1M
PAGE_DIR_BASE					equ 0x100000
; 页表开始地址:1M+4K
PAGE_TABLE_BASE					equ 0x101000

; LOADER.BIN 被加载的地址:段地址
LOADER_SEG						equ 0x9000
; 偏移地址
LOADER_OFFSET					equ 0x100
; LOADER.BIN 被加载到的位置---物理地址（=LOADER_SEG * 0x10）
LOADER_PHY_ADDR					equ	LOADER_SEG * 0x10

; KERNEL.BIN 被加载的地址：段地址
KERNEL_SEG						equ 0x7000
KERNEL_OFFSET					equ 0
KERNEL_PHY_ADDR					equ KERNEL_SEG * 0x10

; 为KERNEL.BIN装载保留的内存大小（字节），内核大小不应该超过这个大小
KERNEL_HAVE_SPACE				equ LOADER_PHY_ADDR - KERNEL_PHY_ADDR

; 引导启动参数
; 注意：
;	以下的宏应该和C代码里面的同步，它们在include/ilinux/config.h下
BOOT_PARAM_ADDR					equ 0x700
BOOT_PARAM_MAGIC				equ 0x328
