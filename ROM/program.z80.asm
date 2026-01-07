nop
ld A, 0
ld B, 1
END:
    ADD A, B
    ADD A, 1
    ld B, A
    JR END