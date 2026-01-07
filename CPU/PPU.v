module PPU(input CLK, input [7:0] reg_data, input [2:0] reg_addr, input [10:0] hdmi_x, input [10:0] hdmi_y, output [23:0] rgb, input [7:0] registers [7:0]);
	
	parameter char_A = 65;
	parameter char_B = 66;
	parameter char_C = 67;
	parameter char_D = 68;
	parameter char_E = 69;
	parameter char_F = 70;
	parameter char_G = 71;
	parameter char_H = 72;
	parameter char_I = 73;
	parameter char_J = 74;
	parameter char_K = 75;
	parameter char_L = 76;
	parameter char_M = 77;
	parameter char_N = 78;
	parameter char_O = 79;
	parameter char_P = 80;
	parameter char_Q = 81;
	parameter char_R = 82;
	parameter char_S = 83;
	parameter char_T = 84;
	parameter char_U = 85;
	parameter char_V = 86;
	parameter char_W = 87;
	parameter char_X = 88;
	parameter char_Y = 89;
	parameter char_Z = 90;
	
	parameter char_0 = 16;
	parameter char_1 = 17;
	parameter char_2 = 18;
	parameter char_3 = 19;
	parameter char_4 = 20;
	parameter char_5 = 21;
	parameter char_6 = 22;
	parameter char_7 = 23;
	parameter char_8 = 24;
	parameter char_9 = 25;
	
	parameter char_colon = 26;
	
	reg [7:0] half_byte_to_char [15:0] = '{ 
	{char_F}, {char_E}, {char_D}, {char_C}, 
	{char_B}, {char_A}, {char_9}, {char_8}, 
	{char_7}, {char_6}, {char_5}, {char_4}, 
	{char_3}, {char_2}, {char_1}, {char_0}	};
	
	parameter resolution_x = 640;
	parameter resolution_y = 480;
	
	wire [23:0] set_rgb;
	text_rom chars((char*64+y*8+x), CLK, set_rgb);
	
	//rendering characters
	wire [21:0] full_index = (hdmi_x + hdmi_y*resolution_x + 1)%(resolution_x*resolution_y);
	wire [10:0] set_x = full_index%resolution_x;
	wire [10:0] set_y = full_index/resolution_x;
	
	wire [7:0] tile_x = set_x/8;
	wire [7:0] tile_y = set_y/8;
	
	wire [2:0] x = set_x%8;
	wire [2:0] y = set_y%8;
	
	reg [7:0] char;
	
	wire [15:0] pos = {tile_x, tile_y};

	always @ (*) begin
			case(pos)
				{8'd20,8'd0}:  char <= char_R;
				{8'd21,8'd0}:  char <= char_E;
				{8'd22,8'd0}:  char <= char_G;
				{8'd23,8'd0}:  char <= 0;
				{8'd24,8'd0}:  char <= char_B;
				{8'd25,8'd0}:  char <= char_colon;
				{8'd26,8'd0}:  char <= half_byte_to_char[registers[0][7:4]];
				{8'd27,8'd0}:  char <= half_byte_to_char[registers[0][3:0]];
				default: char <= 0;
			endcase
	end
	
	assign rgb = set_rgb;
	
	
endmodule