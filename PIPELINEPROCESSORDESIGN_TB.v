// Testbench for 4-stage pipelined processor
module tb_PipelinedProcessor;

reg clk;     // Clock signal
reg reset;   // Reset signal

// Instantiate the PipelinedProcessor module (DUT - Device Under Test)
PipelinedProcessor uut (
    .clk(clk),
    .reset(reset)
);

// Clock generation: toggles every 5 time units (10 time unit period)
always #5 clk = ~clk;

// === First initial block: Set register values and data memory ===
initial begin
    clk = 0;            // Initialize clock to 0
    reset = 1;          // Assert reset
    #10 reset = 0;      // Deassert reset after 10 time units

    // === Register Initialization ===
    // regfile[2] = 10, regfile[3] = 5 ? used for ADD
    // regfile[5] = 20, regfile[6] = 7 ? used for SUB
    // regfile[4] = 4 ? address for LOAD
    uut.regfile[2] = 8'd10;
    uut.regfile[3] = 8'd5;
    uut.regfile[5] = 8'd20;
    uut.regfile[6] = 8'd7;
    uut.regfile[4] = 4;

    // === Data Memory Initialization ===
    // Memory at address 4 has data = 99 (for LOAD)
    uut.data_mem[4] = 8'd99;

    // Wait for simulation to observe pipeline behavior
    #100 $finish;   // End simulation after 100 time units
end

// === Second initial block: Load instructions into instruction memory ===
initial begin
    // Format: [opcode][rd][rs1][rs2]
    // ADD R1 = R2 + R3 ? opcode=0001, rd=001, rs1=010, rs2=011
    uut.instr_mem[0] = 16'b0001_001_010_011_000;

    // SUB R4 = R5 - R6 ? opcode=0010, rd=100, rs1=101, rs2=110
    uut.instr_mem[1] = 16'b0010_100_101_110_000;

    // AND R0 = R1 & R2 ? opcode=0011, rd=000, rs1=001, rs2=010
    uut.instr_mem[2] = 16'b0011_000_001_010_000;

    // LOAD R3 = MEM[R4] ? opcode=0100, rd=011, rs1=100, rs2=000
    uut.instr_mem[3] = 16'b0100_011_100_000_000;
end

endmodule