import states::*;

module onehot_decoder(addr, sel);
	parameter addr_size = 8;
	
	input wire [addr_size-1:0] addr;
	output wire [(1<<addr_size)-1:0] sel;
	
	assign sel[2**addr_size-1:0] = (1'b1 << addr);
	
endmodule

module gb_clock(CLK, pulse);
	parameter bits = 16;
	parameter value = 6;
	parameter half_value = 3;
	
	input wire CLK;
	output wire pulse;
	
	reg [bits-1:0] targ = value-1;
	
	always @(posedge CLK) begin
		if(targ > 0) begin
			targ <= targ - 1;
		end else begin
			targ <= value-1;
		end
	end
	
	assign pulse = (targ > half_value-1);
endmodule
	
	
	
module RF(CLK, RESET, T, PC, IR_READ, IR_WRITE, ram_write, ram_wren, ram_read, ram_read_addr, addr_sel, load, load_imm, use_indirect_addr, load_indirect, write_indirect, rp_load, rp2_load, alu_op, sp_push, sp_pop, sp_read, displacement, registers);
	//bus enums
	
	
	parameter data_size = 8;
	parameter addr_size = 3;
	parameter ram_addr_size = 16;
	
	parameter A = 3'b111;
	parameter H = 3'b100;
	parameter L = 3'b101;
	parameter HL = 3'b110;
	
	
	//registers
	reg [data_size-1:0] ram_write_data, alu_in;
	reg [ram_addr_size-1:0] SP, ram_write_addr_reg; //special resigsters
	reg [data_size-1:0] reg_arr [(1<<addr_size)-1:0]; //general purpose registers
	reg [2:0] addr_reg;
	reg [data_size-1:0] F = 0;
	
	//i/o
	input wire CLK, RESET, load, load_imm, use_indirect_addr, load_indirect, write_indirect, rp_load, rp2_load, alu_op, sp_push, sp_pop, sp_read;
	input clock_cycle T;
	input wire [data_size-1:0] ram_read, IR_READ, IR_WRITE;
	input wire [ram_addr_size-1:0] PC;
	

	output wire [2:0] addr_sel;
	output wire [data_size-1:0] ram_write;
	output wire [ram_addr_size-1:0] ram_read_addr;
	output wire [data_size-1:0] displacement;
	output wire [data_size-1:0] registers [(1<<addr_size)-1:0];
	output wire ram_wren;

	//i/o assignments
	assign addr_sel = addr_reg;
	assign registers = reg_arr;
	
	//address wires
	wire [2:0] addr_A = IR_WRITE[5:3];
	wire [2:0] addr_B = IR_WRITE[2:0];
	wire [1:0] rp_addr = IR_WRITE[5:4];
	
	
	
	
	//data wires
	reg [15:0] rp_data = 0, rp2_data = 0;
	always @(*) begin
		case(rp_addr)
			0: rp_data <= {reg_arr[0],reg_arr[1]};
			1: rp_data <= {reg_arr[2],reg_arr[3]};
			2: rp_data <= {reg_arr[4],reg_arr[5]};
			3: rp_data <= SP;
			default: rp_data <= 0;
		endcase
		
		case(rp_addr)
			0: rp2_data <= {reg_arr[0],reg_arr[1]};
			1: rp2_data <= {reg_arr[2],reg_arr[3]};
			2: rp2_data <= {reg_arr[4],reg_arr[5]};
			3: rp2_data <= {reg_arr[A],F};
			default: rp2_data <= 0;
		endcase
	end
	reg [ram_addr_size-1:0] hl_bus;
	
	
	
	wire [7:0] [ram_addr_size-1:0] ram_read_bus;
	assign ram_read_bus[BUS_RP] = rp_data;
	assign ram_read_bus[BUS_PC] = PC;
	assign ram_read_bus[BUS_HL] = {reg_arr[H], reg_arr[L]};
	assign ram_read_bus[BUS_SP] = SP;
	
	wire [ram_addr_size-1:0] ram_write_addr = ram_write_addr_reg;
	assign ram_write = ram_write_data;
	
	wire use_bus_hl = (IR_READ[2:0] == HL && ~load_imm) || (IR_WRITE[5:3] == HL && load);
	assign ram_wren = ((load && IR_WRITE[5:3] == HL) || write_indirect || sp_push);
	
	always @(*) begin
		if(use_indirect_addr || load_indirect || write_indirect) begin
			addr_reg <= BUS_RP;
		end else if(sp_read || sp_push || sp_pop) begin
			addr_reg <= BUS_SP;
		end else if(use_bus_hl) begin
			addr_reg <= BUS_HL;
		end else begin
			addr_reg <= BUS_PC;
		end
	end
	
	assign ram_read_addr = ram_read_bus[addr_sel];
	
	wire [data_size-1:0] imm = reg_arr[3'b110];
	assign displacement = imm;
	
	//ALU
	wire [data_size-1:0] alu_buffer, flag_buffer;
	ALU #(.bit_size(8)) arithlogic(CLK,reg_arr[A],reg_arr[addr_B],F,alu_buffer,addr_A,flag_buffer);
	


	always @(posedge CLK) begin	
		if(RESET) begin
			reg_arr[3'b000] <=  0;
			reg_arr[3'b001] <=  0;
			reg_arr[3'b010] <=  0;
			reg_arr[3'b011] <=  0;
			reg_arr[3'b100] <=  0;
			reg_arr[3'b101] <=  0;
			reg_arr[3'b110] <=  0;
			reg_arr[3'b111] <=  0;
			SP <= 0;
			F <= 0;
		end else begin
		//update addr busses
		hl_bus <= {reg_arr[H], reg_arr[L]}; //sync hl bus with clock
		case(T)
			T1: begin 
				if(sp_push) begin
					ram_write_data <= rp2_data[7:0];
				end
			end
			T2: begin 
				
				if(sp_push) begin
					ram_write_data <= rp2_data[15:8];
					SP <= SP + 1;
				end else if(alu_op) begin
					F <= flag_buffer;
					reg_arr[A] <= alu_buffer;
				end else if(load) begin //ld
					case(addr_A)
						3'b000: reg_arr[3'b000] <=  reg_arr[addr_B];
						3'b001: reg_arr[3'b001] <=  reg_arr[addr_B];
						3'b010: reg_arr[3'b010] <=  reg_arr[addr_B];
						3'b011: reg_arr[3'b011] <=  reg_arr[addr_B];
						3'b100: reg_arr[3'b100] <=  reg_arr[addr_B];
						3'b101: reg_arr[3'b101] <=  reg_arr[addr_B];
						3'b110: ram_write_data <=  reg_arr[addr_B];
						3'b111: reg_arr[3'b111] <=  reg_arr[addr_B];
					endcase
				end else if(rp_load) begin //rp low
					case(rp_addr)
						0: reg_arr[1] <= reg_arr[HL];
						1: reg_arr[3] <= reg_arr[HL];
						2: reg_arr[5] <= reg_arr[HL];
						3: SP[7:0] <= reg_arr[HL];
					endcase
					reg_arr[0] <= reg_arr[0];
					reg_arr[2] <= reg_arr[2];
					reg_arr[4] <= reg_arr[4];
					SP[15:8] <= SP[15:8];
				end else if(sp_pop) begin //rp low
					case(rp_addr)
						0: reg_arr[1] <= reg_arr[HL];
						1: reg_arr[3] <= reg_arr[HL];
						2: reg_arr[5] <= reg_arr[HL];
						3: reg_arr[A] <= reg_arr[HL];
					endcase
					reg_arr[0] <= reg_arr[0];
					reg_arr[2] <= reg_arr[2];
					reg_arr[4] <= reg_arr[4];
					F <= F;
				end else if(write_indirect) begin
					ram_write_data <= reg_arr[A];
				end
			end
			T3: begin 
				if(load_indirect) begin
					reg_arr[A] <= ram_read;
				end
				
				if(sp_read || sp_pop) begin
					SP <= SP + 1;
				end
				
				if(sp_push) begin
					SP <= SP + 1;
				end if(rp_load && ~load) begin //rp high
					case(rp_addr)
						0: reg_arr[0] <= ram_read;
						1: reg_arr[2] <= ram_read;
						2: reg_arr[4] <= ram_read;
						3: SP[15:8] <= ram_read;
					endcase
					SP[7:0] <= SP[7:0];
					reg_arr[1] <= reg_arr[1];
					reg_arr[3] <= reg_arr[3];
					reg_arr[5] <= reg_arr[5];
				end else if(sp_pop && ~load) begin //rp high
					case(rp_addr)
						0: reg_arr[0] <= ram_read;
						1: reg_arr[2] <= ram_read;
						2: reg_arr[4] <= ram_read;
						3: F <= ram_read;
					endcase
					reg_arr[A] <= reg_arr[A];
					reg_arr[1] <= reg_arr[1];
					reg_arr[3] <= reg_arr[3];
					reg_arr[5] <= reg_arr[5];
				end 
				
				if(load_imm || use_bus_hl) begin
					reg_arr[HL] <= ram_read;
				end else begin
					reg_arr[HL] <= reg_arr[HL];
				end
				
			end
	
		endcase
		end
			
	end
	
endmodule

module ALU(CLK,A,r,f,reg_out,mode,flags_w);
	parameter bit_size = 16;
	
	localparam S = 7, Z = 6, x = 5, H = 4, y = 3, PV = 2, N = 1, C = 0;
	
	input wire CLK;
	input wire [2:0] mode;
	input wire [bit_size-1:0] A,r,f;
	output wire [bit_size-1:0] reg_out, flags_w;
	
	wire [bit_size:0] adc = r + f[0];

	reg [bit_size-1:0] res, F = 0;
	
	assign flags_w[N] = f[N];
	assign flags_w[Z] = (res == 0);
	assign flags_w[S] = ~res[7];
	assign flags_w[H] = (A[3] == 1) & (A[4] == 1);
	
	assign flags_w[PV] = ( 
	(mode == 0) & (A[7] == r[7]) & (res[7] != A[7]) |
	(mode == 1 | mode == 7) & (A[7] == adc[7]) & (res[7] != A[7]) |
	(mode == 2) & (A[7] != r[7]) & (res[7] != A[7]) |
	(mode == 3) & (A[7] != adc[7]) & (res[7] != A[7])
	);
	
	assign flags_w[C] = F[C];
	assign flags_w[x] = 0;
	assign flags_w[y] = 0;
	
	
	
	always @(posedge CLK) begin
		case(mode)
			0: begin
				{F[C], res} <= A + r;
			end
			1: begin
				{F[C], res} <= A + adc;
			end
			2: begin
				{F[C], res} <= A - r;
			end
			3: begin
				{F[C], res} <= A - adc;
			end
			4: begin
				F[C] <= 0;
				res <= A & r;
			end
			5: begin
				F[C] <= 0;
				res <= A ^ r;
			end
			6: begin
				F[C] <= 0;
				res <= A | r;
			end
			7: begin
				F[C] <= 0;
				res <= A - r;
			end
			
			default: res <= 0;
		endcase
	end
	
	assign reg_out = res;
endmodule

module IDU(CLK,in,result,inc);
	parameter bit_size = 16; 
	
	parameter NO_OP = 0;
	parameter INC = 1;
	parameter DEC = 2;
	
	input wire CLK;
	input wire [2:0] inc;
	input wire [bit_size-1:0] in;
	output wire [bit_size-1:0] result;
	
	wire [bit_size-1:0] INi = in+1;
	wire [bit_size-1:0] INd = in-1;
	assign result = in&{bit_size{(inc==NO_OP)}} | INi&{bit_size{(inc==INC)}} | INd&{bit_size{(inc==DEC)}};
	
endmodule
