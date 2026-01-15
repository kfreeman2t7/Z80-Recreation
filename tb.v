`timescale 1ns/100ps
module tb;
	
	reg clk;
	
	always #20 clk = ~clk;
	
	initial begin
		clk = 0;
		#10000;
		$stop;
		$finish;
	end
	
	Z80 cpu(
		.FPGA_CLK1_50(clk),
		.KEY(2'b11)
	);
endmodule