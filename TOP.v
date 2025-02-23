`timescale 1ns/10ps
//----------------------------------------------------------------------//
module SYSTOLIC_ARRAY #(
    parameter 	OPND1_SRAM_AWIDTH 		= 10,		// Address bit width of the SRAM
	parameter 	OPND1_SRAM_BWIDTH 		= 32*8,		// Bits per row in the SRAM
	parameter 	OPND2_SRAM_AWIDTH 		= 10,		// Address bit width of the SRAM
	parameter 	OPND2_SRAM_BWIDTH 		= 32*8,		// Bits per row in the SRAM
	parameter 	OUT_SRAM_AWIDTH 		= 10,		// Address bit width of the SRAM
	parameter 	OUT_SRAM_BWIDTH 		= 32*32,	// Bits per row in the SRAM
    parameter   FIFO_BWIDTH             = 8,        // INT8 operands
    parameter   FIFO_DEPTH              = 32,       // For 32-by-32 PE arrays
    parameter   FIFO_DEPTH_LOG2         = 5,        // log_2(32) == 5
	parameter	PE_ARRAY_NUM_ROWS		= 32,		// # of rows in the PE array
	parameter	PE_ARRAY_NUM_ROWS_LOG2  = 5,		// log_2(32) == 5
	parameter	PE_ARRAY_NUM_COLS		= 32,		// # of cols in the PE array
	parameter	PE_ARRAY_NUM_COLS_LOG2  = 5,		// log_2(32) == 5
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

    output wire     IS_FINISHED_out
)

/* Interal ports */
// SRAMs //
// Control signals
wire [OPND1_SRAM_AWIDTH-1:0] opnd1_sram_addr;
wire opnd1_sram_wen;
wire [OPND2_SRAM_AWIDTH-1:0] opnd2_sram_addr;
wire opnd2_sram_wen;
wire [OUT_SRAM_AWIDTH-1:0] out_sram_addr;
wire out_sram_wen;
wire [OUT_SRAM_BWIDTH-1:0] out_sram_be;

// Datapath
wire [OPND1_SRAM_BWIDTH-1:0]    opnd1_sram_data;
wire [OPND2_SRAM_BWIDTH-1:0]    opnd2_sram_data;
wire [OUT_SRAM_BWIDTH-1:0]      out_sram_data;

// FIFOs //
// Control signals
wire [PE_ARRAY_NUM_ROWS-1:0]    opnd1_fifo_pushe;
wire [PE_ARRAY_NUM_ROWS-1:0]    opnd1_fifo_pope;
wire [PE_ARRAY_NUM_COLS-1:0]    opnd2_fifo_pushe;
wire [PE_ARRAY_NUM_COLS-1:0]    opnd2_fifo_pope;

// Datapath
wire [FIFO_BWIDTH-1:0]  opnd1_fifo_data[1:PE_ARRAY_NUM_ROWS-1];
wire [FIFO_BWIDTH-1:0]  opnd2_fifo_data[1:PE_ARRAY_NUM_COLS-1];

CONTROL controller (
    .RSTn   (RSTn),
    .CLK    (CLK),
    .START  (START),
    .STALL  (STALL),

    .M_SIZE_in  (M_SIZE_in),
    .K_SIZE_in  (K_SIZE_in),
    .K_SIZE_in  (N_SIZE_in),

    .OPND1_SRAM_ADDR_out

)


endmodule