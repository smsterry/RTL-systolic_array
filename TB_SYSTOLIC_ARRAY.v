`timescale 1ns/10ps
`define test_M 16
`define test_MAX_M_SIZE_LOG2 9
`define test_K 16
`define test_MAX_K_SIZE_LOG2 9
`define test_N 16
`define test_MAX_N_SIZE_LOG2 9

//----------------------------------------------------------------------//
module TB_SYSTOLIC_ARRAY();

// General signals
wire CLK;
wire RSTn;

// Matrix config
reg [`test_MAX_M_SIZE_LOG2-1:0] m_size;
reg [`test_MAX_K_SIZE_LOG2-1:0] k_size;
reg [`test_MAX_N_SIZE_LOG2-1:0] n_size;

// For the simulation
reg start;
wire is_finished;
reg [31:0] num_cycles;

// Module instantiation
// Clock and reset
CLKRST clkrst (
    .CLK    (CLK),
    .RSTn   (RSTn)
);

// DUT
SYSTOLIC_ARRAY #(
    .OPND_BWIDTH            (8),   
    .OPND_BWIDTH_LOG2       (3),  
    .ACC_BWIDTH             (32),   
    .ACC_BWIDTH_LOG2        (5), 
    .OPND1_SRAM_AWIDTH      (10),
    .OPND1_SRAM_BWIDTH      (4*8),
    .OPND2_SRAM_AWIDTH      (10),
    .OPND2_SRAM_BWIDTH      (4*8),
    .OUT_SRAM_AWIDTH        (10),
    .OUT_SRAM_BWIDTH        (4*32),
    .PE_ARRAY_NUM_ROWS      (4),
    .PE_ARRAY_NUM_ROWS_LOG2 (2),
    .PE_ARRAY_NUM_COLS      (4),
    .PE_ARRAY_NUM_COLS_LOG2 (2),
    .MAX_M_SIZE_LOG2        (9), 
    .MAX_K_SIZE_LOG2        (9), 
    .MAX_N_SIZE_LOG2        (9), 

    .OPND1_ROMDATA          ("C:/Users/Owner/matrix1.hex"),
    .OPND2_ROMDATA          ("C:/Users/Owner/matrix2.hex"),
    .OUT_WRITEDATA          ("C:/Users/Owner/answer.hex")
) dut_systolic_array (
    .RSTn               (RSTn),
    .CLK                (CLK),
    .START              (start),
    .STALL              (1'b0),

    .M_SIZE_in          (m_size),
    .K_SIZE_in          (k_size),
    .N_SIZE_in          (n_size),

    .IS_FINISHED_out    (is_finished)
);


initial begin
    num_cycles <= 0;
    #200    m_size <= `test_M;
            k_size <= `test_N;
            n_size <= `test_K;
            start  <= 1'b1;
    #10000  $finish();
end

always @ (posedge CLK) begin
    if (RSTn) begin
        if (is_finished) begin
            $display("[Sim] %d cycles taken", num_cycles);
        end
        num_cycles <= num_cycles + 1;
    end
end

endmodule
//----------------------------------------------------------------------//