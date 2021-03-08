; =====================================================================
; 导入的函数或变量
; ---------------------------------------------------------------------
; 导入头文件
%include "asm_const.inc"


extern display_position

; =====================================================================
; 导出的函数或变量
; ---------------------------------------------------------------------
global low_print
global in_byte
global out_byte
global interrupt_lock
global interrupt_unlock
global enable_irq
global dsable_irq

global test_int_0

; =====================================================================
; 保护模式下：打印字符串
; arg: 字符串的地址
; ---------------------------------------------------------------------
low_print:
	push esi
	push edi
	push ebx
	push ecx
	push edx

	mov esi, [esp + 4 * 6]				; 得到字符串地址
	mov edi, [display_position]			; 得到显示位置
	mov ah, 0x0f

.1:
	lodsb								; ds:esi -> al，esi++
	test al, al

	jz .print_end						; 遇到了0结束打印

	; call FUN_SET_CURSOR_POSITION		; @TODO

	xchg bx, bx

	cmp al, 10
	je .print_nl						; 打印换行符
	; 如果不是换行符，也不是\0，那我们认为是一个可以打印的字符
	mov [gs:edi], ax					; 将字符显示
	add edi, 2							; 调整偏移量

	cmp edi, 4000						; 判断字符是否超出屏幕，如果是进行滚屏
	; jae .scroll_screen

.2:
	; push ax
	; call FUN_GET_CURSOR_POSITION
	; add ax, 2
	call FUN_SET_CURSOR_POSITION
	; pop ax
	jmp .1 

; ---------------------------------------------------------------------
; 滚动屏幕
; ---------------------------------------------------------------------
.scroll_screen:
	push ax
	push cx
	push esi

	; 拷贝字符
	; 源数据准备
	mov ax, gs
	mov ds, ax
	mov esi, 0xa0

	push edi

	; 目标准备
	mov es, ax
	mov edi, 0x00

	; 设置传输字节数
	mov cx, 1920

	; 设置方向
	cld

	; 开始传输
	rep movsw

	pop edi

	; 调整光标
	mov edi, 3840

	pop esi
	pop cx
	pop ax

	jmp .2

.print_nl:
	call FUN_PRINT_NL					; 打印换行符，也就是换行
	; mov edi, [display_position]
	jmp .1

.print_end:
	mov dword [display_position], edi	; 打印完毕更新显示

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
	mov edi, [display_position]
	mov [gs:edi], ax
	add edi, 2
	mov al, 'X'
	mov [gs:edi], ax
	add edi, 2
	mov [display_position], edi			; 显示完毕后重置光标位置
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
    
	mov edi, [display_position]			; 取得当前光标所在位置

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

	mov dword [display_position], edi			; 显示完毕后更新光标位置

	pop edi
	pop ecx
	pop edx
	pop eax

	ret


FUN_PRINT_NL:
	push ebx 
	push eax

	; mov eax, [display_position]
	mov eax, edi								; 
	mov bl, 160
	div bl

	inc eax
	mov bl, 160
	mul bl

	mov edi, eax

	; mov dword [display_position], eax

	pop eax										; 
	pop ebx 

	ret

; =====================================================================
; 设置光标的位置
; arg:
; 	edi: 字符要显示的位置，max(edi) = 25 * 80 * 2 (以下标的形式)
; ---------------------------------------------------------------------
FUN_SET_CURSOR_POSITION:
	push eax
	push bx
	push dx

	mov eax, edi								; 将显示位置暂存到 eax 中
	mov bx, ax
	shr bx, 1									; 由于每一个字符都要两个字节，而显示位置只需要一个字节
												; 存储的形式采取的是两字节形式，所以这个地方需要计算出下一个光标位置

	mov dx, VIDEO_INDEX_PORT
	mov al, CURSOR_POS_HIG8_INDEX
	out dx, al

	mov dx, VIDEO_DATA_PORT
	mov al, bh
	out dx, al
	
	mov dx, VIDEO_INDEX_PORT
	mov al, CURSOR_POS_LOW8_INDEX
	out dx, al

	mov dx, VIDEO_DATA_PORT
	mov al, bl
	out dx, al

	pop dx
	pop bx
	pop eax

	ret

; =====================================================================
; 取出光标的位置，将光标的位置存储到 edi 寄存器中
; ---------------------------------------------------------------------
FUN_GET_CURSOR_POSITION:
	push eax
	push dx

	mov dx, VIDEO_INDEX_PORT
	mov al, CURSOR_POS_HIG8_INDEX
	out dx, al

	mov dx, VIDEO_DATA_PORT
	in al, dx
	mov ah, al
	
	mov dx, VIDEO_INDEX_PORT
	mov al, CURSOR_POS_LOW8_INDEX
	out dx, al

	mov dx, VIDEO_DATA_PORT
	in al, dx

	; 左移一位，得出下一个字符要显示的位置
	shl ax, 1
	; 将计算出的位置存储到 edi 寄存器中
	or eax, 0x00FF
	mov edi, eax

	pop dx
	pop eax

	ret



; =====================================================================
; 从指定端口号读取一个数据
; 函数原型：u8_t in_byte(port_t port);
; ---------------------------------------------------------------------
align 16
in_byte:
	push edx

	mov edx, [esp + 4 * 2]							; 获取到端口号
	xor eax, eax
	in al, dx									; 读取数据到 al 中
	nop
	pop edx
	nop	
	ret

; =====================================================================
; 从指定端口号读取一个数据
; 函数原型：void out_byte(port_t port, U8_t value);
; ---------------------------------------------------------------------
align 16
out_byte:
	push edx

	mov edx, [esp + 4 * 2]						; 获取到端口号
	mov al, [esp + 4 * 3]						; 要输出的数据
	out dx, al									; 读取数据到 al 中
	nop
	pop edx
	nop	
	ret

; =====================================================================
; 关中断
; ---------------------------------------------------------------------
align 16
interrupt_lock:
	cli
	ret

; =====================================================================
; 开中断
; 函数原型：void interrupt_unlock(void);
; ---------------------------------------------------------------------
align 16
interrupt_unlock:
	sti
	ret


; =====================================================================
; 屏蔽特定中断
; 函数原型：void dsable_irq(int int_request)
; ---------------------------------------------------------------------
align 16
dsable_irq:
	pushf										; 将标志寄存器 EFLAGS 压栈，需要用到 test 指令，会改变 EFLAGS
	push eax

	cli											; 屏蔽全部中断

	mov ecx, [esp + 4 * 3]							; 取出要屏蔽的中断号 ecx = int_request

	; 判断中断来自哪一个 8259
	mov ah, 1									; ah = 00000001b
	rol ah, cl									; ah = ah << (int_request % 8)

	cmp cl, 7
	ja disable_slave


disable_master:
	in al, INT_M_CTLMASK
	or al, ah
	out INT_M_CTLMASK, al
	jmp disable_ok

disable_slave:
	in al, INT_S_CTLMASK
	or al, ah
	out INT_S_CTLMASK, al
	jmp disable_ok

disable_ok:
	pop ecx
	popf										; 恢复标志寄存器
	ret

disable_already:
	pop ecx
	popf 
	ret 

; =====================================================================
; 打开特定中断
; 函数原型：void enable_irq(int int_request)
; ---------------------------------------------------------------------
align 16
enable_irq:
	pushf										; 将标志寄存器 EFLAGS 压栈，需要用到 test 指令，会改变 EFLAGS
	push ecx

	cli											; 屏蔽全部中断

	mov ecx, [esp + 4 * 3]							; 取出要屏蔽的中断号 ecx = int_request

	; 判断中断来自哪一个 8259
	mov ah, ~1									; ah = 00000001b
	rol ah, cl									; ah = ah << (int_request % 8)

	cmp cl, 7
	ja enable_slave

enable_master:
	in al, INT_M_CTLMASK
	and al, ah
	out INT_M_CTLMASK, al
	jmp enable_ok

enable_slave:
	in al, INT_S_CTLMASK
	and al, ah
	out INT_S_CTLMASK, al
	jmp enable_ok

enable_ok:
	pop ecx
	popf										; 恢复标志寄存器
	ret


test_int_0:
	int 32
	ret