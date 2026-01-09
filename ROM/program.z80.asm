nop
ld B, 0x0
ld A, 0x0
ld HL, 0x4347
ld (HL), 0x55
END:
    ld B, (HL)
    ld A, L
    ADD A, 1
    ld L, A
    JR END
