module arbiter(rom_addr, addr_req, request_addr);
	parameter data_size = 8;
	parameter req_addr_size = 1;
	
	output wire [data_size-1:0] rom_addr;
	input wire [req_addr_size-1:0] request_addr;
	input wire [req_addr_size-1:0] [data_size-1:0] addr_req;
	
	assign rom_addr = addr_req[request_addr];
	
endmodule