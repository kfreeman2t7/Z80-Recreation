//bus enums
parameter BUS_PC = 0;
parameter BUS_HL = 1;

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
	
	typedef enum {
		T1,
		T2,
		T3
	} clock_cycle;





module SM83(CLK, REQ_out, ACK, ram_wren, addr_bus, data_bus, RESET, registers);
	parameter N_data = 8;
	parameter N_ram_addr = 16;
	parameter N_reg_addr = 3;
	
	
	output wire [7:0] registers [7:0];
	
	
	input wire CLK, RESET;
	input wire [7:0] data_bus;
	output wire [15:0] addr_bus;
	
	assign addr_bus = ram_addr;
	
	wire [15:0] ram_addr;
	wire data_is_imm = load_imm || rp_load;
	
	wire fetch_enable = (ram_addr == PC) && ~RESET;
	wire valid_data = ~data_is_imm;
	
	
	
	input wire ACK;
	output wire REQ_out, ram_wren;
	
	opcode OP_FETCH, OP_READ, OP_WRITE;
	reg [7:0] IR_FETCH, IR_READ, IR_WRITE;
	reg REQ; assign REQ_out = REQ;
	wire [2:0] addr_sel;
	clock_cycle T;
	
	reg [15:0] PC;
	wire [7:0] ram_write;
	
	//decoder
	opcode OP_TEMP;
	decoder(data_bus, OP_TEMP);
	
	//RF
	RF(CLK, T, PC, IR_READ, IR_WRITE, ram_write, data_bus, ram_addr, addr_sel, load, load_imm, rp_load, alu_op, displacement, registers);
	
	//write control signals
	wire load = (OP_WRITE == C_LOAD || OP_WRITE == C_LOAD_IMM);
	wire alu_op = (OP_WRITE == C_ALU || OP_WRITE == C_ALU_IMM);
	wire rp_load = (OP_WRITE == C_16BIT_LDIMM);
	//read control signals
	wire load_imm = (
	OP_READ == C_LOAD_IMM 
	|| OP_READ == C_16BIT_LDIMM 
	|| OP_READ == C_ALU_IMM
	|| OP_READ == C_JR
	);
	
	wire load_pc = (OP_WRITE == C_JR);
	
	wire [7:0] displacement;

	always @ (posedge CLK) begin
		if(ACK == 1) begin
			case(T)
				T1: T <= T2;
				T2: T <= T3;
				T3: T <= T1;
				default: T <= T1;
			endcase
		end else begin
			T <= T;
		end
		
		if(ACK == 0) begin
		end else if(T == T1) begin 						//T2 cycle
			if(fetch_enable && valid_data) begin
				OP_FETCH <= OP_TEMP; IR_FETCH <= data_bus;
			end else begin
				OP_FETCH <= C_NOP; IR_FETCH <= 0;
			end
		end else if(T == T2) begin 						//T3 cycle
			if(load_pc) begin
				PC <= PC + {{8{displacement[7]}},displacement};
				OP_FETCH <= C_NOP; IR_FETCH <= 0;
			end
		end else	if(T == T3) begin 						//T1 cycle
			OP_WRITE <= OP_READ; IR_WRITE <= IR_READ;
			OP_READ <= OP_FETCH; IR_READ <= IR_FETCH;
			//set fetch IR
			if(fetch_enable && ~load_pc) begin
				PC <= PC + 1; //increment PC
			end
		end
	end
		
	
	

endmodule

module decoder(code, ic);
	input wire [7:0] code;

	output opcode ic;
	
	wire [1:0] x = code[7:6];
	wire [2:0] y = code[5:3];
	wire [2:0] z = code[2:0];
	wire q = code[3];
	wire [1:0] p = code[5:4];
	
	always @(*) begin
		case(x)
			0: begin
				case(z)
					0: begin
							case(y)
								0: ic <= C_NOP;
								1: ic <= C_EX;
								2: ic <= C_DJNZ;
								3: ic <= C_JR;
								4: ic <= C_JR2;
								5: ic <= C_JR2;
								6: ic <= C_JR2;
								7: ic <= C_JR2;
							endcase
						end
					1: begin
							case(q)
								0: ic <= C_16BIT_LDIMM;
								1: ic <= C_16BIT_ADDHL;
							endcase
						end
					2: begin 
							case(q)
								0: begin 
										case(p)
											0: ic <= C_WRITE_INDIRECT;
											1: ic <= C_WRITE_INDIRECT;
											2: ic <= C_WRITE_INDIRECT_HL_IMM;
											3: ic <= C_WRITE_INDIRECT_A_IMM;
										endcase
									end
								1: begin 
										case(p)
											0: ic <= C_LOAD_INDIRECT;
											1: ic <= C_LOAD_INDIRECT;
											2: ic <= C_LOAD_INDIRECT_HL_IMM;
											3: ic <= C_LOAD_INDIRECT_A_IMM;
										endcase
									end
							endcase
						end
					3: ic <= C_16BIT_INCDEC;
					4: ic <= C_INC;
					5: ic <= C_DEC;
					6: ic <= C_LOAD_IMM;
					7: ic <= C_ACC;
				endcase
			end
			
			1: begin
				if(z == 6 && y == 6) begin
					ic <= C_HALT;
				end else begin
					ic <= C_LOAD;
				end
			end
			
			2: ic <= C_ALU;
			
			3: begin
				ic <= ic;
				// TODO
				case(z)
					6: ic <= C_ALU_IMM;
				endcase
			end
			
			default: ic <= ic;
		endcase	
	end
endmodule