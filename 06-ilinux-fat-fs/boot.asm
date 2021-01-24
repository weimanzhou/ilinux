; int 10h / ah = 0x13 document http://www.ablmcc.edu.hk/~scy/CIT/8086_bios_and_dos_interrupts.htm#int10h_13h
; define _BOOT_DEBUG_
%ifdef _BOOT_DEBUG_
	org 0x0100					; 调试状态，做成 .com 文件，可调试
%else
	org 0x7c00					; Boot 状态，BIOS将把 bootector
								; 加载到 0:7c00 处并开始执行
%endif

jmp short LABEL_START
nop


BS_OEMName		DB '---XX---'	; OEM string, 必须是 8 个字节
BPB_BytsPerSec	DW 0x0200		; 每扇区字节数
BPB_SecPerClus	DB 0x01			; 每簇多少个扇区
BPB_RsvdSecCnt	DW 0x01			; Boot 记录占用多少扇区
BPB_NumFATs		DB 0x02			; 共有多少 FAT 表
BPB_RootEntCnt	DW 0xe0			; 根目录文件最大数
BPB_TotSec16	DW 0x0b40		; 逻辑扇区总数
BPB_Media		DB 0xF0			; 媒体描述符
BPB_FATSz16		DW 0x09			; 每FAT扇区数
BPB_SecPerTrk	DW 0x12			; 每磁道扇区数
BPB_NumHeads	DW 0x02			; 磁头数（面数）
BPB_HiddSec		DD 0			; 隐藏扇区数
BPB_TotSec32	DD 0			; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
BS_DrvNum		DB 0			; 中断13的驱动器号
BS_Reserved1	DB 0			; 未使用
BS_BootSig		DB 0x29			; 扩展引导标记（29h）
BS_VolID		DD 0			; 卷序列号
BS_VolLab		DB 'snowflake01'; 卷标，必须11个字节
BS_FileSysType	DB 'FAT12'		; 文件系统类型，必须8个字节''''''

stack_base equ 0x7c00

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, stack_base

	; 进行磁盘复位
	xor ah, ah
	xor dl, dl
	int 13h

	; 下面在A盘的根目录寻找loader.bin
	mov word [W_SECTOR_NO], SECTOR_NO_OF_ROOT_DIRECTORY
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp word [W_ROOT_DIR_SIZE_FOR_LOOP], 0	; 判断根目录区是否已经读完,
	jz LABEL_NO_LOADERBIN					; 如果读完表示没有找到loader.bin
	dec word [W_ROOT_DIR_SIZE_FOR_LOOP]
	mov ax, BASE_OF_LOADER
	mov es, ax
	mov bx, OFFSET_OF_LOADER
	mov ax, [W_SECTOR_NO]
	mov cl, 1
	call read_sector

	mov si, LOADER_FILE_NAME
	mov di, OFFSET_OF_LOADER

	cld
	mov dx, 10h

LABEL_SEARCH_FOR_LOADERBIN:
	cmp dx, 0
	jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec dx
	mov cx, 11
LABEL_CMP_FILENAME:
	cmp cx, 0
	jz LABEL_FILENAME_FOUND
	dec cx
	lodsb
	cmp al, byte [es:di]
	jz LABEL_GO_ON
	jmp LABEL_DIFFERENT

LABEL_GO_ON:
	inc di
	jmp LABEL_CMP_FILENAME

LABEL_DIFFERENT:
	and di, 0xFFE0
	add di, 0x20
	mov si, LOADER_FILE_NAME
	jmp LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add word [W_SECTOR_NO], 1
	jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov dh, 2
	call disp_str

%ifdef _BOOT_DEBUG_
	mov ax, 0x4c00
	int 21h
%else
	jmp $
%endif

LABEL_FILENAME_FOUNT:
	jmp $

	; 进行清屏操作
	mov ax, 0x0600
	mov bx, 0x0700
	mov cx, 0
	mov dx, 0x0184f
	int 0x10

	mov cx, 0x09
	push cs
	pop es
	mov bp, boot_message

	call print_string

    jmp $			; 跳转到当前地址，实现循环


read_sector:		; 从第 ax 个sector开始，将el个sector读入es:bx中
	push bp
	mov bp, sp
	sub esp, 2		; 劈出2字节的堆栈区域保存要读的扇区数
					; byte [bp-2]
	mov byte [bp-2], el
	push bx			; 保存bx
	mov bl, [BPB_SEC_PER_TRK]	; b1: 除数
	div bl			; y在al中,z在ah中
	inc ah			; z++
	mov cl, ah		; cl <- 起始扇区号
	mov dh, al		; dh <- y
	shr al, 1		; y >> 1 (其实是y/BPB_NUM_HEADS),这里
					; BPB_NUM_HEADS=2
	mov ch, al		; ch <- 柱面号
	and dh, 1		; dh & 1 = 磁头号
	pop bx			; 恢复bx
	; 至此,*柱面号,起始扇区,磁头号*全部得到
	mov dl, [BS_DRV_NUM]	; 驱动器号(0表示A盘)
.GO_ON_READING:
	mov ah, 2				; 读
	mov al, byte [bp-2]		; 读al个扇区
	int 13h
	jc .GO_ON_READING:		; 如果读取错误,CF会被置1,这时不停的读,直到
							; 正确为止

	add esp, 2
	pop bp

	ret


DISP_STR:
	mov ax, MESSAGE_LENGTH
	mul dh
	add ax, BOOT_MESSAGE
	mov bp, ax
	mov ax, ds
	mov cx, MESSAGE_LENGTH
	mov ax, 0x1301
	mov bx, 0x0007
	mov dl, 0
	int 10h
	ret

boot_message:		dd "Booting......", 0	; 定义一个字符串为 dd 类型，并且后要添加一个 0，表示字符串的结束
boot_message_len:	; boot_message_len - boot_message 刚好为字符串的大小
BASE_OF_LOADER		equ 0x9000
OFFSET_OF_LOADER	equ 0x0100
ROOT_DIR_SECTORS	equ 14
; 变量
SECTOR_NO_OF_ROOT_DIRECTORY	equ 19

W_ROOE_DIR_SIZE_FOR_LOOP	dw RootDirSectors
W_SECTOR_NO					dw 0
B_ODD						db 0

; 字符串
LOADER_FILE_NAME			db "LOADER  BIN", 0	; loader.bin 文件名
; 为简化代码,下面每个字符串的长度均为MESSAGE_LENGTH
MOESSAGE_LENGTH		equ 9
BOOT_MESSAGE		db "Booting  "
MESSAGE1			db "Ready.   "
MESSAGE2			db "NO LOADER"

; ============================================================================
; time n m
;	n: 重复多少次
;	m: 重复的代码
; 	
;
; $	 : 当前地址
; $$ : 代表上一个代码的地址减去起始地址
; ============================================================================
times 510-($-$$) db 0	; 填充 0 
dw 0xaa55				; 可引导扇区标志,必须是 0xaa55,不然bios无法识别
