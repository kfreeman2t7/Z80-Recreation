module SM83(CLK, REQ, ACK, data_write, data_read, addr,write);
	parameter N_data = 16;
	parameter N_addr = 16;
	
	input wire CLK,write;
	inout wire [N_data-1:0] addr;
	input wire [N_addr-1:0] data_write;
	output wire [N_addr-1:0] data_read;
	
	input wire REQ;
	output wire ACK;
	
	//special registers
	reg [N_addr-1:0] IR;
	reg [N_addr-1:0] PC;
	reg [N_addr-1:0] SP;
	
	reg [N_data-1:0] opcode;
	
	reg [N_data-1:0] memory;
	
	always @(posedge CLK) begin
		opcode <= memory;
	end
	
	RF #(.data_size(N_data), .addr_size(N_addr)) reg_file (CLK, data_write, data_read, addr,write);
	ALU #(.bit_size(N_data)) alu (CLK, data_write, data_read, addr,write);
	IDU #(.bit_size(N_data)) idu (CLK, data_write, data_read, addr,write);
	

endmodule