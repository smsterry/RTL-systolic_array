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
	input wire [MAX_M_SIZE_LOG2-1:0] 	M_SIZE_in,	// Mat A: M x K
	input wire [MAX_K_SIZE_LOG2-1:0] 	K_SIZE_in,
	input wire [MAX_N_SIZE_LOG2-1:0] 	N_SIZE_in,	// Mat B: K x N

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

/* Register statement */
// State registers
reg 	is_idle;
reg 	is_computing;
reg 	is_flushing;

// Configuration registers
reg [MAX_M_SIZE_LOG2-1:0] m_size;
reg [MAX_K_SIZE_LOG2-1:0] k_size;
reg [MAX_N_SIZE_LOG2-1:0] n_size;
reg [MAX_M_SIZE_LOG2-PE_ARRAY_NUM_ROWS_LOG2:0]	num_tile_row_ids;
reg [MAX_N_SIZE_LOG2-PE_ARRAY_NUM_COLS_LOG2:0]	num_tile_col_ids;

// Tile id registers
reg [MAX_M_SIZE_LOG2-PE_ARRAY_NUM_ROWS_LOG2:0]	curr_tile_row_id;
reg [MAX_N_SIZE_LOG2-PE_ARRAY_NUM_COLS_LOG2:0]	curr_tile_col_id;

// Intra-tile logic registers
reg [PE_ARRAY_NUM_ROWS_LOG2-1:0]	curr_num_actv_row_ids;
reg [PE_ARRAY_NUM_COLS_LOG2-1:0] 	curr_num_actv_col_ids;
reg [MAX_K_SIZE_LOG2:0]				compute_count;
reg [MAX_K_SIZE_LOG2:0]				flush_count;

/* Temporal wire statement & assignment for the next value */

/**
 *	[num_tile_row_ids_nxt, num_tile_col_ids_nxt]
 *	
 *	The number of tiles per each column, row.
 *	Note that these values are determined by M, N, and PE array sizes.
 * 	Also, note that these values are set only for: idle -> compute
 * 	e.g.) 
 *	For 32 x 32 PE array, M = 128, and N = 96:
 * 		- num_tile_row_ids_nxt = ceil(128 / 32) = 4
 *		- num_tile_col_ids_nxt = ceil(96 / 32) = 3
 */
wire [MAX_M_SIZE_LOG2-PE_ARRAY_NUM_ROWS_LOG2:0] num_tile_row_ids_nxt;
wire [MAX_N_SIZE_LOG2-PE_ARRAY_NUM_COLS_LOG2:0]	num_tile_col_ids_nxt;
wire [MAX_M_SIZE_LOG2-1:0]	m_divisible_by_num_rows;
wire [MAX_M_SIZE_LOG2-1:0] 	m_not_divisible_by_num_rows;
wire [MAX_N_SIZE_LOG2-1:0]	n_divisible_by_num_cols;
wire [MAX_N_SIZE_LOG2-1:0]	n_not_divisible_by_num_cols;

assign m_divisible_by_num_rows 		= M_SIZE_in >> PE_ARRAY_NUM_ROWS_LOG2;
assign m_not_divisible_by_num_rows 	= m_divisible_by_num_rows + 1;
assign n_divisible_by_num_cols 		= N_SIZE_in >> PE_ARRAY_NUM_COLS_LOG2;
assign n_not_divisible_by_num_cols 	= n_divisible_by_num_cols + 1;

assign num_tile_row_ids_nxt	
	= (M_SIZE_in[PE_ARRAY_NUM_ROWS_LOG2-1:0] == 0)? 
	m_divisible_by_num_rows : m_not_divisible_by_num_rows;
assign num_tile_col_ids_nxt	
	= (N_SIZE_in[PE_ARRAY_NUM_COLS_LOG2-1:0] == 0)? 
	n_divisible_by_num_cols : n_not_divisible_by_num_cols;




/**
 *	[compute_to_flush]
 *	
 *	Determine if state transition from the computing state to the flushing 
 * 	state is required or not. This flag is turned on when the computing the 
 *	current tile is finished.
 */
wire compute_to_flush;
wire curr_end_compute_count;

assign curr_end_compute_count 
	= k_size + (curr_num_actv_row_ids-1) + (curr_num_actv_col_ids-1);
assign compute_to_flush
	 = (compute_count == curr_end_compute_count)? 1 : 0;

/**
 *	[flush_to_compute, is_finished]
 *	
 *	Determine if state transition from the flushing state to the computing 
 * 	state (or the idle state) is required or not. These flags can be turned
 * 	on if flushing all accumulated output is finished.
 */
wire flush_to_compute;
wire is_finished;
wire all_tile_flushed;
wire all_row_flushed;

assign all_row_flushed = (flush_count == PE_ARRAY_NUM_ROWS)? 1 : 0;
assign all_tile_flushed 
	= ((curr_tile_row_id == num_tile_row_ids - 1) 
	&& (curr_tile_col_id == num_tile_col_ids - 1))? 1 : 0;
assign flush_to_compute = (all_row_flushed & ~all_tile_flushed);
assign is_finished		= (all_row_flushed & all_tile_flushed);


// Sequential logic: update state
always @ (posedge CLK, negedge RSTn) begin
	
	if (~RSTn) begin
		
	end
	else begin
		// Start to compute. Set all signals that are required to compute
		if (~is_computing & ~is_flushing & START) begin
		end
	end
end

endmodule
//----------------------------------------------------------------------//