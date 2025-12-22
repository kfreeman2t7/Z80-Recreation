module Z80 (FPGA_CLK1_50, LED, SW, KEY);
	
	input wire FPGA_CLK1_50;
	output wire [7:0] LED;
	input wire [3:0] SW;
	input wire [1:0] KEY;
	
	reg [7:0] reg_write, reg_read;
	
	always @(posedge ~KEY[1]) begin
		reg_write = reg_write+1;
	end

	wire ACK;
	
	wire [7:0] data_read, data_write;
	assign data_write = reg_write;

	
	wire [3:0] addr = {SW[3],SW[2],SW[1],SW[0]};
	SM83 #(.N_data(8), .N_addr(4)) core(FPGA_CLK1_50, 1'b0, ACK,data_write,data_read,addr,~KEY[0]);
	
	reg [7:0] LED_reg;
	always @(posedge FPGA_CLK1_50) begin
		LED_reg[3:0] <= data_write[3:0];
		LED_reg[7:4] <= data_read[3:0];
	end
	
	assign LED[7:0] = LED_reg[7:0];
endmodule