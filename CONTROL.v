`timescale 1ns/10ps
//----------------------------------------------------------------------//
module CONTROL #(
	parameter 	OPND1_SRAM_AWIDTH 		= 10,	// Address bit width of the SRAM
	parameter 	OPND1_SRAM_BWIDTH 		= 256,	// Bits per row in the SRAM
	parameter 	OPND2_SRAM_AWIDTH 		= 10,	// Address bit width of the SRAM
	parameter 	OPND2_SRAM_BWIDTH 		= 256,	// Bits per row in the SRAM
	parameter 	OUT_SRAM_AWIDTH 		= 10,	// Address bit width of the SRAM
	parameter 	OUT_SRAM_BWIDTH 		= 1024,	// Bits per row in the SRAM
	parameter	PE_ARRAY_NUM_ROWS		= 32,	// # of rows in the PE array
	parameter	PE_ARRAY_NUM_ROWS_LOG2	= 5,	// log_2(32) == 5
	parameter	PE_ARRAY_NUM_COLS		= 32	// # of cols in the PE array
	parameter	PE_ARRAY_NUM_COLS_LOG2	= 5,	// log_2(32) == 5
	parameter	MAX_M_SIZE_LOG2			= 9, 	// # row entries of the first operand matrix == 511
	parameter	MAX_K_SIZE_LOG2			= 9, 	// # col entries of the first operand matrix == 511
	parameter	MAX_N_SIZE_LOG2			= 9 	// # col entries of the second operand matrix == 511
) 
(
	// Clock/reset/start
	input wire	RSTn,		// Reset 
	input wire 	CLK,		// Clock
	input wire 	START, 		// Start (ignored while working)

	// Matrix config
	input wire [MAX_M_SIZE_LOG2-1:0] 	M_SIZE,	// Mat A: M x K
	input wire [MAX_K_SIZE_LOG2-1:0] 	K_SIZE,
	input wire [MAX_N_SIZE_LOG2-1:0] 	N_SIZE,	// Mat B: K x N

	// SRAM control outputs
	output wire [OPND1_SRAM_AWIDTH-1:0] OPND1_SRAM_ADDR,
	output wire [OPND2_SRAM_AWIDTH-1:0] OPND2_SRAM_ADDR,
	output wire [OUT_SRAM_AWIDTH-1:0] 	OUT_SRAM_ADDR,
	
	// FIFO control outputs
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND1_FIFO_PUSHEs,
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND1_FIFO_POPEs,
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND2_FIFO_PUSHEs,
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND2_FIFO_POPEs,

	// PE array control outputs
	output wire [PE_ARRAY_NUM_ROWS-1:0]	ROWEs,
	output wire [PE_ARRAY_NUM_COLS-1:0]	COLEs,
	output wire 	COMPUTE,
	output wire 	FLUSH,

	// Processing control signals
	output wire 	STALL,
	output wire 	FINISHED
);

// Processing status register

// Matrix tile id
reg [MAX_M_SIZE_LOG2-PE_ARRAY_NUM_ROWS_LOG2:0]	CURR_TILE_ROW_ID;
reg [MAX_N_SIZE_LOG2-PE_ARRAY_NUM_COLS_LOG2:0]	CURR_TILE_COL_ID;
reg [MAX_K_SIZE_LOG2:0]	CURR_COMPUTE_COUNT;





// Sequential logic: 
always @ (posedge CLK, negedge RSTn) begin
	
	if (~RSTn) begin
		
	end
	else begin
		
	end
end

endmodule
//----------------------------------------------------------------------//