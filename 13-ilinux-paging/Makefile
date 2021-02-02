# ===================================================
# ---------------------------------------------------
# 变量
# ---------------------------------------------------
# 编译中间目录
t 				= target
tb 				= target/boot
tk 				= target/kernel

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
ASM_PARA 		= -i boot/include/ 
CC 				= gcc


# ===================================================
# 目标程序以及编译的中间文件
# ---------------------------------------------------
ILINUX_BOOT 	= $(tb)/boot.bin $(tb)/loader.bin $(tb)/kernel.bin

# ===================================================
# 所有的功能
# ---------------------------------------------------
.PHONY: nop all image debug run clean 
# 默认选项（输入make但是没有子命令）
nop:
	@echo "all			编译所有文件，生成目标文件（二进制文件，boot.bin）"
	@echo "image			生成系统镜像文件"
	@echo "debug 			打开bochs运行系统并调试"
	@echo "run			提示用于如何将系统安装到虚拟机中"
	@echo "clean 			清理文件"


all: $(ILINUX_BOOT)

all_run: all image debug

image: $(FD) $(ILINUX_BOOT)
	dd if=$(tb)/boot.bin of=$(FD) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(FD) $(IMG_MOUNT_PATH)
	cp $(tb)/loader.bin $(IMG_MOUNT_PATH)
	cp $(tb)/kernel.bin $(IMG_MOUNT_PATH)
	sudo umount $(IMG_MOUNT_PATH)

# 打开bochs进行调试
debug: $(FD) $(BOCHS_CONFIG)
	@bochs $(BOCHS_ARGA)

run: $(FD)
	qemu-system-i386 -drive file=$(FD) if=floppy
	; @echo "使用虚拟机挂载即可运行"

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

$(tb)/boot.bin:	boot/boot_ans.asm $(t) $(tb)
	$(ASM) $(ASM_PARA) -f bin $< -o $@
$(tb)/loader.bin: boot/loader_ok.asm $(t) $(tb)
	$(ASM) $(ASM_PARA) -f bin $< -o $@
$(tb)/kernel.bin: boot/kernel.asm $(t) $(tb)
	$(ASM) $(ASM_PARA) -f bin $< -o $@

# ===================================================
# 中间Obj文件生成规则
# ---------------------------------------------------
# ===================================================
