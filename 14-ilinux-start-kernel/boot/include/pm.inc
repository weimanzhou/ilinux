; 描述符
; usage: desciptor base, limit, attr
;                base:  dd
;                limit: dd(low 20 bits available)
;                attr:  dw(lower 4 bits of higher byte are always 0)
%macro descriptor 3
        dw %2 & 0xFFFF          ; 段界限 1                                      (2 字节)
        dw %1 & 0xFFFF          ; 段基址 1                                      (2 字节)
        db (%1 >> 16) & 0xFF; 段基址 2                                  (1 字节)
        dw ((%2 >> 8) & 0x0F00) | (%3 & 0xF0FF)
                                                ; 属性1 + 段界限2 + 属性2       (2 字节)
        db (%1 >> 24) & 0xFF; 段基址 3                                  (1 字节)
%endmacro ; 共8字节

;%1 Selector
;%2 Offset
;%3 Para Count
;%4 Attr
;%macro gate 4
;       dw %2 & 0ffffh
;       dw %1 & 0ffffh
;       db %3 & 00011111b
;       db %4 & 0ffh
;       dw (%2 >> 16) & 0ffffh
;%endmacro


;%1 Descriptor's Offset
;%2 Segment's Offset
;%macro  fill_descriptor 2
;       xor eax,eax
;       mov ax,cs
;       shl eax,4
;       add eax,%2
;       mov word [%1 + 2],ax
;       shr eax,16
;       mov byte [%1 + 4],al
;       mov byte [%1 + 7],ah
;%endmacro''


;By Marcus Xing
;boot/include/pm.inc
;保护模式下的宏定义，供boot文件夹下的文件使用

; 描述符类型
DA_32       EQU 4000h   ; 32 位段
DA_LIMIT_4K EQU 8000h   ; 粒度4K

DA_DPL0     EQU   00h   ; DPL = 0
DA_DPL1     EQU   20h   ; DPL = 1
DA_DPL2     EQU   40h   ; DPL = 2
DA_DPL3     EQU   60h   ; DPL = 3

; 存储段描述符类型
DA_DR       EQU   90h   ; 存在的只读数据段类型值
DA_DRW      EQU   92h   ; 存在的可读写数据段属性值
DA_DRWA     EQU   93h   ; 存在的已访问可读写数据段类型值
DA_C        EQU   98h   ; 存在的只执行代码段属性值
DA_CR       EQU   9Ah   ; 存在的可执行可读代码段属性值
DA_CCO      EQU   9Ch   ; 存在的只执行一致代码段属性值
DA_CCOR     EQU   9Eh   ; 存在的可执行可读一致代码段属性值

; 系统段描述符类型
DA_LDT      EQU   82h   ; 局部描述符表段类型值
DA_TaskGate EQU   85h   ; 任务门类型值
DA_386TSS   EQU   89h   ; 可用 386 任务状态段类型值
DA_386CGate EQU   8Ch   ; 386 调用门类型值
DA_386IGate EQU   8Eh   ; 386 中断门类型值
DA_386TGate EQU   8Fh   ; 386 陷阱门类型值

; 选择子类型
SA_RPL0     EQU 0   ; ┓
SA_RPL1     EQU 1   ; ┣ RPL
SA_RPL2     EQU 2   ; ┃
SA_RPL3     EQU 3   ; ┛

SA_TIG      EQU 0   ; ┓TI
SA_TIL      EQU 4   ; ┛
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; 分页机制使用的常量说明
;----------------------------------------------------------------------------
PG_P            equ 1       ; 页存在属性
PG_RW_R         equ 0       ; R/W 属性位值，读/执行
PG_RW_W         equ 2       ; R/W 属性位值，读/写/执行
PG_US_S         equ 0       ; U/S 属性位值，系统级
PG_US_U         equ 4       ; U/S 属性位值，用户级
;----------------------------------------------------------------------------


