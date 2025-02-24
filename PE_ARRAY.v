`timescale 1ns/10ps
//----------------------------------------------------------------------//
module PE_ARRAY #(
    parameter   OPND1_SRAM_BWIDTH       = 32*8,     // Bits per row in the SRAM
    parameter   OPND2_SRAM_BWIDTH       = 32*8,     // Bits per row in the SRAM
    parameter   OUT_SRAM_BWIDTH         = 32*32,    // Bits per row in the SRAM
    parameter   OPND_BWIDTH             = 8,        // INT8 operands
    parameter   OPND_BWIDTH_LOG2        = 3,        // log_2(8) == 3
    parameter   ACC_BWIDTH              = 32,       // INT32 partial sums
    parameter   ACC_BWIDTH_LOG2         = 5,        // log_2(32) == 5
    parameter   PE_ARRAY_NUM_ROWS       = 32,       // # of rows in the PE array
    parameter   PE_ARRAY_NUM_ROWS_LOG2  = 5,        // log_2(32) == 5
    parameter   PE_ARRAY_NUM_COLS       = 32,       // # of cols in the PE array
    parameter   PE_ARRAY_NUM_COLS_LOG2  = 5         // log_2(32) == 5
)
(
    // Clock/reset/start/stall
    input wire  RSTn,       // Reset 
    input wire  CLK,        // Clock
    input wire  STALL,      // Stall

    // Control inputs
    input wire  IS_COMPUTING_in,
    input wire  IS_FLUSHING_in,
    input wire [PE_ARRAY_NUM_ROWS-1:0]  OPND1_IS_VALID_in,
    input wire [PE_ARRAY_NUM_COLS-1:0]  OPND2_IS_VALID_in,
    
    // Data input
    input wire [OPND1_SRAM_BWIDTH-1:0]  OPND1_DATA_in,
    input wire [OPND2_SRAM_BWIDTH-1:0]  OPND2_DATA_in,

    // Data output
    output wire [OUT_SRAM_BWIDTH-1:0]   OUT_DATA_out
);

// Note: for each port, make one more chunk of wires (just for instantiation)
wire [OPND1_SRAM_BWIDTH-1:0]    opnd1_data      [0:PE_ARRAY_NUM_COLS];
wire [PE_ARRAY_NUM_ROWS-1:0]    opnd1_is_valid  [0:PE_ARRAY_NUM_COLS];
wire [OPND2_SRAM_BWIDTH-1:0]    opnd2_data      [0:PE_ARRAY_NUM_ROWS];
wire [PE_ARRAY_NUM_COLS-1:0]    opnd2_is_valid  [0:PE_ARRAY_NUM_ROWS];
wire [OUT_SRAM_BWIDTH-1:0]      out_data        [0:PE_ARRAY_NUM_ROWS];

assign out_data[0] = 0;

genvar row_id, col_id;
generate
    for (row_id = 0; row_id < PE_ARRAY_NUM_ROWS; row_id = row_id + 1) 
    begin: gen_pe_row
        for (col_id = 0; col_id < PE_ARRAY_NUM_COLS; col_id = col_id + 1) 
        begin: gen_pe_col
            PE # (
                .OPND_BWIDTH    (OPND_BWIDTH),
                .ACC_BWIDTH     (ACC_BWIDTH)
            ) pe (
                .RSTn           (RSTn),
                .CLK            (CLK),
                .STALL          (STALL),
                .COMPUTE        (IS_COMPUTING_in),
                .FLUSH          (IS_FLUSHING_in),

                .OPND1_is_valid_in  (opnd1_is_valid[col_id][row_id]),
                .OPND2_is_valid_in  (opnd2_is_valid[row_id][col_id]),

                .OPND1_in       (opnd1_data[col_id][((row_id + 1) << OPND_BWIDTH_LOG2)-1:(row_id << OPND_BWIDTH_LOG2)]),
                .OPND2_in       (opnd2_data[row_id][((col_id + 1) << OPND_BWIDTH_LOG2)-1:(col_id << OPND_BWIDTH_LOG2)]),
                .ACC_in         (out_data[row_id][((col_id + 1) << ACC_BWIDTH_LOG2)-1:(col_id << ACC_BWIDTH_LOG2)]),

                .OPND1_is_valid_out (opnd1_is_valid[col_id + 1][row_id]),
                .OPND2_is_valid_out (opnd2_is_valid[row_id + 1][col_id]),

                .OPND1_out      (opnd1_data[col_id+1][((row_id + 1) << OPND_BWIDTH_LOG2)-1:(row_id << OPND_BWIDTH_LOG2)]),
                .OPND2_out      (opnd2_data[row_id+1][((col_id + 1) << OPND_BWIDTH_LOG2)-1:(col_id << OPND_BWIDTH_LOG2)]),
                .ACC_out        (out_data[row_id+1][((col_id + 1) << ACC_BWIDTH_LOG2)-1:(col_id << ACC_BWIDTH_LOG2)])
            );
        end
    end
endgenerate

// Input, output ports assignments
// Inputs
assign opnd1_data[0]        = OPND1_DATA_in;
assign opnd2_data[0]        = OPND2_DATA_in;
assign opnd1_is_valid[0]    = OPND1_IS_VALID_in;
assign opnd2_is_valid[0]    = OPND2_IS_VALID_in;

// Outputs
assign OUT_DATA_out = out_data[PE_ARRAY_NUM_ROWS];

endmodule