module copy_rom(CLK, rom_data, ram_data, ram_addr_r, ram_write, rom_addr, ram_addr_w, active, wren_wire);
	parameter data_size = 8;
	parameter addr_size = 8;
	parameter rom_size = 256;
	
	input wire CLK;
	input wire [data_size-1:0] rom_data, ram_data;
	output wire [data_size-1:0] ram_write;
	output wire [addr_size-1:0] rom_addr, ram_addr_w, ram_addr_r;
	output wire active, wren_wire;
	
	reg act_reg = 1, wren = 1;
	reg [addr_size-1:0] addr = 0;
	
	assign active = act_reg;
	assign rom_addr = addr;
	assign ram_addr_w = addr;
	assign ram_addr_r = addr;
	assign ram_write = rom_data;
	assign wren_wire = wren;
	
	reg [7:0] countdown = 300;
	
	always @(posedge CLK) begin
		if(countdown > 0) begin
			countdown <= countdown - 1;
		end else if(ram_data == rom_data && addr < rom_size-1) begin
			addr <= addr+1;
			countdown <= 300;
		end else if(addr < rom_size-1) begin
			addr <= addr;
		end else begin
			act_reg <= 0;
		end
			
	end
endmodule