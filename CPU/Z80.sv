module Z80 (

      ///////// ADC /////////
      output             ADC_CONVST,
      output             ADC_SCK,
      output             ADC_SDI,
      input              ADC_SDO,

      ///////// ARDUINO /////////
      inout       [15:0] ARDUINO_IO,
      inout              ARDUINO_RESET_N,

      ///////// FPGA /////////
      input              FPGA_CLK1_50,
      input              FPGA_CLK2_50,
      input              FPGA_CLK3_50,

      ///////// GPIO /////////
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      ///////// HDMI /////////
      inout              HDMI_I2C_SCL,
      inout              HDMI_I2C_SDA,
      inout              HDMI_I2S,
      inout              HDMI_LRCLK,
      inout              HDMI_MCLK,
      inout              HDMI_SCLK,
      output             HDMI_TX_CLK,
      output      [23:0] HDMI_TX_D,
      output             HDMI_TX_DE,
      output             HDMI_TX_HS,
      input              HDMI_TX_INT,
      output             HDMI_TX_VS,

`ifdef ENABLE_HPS
      ///////// HPS /////////
      inout              HPS_CONV_USB_N,
      output      [14:0] HPS_DDR3_ADDR,
      output      [2:0]  HPS_DDR3_BA,
      output             HPS_DDR3_CAS_N,
      output             HPS_DDR3_CKE,
      output             HPS_DDR3_CK_N,
      output             HPS_DDR3_CK_P,
      output             HPS_DDR3_CS_N,
      output      [3:0]  HPS_DDR3_DM,
      inout       [31:0] HPS_DDR3_DQ,
      inout       [3:0]  HPS_DDR3_DQS_N,
      inout       [3:0]  HPS_DDR3_DQS_P,
      output             HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_N,
      output             HPS_DDR3_RESET_N,
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_N,
      output             HPS_ENET_GTX_CLK,
      inout              HPS_ENET_INT_N,
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_ENET_RX_CLK,
      input       [3:0]  HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output      [3:0]  HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      inout              HPS_GSENSOR_INT,
      inout              HPS_I2C0_SCLK,
      inout              HPS_I2C0_SDAT,
      inout              HPS_I2C1_SCLK,
      inout              HPS_I2C1_SDAT,
      inout              HPS_KEY,
      inout              HPS_LED,
      inout              HPS_LTC_GPIO,
      output             HPS_SD_CLK,
      inout              HPS_SD_CMD,
      inout       [3:0]  HPS_SD_DATA,
      output             HPS_SPIM_CLK,
      input              HPS_SPIM_MISO,
      output             HPS_SPIM_MOSI,
      inout              HPS_SPIM_SS,
      input              HPS_UART_RX,
      output             HPS_UART_TX,
      input              HPS_USB_CLKOUT,
      inout       [7:0]  HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP,
`endif /*ENABLE_HPS*/

      ///////// KEY /////////
      input       [1:0]  KEY,

      ///////// LED /////////
      output      [7:0]  LED,

      ///////// SW /////////
      input       [3:0]  SW
);
	
	//cpu params
	parameter data_size = 8;
	parameter core_addr_size = 2;
	parameter reg_addr_size = 3;
	
	parameter rom_addr_size = 16;
	parameter ram_addr_size = 16;
	
	//control signals
	wire core_vCLK;
	gb_clock #(.value(10000000), .half_value((10000000/2)), .bits(32)) vclock(FPGA_CLK1_50, core_vCLK);
	
	wire core_CLK = core_vCLK;
	wire mem_CLK = core_vCLK;
	wire REQ, ACK;
	
	reg FORCE_RESET = 1;
	reg [8:0] FORCE_RESET_TIMER = 32;
	
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
	wire [core_addr_size-1:0] boot_control = write_control;
	wire ram_wren;
	
	
	arbiter #(.data_size(ram_addr_size), .req_addr_size(core_addr_size)) 	rr_arb(ram_read_addr, core_to_ram_read_addr, boot_control);
	arbiter #(.data_size(ram_addr_size), .req_addr_size(core_addr_size)) 	rw_arb(ram_write_addr, core_to_ram_write_addr, boot_control);
	arbiter #(.data_size(data_size), .req_addr_size(core_addr_size)) 		rwd_arb(ram_write_data, core_to_ram_write_data, boot_control);
	arbiter #(.data_size(1), .req_addr_size(core_addr_size)) 		wren_arb(ram_wren, core_to_ram_wren, boot_control);
	
	z80_ram dram(mem_CLK, ram_write_data, ram_read_addr, ram_write_addr, ram_wren, ram_read_data);
	
	reg [ram_addr_size-1:0] RAM_addr, Prev_RAM_addr;
	
	assign ACK = (RAM_addr == ram_read_addr);
	
	always @ (posedge mem_CLK) begin
		Prev_RAM_addr <= ram_read_addr;
		RAM_addr <= Prev_RAM_addr;
	end

	

	
	//wire [rom_addr_size-1:0] addr = {SW[3],SW[2],SW[1],SW[0]};
	wire [ram_addr_size-1:0] cpu_addr;
	wire [data_size-1:0] cpu_data;
	
	assign core_to_ram_read_addr[1] = cpu_addr;
	assign core_to_ram_write_addr[1] = cpu_addr;
	
	wire [7:0] registers [7:0];
	
	//cores
	SM83 #(.N_data(data_size), .N_reg_addr(reg_addr_size), .N_ram_addr(ram_addr_size)) core(
	core_CLK, REQ, ACK, 
	core_to_ram_wren[1], core_to_ram_write_data[1],
	cpu_addr, ram_read_data,
	~KEY[1]|FORCE_RESET,
	registers
	);
	
	always @ (posedge core_CLK) begin
		if(FORCE_RESET_TIMER > 0) begin
			FORCE_RESET_TIMER <= FORCE_RESET_TIMER - 1;
		end else begin
			FORCE_RESET <= 0;
		end
	end
	
	wire [10:0] HDMI_x, HDMI_y;
	wire [23:0] HDMI_rgb;
	
	//HDMI
	//DE10_Nano_HDMI_TX(
	//ADC_CONVST, ADC_SCK, ADC_SDI, ADC_SDO, 
	//FPGA_CLK1_50, FPGA_CLK2_50, FPGA_CLK3_50,
	//HDMI_I2C_SCL, HDMI_I2C_SDA, HDMI_I2S,
	//HDMI_LRCLK, HDMI_MCLK, HDMI_SCLK, 
	//HDMI_TX_CLK, HDMI_TX_D, HDMI_TX_DE, HDMI_TX_HS, HDMI_TX_INT, HDMI_TX_VS,
	//2'b0, 1'b0,
	//HDMI_x, HDMI_y, HDMI_rgb
	//);
	
	//PPU(FPGA_CLK1_50, 8'b0, 3'b0, HDMI_x, HDMI_y, HDMI_rgb, registers);
	
endmodule