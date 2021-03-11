# ===================================================
# ---------------------------------------------------
# 变量
# ---------------------------------------------------
# 编译中间目录

sk				= kernel
sb				= boot
sl				= include

t 				= target
tb 				= target/boot
tk 				= target/kernel
tl 				= target/lib
tl_ansi			= target/lib/ansi

# 库文件所在目录
lansi = lib/ansi
lstdio = lib/stdio
li386 = lib/i386

# bochs 配置文件
BOCHS_CONFIG 	= config/bochsrc.bxrc
BOCHS_ARGA		= -f $(BOCHS_CONFIG)

# 所需硬盘镜像，可以指定已经存在的软盘镜像，系统内核将被写入到这里
#
# 挂载点路径
IMG_MOUNT_PATH 	= /media/floppy0/
FD 				= ilinux.img
# 所需要的汇编器以及汇编参数
ASM 			= nasm
ASM_PARA 		= -i boot/include/  -i kernel/include/ -f elf 
CC 				= gcc
CC_PARA			= -I $(sk)/include -I include -fno-builtin -fno-stack-protector -m32 -c 
LD 				= ld 
LD_PARA			= -Ttext 0x1000 -m elf_i386

# ===================================================
# 目标程序以及编译的中间文件
# ---------------------------------------------------
ILINUX_BOOT 	= $(tb)/boot.bin $(tb)/loader.bin $(tk)/kernel.bin
ILINUX_KERNEL 	= $(tk)/kernel.bin 

KERNEL_OBJS 	= $(tk)/kernel.o $(tk)/kernel_i386_lib.o $(tk)/main.o  \
				  $(tk)/protect.o $(tk)/table.o $(tk)/init.o $(tk)/exception.o \
				  $(tk)/mics.o $(tk)/i8259.o $(tk)/clock.o $(tk)/process.o

STDIO_OBJS      = $(tl)/vsprintf.o
I386_OBJS       = $(tl)/i386/ipc/ipc_msg.o
ANSI_OBJS		= $(tl)/ansi/string.o  # $(tl)/ansi/stringc.o # $(tl)/ansi/memcmp.o 

LIB_OBJS 		= $(ANSI_OBJS) $(STDIO_OBJS)

OBJS 			= $(KERNEL_OBJS) $(LIB_OBJS)

# ===================================================
# 所有的功能
# ---------------------------------------------------
.PHONY: nop all image debug run clean 
# 默认选项（输入make但是没有子命令）
nop:
	@echo "all  			编译所有文件，生成目标文件（二进制文件，boot.bin）"
	@echo "image			生成系统镜像文件"
	@echo "debug 			打开bochs运行系统并调试"
	@echo "run  			提示用于如何将系统安装到虚拟机中"
	@echo "clean 			清理文件"


all: $(ILINUX_BOOT)

all_run: all image debug

image: $(FD) $(ILINUX_BOOT)
	dd if=$(tb)/boot.bin of=$(FD) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(FD) $(IMG_MOUNT_PATH)
	cp $(tb)/loader.bin $(IMG_MOUNT_PATH)
	cp $(ILINUX_KERNEL) $(IMG_MOUNT_PATH)
	sudo umount $(IMG_MOUNT_PATH)

# 打开bochs进行调试
debug: $(FD) $(BOCHS_CONFIG)
	@bochs $(BOCHS_ARGA)

run: $(FD)
	@qemu-system-x86_64 -drive file=$(FD),if=floppy
	# qemu-system-i386 -kernel bzImage -hda $(FD) id=ilinux
	# qemu-system-i386 -drive file=$(FD) if=ilinux
	@echo "使用虚拟机挂载即可运行"

clean:
	rm -r $(t)
	@echo "文件删除干净"
	
# ===================================================
# 目标文件生成规则
# ---------------------------------------------------
#  软件镜像不存在时，将会自动生成
$(FD):
	dd if=/dev/zero of=$(FD) bs=512 count=2880
# 目标文件夹不存在时
$(t):
	mkdir $@
$(tb):
	mkdir $@
$(tk):
	mkdir $@
$(tl):
	mkdir $@
$(tl_ansi):
	mkdir $@

$(tb)/boot.bin:	boot/boot.asm $(t) $(tb) $(tk) $(tl) $(tl_ansi)
	$(ASM) $(ASM_PARA) -f bin $< -o $@
$(tb)/loader.bin: boot/loader.asm $(t) $(tb) $(tk)
	$(ASM) $(ASM_PARA) -f bin $< -o $@
$(tk)/kernel.bin: $(OBJS)
	$(LD) $(LD_PARA) -o $@ $^

# ===================================================
# 中间Obj文件生成规则
# ---------------------------------------------------
# ===================================================
$(tk)/kernel.o: kernel/kernel.asm
	$(ASM) $(ASM_PARA) $< -o $@
$(tk)/kernel_i386_lib.o: kernel/kernel_i386_lib.asm
	$(ASM) $(ASM_PARA) $< -o $@
$(tk)/main.o: kernel/main.c
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/init.o: kernel/init.c
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/protect.o: kernel/protect.c
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/table.o: kernel/table.c
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/mics.o: kernel/mics.c
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/i8259.o: kernel/i8259.c
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/clock.o: kernel/clock.c 
	$(CC) $(CC_PARA) -o $@ $<
$(tk)/process.o: kernel/process.c 
	$(CC) $(CC_PARA) -o $@ $<

$(tl)/ansi/string.o: $(lansi)/string.asm
	$(ASM) $(ASM_PARA) -o $@ $<

$(tl)/ansi/memcmp.o: $(lansi)/memcmp.c
	$(CC) $(CC_PARA) -o $@ $<

$(tl)/ansi/stringc.o: $(lansi)/stringc.c
	$(CC) $(CC_PARA) -o $@ $<

$(tl)/vsprintf.o: $(lstdio)/vsprintf.c
	$(CC) $(CC_PARA) -o $@ $<

# $(OBJS): %.o : %.c
# 	$(CC) $(CC_PARA) -o $@ $< 

$(tl)/i386/ipc/ipc_msg.o: $(li386)/ipc/ipc_msg.asm
	$(ASM) $(ASM_PARA) -o $@ $<

$(tl)/vsprintf.o: $(lstdio)/vsprintf.c
	$(CC) $(CC_PARA) -o $@ $<

$(tk)/exception.o: kernel/exception.c
	$(CC) $(CC_PARA) -o $@ $<
	
