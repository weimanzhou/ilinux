org	0100h
	jmp LABEL_START

; 导入头文件
%include "loader.inc"			; 挂载点相关的常量
%include "fat12hdr.inc"			; 导入FAT12相关的常量
%include "pm.inc"				; 导入宏gdt

[SECTION .gdt]
; GDT
LABEL_GDT:			descriptor	0, 0, 0
LABEL_DESC_CODE32:	descriptor	0, 0xFFFFF, DA_CR | DA_32 | DA_LIMIT_4K		; 0~4G，32位可读代码段，粒度为4KB
; LABEL_DESC_CODE32:	descriptor	0, 0xFFFF, DA_C + DA_32
LABEL_DESC_DATA:	descriptor	0, 0xFFFFF, DA_DRW | DA_32 | DA_LIMIT_4K	; 0~3G，32位可读写数据段，粒度为4KB
; LABEL_DESC_DATA:	descriptor	0, DATA_LEN - 1, DA_DRW
LABEL_DESC_VIDEO:	descriptor	0xB8000, 0xFFFFF, DA_DRW | DA_DPL3			; 视频段，特权级为3（用户特权级）


; GDT END

GDT_LEN				equ $ - LABEL_GDT
GDT_PTR				dw GDT_LEN
					dd LOADER_PHY_ADDR + LABEL_GDT

; GDT SELECTOR
SELECTOR_CODE32		equ LABEL_DESC_CODE32	- LABEL_GDT
SELECTOR_DATA		equ LABEL_DESC_DATA		- LABEL_GDT
SELECTOR_VIDEO		equ LABEL_DESC_VIDEO	- LABEL_GDT | SA_RPL3	; 视频段选择字，特权级3（用户特权级）

BASE_OF_STACK		equ 0x100

[SECTION .code16]
align 16
[bits 16]
LABEL_START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BASE_OF_STACK

	; 清屏操作
	mov	ax, 0600h		; AH = 6,  AL = 0h
	mov	bx, 0700h		; (BH = 07h): 0111      light gray
	mov	cx, 0			; 屏幕左上角: (00, 00)
	mov	dx, 0x184f		; 屏幕右下角: (80, 50)
	int	10h				; int 10h

	mov dh, 0
	call DISP_STR

	; 检查并得到内存信息
	mov ebx, 0		; 得到后续的内存信息的值，第一次必须为0
	mov di, _MEM_CHK_BUF; es:di 指向准备写入ADRS的缓冲区地址
LABEL_MEM_CHK_LOOP:
	mov eax, 0x0000E820	; eax=0x0000E820
	mov ecx, 20			; ecx=ADRS的大小
	mov edx, 0x534D4150 ; 约定签名 "SMAP"
	int 0x15			; 得到ADRS

	jc LABEL_MEM_CHK_ERROR
						; 产生了一个进位标志，CF=1，检查得到ADRS错误
	; CF=0
	add di, 20			; di += 20，es:di指向缓冲区准备放入的下一个ADRS的地址
	inc dword [_DD_MCR_COUNT]	
						;ADRS的数量++

	cmp ebx, 0
	je LABEL_MEM_CHK_FINISH					; ebx=0 表示拿到最后一个ADRS，完成检查并跳出循环
	; ebx!=0，表示还没有拿到最后一个，继续循环
	jmp LABEL_MEM_CHK_LOOP

LABEL_MEM_CHK_ERROR:
	mov dword [_DD_MCR_COUNT], 0			; 检查失败，ADRS数量为0

	mov dh, 1
	call DISP_STR

	jmp $

LABEL_MEM_CHK_FINISH:
	; mov dh, 2
	; call DISP_STR

	; jmp $

	xor	ah, ah								; ��
	xor	dl, dl								; �� ������λ：
	int	13h									; ��
	
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0		; ��
	jz	LABEL_NO_LOADERBIN					; �� �жϸ�Ŀ¼���ǲ����Ѿ�����
	dec	word [wRootDirSizeForLoop]			; �� ��������ʾû���ҵ� LOADER.BIN
	mov	ax, KERNEL_SEG
	mov	es, ax								; es <- BaseOfLoader
	mov	bx, KERNEL_OFFSET					; bx <- OffsetOfLoader	����, es:bx = BaseOfLoader:OffsetOfLoader
	mov	ax, [wSectorNo]						; ax <- Root Directory �е�ĳ Sector ��
	mov	cl, 1
	call	READ_SECTOR

	mov	si, KERNEL_FILE_NAME				; ds:si -> "LOADER  BIN"
	mov	di, KERNEL_OFFSET					; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0								; ��ѭ����������,
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR	; ������Ѿ�������һ�� Sector,
	dec	dx									; ����������һ�� Sector
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	; TODO
	jz LABEL_FILENAME_FOUND
	dec	cx
	lodsb									; ds:si -> al
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT						; ֻҪ���ֲ�һ�����ַ��ͱ����� DirectoryEntry ����
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME					;	����ѭ��

LABEL_DIFFERENT:
	and	di, 0FFE0h							; else ��	di &= E0 Ϊ������ָ����Ŀ��ͷ
	add	di, 20h								;     ��
	mov	si, KERNEL_FILE_NAME				;     �� di += 20h  ��һ��Ŀ¼��Ŀ
	jmp	LABEL_SEARCH_FOR_LOADERBIN			;    ��

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 3								; "No KERNEL."
	call	DISP_STR						; ��ʾ�ַ���
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h							; ��
	int	21h									; ��û���ҵ� KERNEL.BIN, �ص� DOS
%else
	jmp	$									; û���ҵ� KERNEL.BIN, ��ѭ��������
%endif

LABEL_FILENAME_FOUND:						; �ҵ� KERNEL.BIN ��������������
	mov	ax, RootDirSectors
	and	di, 0FFE0h							; di -> ��ǰ��Ŀ�Ŀ�ʼ
	add	di, 01Ah							; di -> �� Sector
	mov	cx, word [es:di]
	push	cx								; ����� Sector �� FAT �е����
	add	cx, ax
	add	cx, DeltaSectorNo					; ������ʱ cl ������ LOADER.BIN ����ʼ������ (�� 0 ��ʼ�������)
	mov	ax, KERNEL_SEG
	mov	es, ax								; es <- BaseOfLoader
	mov	bx, KERNEL_OFFSET					; bx <- OffsetOfLoader	����,
											; es:bx = BaseOfLoader:OffsetOfLoader = BaseOfLoader * 10h + OffsetOfLoader
	mov	ax, cx								; ax <- Sector ��

LABEL_GOON_LOADING_FILE:
	push	ax								; ��
	push	bx								; ��
	mov	ah, 0Eh								; �� ÿ��һ���������� "Booting  " �����һ����, �γ�������Ч��:
	mov	al, '.'								; ��
	mov	bl, 0Fh								; �� Booting ......
	int	10h									; ��
	pop	bx									; ��
	pop	ax									; ��

	mov	cl, 1
	call	READ_SECTOR
	pop	ax				; ȡ���� Sector �� FAT �е����
	call	GET_FAT_ENTRY
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax			; ���� Sector �� FAT �е����
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
	; 文件找到并加载之后，跳转到这个位置运行
	; jmp	KERNEL_SEG:KERNEL_OFFSET	; 

	mov dh, 4
	call DISP_STR

	call KILL_MOTOR

	; 1. 加载gdt
	lgdt [GDT_PTR]

	cli

	in al, 0x92
	or al, 0x02
	out 0x92, al

	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp dword SELECTOR_CODE32:LABEL_PM_32_START + LOADER_PHY_ADDR

	jmp $



DISP_STR:
	mov ax, MESSAGE_LENGTH
	mul dh
	add ax, BOOT_MESSAGE
	mov bp, ax
	mov ax, ds
	mov es, ax
	mov cx, MESSAGE_LENGTH
	mov ax, 0x1301
	mov bx, 0x0007
	mov dl, 0
	int 10h
	ret

;----------------------------------------------------------------------------
; ������: ReadSector
;----------------------------------------------------------------------------
; ����:
;	�ӵ� ax �� Sector ��ʼ, �� cl �� Sector ���� es:bx ��
READ_SECTOR:
	; -----------------------------------------------------------------------
	; �������������������ڴ����е�λ�� (������ -> �����, ��ʼ����, ��ͷ��)
	; -----------------------------------------------------------------------
	; ��������Ϊ x
	;                           �� ����� = y >> 1
	;       x           �� �� y ��
	; -------------- => ��      �� ��ͷ�� = y & 1
	;  ÿ�ŵ�������     ��
	;                   �� �� z => ��ʼ������ = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; �ٳ������ֽڵĶ�ջ���򱣴�Ҫ����������: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; ���� bx
	mov	bl, [BPB_SecPerTrk]	; bl: ����
	div	bl				; y �� al ��, z �� ah ��
	inc	ah				; z ++
	mov	cl, ah			; cl <- ��ʼ������
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (��ʵ�� y/BPB_NumHeads, ����BPB_NumHeads=2)
	mov	ch, al			; ch <- �����
	and	dh, 1			; dh & 1 = ��ͷ��
	pop	bx			; �ָ� bx
	; ����, "�����, ��ʼ����, ��ͷ��" ȫ���õ� ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; �������� (0 ��ʾ A ��)
.GO_ON_READING:
	mov	ah, 2			; ��
	mov	al, byte [bp-2]		; �� al ������
	int	13h
	jc	.GO_ON_READING		; �����ȡ���� CF �ᱻ��Ϊ 1, ��ʱ�Ͳ�ͣ�ض�, ֱ����ȷΪֹ

	add	esp, 2
	pop	bp

	ret

;----------------------------------------------------------------------------
; ������: GetFATEntry
;----------------------------------------------------------------------------
; ����:
;	�ҵ����Ϊ ax �� Sector �� FAT �е���Ŀ, ������� ax ��
;	��Ҫע�����, �м���Ҫ�� FAT �������� es:bx ��, ���Ժ���һ��ʼ������ es �� b
GET_FAT_ENTRY:
	push	es
	push	bx
	push	ax
	mov	ax, LOADER_SEG	; ��
	sub	ax, 0100h		; �� �� BaseOfLoader �������� 4K �ռ����ڴ�� FAT
	mov	es, ax			; ��
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- ��, dx <- ����
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;ż��
	xor	dx, dx			; ���� ax ���� FATEntry �� FAT �е�ƫ����. ���������� FATEntry ���ĸ�������(FATռ�ò�ֹһ������)
	mov	bx, [BPB_BytsPerSec]
	div	bx			; dx:ax / BPB_BytsPerSec  ==>	ax <- ��   (FATEntry ���ڵ���������� FAT ��˵��������)
					;				dx <- ���� (FATEntry �������ڵ�ƫ��)��
	push	dx
	mov	bx, 0			; bx <- 0	����, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h
	add	ax, SectorNoOfFAT1	; �˾�ִ��֮��� ax ���� FATEntry ���ڵ�������
	mov	cl, 2
	call	READ_SECTOR		; ��ȡ FATEntry ���ڵ�����, һ�ζ�����, �����ڱ߽緢������, ��Ϊһ�� FATEntry ���ܿ�Խ��������
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:
	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------


KILL_MOTOR:
	push dx
	mov dx, 0x03F2
	mov al, 2
	out dx, al
	pop dx
	ret


[SECTION .code32]
align 32
[bits 32]
LABEL_PM_32_START:
	; TODO
	mov ax, SELECTOR_DATA
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax

	mov esp, TOP_OF_STACK

	mov ax, SELECTOR_VIDEO
	mov gs, ax

	; 显示数据
	mov edi, (80 * 10 + 0) * 2		; 屏幕第9行，第0列
	mov ah, 0x0C					; 0000:黑底 1100:红字
	mov al, 'P'
	mov word [gs:edi], ax			; 将数据写入到显存中
	add edi, 2
	mov al, 'M'
	mov word [gs:edi], ax


	call FUN_CAL_MM_SIZE			; 计算内存大小

	call FUN_PRINT_MM_SIZE			; 显示内存大小

	call FUN_SETUP_PAGING			; 开启分页

	

	jmp $

; =====================================================================
; 计算内存大小
; ---------------------------------------------------------------------
FUN_CAL_MM_SIZE:						
	push esi
	push edi
	push ecx
	push edx

	mov esi, MEM_CHK_BUF				; ds:esi 指向缓冲区
	mov ecx, [DD_MCR_COUNT]				; ecx=有多少个ADRS，记为i
.loop:									
	mov edx, 5							; ADRS有5个成员变量，记为j
	mov edi, ADRS						; ds:edi -> 一个ARDS结构
.1:										
	push dword [esi]					; 
	pop eax								; ds:eax -> 缓冲区中的第一个ARDS结构
	stosd								; 将ds:eax中的一个dword内容拷贝到ds:edi，填充ADRS结构，并edit+4 
	add esi, 4							; ds:esi -> 指向ADRS中的下一个变量
	dec edx								; j--
	
	cmp edx, 0							; 									
	jnz .1								; 如果数据没有填充完毕，将继续填充
	
	cmp dword [DD_TYPE], 1				; 
	jne .2								; 

	mov eax, [DD_BASE_ADDR_LOW]			; eax 为基地址低32位
	add eax, [DD_SIZE_LOW]				; eax = 基地址低32位 + 长度低32位 --> 这个ARDS结构指代的内存的大小
										; 为什么不算高32位，因为32位可以表示0~4G大小的内存，而32位CPU也只能到4G
										; 我们编写的是32位操作系统，高32位系统是为64位操作系统准备的，我们不需要

	cmp eax, [DD_MEM_SIZE]
	jb .2

	mov [DD_MEM_SIZE], eax				; 内存大小为 = 最后一个基地址最大的ARDS的基地址32位+长度低32位 
.2:
	loop .loop							; ecx--, jmp .loop  

	pop edx
	pop ecx
	pop edi
	pop esi

	ret
		

; =====================================================================
; 打印内存大小函数
; ---------------------------------------------------------------------
FUN_PRINT_MM_SIZE:
	push ebx
	push ecx

	mov eax, [DD_MEM_SIZE]				; 存放内存大小
	xor edx, edx

	mov ebx, 1024

	div ebx								; eax / 1024 (KB)
										; ax 为商，dx为余数
	push eax
	; 显示一个字符串"MEMORY SIZE"
	push STR_MEM_INFO
	call FUN_PRINT
	add esp, 4
	pop eax								; 重置栈顶指针
	; 将内存大小显示
	push eax							; 将一个数字压入栈
	call FUN_PRINT_INT					; 调用显示数字函数
	add esp, 4							; 重置栈顶指针

	; 显示"KB"
	push STR_KB
	call FUN_PRINT
	add esp, 4							; 重置栈顶指针

	pop ecx
	pop ebx

	ret
	

; =====================================================================
; 保护模式下：打印字符串
; arg: 字符串的地址
; ---------------------------------------------------------------------
FUN_PRINT:
	push esi
	push edi
	push ebx
	push ecx
	push edx

	mov esi, [esp + 4 * 6]				; 得到字符串地址
	mov edi, [DD_DISP_POSITION]			; 得到显示位置
	mov ah, 0x0f

.1:
	lodsb								; ds:esi -> al，esi++
	test al, al

	jz .print_end						; 遇到了0结束打印

	cmp al, 10
	jz .print_nl						; 打印换行符
	; 如果不是换行符，也不是\0，那我们认为是一个可以打印的字符
	mov [gs:edi], ax					; 将字符显示
	add edi, 2							; 调整偏移量
	jmp .1 

.print_nl:
	call FUN_PRINT_NL					; 打印换行符，也就是换行
	jmp .1 

.print_end:
	mov dword [DD_DISP_POSITION], edi	; 打印完毕更新显示

	pop edx
	pop ecx
	pop ebx
	pop edi
	pop esi

	ret

; =====================================================================
; 显示一个整数
; ---------------------------------------------------------------------
FUN_PRINT_INT:
	mov ah, 0x0F						; 设置黑底白字
	mov al, '0'
	push edi
	mov edi, [DD_DISP_POSITION]
	mov [gs:edi], ax
	add edi, 2
	mov al, 'X'
	mov [gs:edi], ax
	add edi, 2
	mov [DD_DISP_POSITION], edi			; 显示完毕后重置光标位置
	pop edi

	mov eax, [esp + 4]
	shr eax, 24
	call FUN_PRINT_AL

	mov eax, [esp + 4]
	shr eax, 16
	call FUN_PRINT_AL

	mov eax, [esp + 4]
	shr eax, 8
	call FUN_PRINT_AL

	mov eax, [esp + 4]
	call FUN_PRINT_AL

	ret


; =====================================================================
; 显示AL中的数字
; ---------------------------------------------------------------------
FUN_PRINT_AL:
	push eax
	push ecx
	push edx
	push edi
    
	mov edi, [DD_DISP_POSITION]			; 取得当前光标所在位置

	mov ah, 0x0F						; 设置黑底白字
	mov dl, al							; dl = al
	shr al, 4							; al 右移 4 位
	mov ecx, 2							; 设置循环次数

.begin:
	and al, 01111b
	cmp al, 9
	ja .1
	add al, '0'
	jmp .2

.1:
	sub al, 10
	add al, 'A'

.2:
	mov [gs:edi], ax
	add edi, 2

	mov al, dl
	loop .begin

	mov [DD_DISP_POSITION], edi			; 显示完毕后更新光标位置

	pop edi
	pop ecx
	pop edx
	pop eax

	ret


FUN_PRINT_NL:
	push edi
	push ebx 
	push eax


	mov edi, [DD_DISP_POSITION]
	mov eax, edi
	mov bl, 160
	div bl
	
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax

	mov [DD_DISP_POSITION], edi

	pop eax								; 
	pop ebx 
	pop edi 

	ret 

; =====================================================================
; 启动分页机制
; 根据内存大小来计算初始化多少的PDE以及多少的PTE，我们给每页分配4KB大小
; 32操作系统一般是为4K，（Windows）
; 注意：
;	页目录表存放在1  M（0x100000）~1.4M处（0x101000）
;	所有页表存放在1.4M（0x101000）~5.4M处（0x501000）
; ---------------------------------------------------------------------
FUN_SETUP_PAGING:
	xor edx, edx						; edx=0
	mov eax, [DD_MEM_SIZE]				; eax 为内存大小
	mov ebx, 0x400000					; 0x400000 = 4M = 4096 * 1024, 
										; 即一个页表的大小
	div ebx								; 内存大小 / 4M
	mov ecx, eax						; ecx = 页表项的个数，即PDE的个数
	test edx, edx
	jz .no_remainder					; 每有余数
	inc ecx

.no_remainder:
	push ecx							; 保存页表个数
	; ilinux 为了简化处理，所有线性地址对应相应的物理地址，并且暂不考虑内存的空间

	; 首先初始化页目录
	mov ax, SELECTOR_DATA
	mov es, ax
	mov edi, PAGE_DIR_BASE				; edi = 页目录存放的首地址
	xor eax, eax

	; eax = PDE，PG_P（该页存在），PS_US_U（用户级页表），PG_RW_W（可读、写、执行）

	mov eax, PAGE_TABLE_BASE | PG_P | PG_US_U | PG_RW_W
.setup_pde:
	stosd								; 将ds:eax中的一个dword内容拷贝到ds:edi中，填充页目录表结构

	add eax, 4096						
	loop .setup_pde

	; 现在开始初始化所有页表

	pop eax								; 取出页表个数
	mov ebx, 1024						; 每个页表可以存放1024个PTE
	mul ebx								; 页表个数 * 1024，得到需要多少个PTE
	mov ecx, eax 
	mov edi, PAGE_TABLE_BASE			; edi = 页表存放的首地址
	xor eax, eax
	; eax = PTE， 页表从物理地址 0 开始映射，所以 0x0 | 后面的属性，该句可有可无，但是这样看折比较直观
	mov eax, 0x | PG_P | PG_US_U | PG_RW_W

.setup_pte:
	stosd
	add eax, 4096
	loop .setup_pte	

	; 最后设置cr3寄存器和cr0，开启分页机制
	mov eax, PAGE_DIR_BASE
	mov cr3, eax						; 将 PAGE_DIR_BASE 存储到 cr3 中
	mov eax, cr0
	or eax, 0x80000000					; 将 cr0 中的 PG位 置位
	mov cr0, eax

	jmp short .setup_pgok				; 和进入保护模式一样，一个跳转指令使其生效，
										; 表明是一个短跳转，其实不表明也可以

.setup_pgok:
	nop									; 一个小延迟，让CPU反应一下（为什么要反应呢？）
	nop
	ret 


[SECTION .data32]
align 32
DATA32:
; =====================================================================
; 实模式下的数据
; ---------------------------------------------------------------------
_DD_MCR_COUNT:			dd 0
_DD_MEM_SIZE:			dd 0
_STR_TEST:				dd "Print ~~~", 10, 0
_STR_KB:				dd "KB", 10, 0
_STR_MEM_INFO:			dd "MEMORY SIZE:", 0
; 存储当前光标所在位置
_DD_DISP_POSITION:		dd (80 * 6 + 0) * 2
; 地址范围描述符结构（Address Range Descriptor Structor）
_ADRS:
	_DD_BASE_ADDR_LOW:	dd 0			; 基地址低32位
	_DD_BASE_ADDR_HIG:	dd 0			; 基地址高32位
	_DD_SIZE_LOW:		dd 0			; 内存大小低32位
	_DD_SIZE_HIG:		dd 0			; 内存大小高32位
	_DD_TYPE:			dd 0			; ADRS类型
; 内存检查结果缓冲区，用于存放没检查的ADRS结构，256字节是为了对齐32位，
; 256/20=12.8，所以这个缓冲区可以存放12个ADRS
_MEM_CHK_BUF:			times 256 db 0


; =====================================================================
; 保护模式下的数据
; ---------------------------------------------------------------------
DD_MCR_COUNT:			equ LOADER_PHY_ADDR + _DD_MCR_COUNT 
DD_MEM_SIZE:			equ LOADER_PHY_ADDR + _DD_MEM_SIZE
STR_TEST:				equ LOADER_PHY_ADDR + _STR_TEST
STR_KB:					equ LOADER_PHY_ADDR + _STR_KB
STR_MEM_INFO:			equ LOADER_PHY_ADDR + _STR_MEM_INFO
DD_DISP_POSITION:		equ LOADER_PHY_ADDR + _DD_DISP_POSITION
; 地址范围描述符结构（Aequress Range Descriptor Structor）
ADRS:					equ LOADER_PHY_ADDR + _ADRS
	DD_BASE_ADDR_LOW:	equ LOADER_PHY_ADDR + _DD_BASE_ADDR_LOW		; 基地址低32位
	DD_BASE_ADDR_HIG:	equ LOADER_PHY_ADDR + _DD_BASE_ADDR_HIG		; 基地址高32位
	DD_SIZE_LOW:		equ LOADER_PHY_ADDR + _DD_SIZE_LOW			; 内存大小低32位
	DD_SIZE_HIG:		equ LOADER_PHY_ADDR + _DD_SIZE_HIG			; 内存大小高32位
	DD_TYPE:			equ LOADER_PHY_ADDR + _DD_TYPE				; ADRS类型
MEM_CHK_BUF:			equ LOADER_PHY_ADDR + _MEM_CHK_BUF			; 


DATA_LEN				equ $ - DATA32


; =====================================================================
; 字符串常量
; ---------------------------------------------------------------------
KERNEL_FILE_NAME	db "KERNEL  BIN", 0 ; 内核文件名

MESSAGE_LENGTH		equ 13
BOOT_MESSAGE:		db "HELLO WORD   "
					db "MEM CHK ERROR"
					db "MEM CHK OK..."
					db "NO KERNEL...."
					db "HELLO KERNEL."


; 堆栈段
[SECTION .gs]
align 32
LABEL_STACK:		times 512 db 0
TOP_OF_STACK		equ $ - LABEL_STACK

