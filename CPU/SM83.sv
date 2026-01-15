import states::*;
	

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
								default: ic <= C_NOP;
							endcase
						end
					1: begin
							case(q)
								0: ic <= C_16BIT_LDIMM;
								1: ic <= C_16BIT_ADDHL;
								default: ic <= C_NOP;
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
											default: ic <= C_NOP;
										endcase
									end
								1: begin 
										case(p)
											0: ic <= C_LOAD_INDIRECT;
											1: ic <= C_LOAD_INDIRECT;
											2: ic <= C_LOAD_INDIRECT_HL_IMM;
											3: ic <= C_LOAD_INDIRECT_A_IMM;
											default: ic <= C_NOP;
										endcase
									end
							endcase
						end
					3: ic <= C_16BIT_INCDEC;
					4: ic <= C_INC;
					5: ic <= C_DEC;
					6: ic <= C_LOAD_IMM;
					7: ic <= C_ACC;
					default: ic <= C_NOP;
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
				// TODO
				case(z)
					0: ic <= C_CON_RET;
					1: begin case(q)
							0: ic <= C_POP;
							1: begin case(p)
								0: ic <= C_RET;
								1: ic <= C_EXX;
								2: ic <= C_JUMP_HL;
								3: ic <= C_LD_SP_HL;
								default: ic <= C_NOP;
							endcase end
							default: ic <= C_NOP;
						endcase end
					2: ic <= C_CON_JUMP;
					3: begin case(y)
						0: ic <= C_JUMP_IMM;
						1: ic <= C_PREFIX_CB;
						2: ic <= C_OUT;
						3: ic <= C_IN;
						4: ic <= C_EX_SP_HL;
						5: ic <= C_EX_DE_HL;
						6: ic <= C_DI;
						7: ic <= C_EI;
						default: ic <= C_NOP;
						endcase end
					4: ic <= C_CON_CALL;
					5: begin case(q)
						0: ic <= C_PUSH;
						1: begin case(p)
							0: ic <= C_CALL;
							1: ic <= C_PREFIX_DD;
							2: ic <= C_PREFIX_ED;
							3: ic <= C_PREFIX_FD;
							default: ic <= C_NOP;
							endcase end
						default: ic <= C_NOP;
						endcase end
					6: ic <= C_ALU_IMM;
					7: ic <= C_RESTART;
					default: ic <= C_NOP;
				endcase
			end
			
			default: ic <= C_NOP;
		endcase	
	end
endmodule



module SM83(CLK, REQ_out, ACK, ram_wren, write_data, addr_bus, data_bus, RESET, registers);
	
	parameter N_data = 8;
	parameter N_ram_addr = 16;
	parameter N_reg_addr = 3;
	
	output wire [7:0] registers [7:0];
	
	
	input wire CLK, RESET;
	input wire [7:0] data_bus;
	output wire [15:0] addr_bus;
	output wire [7:0] write_data;
	
	
	
	
	
	input wire ACK;
	output wire REQ_out, ram_wren;
	
	opcode OP_FETCH, OP_READ, OP_WRITE;
	reg [7:0] IR_FETCH, IR_READ, IR_WRITE;
	
	reg REQ; assign REQ_out = REQ;
	wire [2:0] addr_sel;
	clock_cycle T;
	
	reg [15:0] PC;
	
	wire [15:0] ram_addr;
	assign addr_bus = ram_addr;
	
	
	//decoder
	opcode OP_TEMP;
	decoder ohd(data_bus, OP_TEMP);
	
	
	
	//write control signals
	wire load = (OP_WRITE == C_LOAD || OP_WRITE == C_LOAD_IMM);
	wire alu_op = (OP_WRITE == C_ALU || OP_WRITE == C_ALU_IMM);
	wire rp_load = (
		OP_WRITE == C_16BIT_LDIMM
	);
	wire rp2_load = (
		OP_WRITE == C_POP
	);
	//read control signals
	wire load_imm = (
	OP_READ == C_LOAD_IMM 
	|| OP_READ == C_16BIT_LDIMM 
	|| OP_READ == C_ALU_IMM
	|| OP_READ == C_JR
	|| OP_READ == C_LOAD_INDIRECT
	|| OP_READ == C_POP
	);
	
	wire sp_read = (
		OP_READ == C_POP
	);
	
	wire load_indirect = 
	(
		OP_WRITE == C_LOAD_INDIRECT
	);
	
	wire write_indirect = 
	(
		OP_WRITE == C_WRITE_INDIRECT
	);
	
	wire sp_push = (
		OP_WRITE == C_PUSH
	);
	
	wire sp_pop = (
		OP_WRITE == C_POP
	);
	
	wire use_indirect_addr = (OP_READ == C_LOAD_INDIRECT) || (OP_READ == C_WRITE_INDIRECT);
	
	wire load_pc = (OP_WRITE == C_JR);
	
	wire op_is_store = (OP_FETCH == C_LOAD && IR_FETCH[2:0] == 3'b110) || (OP_FETCH == C_WRITE_INDIRECT);
	wire read_conflict = op_is_store && (OP_READ != C_NOP);
	
	wire insert_gap = read_conflict;
	
	wire fetch_enable = (ram_addr == PC) && ~RESET && ~insert_gap && (OP_READ != C_PUSH);
	
	wire [7:0] displacement;
	wire pending_req = (ACK == 0) && (REQ == 1);
	
	wire data_is_imm = load_imm || rp_load || rp2_load;
	wire valid_data = ~data_is_imm;

	always @ (posedge CLK) begin
		if(RESET) begin
			T <= T1;
			PC <= 0;
			REQ <= 0;
		end else begin
			if(~pending_req) begin
				REQ <= 0;
				case(T)
					T1: T <= T2;
					T2: T <= T3;
					T3: T <= T1;
					default: T <= T1;
				endcase
			end else begin
				T <= T;
			end
			
			if(pending_req) begin
			end else if(T == T1) begin 						//T2 cycle
				if(fetch_enable && valid_data) begin
					OP_FETCH <= OP_TEMP; IR_FETCH <= data_bus;
				end else if(insert_gap) begin 
					OP_FETCH <= OP_TEMP; IR_FETCH <= data_bus;
				end else begin
					OP_FETCH <= C_NOP; IR_FETCH <= 0;
				end
			end else if(T == T2) begin 						//T3 cycle
				if(load_pc) begin
					PC <= PC + {{8{displacement[7]}},displacement} - 1;
					REQ <= 0;
					OP_FETCH <= C_NOP; IR_FETCH <= 0;
				end
			end else	if(T == T3) begin 						//T1 cycle
				
				OP_WRITE <= OP_READ; IR_WRITE <= IR_READ;
				
				if(insert_gap) begin
					OP_READ <= C_NOP; IR_READ <= 0;
				end else begin
					OP_READ <= OP_FETCH; IR_READ <= IR_FETCH;
				end
				
				//set fetch IR
				if(fetch_enable && ~load_pc) begin
					PC <= PC + 1; //increment PC
					REQ <= 1;
				end
				
				if(~fetch_enable && ~load_pc) begin
					REQ <= 1;
				end
			end
		end
	end
	
	//RF
	reg wren_peek;
	assign wren_peek = ram_wren;
	RF regfile(CLK, RESET, T, PC, IR_READ, IR_WRITE, write_data, ram_wren, data_bus, ram_addr, addr_sel, load, load_imm, use_indirect_addr, load_indirect, write_indirect, rp_load, rp2_load, alu_op, sp_push, sp_pop, sp_read, displacement, registers);
	
endmodule

