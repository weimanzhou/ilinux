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
	mov ebx, 0			; 得到后续的内存信息的值，第一次必须为0
	mov di, _MEM_CHK_BUF; es:di 指向准备写入ADRS的缓冲区地址
LABEL_MEM_CHK_LOOP:
	mov eax, 0x0000E820	; eax=0x0000E820
	mov ecx, 20			; ecx=ADRS的大小
	mov edx, 0x534D4150 ; "SMAP"
	int 0x15			; 得到ADRS

	jc LABEL_MEM_CHK_ERROR					; 产生了一个进位标志，CF=1，检查得到ADRS错误
	; CF=0
	add di, 20			; di += 20，es:di指向缓冲区准备放入的下一个ADRS的地址
	inc dword [_DD_MCR_COUNT]	;ADRS的数量++

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
	jz	LABEL_FILENAME_FOUND				; ����Ƚ��� 11 ���ַ������, ��ʾ�ҵ�
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


[SECTION .data32]
align 32
DATA32:
_DD_MCR_COUNT:			dd 0
_DD_MEM_SIZE:			dd 0
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

	jmp $

; 堆栈段
[SECTION .gs]
align 32
LABEL_STACK:		times 512 db 0
TOP_OF_STACK		equ $ - LABEL_STACK

