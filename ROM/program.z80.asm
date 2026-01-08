nop
ld A, 0
ld B, 1
END:
    ADD A, 1
    AND A, 0b00001111
    JR END
