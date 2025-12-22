module onehot_decoder(addr, sel);
	parameter addr_size = 8;
	
	input wire [addr_size-1:0] addr;
	output wire [(1<<addr_size)-1:0] sel;
	
	assign sel[2**addr_size-1:0] = (1'b1 << addr);
	
endmodule
	
	
	
module RF(CLK, data_write, data_read, addr, write);
	parameter data_size = 16;
	parameter addr_size = 8;
	
	input wire CLK, write;
	input wire [data_size-1:0] data_write;
	output wire [data_size-1:0] data_read;
	inout wire [addr_size-1:0] addr;
	
	
	
	reg [data_size-1:0] PC, SP;
	reg [data_size-1:0] reg_arr [(1<<addr_size)-1:0];

	reg [data_size-1:0] R;
	
	always @(posedge CLK) begin
		if (write) begin
			reg_arr[addr] <= data_write;
		end else begin
			R <= reg_arr[addr];
		end
	end
	
	assign data_read = R;
	
endmodule

module ALU(CLK,A,B,result,add,status);
	parameter bit_size = 16;
	
	input wire CLK, status, operation;
	input wire [data_size-1:0] A,B;
	output wire [data_size-1:0] result;
	
	reg [data_size-1:0] res;
	
	always @(posedge CLK) begin
			if(add == 1) begin
				res <= A+B;
			end else if(add == 0) begin
				res <= A-B;
			end
	end
	
	assign result = res;
endmodule

module IDU(CLK,A,result,inc);
	parameter bit_size = 16; 
	
	input wire CLK, inc;
	input wire [bit_size-1:0] A;
	output wire [bit_size-1:0] result;
	
	reg [bit_size-1:0] buffer;
	
	always @(posedge CLK) begin
		if(inc == 1) begin
			buffer <= A+1;
		end else if(inc == 0) begin
			buffer <= A-1;
		end
	end
	
	assign result = buffer;
	
endmodule
