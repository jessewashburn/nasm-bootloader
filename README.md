# x86-64 Long Mode Bootloader in NASM

This project is a custom bootloader written in NASM that transitions an x86-64 virtual machine from **real mode** to **protected mode** to **long mode** and demonstrates successful execution of 64-bit code. It is developed for the COSC 439 Operating Systems group project.

## Features

- Boots in **real mode** as initialized by the BIOS  
- Switches to **protected mode** with paging disabled  
- Enables **Physical Address Extension (PAE)** and activates **paging**  
- Loads a valid **GDT** with a 64-bit code segment  
- Enters **long mode (x86-64)**  
- Executes a 64-bit instruction (`mov rax, 0x12345678`)  
- Prints a unique group message (e.g., `"Entered Long Mode: Group X"`)

---

## Project Structure

```
.
├── boot.asm        # NASM bootloader source code
├── boot.bin        # Compiled 512-byte bootloader binary (generated)
├── boot.img        # Bootable image file (generated)
├── Makefile        # Automates build and run tasks
├── README.md       # Project documentation
├── report.pdf      # 3-page written explanation (see assignment)
└── demo.mp4        # Video demonstration (see assignment)
```

---

## Requirements

- [NASM](https://www.nasm.us/) (v2.16+)
- [QEMU](https://www.qemu.org/) (e.g., `qemu-system-x86_64`)
- [Make](https://www.gnu.org/software/make/) (optional, simplifies build process)
- Git Bash or any terminal with access to the above tools

---

## Build Instructions

To convert the binary into a bootable image file, use the provided `Makefile`:

```bash
make run
```
This should open the qemu emulator and show a booting message 

****THIS IS AS FAR AS WE'VE GOTTEN 6/23/25 ****

To compile the bootloader into a 512-byte flat binary:

```bash
nasm -f bin boot.asm -o boot.bin
```

---

## Run Instructions

To launch the bootloader in a virtual x86-64 machine:

```bash
qemu-system-x86_64 -drive format=raw,file=boot.img
```

You should see output such as:

```
Entered Long Mode: Group 3
```

Followed by successful execution of a 64-bit instruction (`mov rax, 0x12345678`).

---

## Cleaning Up

To remove generated files:

```bash
make clean
```

---

## Assignment Requirements (Checklist)

- [x] NASM bootloader that performs all required mode transitions  
- [x] Fits within 512 bytes (boot sector)  
- [x] No GRUB or external bootloader used  
- [x] Bootable with QEMU  
- [x] Unique string and 64-bit instruction executed  
- [x] Code well-structured and commented  
- [x] README and Makefile provided  
- [x] PDF report and video demo submitted  

---

## Authors

Group X – COSC 439  
- Member 1 – Role  
- Member 2 – Role  
- Member 3 – Role  
- Member 4 – Role  
- Member 5 – Role  

---

## License

This project is for educational purposes and submitted as coursework for COSC 439 at Towson University.
