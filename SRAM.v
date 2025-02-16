`timescale 1ns/10ps
module SRAM #(
	parameter ROMDATA = "", 
	BWIDTH 		= 256, 	// Bits per row
	AWIDTH 		= 10, 	// Address width (Row-address)
	NUM_ROWS 	= 1024) // # rows
(
	input	wire					CLK,
	input	wire					CSn,	// chip select negative
	input	wire	[AWIDTH-1:0]	ADDR,
	input	wire					WEn,	// write enable negative
	input	wire	[BWIDTH-1:0]	BE,		// bit enable
	input	wire	[BWIDTH-1:0]	D_in, 	// data in

	output	wire	[BWIDTH-1:0]	D_out 	// data out
);

	reg		[BWIDTH-1:0]		outline;
	reg		[BWIDTH-1:0]		rows[0 : NUM_ROWS-1];

	wire	[BWIDTH-1:0]		data_masked;
	assign	data_masked = (rows[ADDR] & BE);
	

	initial begin
		if (ROMDATA != "")
			$readmemh(ROMDATA, ram);
	end

	assign #1 DOUT = outline;

	always @ (posedge CLK) begin
		// Synchronous write
		if (~CSN) begin
			if (~WEN) begin
				rows[ADDR] <= data_masked;
			end
		end

	end

	always @ (*) begin
		// Asynchronous read
		if (~CSN) begin
			if (WEN) outline = ram[ADDR];
		end
	end

endmodule
