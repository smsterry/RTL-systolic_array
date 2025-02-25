`timescale 1ns/10ps
module SRAM #(
    parameter ROMDATA       = "", 
    parameter WRITEDATA     = "",
    parameter BWIDTH        = 256,  // Bits per row
    parameter AWIDTH        = 10,   // Address width (Row-address)
    parameter NUM_ROWS      = 1024  // # rows
) 
(
    input wire              CLK,
    input wire              CSn,            // chip select negative
    input wire [AWIDTH-1:0] ADDR,
    input wire              WEn,            // write enable negative
    input wire [BWIDTH-1:0] BE,             // bit enable
    input wire [BWIDTH-1:0] D_in,           // data in

    input wire              IS_FINISHED_in, // to verify

    output wire [BWIDTH-1:0]    D_out       // data out
);

reg [BWIDTH-1:0]    outline;
reg [BWIDTH-1:0]    rows[0 : NUM_ROWS-1];

wire [BWIDTH-1:0]   data_masked;
assign data_masked = (rows[ADDR] & ~BE) | (D_in & BE);

initial begin
    if (ROMDATA != "")
        $readmemh(ROMDATA, rows);
    if (WRITEDATA != "")
        #10000 $writememh(WRITEDATA, rows);
end

assign #1 D_out = outline;

always @ (posedge CLK) begin
    // Synchronous read/write
    if (~CSn) begin
        if (~WEn) begin
            rows[ADDR]  <= data_masked;
        end
        else begin
            outline     <= rows[ADDR];
        end
    end

    // Only in the simulation
    //if (IS_FINISHED_in) begin
    //    if (WRITEDATA != "")
    //        $writememh(WRITEDATA, rows);
    //end
end

endmodule
