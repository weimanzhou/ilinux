
; FAT12 文件系统参数
BS_OEMName		DB '--snow--'	; OEM String, ���� 8 ���ֽ�
BPB_BytsPerSec	DW 512			; ÿ�����ֽ���
BPB_SecPerClus	DB 1			; ÿ�ض�������
BPB_RsvdSecCnt	DW 1			; Boot ��¼ռ�ö�������
BPB_NumFATs		DB 2			; ���ж��� FAT ��
BPB_RootEntCnt	DW 224			; ��Ŀ¼�ļ������ֵ
BPB_TotSec16	DW 2880			; �߼���������
BPB_Media		DB 0xF0			; ý��������
BPB_FATSz16		DW 9			; ÿFAT������
BPB_SecPerTrk	DW 18			; ÿ�ŵ�������
BPB_NumHeads	DW 2			; ��ͷ��(����)
BPB_HiddSec		DD 0			; ����������
BPB_TotSec32	DD 0			; ��� wTotalSectorCount �� 0 �����ֵ��¼������
BS_DrvNum		DB 0			; �ж� 13 ����������
BS_Reserved1	DB 0			; δʹ��
BS_BootSig		DB 29h			; ��չ������� (29h)
BS_VolID		DD 0			; �����к�
BS_VolLab		DB '-snowflake-'; ����, ���� 11 ���ֽ�
BS_FileSysType	DB 'FAT12   '	; �ļ�ϵͳ����, ���� 8���ֽ�  

;============================================================================
;����
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory ռ�õ�������, ��ѭ���л�ݼ�����.
wSectorNo		dw	0		; Ҫ��ȡ��������
bOdd			db	0		; ��������ż��

RootDirSectors			equ	14	; ��Ŀ¼ռ�ÿռ�
SectorNoOfRootDirectory	equ	19	; Root Directory �ĵ�һ��������
SectorNoOfFAT1			equ	1	; FAT1 �ĵ�һ��������	= BPB_RsvdSecCnt
DeltaSectorNo			equ	17	; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
					; �ļ��Ŀ�ʼSector�� = DirEntry�еĿ�ʼSector�� + ��Ŀ¼ռ��Sector��Ŀ + DeltaSectorNo
