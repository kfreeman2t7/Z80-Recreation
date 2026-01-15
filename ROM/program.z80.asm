nop
ld SP, 0x1000
ld A, 0x10
push AF
add A, 8
ld A, 0x83
push AF
and A, 7
sub A, 3
ld SP, 0x1002
pop BC
ld E, B
END:    
    JR END
