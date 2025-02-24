`timescale 1ns/10ps
//----------------------------------------------------------------------//
module PE #(
    parameter   OPND_BWIDTH = 8,    // INT8 operands
    parameter   ACC_BWIDTH  = 32    // INT32 partial sums
) 
(
    // Control inputs
    input wire  RSTn,       // Reset 
    input wire  CLK,        // Clock
    input wire  STALL,      // Stall
    input wire  COMPUTE,    // Computing is assigned
    input wire  FLUSH,      // Flushing is assigned

    input wire  OPND1_is_valid_in,  // if 1st input operand is valid or not
    input wire  OPND2_is_valid_in,  // if 2nd input operand is valid or not

    // Data inputs
    input wire signed [OPND_BWIDTH-1:0] OPND1_in,   // 1st operand from another PE
    input wire signed [OPND_BWIDTH-1:0] OPND2_in,   // 2nd operand from another PE
    input wire signed [ACC_BWIDTH-1:0]  ACC_in,     // Accumulated partial sum (for flushing)

    // Control outputs
    output wire OPND1_is_valid_out, // if 1st output operand is valid or not
    output wire OPND2_is_valid_out, // if 2nd output operand is valid or not

    // Data outputs
    output wire signed [OPND_BWIDTH-1:0]    OPND1_out,  // 1st operand to another PE
    output wire signed [OPND_BWIDTH-1:0]    OPND2_out,  // 2nd operand to another PE
    output wire signed [ACC_BWIDTH-1:0]     ACC_out     // Accumulated partial sum (for flushing)
);

// Buffers for the operands and the accumulated partial sum
reg signed [OPND_BWIDTH-1:0]    opnd1_buf;
reg signed [OPND_BWIDTH-1:0]    opnd2_buf;
reg signed [ACC_BWIDTH-1:0]     acc_buf;

// Buffer for checking if each operand is valid or not
reg signed opnd1_is_valid;
reg signed opnd2_is_valid;

// Temporal values for computing MAC
wire signed [ACC_BWIDTH-1:0]    curr_acc;
wire signed [ACC_BWIDTH-1:0]    acc_nxt;
wire signed [ACC_BWIDTH-1:0]    product;

// Combinational computing logic
assign curr_acc = acc_buf;
assign product  = opnd1_buf * opnd2_buf;
assign acc_nxt  = curr_acc + product;

// Combinational output logic: output wires that will be used by other PEs
assign OPND1_is_valid_out   = opnd1_is_valid;
assign OPND2_is_valid_out   = opnd2_is_valid;
assign OPND1_out    = opnd1_buf;
assign OPND2_out    = opnd2_buf;
assign ACC_out      = acc_buf;

// Sequential logic: update operand/accumulation buffers
always @ (posedge CLK, negedge RSTn) begin
    // Reset all buffers
    if (~RSTn) begin
        opnd1_is_valid  <= 0;
        opnd2_is_valid  <= 0;
        opnd1_buf       <= 0;
        opnd2_buf       <= 0;
        acc_buf         <= 0;
    end
    else if (~STALL) begin
        // Compute if corresponding control signals are asserted
        if (COMPUTE & ~FLUSH) begin
            if (opnd1_is_valid & opnd2_is_valid) begin
                opnd1_is_valid  <= OPND1_is_valid_in;
                opnd2_is_valid  <= OPND2_is_valid_in;
                opnd1_buf       <= OPND1_in;
                opnd2_buf       <= OPND2_in;
                acc_buf         <= acc_nxt;
            end
        end
        if (FLUSH & ~COMPUTE) begin
            acc_buf <= ACC_in;
        end
    end
end

endmodule
//----------------------------------------------------------------------//