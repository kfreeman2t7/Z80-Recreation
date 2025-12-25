module copy_rom(CLK, rom_data, ram_write, rom_addr, ram_addr_w, active);
	parameter data_size = 8;
	parameter addr_size = 8;
	parameter rom_size = 256;
	
	input wire CLK;
	input wire [data_size-1:0] rom_data;
	output wire [data_size-1:0] ram_write;
	output wire [addr_size-1:0] rom_addr, ram_addr_w;
	output wire active;
	
	reg act_reg = 1;
	reg [addr_size-1:0] addr = 0;
	
	assign active = act_reg;
	assign rom_addr = addr;
	assign ram_addr_w = addr;
	assign ram_write = rom_data;
	
	reg [7:0] countdown = 2;
	
	always @(posedge CLK) begin
		if(countdown > 0) begin
			countdown <= countdown - 1;
		end else if(addr < rom_size-1) begin
			addr <= addr + 1;
			countdown <= 2;
		end else begin
			act_reg <= 0;
		end
			
	end
endmodule