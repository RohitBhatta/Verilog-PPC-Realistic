module regs(
    input clk,

    /* read port 0 */
    input readEn0,
    input [4:0] readAddr0,
    output [63:0] readData0,

    /* read port 1 */
    input readEn1,
    input [4:0] readAddr1,
    output [63:0] readData1,

    /* write port 0 */
    input writeEn0,
    input [4:0] writeAddr0,
    input [63:0] writeData0,

    /* write port 0 */
    input writeEn1,
    input [4:0] writeAddr1,
    input [63:0] writeData1
);

    // memory
    reg [63:0]memory[0:31];
    wire [0:63]gpr0 = memory[0];
    wire [0:63]gpr1 = memory[1];
    wire [0:63]gpr2 = memory[2];
    wire [0:63]gpr3 = memory[3];
    wire [0:63]gpr4 = memory[4];
    wire [0:63]gpr5 = memory[5];
    wire [0:63]gpr6 = memory[6];
    wire [0:63]gpr7 = memory[7];
    wire [0:63]gpr8 = memory[8];
    wire [0:63]gpr9 = memory[9];
    wire [0:63]gpr10 = memory[10];
    wire [0:63]gpr11 = memory[11];
    wire [0:63]gpr12 = memory[12];
    wire [0:63]gpr13 = memory[13];
    wire [0:63]gpr14 = memory[14];
    wire [0:63]gpr15 = memory[15];
    wire [0:63]gpr16 = memory[16];
    wire [0:63]gpr17 = memory[17];
    wire [0:63]gpr18 = memory[18];
    wire [0:63]gpr19 = memory[19];
    wire [0:63]gpr20 = memory[20];
    wire [0:63]gpr21 = memory[21];
    wire [0:63]gpr22 = memory[22];
    wire [0:63]gpr23 = memory[23];
    wire [0:63]gpr24 = memory[24];
    wire [0:63]gpr25 = memory[25];
    wire [0:63]gpr26 = memory[26];
    wire [0:63]gpr27 = memory[27];
    wire [0:63]gpr28 = memory[28];
    wire [0:63]gpr29 = memory[29];
    wire [0:63]gpr30 = memory[30];
    wire [0:63]gpr31 = memory[31];

    initial begin
        $readmemh("regs.bin",memory);
    end

    reg [63:0]d0;
    reg [63:0]d1;

    assign readData0 = d0;
    assign readData1 = d1;

    always @(posedge clk) begin
        if (readEn0) d0 <= memory[readAddr0];
        if (readEn1) d1 <= memory[readAddr1];
        if (writeEn0) memory[writeAddr0] <= writeData0;
        if (writeEn1) memory[writeAddr1] <= writeData1;
    end
    
endmodule
