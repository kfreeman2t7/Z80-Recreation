nop
ld B, 0x0
ld A, 0x0
ld HL, 0x4347
ld (HL), 0x55
ld C, 4
ld B, (HL)
ld A, H
ADD A, 1
ld H, A
ld B, (HL)
END:    
    JR END
