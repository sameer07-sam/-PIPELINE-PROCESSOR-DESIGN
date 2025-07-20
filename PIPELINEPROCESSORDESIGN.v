// Simple 4-stage pipelined processor in Verilog
module PipelinedProcessor (
    input clk,               // Clock signal
    input reset              // Reset signal
);

// ==== Instruction Memory: 16 instructions max (8-bit each) ====
reg [15:0] instr_mem [0:15];

// ==== Data Memory ====
reg [7:0] data_mem [0:15];

// ==== Register File: 8 registers (R0 to R7) ====
reg [7:0] regfile [0:7];

// ==== Pipeline Registers ====
reg [15:0] IF_ID;        // Between Fetch and Decode
reg [15:0] ID_EX;        // Between Decode and Execute
reg [7:0]  EX_MEM_result; // Result from EX to MEM
reg [2:0]  EX_MEM_rd;     // Destination register
reg        EX_MEM_mem_read; // Load flag
reg        EX_MEM_reg_write; // Register write flag

reg [7:0]  MEM_WB_result; // Final output to write
reg [2:0]  MEM_WB_rd;     // Destination reg
reg        MEM_WB_reg_write;

// ==== Program Counter ====
reg [3:0] PC;

// ==== Instruction Fields ====
wire [3:0] opcode = IF_ID[15:12];   // 4-bit opcode
wire [2:0] rd     = IF_ID[11:9];    // destination register
wire [2:0] rs1    = IF_ID[8:6];     // source register 1
wire [2:0] rs2    = IF_ID[5:3];     // source register 2 / base for LOAD

// ==== Stage 1: Instruction Fetch ====
always @(posedge clk or posedge reset) begin
    if (reset) begin
        PC <= 0;
        IF_ID <= 0;
    end else begin
        IF_ID <= instr_mem[PC];  // Fetch instruction from memory
        PC <= PC + 1;            // Increment PC
    end
end

// ==== Stage 2: Instruction Decode ====
reg [7:0] reg_rs1, reg_rs2;
always @(posedge clk) begin
    reg_rs1 <= regfile[rs1]; // Read reg source 1
    reg_rs2 <= regfile[rs2]; // Read reg source 2
    ID_EX <= IF_ID;          // Pass instruction to next stage
end

// ==== Stage 3: Execute ====
reg [7:0] alu_result;
always @(posedge clk) begin
    case (ID_EX[15:12])
        4'b0001: alu_result <= reg_rs1 + reg_rs2; // ADD
        4'b0010: alu_result <= reg_rs1 - reg_rs2; // SUB
        4'b0011: alu_result <= reg_rs1 & reg_rs2; // AND
        4'b0100: alu_result <= data_mem[reg_rs1]; // LOAD
        default: alu_result <= 8'b00000000;
    endcase

    // Pass to EX/MEM stage
    EX_MEM_result <= alu_result;
    EX_MEM_rd <= ID_EX[11:9]; // Destination register
    EX_MEM_mem_read <= (ID_EX[15:12] == 4'b0100); // If LOAD
    EX_MEM_reg_write <= 1;  // Always write for now
end

// ==== Stage 4: Memory / Write Back ====
always @(posedge clk) begin
    if (EX_MEM_mem_read)
        MEM_WB_result <= EX_MEM_result; // From memory
    else
        MEM_WB_result <= EX_MEM_result; // From ALU

    MEM_WB_rd <= EX_MEM_rd;
    MEM_WB_reg_write <= EX_MEM_reg_write;
end

// ==== Write Back to Register File ====
always @(posedge clk) begin
    if (MEM_WB_reg_write)
        regfile[MEM_WB_rd] <= MEM_WB_result; // Final write to register
end

endmodule
