`timescale 1ns/10ps
//----------------------------------------------------------------------//
module FIFO #(
    parameter   DEPTH       = 32,   // For 32-by-32 PE arrays
    parameter   DEPTH_LOG2  = 5,    // log_2(32) == 5
    parameter   BWIDTH      = 8     // INT8 operands
) 
(
    // Control inputs
    input wire  RSTn,   // Reset 
    input wire  CLK,    // Clock
    input wire  PUSHE,  // Push enable
    input wire  POPE,   // Pop enable

    // Data inputs
    input wire [BWIDTH-1:0] D_in,       // Data that are being pushed

    // Control outputs
    output wire IS_EMPTY,
    output wire IS_FULL,

    // Data outputs
    output wire [BWIDTH-1:0]    D_out   // Data that are being popped
);

// Status registers (currently, max depth of FIFO is set to 31)
reg [DEPTH_LOG2-1:0]    front;
reg [DEPTH_LOG2-1:0]    rear;

// Data register
reg [BWIDTH-1:0]    data [0:DEPTH-1];

// Combinational logic for the next front/rear
wire [DEPTH_LOG2-1:0]   rear_pushed;
wire [DEPTH_LOG2-1:0]   front_popped;
assign rear_pushed  = rear + 1;
assign front_popped = front + 1;

// Combinational output logic
assign IS_EMPTY = (front == rear)? 1 : 0;
assign IS_FULL  = (front == (rear+1))? 1 : 0;
assign D_out    = data[front];

// Sequential logic: push/pop data if the control signals are asserted
always @ (posedge CLK, negedge RSTn) begin
    // Reset status: make it empty
    if (~RSTn) begin
        front   <= 0;
        rear    <= 0;
    end
    else begin
        // Push if required
        if (PUSHE & ((~IS_FULL | (IS_FULL & POPE)))) begin
            rear        <= rear_pushed;
            data[rear]  <= D_in;
        end
        // Pop if required
        if (POPE & ~IS_EMPTY) begin
            front       <= front_popped;
        end
    end
end

endmodule
//----------------------------------------------------------------------//