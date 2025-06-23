[BITS 16]
[ORG 0x7C00]

start:
    mov ah, 0x0E
    mov si, message
.print_loop:
    lodsb
    or al, al
    jz halt
    int 0x10     ; BIOS teletype output
    jmp .print_loop

halt:
    cli
    hlt
    jmp halt

message db "Booting...", 0

times 510 - ($ - $$) db 0
dw 0xAA55
