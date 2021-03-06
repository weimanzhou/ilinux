
;%define	_BOOT_DEBUG_	; �� Boot Sector ʱһ��������ע�͵�!�����д򿪺��� nasm Boot.asm -o Boot.com ����һ��.COM�ļ����ڵ���

%ifdef	_BOOT_DEBUG_
	org  0100h			; ����״̬, ���� .COM �ļ�, �ɵ���
%else
	org  07c00h			; Boot ״̬, Bios ���� Boot Sector ���ص� 0:7C00 ������ʼִ��
%endif

;================================================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack		equ	0100h	; ����״̬�¶�ջ����ַ(ջ��, �����λ����͵�ַ����)
%else
BaseOfStack		equ	07c00h	; Boot״̬�¶�ջ����ַ(ջ��, �����λ����͵�ַ����)
%endif

BaseOfLoader		equ	09000h	; LOADER.BIN �����ص���λ�� ----  �ε�ַ
OffsetOfLoader		equ	0100h	; LOADER.BIN �����ص���λ�� ---- ƫ�Ƶ�ַ

RootDirSectors			equ	14	; ��Ŀ¼ռ�ÿռ�
SectorNoOfRootDirectory	equ	19	; Root Directory �ĵ�һ��������
SectorNoOfFAT1			equ	1	; FAT1 �ĵ�һ��������	= BPB_RsvdSecCnt
DeltaSectorNo			equ	17	; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
					; �ļ��Ŀ�ʼSector�� = DirEntry�еĿ�ʼSector�� + ��Ŀ¼ռ��Sector��Ŀ + DeltaSectorNo
;================================================================================================

	jmp short LABEL_START		; Start to boot.
	nop				; ��� nop ������

	; ������ FAT12 ���̵�ͷ
	BS_OEMName		DB 'ForrestY'	; OEM String, ���� 8 ���ֽ�
	BPB_BytsPerSec	DW 512		; ÿ�����ֽ���
	BPB_SecPerClus	DB 1		; ÿ�ض�������
	BPB_RsvdSecCnt	DW 1		; Boot ��¼ռ�ö�������
	BPB_NumFATs		DB 2		; ���ж��� FAT ��
	BPB_RootEntCnt	DW 224		; ��Ŀ¼�ļ������ֵ
	BPB_TotSec16	DW 2880		; �߼���������
	BPB_Media		DB 0xF0		; ý��������
	BPB_FATSz16		DW 9		; ÿFAT������
	BPB_SecPerTrk	DW 18		; ÿ�ŵ�������
	BPB_NumHeads	DW 2		; ��ͷ��(����)
	BPB_HiddSec		DD 0		; ����������
	BPB_TotSec32	DD 0		; ��� wTotalSectorCount �� 0 �����ֵ��¼������
	BS_DrvNum		DB 0		; �ж� 13 ����������
	BS_Reserved1	DB 0		; δʹ��
	BS_BootSig		DB 29h		; ��չ������� (29h)
	BS_VolID		DD 0		; �����к�
	BS_VolLab		DB 'Tinix0.01  '; ����, ���� 11 ���ֽ�
	BS_FileSysType	DB 'FAT12   '	; �ļ�ϵͳ����, ���� 8���ֽ�  

LABEL_START:	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	; ����
	mov	ax, 0600h		; AH = 6,  AL = 0h
	mov	bx, 0700h		; �ڵװ���(BL = 07h)
	mov	cx, 0			; ���Ͻ�: (0, 0)
	mov	dx, 0184fh		; ���½�: (80, 50)
	int	10h			; int 10h

	mov	dh, 0			; "Booting  "
	call	DispStr			; ��ʾ�ַ���
	
	xor	ah, ah	; ��
	xor	dl, dl	; �� ������λ：
	int	13h	; ��
	
; ������ A �̵ĸ�Ŀ¼Ѱ�� LOADER.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; ��
	jz	LABEL_NO_LOADERBIN		; �� �жϸ�Ŀ¼���ǲ����Ѿ�����
	dec	word [wRootDirSizeForLoop]	; �� ��������ʾû���ҵ� LOADER.BIN
	mov	ax, BaseOfLoader
	mov	es, ax			; es <- BaseOfLoader
	mov	bx, OffsetOfLoader	; bx <- OffsetOfLoader	����, es:bx = BaseOfLoader:OffsetOfLoader
	mov	ax, [wSectorNo]	; ax <- Root Directory �е�ĳ Sector ��
	mov	cl, 1
	call	ReadSector

	mov	si, LoaderFileName	; ds:si -> "LOADER  BIN"
	mov	di, OffsetOfLoader	; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0										; ��ѭ����������,
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR	; ������Ѿ�������һ�� Sector,
	dec	dx											; ����������һ�� Sector
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND	; ����Ƚ��� 11 ���ַ������, ��ʾ�ҵ�
dec	cx
	lodsb				; ds:si -> al
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT		; ֻҪ���ֲ�һ�����ַ��ͱ����� DirectoryEntry ����
; ����Ҫ�ҵ� LOADER.BIN
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME	;	����ѭ��

LABEL_DIFFERENT:
	and	di, 0FFE0h						; else ��	di &= E0 Ϊ������ָ����Ŀ��ͷ
	add	di, 20h							;     ��
	mov	si, LoaderFileName					;     �� di += 20h  ��һ��Ŀ¼��Ŀ
	jmp	LABEL_SEARCH_FOR_LOADERBIN;    ��

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2			; "No LOADER."
	call	DispStr			; ��ʾ�ַ���
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h		; ��
	int	21h			; ��û���ҵ� LOADER.BIN, �ص� DOS
%else
	jmp	$			; û���ҵ� LOADER.BIN, ��ѭ��������
%endif

LABEL_FILENAME_FOUND:			; �ҵ� LOADER.BIN ��������������

	push es
	mov dh, 1
	call DispStr
	pop es


	

	jmp $

LABEL_GOON_LOADING_FILE:
	jmp $

LABEL_FILE_LOADED:

	mov	dh, 1			; "Ready."
	call	DispStr			; ��ʾ�ַ���

; *****************************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; ��һ����ʽ��ת���Ѽ��ص��ڴ��е� LOADER.BIN �Ŀ�ʼ��
						; ��ʼִ�� LOADER.BIN �Ĵ���
						; Boot Sector ��ʹ�����˽���
; *****************************************************************************************************



;============================================================================
;����
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory ռ�õ�������, ��ѭ���л�ݼ�����.
wSectorNo		dw	0		; Ҫ��ȡ��������
B_ODD			db	0		; ��������ż��

;============================================================================
;�ַ���
;----------------------------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	; LOADER.BIN ֮�ļ���
; Ϊ�򻯴���, ����ÿ���ַ����ĳ��Ⱦ�Ϊ MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "; 9�ֽ�, �������ÿո���. ��� 0
Message1			db	"Ready.   "; 9�ֽ�, �������ÿո���. ��� 1
Message2			db	"No LOADER"; 9�ֽ�, �������ÿո���. ��� 2
Message3			db	"Founded  "; 9�ֽ�, �������ÿո���. ��� 2
;============================================================================

;----------------------------------------------------------------------------
; ������: DispStr
;----------------------------------------------------------------------------
; ����:
;	��ʾһ���ַ���, ������ʼʱ dh ��Ӧ�����ַ������(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax			; ��
	mov	ax, ds			; �� ES:BP = ����ַ
	mov	es, ax			; ��
	mov	cx, MessageLength	; CX = ������
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	mov	dl, 0
	int	10h			; int 10h
	ret

;----------------------------------------------------------------------------
; ������: ReadSector
;----------------------------------------------------------------------------
; ����:
;	�ӵ� ax �� Sector ��ʼ, �� cl �� Sector ���� es:bx ��
ReadSector:
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
.GoOnReading:
	mov	ah, 2			; ��
	mov	al, byte [bp-2]		; �� al ������
	int	13h
	jc	.GoOnReading		; �����ȡ���� CF �ᱻ��Ϊ 1, ��ʱ�Ͳ�ͣ�ض�, ֱ����ȷΪֹ

	add	esp, 2
	pop	bp

	ret

GET_FAT_ENTRY:
	push es
	push bx
	push ax

	mov ax, BaseOfLoader
	sub ax, 0100h
	mov es, ax
	pop ax

	; 首先计算出簇号在FAT中的字节偏移量，然后需要计算出该簇号的奇偶性
	; 偏移值：簇号 / 2 * 3，因为三个字节表示两个簇号，所以字节和簇的比例为3:2
	mov byte [B_ODD], 0
	mov bx, 3 
	mul bx				; ax = ax * 3, dx存放高八位，ax存放低8位
	mov dx, 2
	div bx				; ax / 2 => ax:商 dx:余数
	cmp dx, 0
	jz LABEL_EVEN		; 如果是偶数则跳转到偶数处理部分
	mov byte [B_ODD], 1
LABEL_EVEN:				; 偶数
	xor dx, dx			; 现在 ax 中是FATEntry在FAT中的偏移量
	mov bx, [BPB_BytsPerSec]
	div bx
	push dx

	mov bx, 0			; bx:0 于是es:bx=(BaseOfLoader-100):00
	add ax, SectorNoOfFAT1
	mov cl, 2
	call ReadSector

	pop dx
	add bx, dx
	mov ax, [es:bx]
	cmp byte [B_ODD], 1
	jnz LABEL_EVEN_2
	shr ax, 4
LABEL_EVEN_2:
	and ax, 0FFFh
LABEL_GET_FAT_ENRY_OK:
	pop bx
	pop es
	ret


;----------------------------------------------------------------------------

times 	510-($-$$)	db	0	; ���ʣ�µĿռ䣬ʹ���ɵĶ����ƴ���ǡ��Ϊ512�ֽ�
dw 	0xaa55				; ������־
