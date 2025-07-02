# COSC 439 x86-64 Bootloader Makefile
# Group 3 - Final Version

# Tools
NASM := nasm
QEMU := qemu-system-x86_64
DD := dd

# Targets
all: boot.bin boot.img

boot.bin: boot.asm
	$(NASM) -f bin -Wall $< -o $@
	@echo "Bootloader built (512-byte):" $(shell stat -c%s $@) "bytes"

boot.img: boot.bin
	$(DD) if=/dev/zero of=$@ bs=1M count=1 status=none
	$(DD) if=$< of=$@ conv=notrunc status=none
	@echo "Disk image created"

run: boot.bin
	$(QEMU) -drive format=raw,file=$< -display sdl

debug: boot.bin
	$(QEMU) -drive format=raw,file=$< -d int -D qemu.log -serial stdio

clean:
	rm -f boot.bin boot.img qemu.log
	@echo "Clean complete"

.PHONY: all run debug clean