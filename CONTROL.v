`timescale 1ns/10ps
//----------------------------------------------------------------------//
module CONTROL #(
	parameter 	OPND1_SRAM_AWIDTH 		= 10,		// Address bit width of the SRAM
	parameter 	OPND1_SRAM_BWIDTH 		= 32*8,		// Bits per row in the SRAM
	parameter 	OPND2_SRAM_AWIDTH 		= 10,		// Address bit width of the SRAM
	parameter 	OPND2_SRAM_BWIDTH 		= 32*8,		// Bits per row in the SRAM
	parameter 	OUT_SRAM_AWIDTH 		= 10,		// Address bit width of the SRAM
	parameter 	OUT_SRAM_BWIDTH 		= 32*32,	// Bits per row in the SRAM
	parameter	PE_ARRAY_NUM_ROWS		= 32,		// # of rows in the PE array
	parameter	PE_ARRAY_NUM_ROWS_LOG2	= 5,		// log_2(32) == 5
	parameter	PE_ARRAY_NUM_COLS		= 32		// # of cols in the PE array
	parameter	PE_ARRAY_NUM_COLS_LOG2	= 5,		// log_2(32) == 5
	parameter	MAX_M_SIZE_LOG2			= 9, 		// # row entries of the first operand matrix == 511
	parameter	MAX_K_SIZE_LOG2			= 9, 		// # col entries of the first operand matrix == 511
	parameter	MAX_N_SIZE_LOG2			= 9 		// # col entries of the second operand matrix == 511
) 
(
	// Clock/reset/start/stall
	input wire	RSTn,		// Reset 
	input wire 	CLK,		// Clock
	input wire 	START, 		// Start (ignored while working)
	input wire	STALL,		// Stall

	// Matrix config
	input wire [MAX_M_SIZE_LOG2-1:0] 	M_SIZE,	// Mat A: M x K
	input wire [MAX_K_SIZE_LOG2-1:0] 	K_SIZE,
	input wire [MAX_N_SIZE_LOG2-1:0] 	N_SIZE,	// Mat B: K x N

	// SRAM control outputs
	output wire [OPND1_SRAM_AWIDTH-1:0] OPND1_SRAM_ADDR_out,
	output wire [OPND2_SRAM_AWIDTH-1:0] OPND2_SRAM_ADDR_out,
	output wire [OUT_SRAM_AWIDTH-1:0] 	OUT_SRAM_ADDR_out,
	
	// FIFO control outputs
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND1_FIFO_PUSHEs_out,
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND1_FIFO_POPEs_out,
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND2_FIFO_PUSHEs_out,
	output wire [PE_ARRAY_NUM_ROWS-1:0] OPND2_FIFO_POPEs_out,

	// PE array control outputs
	output wire [PE_ARRAY_NUM_ROWS-1:0]	PE_ROW_VALID_out,
	output wire [PE_ARRAY_NUM_COLS-1:0]	PE_COL_VALID_out,
	output wire 	IS_COMPUTING_out,
	output wire 	IS_FLUSHING_out,

	// Processing control signals
	output wire 	IS_FINISHED_out
);

// State registers
reg 	is_idle;
reg 	is_computing;
reg 	is_flushing;

// Configuration registers
reg [MAX_M_SIZE_LOG2-PE_ARRAY_NUM_ROWS_LOG2:0]	num_tile_row_ids;
reg [MAX_N_SIZE_LOG2-PE_ARRAY_NUM_COLS_LOG2:0]	num_tile_col_ids;

// Tile id registers
reg [MAX_M_SIZE_LOG2-PE_ARRAY_NUM_ROWS_LOG2:0]	curr_tile_row_id;
reg [MAX_N_SIZE_LOG2-PE_ARRAY_NUM_COLS_LOG2:0]	curr_tile_col_id;

// Intra-tile logic registers
reg [PE_ARRAY_NUM_ROWS_LOG2-1:0]	curr_num_actv_row_ids;
reg [PE_ARRAY_NUM_COLS_LOG2-1:0] 	curr_num_actv_col_ids;
reg [MAX_K_SIZE_LOG2:0]	compute_count;
reg [MAX_K_SIZE_LOG2:0]	flush_count;



// Sequential logic: update state
always @ (posedge CLK, negedge RSTn) begin
	
	if (~RSTn) begin
		
	end
	else begin
		
	end
end

endmodule
//----------------------------------------------------------------------//