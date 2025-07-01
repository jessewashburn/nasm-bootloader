; Simple Bootloader - Real Mode to Protected Mode Transition
; Loads at 0x7C00, switches to 32-bit protected mode, displays success message

[BITS 16]                       ; 16-bit real mode
[ORG 0x7C00]                    ; BIOS load address

; === REAL MODE SECTION ===

start:
    mov ah, 0x0E                ; BIOS teletype function
    mov si, boot_message        ; Load message pointer
    call print_string           ; Display boot message
    
    mov cx, 0xFFFF              ; Delay to see real mode message
.delay_loop:
    nop
    loop .delay_loop
    
    call enter_protected_mode   ; Switch to protected mode
    
; Print null-terminated string using BIOS
print_string:
    lodsb                       ; Load char, advance SI
    test al, al                 ; Check for null terminator
    jz .done
    int 0x10                    ; BIOS print character
    jmp print_string
.done:
    ret

; Switch to protected mode: load GDT, setup paging, set PE bit, far jump
enter_protected_mode:
    cli                         ; Disable interrupts
    
    ; Setup paging structures
    call setup_paging
    
    ; Enable PAE (Physical Address Extension)
    mov eax, cr4
    or eax, 0x20                ; Set PAE bit (bit 5)
    mov cr4, eax
    
    ; Load page directory pointer table
    mov eax, pdpt
    mov cr3, eax
    
    lgdt [gdt_descriptor]       ; Load GDT
    
    ; Enable protected mode and paging
    mov eax, cr0
    or eax, 0x80000001          ; Set PG bit (bit 31) and PE bit (bit 0)
    mov cr0, eax
    
    jmp 0x08:protected_mode_start ; Far jump to flush pipeline

; Setup page tables for identity mapping (first 4MB)
setup_paging:
    ; Clear page tables area (using absolute addresses)
    mov edi, pdpt
    mov ecx, 0x4000 / 4         ; Clear 16KB total
    xor eax, eax
    rep stosd
    
    ; Setup PDPT (Page Directory Pointer Table)
    mov dword [pdpt], page_directory + 0x1  ; Present bit set
    mov dword [pdpt + 4], 0     ; High 32 bits = 0
    
    ; Setup Page Directory (maps first 4MB)
    mov dword [page_directory], page_table_0 + 0x1     ; First 2MB, present
    mov dword [page_directory + 4], 0                  ; High 32 bits
    mov dword [page_directory + 8], page_table_1 + 0x1 ; Second 2MB, present  
    mov dword [page_directory + 12], 0                 ; High 32 bits
    
    ; Setup First Page Table (0-2MB identity mapping)
    mov edi, page_table_0
    mov eax, 0x1                ; Start at 0x0000, present bit set
    mov ecx, 512                ; 512 entries per table
.fill_pt0:
    mov [edi], eax              ; Store low 32 bits
    mov dword [edi + 4], 0      ; Store high 32 bits (zero)
    add edi, 8                  ; Next entry (8 bytes)
    add eax, 0x1000             ; Next 4KB page
    loop .fill_pt0
    
    ; Setup Second Page Table (2-4MB identity mapping)
    mov edi, page_table_1
    mov ecx, 512                ; 512 entries for second 2MB
.fill_pt1:
    mov [edi], eax              ; Store low 32 bits
    mov dword [edi + 4], 0      ; Store high 32 bits (zero)
    add edi, 8                  ; Next entry (8 bytes)
    add eax, 0x1000             ; Next 4KB page
    loop .fill_pt1
    
    ret

; === PROTECTED MODE SECTION ===

[BITS 32]                       ; 32-bit protected mode

protected_mode_start:
    mov ax, 0x10                ; Data segment selector
    mov ds, ax                  ; Set all segment registers
    mov es, ax                  ; to data segment
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    call clear_screen           ; Clear VGA buffer
    call display_protected_message ; Show success message
    call display_paging_status  ; Show paging is enabled
    jmp system_halt             ; Infinite halt loop

; Clear VGA text buffer (80x25 chars at 0xB8000)
clear_screen:
    mov edi, 0xB8000            ; VGA text buffer
    mov ecx, 80 * 25            ; Screen size
    mov ax, 0x0720              ; Space + attribute
    rep stosw                   ; Fill with spaces
    ret

; Display message in VGA text mode
display_protected_message:
    mov edi, 0xB8000            ; VGA buffer start
    mov esi, protected_message  ; Message pointer
    mov ah, 0x0F                ; White on black
.print_loop:
    lodsb                       ; Load character
    test al, al                 ; Check null terminator
    jz .done
    stosw                       ; Store char + attribute
    jmp .print_loop
.done:
    ret

; Display paging status on second line
display_paging_status:
    mov edi, 0xB8000 + 160      ; Second line (80 chars * 2 bytes)
    mov esi, paging_message     ; Paging message
    mov ah, 0x0A                ; Light green on black
.print_loop:
    lodsb                       ; Load character
    test al, al                 ; Check null terminator
    jz .done
    stosw                       ; Store char + attribute
    jmp .print_loop
.done:
    ret

; Halt system
system_halt:
    cli                         ; Disable interrupts
    hlt                         ; Halt CPU
    jmp system_halt             ; Loop on wake

; === GLOBAL DESCRIPTOR TABLE ===
; Defines memory segments for protected mode

gdt_start:

gdt_null:                       ; Required null descriptor
    dq 0x0000000000000000

gdt_code:                       ; Code segment (execute/read)
    dw 0xFFFF                   ; Limit 0-15
    dw 0x0000                   ; Base 0-15
    db 0x00                     ; Base 16-23
    db 10011010b                ; Access: P=1,DPL=00,S=1,Type=1010
    db 11001111b                ; Flags: G=1,D=1,L=0,AVL=0 + Limit 16-19
    db 0x00                     ; Base 24-31

gdt_data:                       ; Data segment (read/write)
    dw 0xFFFF                   ; Limit 0-15
    dw 0x0000                   ; Base 0-15
    db 0x00                     ; Base 16-23
    db 10010010b                ; Access: P=1,DPL=00,S=1,Type=0010
    db 11001111b                ; Flags: G=1,D=1,L=0,AVL=0 + Limit 16-19
    db 0x00                     ; Base 24-31

gdt_end:

gdt_descriptor:                 ; GDT pointer for LGDT
    dw gdt_end - gdt_start - 1  ; GDT size - 1
    dd gdt_start                ; GDT base address

; === DATA ===

boot_message:
    db "Starting bootloader...", 13, 10, 0

protected_message: 
    db "SUCCESS: Protected Mode Active!", 0

paging_message:
    db "PAE + Paging Enabled - Identity Mapped 4MB", 0

; === BOOT SIGNATURE ===

times 510 - ($ - $$) db 0      ; Pad to 510 bytes  
dw 0xAA55                       ; Boot signature

; === PAGE TABLES (After boot sector) ===
; Page tables are located after the boot sector in memory

pdpt equ 0x8000                 ; Page Directory Pointer Table at 0x8000
page_directory equ 0x9000       ; Page Directory at 0x9000  
page_table_0 equ 0xA000         ; First Page Table at 0xA000
page_table_1 equ 0xB000         ; Second Page Table at 0xB000
