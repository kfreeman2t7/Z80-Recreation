module testbench;
	timeunit 1ns;
	timeprecision 100ps;
	
	reg clk;
	
	always #5 clk = ~clk;
	
	initial begin
		clk = 0;
		
	end
	
	Z80(
		.FPGA_CLK1_50(clk)
	);
endmodule