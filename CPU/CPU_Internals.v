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
	
	
	
module RF(CLK, rp_addr, rp_read, rp_wren, data_read, wr_en, ram_write, ram_read, ram_read_addr, addr_sel, pc_w, acc_w, flag_w, load_imm, hold_imm, set_ab, load, rf_ir, displacement);
	parameter data_size = 16;
	parameter addr_size = 3;
	parameter ram_addr_size = 16;
	
	parameter A = 3'b111;
	parameter H = 3'b100;
	parameter L = 3'b101;
	parameter HL = 3'b110;
	
	//i/o
	input wire CLK, load, load_imm, hold_imm, set_ab;
	input wire [1:0] rp_wren; //0 = off, 1 = low, 2 = high
	input wire [addr_size-2:0] rp_addr;
	input wire [ram_addr_size-1:0] pc_w;
	input wire [data_size-1:0] acc_w, flag_w, ram_read, rf_ir;
	
	output wire wr_en;
	output wire [2:0] addr_sel;
	output wire [data_size-1:0] data_read, ram_write;
	output wire [ram_addr_size-1:0] ram_read_addr;
	output wire [data_size*2-1:0] rp_read;
	output wire [data_size-1:0] displacement;

	
	
	//address wires
	wire [2:0] addr_A = rf_ir[5:3];
	wire [2:0] addr_B = rf_ir[2:0];
	
	//registers
	reg [ram_addr_size-1:0] SP, ram_write_data; //special resigsters
	reg [data_size-1:0] reg_arr [(1<<addr_size)-1:0]; //generic registers
	reg wr;
	
	//data wires
	wire [2:0] [ram_addr_size-1:0] ram_read_bus;
	assign ram_read_bus[BUS_PC] = pc_w;
	assign ram_read_bus[BUS_HL] = {reg_arr[H], reg_arr[L]};
	
	assign ram_write_addr = {reg_arr[H], reg_arr[L]};
	assign wr_en = wr; assign ram_write = ram_write_data;
	
	wire use_bus_hl = addr_B == HL && ~load_imm && ~hold_imm;
	assign addr_sel = (BUS_PC&{3{~use_bus_hl}}) | (BUS_HL&{3{(use_bus_hl)}});
	
	register_mux #(.reg_size(ram_addr_size), .sel_size(2)) addr_mux(ram_read_bus, ram_read_addr, addr_sel);
	
	
	wire load_hl = (load_imm | (addr_B == HL)) && ~hold_imm;
	
	assign reg_arr[3'b110] = (ram_read&{8{load_hl}}) | (reg_arr[3'b110]&{8{~load_hl}});
	wire [data_size-1:0] imm = reg_arr[3'b110];
	assign displacement = imm;
	
	assign rp_read = 
 	   {reg_arr[0],reg_arr[1]}&{(data_size*2){rp_addr == 0}}
	|| {reg_arr[2],reg_arr[3]}&{(data_size*2){rp_addr == 1}}
	|| {reg_arr[4],reg_arr[5]}&{(data_size*2){rp_addr == 2}}
	|| SP&{(data_size*2){rp_addr == 3}};

	always @(posedge CLK) begin
		
		//if(load_imm) begin
		//	reg_arr[3'b110] <= ram_read;
		//end
		
		reg_arr[A] <= acc_w;
		
		wr <= (addr_A == 3'b110);
		
		
		if(load) begin
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
		end
		
		if(rp_wren == 1) begin //write low
			case(rp_addr)
				0: reg_arr[1] <= ram_read;
				1: reg_arr[3] <= ram_read;
				2: reg_arr[5] <= ram_read;
				3: SP[7:0] <= ram_read;
			endcase
		end else if(rp_wren == 2) begin //write high
			case(rp_addr)
				0: reg_arr[0] <= ram_read;
				1: reg_arr[2] <= ram_read;
				2: reg_arr[4] <= ram_read;
				3: SP[15:8] <= ram_read;
			endcase
		end
	end
	
	assign data_read = reg_arr[0];
	
endmodule

module ALU(CLK,A,B,reg_out,mode,flags_w);
	parameter bit_size = 16;
	
	input wire CLK;
	input wire [1:0] mode;
	input wire [bit_size-1:0] A,B;
	output wire [bit_size-1:0] reg_out, flags_w;
	
	wire [bit_size:0] wide_res;
	wire [bit_size-1:0] res, flags;
	
	assign wide_res = A + B;
	
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
