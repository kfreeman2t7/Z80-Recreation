package states;
//clock cycles
typedef enum {
		T1,
		T2,
		T3
	} clock_cycle;
	

//unprefixed opcode classes


//opcode states
typedef enum {
	C_NOP,
	C_EX,
	C_DJNZ,
	C_JR,
	C_JR2,
	C_16BIT_LDIMM,
	C_16BIT_ADDHL,
	C_LOAD_INDIRECT,
	C_WRITE_INDIRECT,
	C_LOAD_INDIRECT_HL_IMM,
	C_WRITE_INDIRECT_HL_IMM,
	C_LOAD_INDIRECT_A_IMM,
	C_WRITE_INDIRECT_A_IMM,
	C_16BIT_INCDEC,
	C_INC,
	C_DEC,
	C_LOAD_IMM,
	C_ACC,
	C_LOAD,
	C_HALT,
	C_ALU,
	C_CON_RET,
	C_POP,
	C_RET,
	C_EXX,
	C_JUMP_HL,
	C_LD_SP_HL,
	C_CON_JUMP,
	C_JUMP_IMM,
	C_PREFIX_CB,
	C_OUT,
	C_IN,
	C_EX_SP_HL,
	C_EX_DE_HL,
	C_DI,
	C_EI,
	C_CON_CALL,
	C_PUSH,
	C_CALL,
	C_PREFIX_DD,
	C_PREFIX_ED,
	C_PREFIX_FD,
	C_ALU_IMM,
	C_RESTART
} opcode;
endpackage