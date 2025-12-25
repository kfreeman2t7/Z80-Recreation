module register_mux(input_regs, output_reg, sel);
	parameter sel_size;
	parameter reg_size = 16;
	
	input wire [sel_size-1:0] sel;
	input wire [sel_size-1:0] [reg_size-1:0] input_regs;
	output wire [reg_size-1:0] output_reg;
	
	assign output_reg = input_regs[sel];
	
	
endmodule