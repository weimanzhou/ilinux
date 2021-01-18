; 描述符
; usage: desciptor base, limit, attr
;		 base:	dd
;		 limit: dd(low 20 bits available)
;		 attr:  dw(lower 4 bits of higher byte are always 0)
%macro descriptor 3
	dw %2 & 0xFFFF		; 段界限 1					(2 字节)
	dw %1 & 0xFFFF		; 段基址 1					(2 字节)
	db (%1 >> 16) & 0xFF; 段基址 2					(1 字节)
	dw ((%2 >> 8) & 0x0F00) | (%3 & 0xF0FF)
						; 属性1 + 段界限2 + 属性2	(2 字节)
	db (%1 >> 24) & 0xFF; 段基址 3					(1 字节)
%endmacro ; 共8字节

;By Marcus Xing   
;boot/include/pm.inc   
;保护模式下的宏定义，供boot文件夹下的文件使用   
  
; 描述符类型   
DA_32       EQU 4000h   ; 32 位段   
  
  
; 存储段描述符类型   
DA_DRW      EQU   92h   ; 存在的可读写数据段属性值   
DA_C        EQU   98h   ; 存在的只执行代码段属性值   
