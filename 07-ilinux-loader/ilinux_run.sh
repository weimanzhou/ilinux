##########################################################################
# File Name: ilinux_run.sh
# Author: amoscykl
# mail: amoscykl980629@163.com
# Created Time: Sun 24 Jan 2021 02:11:15 PM CST
#########################################################################
#!/bin/zsh
PATH=/home/edison/bin:/home/edison/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/work/tools/gcc-3.4.5-glibc-2.3.6/bin
export PATH

nasm -f bin boot_ans.asm -o boot.bin
nasm -f bin loader.asm -o loader.bin
dd if=boot.bin of=ilinux.img bs=512 count=1 conv=notrunc
sudo mount -o loop ilinux.img /media/floppy0
cp loader.bin /media/floppy0
umount /media/floppy0
bochs -f bochsrc.bxrc
