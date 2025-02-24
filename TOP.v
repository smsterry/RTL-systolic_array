`timescale 1ns/10ps
//----------------------------------------------------------------------//
module SYSTOLIC_ARRAY #(
    parameter   OPND_BWIDTH             = 8,        // INT8 operands
    parameter   OPND_BWIDTH_LOG2        = 3,        // log_2(8) == 3
    parameter   ACC_BWIDTH              = 32,       // INT32 accumulated outputs
    parameter   ACC_BWIDTH_LOG2         = 5,        // log_2(32) == 5
    parameter   OPND1_SRAM_AWIDTH       = 10,       // Address bit width of the SRAM
    parameter   OPND1_SRAM_BWIDTH       = 32*8,     // Bits per row in the SRAM
    parameter   OPND2_SRAM_AWIDTH       = 10,       // Address bit width of the SRAM
    parameter   OPND2_SRAM_BWIDTH       = 32*8,     // Bits per row in the SRAM
    parameter   OUT_SRAM_AWIDTH         = 10,       // Address bit width of the SRAM
    parameter   OUT_SRAM_BWIDTH         = 32*32,    // Bits per row in the SRAM
    parameter   PE_ARRAY_NUM_ROWS       = 32,       // # of rows in the PE array
    parameter   PE_ARRAY_NUM_ROWS_LOG2  = 5,        // log_2(32) == 5
    parameter   PE_ARRAY_NUM_COLS       = 32,       // # of cols in the PE array
    parameter   PE_ARRAY_NUM_COLS_LOG2  = 5,        // log_2(32) == 5
    parameter   MAX_M_SIZE_LOG2         = 9,        // # row entries of the first operand matrix == 511
    parameter   MAX_K_SIZE_LOG2         = 9,        // # col entries of the first operand matrix == 511
    parameter   MAX_N_SIZE_LOG2         = 9,        // # col entries of the second operand matrix == 511

    parameter   OPND1_ROMDATA           = "",
    parameter   OPND2_ROMDATA           = "",
    parameter   OUT_WRITEDATA           = ""
)
(
    // Clock/reset/start/stall
    input wire  RSTn,   // Reset 
    input wire  CLK,    // Clock
    input wire  START,  // Start (ignored while working)
    input wire  STALL,  // Stall

    // Matrix config
    input wire [MAX_M_SIZE_LOG2-1:0]    M_SIZE_in,  // Mat A: M x K
    input wire [MAX_K_SIZE_LOG2-1:0]    K_SIZE_in,
    input wire [MAX_N_SIZE_LOG2-1:0]    N_SIZE_in,  // Mat B: K x N

    output wire     IS_FINISHED_out
);




/* Interal ports */

// Control signals //
// SRAMs
wire [OPND1_SRAM_AWIDTH-1:0] opnd1_sram_addr;
wire opnd1_sram_wen;
wire [OPND2_SRAM_AWIDTH-1:0] opnd2_sram_addr;
wire opnd2_sram_wen;
wire [OUT_SRAM_AWIDTH-1:0] out_sram_addr;
wire out_sram_wen;
wire [OUT_SRAM_BWIDTH-1:0] out_sram_be;

// FIFOs
wire [PE_ARRAY_NUM_ROWS-1:0]    opnd1_fifo_pushe;
wire [PE_ARRAY_NUM_ROWS-1:0]    opnd1_fifo_pope;
wire [PE_ARRAY_NUM_COLS-1:0]    opnd2_fifo_pushe;
wire [PE_ARRAY_NUM_COLS-1:0]    opnd2_fifo_pope;

// PE array
wire pe_array_is_computing;
wire pe_array_is_flushing;


// Datapath //
// SRAMs -> FIFOs
wire [OPND1_SRAM_BWIDTH-1:0]    opnd1_data_sram_to_fifo;
wire [OPND2_SRAM_BWIDTH-1:0]    opnd2_data_sram_to_fifo;

// FIFOs -> PE array
wire [OPND1_SRAM_BWIDTH-1:0]    opnd1_data_fifo_to_pe_array;
wire [OPND2_SRAM_BWIDTH-1:0]    opnd2_data_fifo_to_pe_array;

// PE array -> SRAM
wire [OUT_SRAM_BWIDTH-1:0]      out_data_pe_array_to_sram;




/* Modules */
// Controller
CONTROL #(
    .OPND1_SRAM_AWIDTH      (OPND1_SRAM_AWIDTH),
    .OPND1_SRAM_BWIDTH      (OPND1_SRAM_BWIDTH),
    .OPND2_SRAM_AWIDTH      (OPND2_SRAM_AWIDTH),
    .OPND2_SRAM_BWIDTH      (OPND2_SRAM_BWIDTH),
    .ACC_BWIDTH_LOG2        (ACC_BWIDTH_LOG2), 
    .OUT_SRAM_AWIDTH        (OUT_SRAM_AWIDTH),
    .OUT_SRAM_BWIDTH        (OUT_SRAM_BWIDTH),
    .PE_ARRAY_NUM_ROWS      (PE_ARRAY_NUM_ROWS),
    .PE_ARRAY_NUM_ROWS_LOG2 (PE_ARRAY_NUM_ROWS_LOG2),
    .PE_ARRAY_NUM_COLS      (PE_ARRAY_NUM_COLS),
    .PE_ARRAY_NUM_COLS_LOG2 (PE_ARRAY_NUM_COLS_LOG2),
    .MAX_M_SIZE_LOG2        (MAX_M_SIZE_LOG2),
    .MAX_K_SIZE_LOG2        (MAX_K_SIZE_LOG2),
    .MAX_N_SIZE_LOG2        (MAX_N_SIZE_LOG2)
) controller (
    .RSTn   (RSTn),
    .CLK    (CLK),
    .START  (START),
    .STALL  (STALL),

    .M_SIZE_in  (M_SIZE_in),
    .K_SIZE_in  (K_SIZE_in),
    .N_SIZE_in  (N_SIZE_in),

    .OPND1_SRAM_ADDR_out    (opnd1_sram_addr),
    .OPND2_SRAM_ADDR_out    (opnd2_sram_addr),
    .OUT_SRAM_ADDR_out      (out_sram_addr),
    .OPND1_SRAM_WEn_out     (opnd1_sram_wen),
    .OPND2_SRAM_WEn_out     (opnd2_sram_wen),
    .OUT_SRAM_WEn_out       (out_sram_wen),
    .OUT_SRAM_BE_out        (out_sram_be),

    .OPND1_FIFO_PUSHEs_out  (opnd1_fifo_pushe),
    .OPND1_FIFO_POPEs_out   (opnd1_fifo_pope),
    .OPND2_FIFO_PUSHEs_out  (opnd2_fifo_pushe),
    .OPND2_FIFO_POPEs_out   (opnd2_fifo_pope),

    .IS_COMPUTING_out       (pe_array_is_computing),
    .IS_FLUSHING_out        (pe_array_is_flushing),

    .IS_FINISHED_out        (IS_FINISHED_out)
);

// SRAMs
SRAM # (
    .ROMDATA    (OPND1_ROMDATA),
    .WRITEDATA  (),
    .BWIDTH     (OPND1_SRAM_BWIDTH),
    .AWIDTH     (OPND1_SRAM_AWIDTH),
    .NUM_ROWS   (1 << OPND1_SRAM_AWIDTH)
) opnd1_sram (
    .CLK        (CLK),
    .CSn        (1'b0),
    .ADDR       (opnd1_sram_addr),
    .WEn        (opnd1_sram_wen),
    .BE         (),
    .D_in       (),
    .IS_FINISHED_in (1'b0),
    .D_out      (opnd1_data_sram_to_fifo)
);

SRAM # (
    .ROMDATA    (OPND2_ROMDATA),
    .WRITEDATA  (),
    .BWIDTH     (OPND2_SRAM_BWIDTH),
    .AWIDTH     (OPND2_SRAM_AWIDTH),
    .NUM_ROWS   (1 << OPND2_SRAM_AWIDTH)
) opnd2_sram (
    .CLK        (CLK),
    .CSn        (1'b0),
    .ADDR       (opnd2_sram_addr),
    .WEn        (opnd2_sram_wen),
    .BE         (),
    .D_in       (),
    .IS_FINISHED_in (1'b0),
    .D_out      (opnd2_data_sram_to_fifo)
);

SRAM # (
    .ROMDATA    (),
    .WRITEDATA  (OUT_WRITEDATA),
    .BWIDTH     (OUT_SRAM_BWIDTH),
    .AWIDTH     (OUT_SRAM_AWIDTH),
    .NUM_ROWS   (1 << OUT_SRAM_AWIDTH)
) out_sram (
    .CLK        (CLK),
    .CSn        (1'b0),
    .ADDR       (out_sram_addr),
    .WEn        (out_sram_wen),
    .BE         (out_sram_be),
    .D_in       (out_data_pe_array_to_sram),
    .IS_FINISHED_in (is_finished),
    .D_out      ()
);

// FIFOs
assign opnd1_data_fifo_to_pe_array[OPND_BWIDTH-1:0] 
    = opnd1_data_sram_to_fifo[OPND_BWIDTH-1:0];
genvar opnd1_fifo_id;
generate
    for (opnd1_fifo_id = 1; opnd1_fifo_id < PE_ARRAY_NUM_ROWS; opnd1_fifo_id = opnd1_fifo_id + 1)
    begin: gen_opnd1_fifos
        FIFO #(
            .DEPTH      (PE_ARRAY_NUM_ROWS),
            .DEPTH_LOG2 (PE_ARRAY_NUM_ROWS_LOG2),
            .BWIDTH     (OPND_BWIDTH)
        ) opnd1_fifo (
            .RSTn       (RSTn),
            .CLK        (CLK),
            .PUSHE      (opnd1_fifo_pushe[opnd1_fifo_id]),
            .POPE       (opnd1_fifo_pope[opnd1_fifo_id]),
            
            .D_in       (opnd1_data_sram_to_fifo[((opnd1_fifo_id + 1) << OPND_BWIDTH_LOG2)-1:(opnd1_fifo_id << OPND_BWIDTH_LOG2)]),
            
            .IS_EMPTY   (),
            .IS_FULL    (),

            .D_out      (opnd1_data_fifo_to_pe_array[((opnd1_fifo_id + 1) << OPND_BWIDTH_LOG2)-1:(opnd1_fifo_id << OPND_BWIDTH_LOG2)])
        );
    end
endgenerate

assign opnd2_data_fifo_to_pe_array[OPND_BWIDTH-1:0] 
    = opnd2_data_sram_to_fifo[OPND_BWIDTH-1:0];
genvar opnd2_fifo_id;
generate
    for (opnd2_fifo_id = 1; opnd2_fifo_id < PE_ARRAY_NUM_COLS; opnd2_fifo_id = opnd2_fifo_id + 1)
    begin: gen_opnd2_fifos
        FIFO #(
            .DEPTH      (PE_ARRAY_NUM_COLS),
            .DEPTH_LOG2 (PE_ARRAY_NUM_COLS_LOG2),
            .BWIDTH     (OPND_BWIDTH)
        ) opnd2_fifo (
            .RSTn       (RSTn),
            .CLK        (CLK),
            .PUSHE      (opnd1_fifo_pushe[opnd2_fifo_id]),
            .POPE       (opnd1_fifo_pope[opnd2_fifo_id]),
            
            .D_in       (opnd2_data_sram_to_fifo[((opnd2_fifo_id + 1) << OPND_BWIDTH_LOG2)-1:(opnd2_fifo_id << OPND_BWIDTH_LOG2)]),
            
            .IS_EMPTY   (),
            .IS_FULL    (),

            .D_out      (opnd2_data_fifo_to_pe_array[((opnd2_fifo_id + 1) << OPND_BWIDTH_LOG2)-1:(opnd2_fifo_id << OPND_BWIDTH_LOG2)])
        );
    end
endgenerate

// PE array
PE_ARRAY #(
    .OPND1_SRAM_BWIDTH      (OPND1_SRAM_BWIDTH),
    .OPND2_SRAM_BWIDTH      (OPND2_SRAM_BWIDTH),
    .OUT_SRAM_BWIDTH        (OUT_SRAM_BWIDTH),
    .OPND_BWIDTH            (OPND_BWIDTH),
    .OPND_BWIDTH_LOG2       (OPND_BWIDTH_LOG2),
    .ACC_BWIDTH             (ACC_BWIDTH),
    .ACC_BWIDTH_LOG2        (ACC_BWIDTH_LOG2),
    .PE_ARRAY_NUM_ROWS      (PE_ARRAY_NUM_ROWS),
    .PE_ARRAY_NUM_ROWS_LOG2 (PE_ARRAY_NUM_ROWS_LOG2),
    .PE_ARRAY_NUM_COLS      (PE_ARRAY_NUM_COLS),
    .PE_ARRAY_NUM_COLS_LOG2 (PE_ARRAY_NUM_COLS_LOG2)
) pe_array (
    .RSTn           (RSTn),
    .CLK            (CLK),
    .STALL          (STALL),

    .IS_COMPUTING_in    (pe_array_is_computing),
    .IS_FLUSHING_in     (pe_array_is_flushing),
    .OPND1_IS_VALID_in  (opnd1_fifo_pope),
    .OPND2_IS_VALID_in  (opnd2_fifo_pope),

    .OPND1_DATA_in      (opnd1_data_fifo_to_pe_array),
    .OPND2_DATA_in      (opnd2_data_fifo_to_pe_array),

    .OUT_DATA_out       (out_data_pe_array_to_sram)
);

endmodule