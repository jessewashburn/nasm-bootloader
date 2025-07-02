[BITS 16]
[ORG 0x7C00]

; === REAL MODE INITIALIZATION ===

start:
    ; Initialize segments and stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Display boot message
    mov si, boot_msg
    call print_string
    
    ; Switch to protected mode
    call enter_protected_mode

; Print null-terminated string using BIOS
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; === PROTECTED MODE TRANSITION ===

enter_protected_mode:
    cli                         ; Disable interrupts
    
    ; Load GDT
    lgdt [gdt32_desc]
    
    ; Enable protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump to 32-bit code
    jmp 0x08:protected_mode

; === PROTECTED MODE SECTION ===

[BITS 32]
protected_mode:
    ; Initialize segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov esp, 0x7C00
    
    ; Setup PAE paging
    call setup_paging
    
    ; Enable PAE
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax
    
    ; Load PML4
    mov eax, pml4_table
    mov cr3, eax
    
    ; Enable long mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr
    
    ; Enable paging and protection
    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax
    
    ; Load 64-bit GDT
    lgdt [gdt64_desc]
    
    ; Jump to 64-bit code
    jmp 0x08:long_mode

; Setup identity paging for first 2MB
setup_paging:
    ; Clear page tables
    mov edi, pml4_table
    mov ecx, 0x3000 / 4
    xor eax, eax
    rep stosd
    
    ; PML4 entry points to PDP
    mov dword [pml4_table], pdpt + 0x3 ; Present + Writeable
    
    ; PDP entry points to PD
    mov dword [pdpt], pd_table + 0x3   ; Present + Writeable
    
    ; PD entries identity map first 2MB with 2MB pages
    mov edi, pd_table
    mov eax, 0x83                      ; Present + Writeable + Page Size
    mov ecx, 1                         ; Just one 2MB page
.setup_pd:
    mov [edi], eax
    add edi, 8
    add eax, 0x200000
    loop .setup_pd
    
    ret

; === LONG MODE SECTION ===

[BITS 64]
long_mode:
    ; Initialize segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov rsp, 0x7C00
    
    ; Clear screen
    mov rdi, 0xB8000
    mov rcx, 80 * 25
    mov rax, 0x1F201F201F201F20 ; White space on blue background
    rep stosq
    
    ; Display success message
    mov rdi, 0xB8000
    mov rsi, success_msg
    mov ah, 0x1F ; White on blue
    call print64
    
    ; Display group message
    mov rdi, 0xB8000 + 160 ; Second line
    mov rsi, group_msg
    call print64
    
    ; Execute 64-bit instruction demo
    mov rax, 0x123456789ABCDEF0
    mov rdi, 0xB8000 + 320 ; Third line
    mov rsi, demo_msg
    call print64
    
    ; Infinite loop
    cli
    hlt
    jmp $

; Print string in 64-bit mode
print64:
    lodsb
    test al, al
    jz .done
    stosw
    jmp print64
.done:
    ret

; === DATA SECTION ===

; 32-bit GDT
align 4
gdt32_start:
    dq 0x0000000000000000 ; Null descriptor
    dq 0x00CF9A000000FFFF ; Code segment
    dq 0x00CF92000000FFFF ; Data segment
gdt32_desc:
    dw $ - gdt32_start - 1
    dd gdt32_start

; 64-bit GDT
align 4
gdt64_start:
    dq 0x0000000000000000 ; Null descriptor
    dq 0x00209A0000000000 ; 64-bit code segment
    dq 0x0000920000000000 ; 64-bit data segment
gdt64_desc:
    dw $ - gdt64_start - 1
    dd gdt64_start

; Messages
boot_msg:      db "Booting into 64-bit mode...", 0
success_msg:   db "64-bit Long Mode Active!", 0
group_msg:     db "COSC439 Bootloader", 0
demo_msg:     db "64-bit demo: rax=0x123456789ABCDEF0", 0

; Page tables (located after boot sector)
pml4_table equ 0x8000
pdpt       equ 0x9000
pd_table   equ 0xA000

; Boot signature
times 510 - ($ - $$) db 0
dw 0xAA55