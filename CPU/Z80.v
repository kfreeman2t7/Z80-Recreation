module Z80 (FPGA_CLK1_50, LED, SW, KEY);
	
	//cpu params
	parameter data_size = 8;
	parameter core_addr_size = 2;
	parameter reg_addr_size = 3;
	
	parameter rom_addr_size = 16;
	parameter ram_addr_size = 16;
	
	//fpga inputs
	input wire FPGA_CLK1_50;
	output wire [7:0] LED;
	input wire [3:0] SW;
	input wire [1:0] KEY;
	
	//control signals
	gb_clock #(.value(6), .half_value(3), .bits(3)) vclock(FPGA_CLK1_50, core_vCLK);
	wire core_vCLK;
	wire core_CLK = core_vCLK&~boot_active;//~KEY[0]&~boot_active;//
	wire REQ, ACK;
	
	//boot logic
	wire boot_active;
	assign core_to_ram_wren[0] = boot_active;
	prgm rom(rom_addr, FPGA_CLK1_50, rom_data);
	copy_rom #(.data_size(data_size), .addr_size(rom_addr_size), .rom_size(14)) boot_rom(FPGA_CLK1_50, 
	rom_data, 
	core_to_ram_write_data[0],
	rom_addr, 
	core_to_ram_write_addr[0],
	boot_active);
	
	//ram+rom write signals
	wire [data_size-1:0] rom_data;
	wire [rom_addr_size-1:0] rom_addr;
	
	wire [data_size-1:0] ram_read_data, ram_write_data;
	wire [ram_addr_size:0] ram_read_addr, ram_write_addr;
	wire [core_addr_size-1:0] [ram_addr_size-1:0] core_to_ram_read_addr, core_to_ram_write_addr;
	wire [core_addr_size-1:0] [data_size-1:0] core_to_ram_write_data ;
	wire [core_addr_size-1:0] [0:0] core_to_ram_wren;
	
	
	//data control
	wire [core_addr_size-1:0] write_control = 8'd1;
	wire [core_addr_size-1:0] boot_control = ((8'd0)&{8{boot_active}}) | (write_control&{8{~boot_active}});
	wire ram_wren;
	
	
	arbiter #(.data_size(ram_addr_size), .req_addr_size(core_addr_size)) 	rr_arb(ram_read_addr, core_to_ram_read_addr, boot_control);
	arbiter #(.data_size(ram_addr_size), .req_addr_size(core_addr_size)) 	rw_arb(ram_write_addr, core_to_ram_write_addr, boot_control);
	arbiter #(.data_size(data_size), .req_addr_size(core_addr_size)) 		rwd_arb(ram_write_data, core_to_ram_write_data, boot_control);
	arbiter #(.data_size(1), .req_addr_size(core_addr_size)) 		wren_arb(ram_wren, core_to_ram_wren, boot_control);
	
	ram dram(FPGA_CLK1_50, ram_write_data, ram_read_addr, ram_write_addr, ram_wren, ram_read_data);
	
	
	

	

	
	//wire [rom_addr_size-1:0] addr = {SW[3],SW[2],SW[1],SW[0]};
	assign core_to_ram_read_addr[0] = SW;
	
	//cores
	SM83 #(.N_data(data_size), .N_reg_addr(reg_addr_size), .N_ram_addr(ram_addr_size)) core(
	core_CLK, REQ, ACK, 
	core_to_ram_wren[1],
	core_to_ram_read_addr[1], core_to_ram_write_addr[1], ram_read_data, core_to_ram_write_data[1],
	reg_read, print
	);
	
	//display
	wire [7:0] print;
	assign LED = print;
endmodule