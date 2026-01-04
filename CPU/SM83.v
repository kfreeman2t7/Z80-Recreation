//bus enums
parameter BUS_PC = 0;
parameter BUS_HL = 1;

//unprefixed opcode classes


//opcode states
	typedef enum {
	C_NOP,
	C_EX,
	C_DJNZ, C_DJNZ_EXEC,
	C_JR, C_JR_EXEC,
	C_JR2,
	C_16BIT_LDIMM, C_16BIT_LDIMM_EXEC_LO, C_16BIT_LDIMM_EXEC_HI,
	C_16BIT_ADDHL,
	C_LOAD_INDIRECT,
	C_WRITE_INDIRECT,
	C_LOAD_INDIRECT_HL_IMM, C_LOAD_INDIRECT_HL_IMM_EXEC_LO, C_LOAD_INDIRECT_HL_IMM_EXEC_HI,
	C_WRITE_INDIRECT_HL_IMM, C_WRITE_INDIRECT_HL_IMM_EXEC_LO, C_WRITE_INDIRECT_HL_IMM_EXEC_HI,
	C_LOAD_INDIRECT_A_IMM, C_LOAD_INDIRECT_A_IMM_EXEC,
	C_WRITE_INDIRECT_A_IMM, C_WRITE_INDIRECT_A_IMM_EXEC,
	C_16BIT_INCDEC,
	C_INC,
	C_DEC,
	C_LOAD_IMM, C_LOAD_IMM_EXEC,
	C_ACC,
	C_LOAD, C_LOAD_EXEC, //for ld [r], (HL)
	C_HALT, C_HALT_EXEC,
	C_ALU,
	C_CON_RET,
	C_POP,
	C_RET,
	C_EXX,
	C_JUMP_HL,
	C_LD_SP_HL,
	C_CON_JUMP,
	C_JUMP_IMM, C_JUMP_IMM_EXEC_LO, C_JUMP_IMM_EXEC_HI,
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
	C_ALU_IMM, C_ALU_IMM_EXEC,
	C_RESTART
	} opcode;





module SM83(CLK, REQ, ACK, ram_wren, ram_read_addr, ram_write_addr, ram_read_data, ram_write_data, reg_read, print, RESET);
	parameter N_data = 8;
	parameter N_ram_addr = 16;
	parameter N_reg_addr = 3;
	
	
	
	
	
	input wire CLK, RESET;
	
	output wire [N_data-1:0] reg_read;
	
	input wire [N_data-1:0] ram_read_data;
	output wire [N_data-1:0] ram_write_data;
	output wire [N_ram_addr-1:0] ram_read_addr, ram_write_addr;
	output wire [N_data-1:0] print; reg [N_data-1:0] print_reg;
	
	
	
	input wire REQ;
	output wire ACK, ram_wren;
	
	
	
	//special registers
	reg [N_data-1:0] IR;
	reg [N_data-1:0] ER = 8'd255;
	reg [N_data-1:0] bus_sel;
	reg [N_data*2-1:0] SP, HL;
	
	//intermediate registers
	wire [N_reg_addr-1:0] A_addr_w, B_addr_w;
	reg [N_reg_addr-2:0] rp_addr;
	wire [N_data*2-1:0] rp_read;
	
	reg [N_ram_addr-1:0] PC;
	reg [N_data-1:0] PC_low;
	reg [N_data-1:0] A, B, acc, I, idu_acc;
	reg [1:0] PC_idu_op = 1; wire [N_ram_addr-1:0] PC_idu_out;
	
	wire [N_data-1:0] acc_w, flag_w, ir;
	wire A_w = A; 
	wire B_w = B;
	
	//control registers
	reg rom_enable, rf_load, load_imm, rf_setab;
	reg [1:0] rp_load;
	wire rf_load_en = rf_load; wire rf_setab_en = rf_setab;
	
	wire [N_ram_addr-1:0] ram_addr;
	wire [2:0] bus_signal;
	wire [N_data-1:0] displacement;
	assign ram_read_addr = ram_addr;
	assign ram_write_addr = ram_addr;
	assign bus_sel = bus_signal;
	
	//components
	RF #(.data_size(N_data), .addr_size(N_reg_addr), .ram_addr_size(N_ram_addr)) reg_file (CLK, rp_addr, rp_read, rp_load, reg_read, ram_write_data, ram_read_data, ram_addr, bus_signal, PC, acc_w, flag_w, load_8, hold_imm, rf_setAB_en, rf_load_en, ir_wire, displacement);
	ALU #(.bit_size(N_data)) alu (CLK, A, B, acc_w, 2'b0, flag_w);
	IDU #(.bit_size(N_ram_addr)) PC_idu(CLK, PC, PC_idu_out, PC_idu_op);
	
	assign print = reg_read;
	
	wire [N_data-1:0] ir_wire = IR_RF;
	
	reg [N_data-1:0] IR_DECODE = 255, IR_RF = 255, IR_EXEC = 255, IR_WB = 255;
	
	//precalculated wires
	wire PC_displacement = {PC[15:8],PC[7:0]+displacement};
	
	//decode wires
	assign IR_DECODE = ram_read_data;
	
	//IC decoder
	opcode IC, ram_IC; //IC = instruction class
	decoder opcode_decode(IR_DECODE, ir_rf, ram_IC, halt, (ram_addr == PC));
	wire [N_data-1:0] ir_rf;
	
	
	
	//8 bit immediate/displacement flag
	wire load_8 = (
		IC == C_JR
	|| IC == C_DJNZ
	|| IC == C_WRITE_INDIRECT_A_IMM 
	|| IC == C_LOAD_INDIRECT_A_IMM 
	|| IC == C_LOAD_IMM
	|| IC == C_LOAD
	|| IC == C_ALU_IMM
	|| IC == C_HALT
	);
	
	wire hold_imm = (
		IC == C_JR_EXEC
	|| IC == C_DJNZ_EXEC
	|| IC == C_WRITE_INDIRECT_A_IMM_EXEC 
	|| IC == C_LOAD_INDIRECT_A_IMM_EXEC
	|| IC == C_LOAD_IMM_EXEC
	|| IC == C_ALU_IMM_EXEC
	|| IC == C_HALT_EXEC
	);
	
	//16 bit immediate flag
	wire load_16 = (
		   IC == C_16BIT_LDIMM
		|| IC == C_JUMP_IMM
	);
	
	wire rp_load_lo = (
			IC == C_16BIT_LDIMM
	);
	
	wire rp_load_hi = (
			IC == C_16BIT_LDIMM_EXEC_LO
	);
	
	wire PC_set_dis = (
			IC == C_JR
	);
	
	wire PC_set_low = (
			IC == C_JUMP_IMM
	);
	
	wire PC_set_high = (
			IC == C_JUMP_IMM_EXEC_LO
	);
	
	assign rp_load = 2'd0&{2{(!rp_load_lo && !rp_load_hi)}} | 2'd1&{2{(rp_load_lo && !rp_load_hi)}} | 2'd2&{2{(!rp_load_lo && rp_load_hi)}};
	
	assign rf_load = (
		   IC == C_LOAD_IMM_EXEC
		|| IC == C_LOAD_EXEC
	);
	
	assign ram_wren = (
		IR_RF[5:3] == 3'b110
	);
	
	
	wire halt_16 = load_16 | rp_load_lo | rp_load_hi | PC_set_low | PC_set_high;
	wire halt_8 = load_8;
	wire halt =  halt_8 | halt_16;
	
	assign rp_addr = IR_RF[5:4];
	
	//registers
	always @(posedge CLK) begin
		//Manage PC
		if(PC_set_dis) begin
			PC <= PC_displacement;
		end else if(PC_set_low) begin
			PC_low[7:0] <= ram_read_data;
		end else if(PC_set_high) begin
			PC <= {ram_read_data, PC_low};
		end else if(ram_addr != PC) begin
			PC <= PC;
		end else begin
			PC <= PC_idu_out;
		end
		
		if(RESET || ram_addr != PC) begin
			IR_RF <= 0;
		end else if(halt == 0) begin
			IR_RF <= ir_rf;
		end else begin
			IR_RF <= IR_RF;
		end
		
		if(RESET || PC < 2) begin
			IC <= C_NOP;
		end else begin
			case(IC)
				C_16BIT_LDIMM: IC <= C_16BIT_LDIMM_EXEC_LO;
				C_16BIT_LDIMM_EXEC_LO: IC <= C_16BIT_LDIMM_EXEC_HI;
				C_LOAD_IMM: IC <= C_LOAD_IMM_EXEC;
				C_LOAD: IC <= C_LOAD_EXEC;
				C_JUMP_IMM: IC <= C_JUMP_IMM_EXEC_LO;
				C_JUMP_IMM_EXEC_LO: IC <= C_JUMP_IMM_EXEC_HI;
				default: IC <= ram_IC;
			endcase
		end
		
		
	end
	

endmodule

module decoder(code, ir_rf, ic, halt, on_pc);
	input wire halt, on_pc;
	input wire [7:0] code;
	output wire [7:0] ir_rf;
	output opcode ic;
	
	wire [1:0] x = code[7:6];
	wire [2:0] y = code[5:3];
	wire [2:0] z = code[2:0];
	wire q = code[3];
	wire [1:0] p = code[5:4];
	
	wire ram_load_8 = (
		ic == C_JR
	|| ic == C_DJNZ
	|| ic == C_WRITE_INDIRECT_A_IMM 
	|| ic == C_LOAD_INDIRECT_A_IMM 
	|| ic == C_LOAD_IMM
	|| ic == C_ALU_IMM
	|| ic == C_HALT
	);
	
	always @(*) begin
		if(on_pc) begin
			ir_rf <= code;
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
				end
				
				default: ic <= ic;
			endcase
		end else begin
			ir_rf <= ir_rf;
			ic <= ic;
		end
		
	
		
	
	end
endmodule