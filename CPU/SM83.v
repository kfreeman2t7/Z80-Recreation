module SM83(CLK, REQ, ACK, data_write, data_read, addr,write);
	parameter N_data = 16;
	parameter N_addr = 16;
	
	input wire CLK,write;
	inout wire [N_data-1:0] addr;
	input wire [N_addr-1:0] data_write;
	output wire [N_addr-1:0] data_read;
	input wire REQ;
	output wire ACK;
	
	RF #(.data_size(N_data), .addr_size(N_addr)) reg_file (CLK, data_write, data_read, addr,write);
	

endmodule