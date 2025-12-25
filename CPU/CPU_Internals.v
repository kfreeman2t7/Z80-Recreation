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
	
	
	
module RF(CLK, data_read, wr_en, ram_write, ram_read, ram_read_addr, addr_sel, pc_w, acc_w, flag_w, mem, set_ab, load, rf_ir);
	parameter data_size = 16;
	parameter addr_size = 16;
	parameter ram_addr_size = 16;
	
	parameter A = 3'b111;
	parameter H = 3'b100;
	parameter L = 3'b101;
	
	//i/o
	input wire CLK, load, mem, set_ab;
	input wire [2:0] addr_sel;
	input wire [ram_addr_size-1:0] pc_w;
	input wire [data_size-1:0] acc_w, flag_w, ram_read, rf_ir;
	output wire wr_en;
	output wire [data_size-1:0] data_read, ram_write;
	output wire [ram_addr_size-1:0] ram_read_addr;

	
	
	//address wires
	wire [2:0] addr_A = rf_ir[5:3];
	wire [2:0] addr_B = rf_ir[2:0];
	
	//registers
	reg [data_size-1:0] SP, ram_write_data; //special resigsters
	reg [data_size-1:0] reg_arr [(1<<addr_size)-1:0]; //generic registers
	reg wr;
	
	//data wires
	wire [2:0] [ram_addr_size-1:0] ram_read_bus;
	assign ram_read_bus[BUS_PC] = pc_w;
	assign ram_read_bus[BUS_HL] = {reg_arr[H], reg_arr[L]};
	
	assign ram_write_addr = {reg_arr[H], reg_arr[L]};
	assign wr_en = wr; assign ram_write = ram_write_data;
	
	register_mux #(.reg_size(ram_addr_size), .sel_size(2)) addr_mux(ram_read_bus, ram_read_addr, addr_sel);
	
	
	
	always @(posedge CLK) begin
		
		if(mem) begin
			reg_arr[3'b110] <= ram_read;
		end
		
		reg_arr[A] <= acc_w;
		//reg_arr[F] <= flag_w;
		
		wr <= (addr_A == 3'b110);
		if(load) begin
			if(addr_A == 3'b110) begin
				ram_write_data <= reg_arr[addr_B];
			end else begin
				reg_arr[addr_A] <= reg_arr[addr_B];
			end
		end
	end
	
	assign data_read = addr_A;
	
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

module IDU(CLK,result,inc);
	parameter bit_size = 16; 
	
	input wire CLK;
	input wire [2:0] inc;
	output wire [bit_size-1:0] result;
	
	reg [bit_size-1:0] cnt;
	
	always @(posedge CLK) begin
		if(inc == 1) begin
			cnt <= cnt+1;
		end else if(inc == 2) begin
			cnt <= cnt-1;
		end
	end
	
	assign result = cnt;
	
endmodule
