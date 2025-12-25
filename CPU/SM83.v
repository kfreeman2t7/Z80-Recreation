//bus enums
parameter BUS_PC = 0;
parameter BUS_HL = 1;

//unprefixed opcode classes








module SM83(CLK, REQ, ACK, ram_wren, ram_read_addr, ram_write_addr, ram_read_data, ram_write_data, reg_read, print);
	parameter N_data = 8;
	parameter N_ram_addr = 16;
	parameter N_reg_addr = 3;
	
	
	
	
	
	input wire CLK;
	
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
	
	reg [N_data-1:0] A, B, acc, I, idu_acc;
	reg [1:0] PC_inc = 1; wire [1:0] PC_inc_w = PC_inc;
	
	wire [N_data-1:0] acc_w, flag_w, PC, ir;
	wire A_w = A; 
	wire B_w = B;
	
	//control registers
	reg rom_enable, rf_load, rf_mem, rf_setab;
	wire rf_load_en = rf_load; wire rf_mem_en = rf_mem; wire rf_setab_en = rf_setab;
	
	wire [N_ram_addr-1:0] ram_addr;
	wire [2:0] bus_signal;
	assign ram_read_addr = ram_addr;
	assign ram_write_addr = ram_addr;
	assign bus_signal = bus_sel;
	
	//components
	RF #(.data_size(N_data), .addr_size(N_reg_addr), .ram_addr_size(N_ram_addr)) reg_file (CLK, reg_read, ram_wren, ram_write_data, ram_read_data, ram_addr, bus_signal, PC, acc_w, flag_w, rf_mem, rf_setAB_en, rf_load_en, ir_wire);
	ALU #(.bit_size(N_data)) alu (CLK, A, B, acc_w, 2'b0, flag_w);
	IDU #(.bit_size(N_ram_addr)) PC_idu(CLK, PC, PC_inc_w);
	
	assign print = reg_read;
	
	wire [N_data-1:0] ir_wire = IR_RF;
	
	reg [N_data-1:0] IR_DECODE = 255, IR_RF = 255, IR_EXEC = 255, IR_WB = 255;
	
	
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
	C_LOAD_INDIRECT_IMM,
	C_WRITE_INDIRECT_IMM,
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
	
	opcode IC; //IC = instruction class
	//decode wires
	wire x = IR_DECODE[7:6];
	wire y = IR_DECODE[5:3];
	wire z = IR_DECODE[2:0];
	wire q = IR_DECODE[3];
	wire p = IR_DECODE[5:4];
	
	//registers
	always @(posedge CLK) begin
		//shift IRs
		IR_WB <= IR_EXEC;
		IR_RF <= IR_EXEC;
		IR_EXEC <= IR_DECODE;
		
		//FETCH
		if(bus_signal == BUS_PC && (IR_DECODE[7:6] != 2'b00)) begin //built-in avoidance for ori
			IR_DECODE <= ram_read_data;
			rf_mem <= (ram_read_data[7:6] == 2'b00); //fetch the immediate data
		end else begin
			IR_DECODE <= 255;
			rf_mem <= 0;
		end
		
		//DECODE
		if(IR_DECODE != 255) begin
			case(x)
				0: begin
					case(z)
						0: begin
								case(y)
									0: IC <= C_NOP;
									1: IC <= C_EX;
									2: IC <= C_DJNZ;
									3: IC <= C_JR;
									4: IC <= C_JR2;
									5: IC <= C_JR2;
									6: IC <= C_JR2;
									7: IC <= C_JR2;
								endcase
							end
						1: begin
								case(q)
									0: IC <= C_16BIT_LDIMM;
									1: IC <= C_16BIT_ADDHL;
								endcase
							end
						2: begin 
								case(q)
									0: begin 
											case(p)
												0: IC <= C_WRITE_INDIRECT;
												1: IC <= C_WRITE_INDIRECT;
												2: IC <= C_WRITE_INDIRECT_IMM;
												3: IC <= C_WRITE_INDIRECT_IMM;
											endcase
										end
									1: begin 
											case(p)
												0: IC <= C_LOAD_INDIRECT;
												1: IC <= C_LOAD_INDIRECT;
												2: IC <= C_LOAD_INDIRECT_IMM;
												3: IC <= C_LOAD_INDIRECT_IMM;
											endcase
										end
								endcase
							end
						3: IC <= C_16BIT_INCDEC;
						4: IC <= C_INC;
						5: IC <= C_DEC;
						6: IC <= C_LOAD_IMM;
						7: IC <= C_ACC;
					endcase
				end
				
				1: begin
					if(z == 6 && y == 6) begin
						IC <= C_HALT;
					end else begin
						IC <= C_LOAD;
					end
				end
				
				2: IC <= C_ALU;
				
				3: begin
					// TODO
				end
			endcase
		end else begin
			bus_sel <= BUS_PC;
		end
		
		//EXEC
		if(IR_EXEC != 255) begin
			case(IC)
				C_NOP: begin
				 end
				C_EX: begin
				 end
				C_DJNZ: begin
				 end
				C_JR: begin
				 end
				C_JR2: begin
				 end
				C_16BIT_LDIMM: begin
				 end
				C_16BIT_ADDHL: begin
				 end
				C_LOAD_INDIRECT: begin
				 end
				C_WRITE_INDIRECT: begin
				 end
				C_LOAD_INDIRECT_IMM: begin
				 end
				C_WRITE_INDIRECT_IMM: begin
				 end
				C_16BIT_INCDEC: begin
				 end
				C_INC: begin
				 end
				C_DEC: begin
				 end
				C_LOAD_IMM: begin
				 end
				C_ACC: begin
				 end
				C_LOAD: begin
				 end
				C_HALT: begin
				 end
				C_ALU: begin
				 end
				C_CON_RET: begin
				 end
				C_POP: begin
				 end
				C_RET: begin
				 end
				C_EXX: begin
				 end
				C_JUMP_HL: begin
				 end
				C_LD_SP_HL: begin
				 end
				C_CON_JUMP: begin
				 end
				C_JUMP_IMM: begin
				 end
				C_PREFIX_CB: begin
				 end
				C_OUT: begin
				 end
				C_IN: begin
				 end
				C_EX_SP_HL: begin
				 end
				C_EX_DE_HL: begin
				 end
				C_DI: begin
				 end
				C_EI: begin
				 end
				C_CON_CALL: begin
				 end
				C_PUSH: begin
				 end
				C_CALL: begin
				 end
				C_PREFIX_DD: begin
				 end
				C_PREFIX_ED: begin
				 end
				C_PREFIX_FD: begin
				 end
				C_ALU_IMM: begin
				 end
				C_RESTART: begin
				 end
			endcase
		end else begin
			//defaut volatile signals
			rf_load <= 0;
		end
		
		//RF + WRITEBACK (WB results in reg A)
		if(IR_WB != 255) begin

		end
		//rf_load <= 0;
		//rf_mem <= 0;
		//rf_set_ir <= 0;
		//rf
		//PC_inc <= 0;

		//read from memory
	end
	

endmodule