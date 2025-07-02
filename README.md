# x86-64 Bootloader

A minimal bootloader that transitions from 16-bit real mode to 64-bit long mode.

## Features
- Boots in real mode (BIOS)
- Switches to 32-bit protected mode
- Enables PAE paging
- Enters 64-bit long mode
- Executes 64-bit instructions (`mov rax,...`)
- Displays status messages in VGA text mode

## Requirements
- NASM (v2.16+)
- QEMU (for emulation)

## Build & Run
```bash
make    # Build boot.bin
make run # Run in QEMU

Expected Output
text

64-bit Long Mode Active!
COSC439 Bootloader
64-bit demo: rax=0x123456789ABCDEF0

Clean Up
bash

make clean

Manual Commands

Build:
bash

nasm -f bin boot.asm -o boot.bin

Run:
bash

qemu-system-x86_64 -drive format=raw,file=boot.bin