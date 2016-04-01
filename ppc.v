`define F 0
`define D 1
`define X 2
//`define M 3
`define WB 3

module main();

    initial begin
        $dumpfile("ppc.vcd");
        $dumpvars(0,main);
    end

    wire clk;
    wire halt = isSc & (regReadData0 == 1) & (state == `WB);

    clock clock0(halt,clk);

    /********************/
    /* Memory interface */
    /********************/

    //Used to be M
    wire memReadEn0 = (state == `X) & allLd;
    wire [0:60]memReadAddr0 = ea[0:60];
    wire [0:63]memReadData0;
    wire memReadEn1 = state == `F;
    wire [0:60]memReadAddr1 = pc[0:60];
    wire [0:63]memReadData1;

    mem mem0(clk,
        memReadEn0,memReadAddr0,memReadData0,
        memReadEn1,memReadAddr1,memReadData1);

    /********/
    /* regs */
    /********/

    wire regReadEn0 = (state == `D) & (allAdd | allOr | isAddi | allLd | isSc);
    wire [0:4]regReadAddr0 = isSc ? 0 : (allOr ? rs : ra);
    wire [0:63]regReadData0;

    wire regReadEn1 = (state == `D) & (allAdd | allOr | isSc);
    wire [0:4]regReadAddr1 = isSc ? 3 : rb;
    wire [0:63]regReadData1;


    wire regWriteEn0 = (state == `WB) & (allAdd | allOr | isAddi | allLd);
    wire [0:4]regWriteAddr0 = allOr ? ra : rt;
    wire [0:63]regWriteData0 = allAdd ? (va + vb) : allOr ? ((rb == 0) ? vs : (vs | vb)) : isAddi ? (va0 + imm) : allLd ? memReadData0 : 0;

    wire regWriteEn1 = (state == `WB) & isLdu;
    wire [0:4]regWriteAddr1 = ra;
    wire [0:63]regWriteData1 = ea;

    regs gprs(clk,
       /* Read port #0 */
       regReadEn0,
       regReadAddr0, 
       regReadData0,

       /* Read port #1 */
       regReadEn1,
       regReadAddr1, 
       regReadData1,

       /* Write port #0 */
       regWriteEn0,
       regWriteAddr0, 
       regWriteData0,

       /* Write port #1 */
       regWriteEn1,
       regWriteAddr1, 
       regWriteData1
    );

    /**********/
    /* Values */
    /**********/

    wire [0:63]va = regReadData0;
    wire [0:63]vb = regReadData1;
    wire [0:63]vs = regReadData0;
    wire [0:63]va0 = (ra == 0) ? 0 : va;
    wire [0:7]print0 = regReadData1;
    wire [0:63]print2 = regReadData1;

    //Branching
    
    wire isBranching = allB | ((allBc | allBclr) & ctr_ok & cond_ok);
    wire ctr_ok = bo[2] | ((ctr1 != 0) ^ bo[3]);
    wire cond_ok = bo[0] | (cr[bi] == bo[1]);
    wire [0:63]branchTarget = allB ? (inst[30] ? li : (pc + li)) : (allBc ? (inst[30] ? bd : (pc + bd)) : extendLR);

    //Special Purpose Registers

    reg [0:63]ctr = 0;
    wire [0:63]ctr1 = ctr - 1;
    reg [0:63]lr = 0;
    reg [0:31]cr = 0;
    reg xer = 0;

    /******/
    /* PC */
    /******/

    reg [0:63]pc = 0;

    /*********/
    /* State */
    /*********/

    reg [0:2]state = `F;

    wire isLess = regWriteData0[0];
    wire isGreater = ~regWriteData0[0] & regWriteData0 != 0;
    wire isEqual = regWriteData0 == 0;
    wire isOver = (isLess & (~regReadAddr0[0] & ~regReadAddr1[0])) | (isGreater & (regReadAddr0[0] & regReadAddr1[0]));

    always @(posedge clk) begin
        if (state == `WB) begin
            state <= `F;
            pc <= nextPC;
            if ((allBc | allBclr) & ~bo[2]) begin
                ctr <= ctr1;
            end
            if ((allB | allBc | allBclr) & inst[31]) begin
                lr <= pc + 4;
            end
            if (isSc) begin
                if (regReadData0 == 0) begin
                    $display("%c", print0);
                end else if (regReadData0 == 2) begin
                    $display("%h", print2);
                end
            end
            //Update cr
            if ((allAdd | allOr) & inst[31]) begin
                cr[0] <= isLess;
                cr[1] <= isGreater;
                cr[2] <= isEqual;
                cr[3] <= (allAdd & inst[21]) ? (isOver | xer) : xer;
            end
            //Update xer
            if (allAdd & inst[21]) begin
                xer <= isOver | xer;
            end
            //$display("%s%d", "res:", regWriteData0);
            //$display("%s%d", "cr[1]:", cr[1]);
            /*if (allAdd) begin
                $display(li);
            end*/
        end else begin
            state <= state + 1;
        end
    end

    /**********/
    /* Decode */
    /**********/

    //Instruction Components
    wire [0:31]inst = pc[61] ? memReadData1[32:63] : memReadData1[0:31];
    wire [0:5]op = inst[0:5];
    wire [0:8]xop9 = inst[22:30];
    wire [0:9]xop10 = inst[21:30];
    wire [0:4]rs = inst[6:10];
    wire [0:4]rt = inst[6:10];
    wire [0:4]ra = inst[11:15];
    wire [0:4]rb = inst[16:20];
    wire [0:63]imm = {{48{inst[16]}}, inst[16:31]};
    wire [0:63]li = {{{38{inst[6]}}, inst[6:29]}, 2'b00};
    wire [0:4]bo = inst[6:10];
    wire [0:4]bi = inst[11:15];
    wire [0:63]bd = {{{48{inst[16]}}, inst[16:29]}, 2'b00};
    wire [0:63]ds = {{{48{inst[16]}}, inst[16:29]}, 2'b00};
    wire [0:63]extendLR = {lr[0:61], 2'b00};

    //Instructions
    wire isAdd = (op == 31) & (xop9 == 266) & ~inst[21] & ~inst[31] ;
    wire isAddDot = (op == 31) & (xop9 == 266) & ~inst[21] & inst[31];
    wire isAddO = (op == 31) & (xop9 == 266) & inst[21] & ~inst[31];
    wire isAddODot = (op == 31) & (xop9 == 266) & inst[21] & inst[31];
    wire isOr = (op == 31) & (xop10 == 444) & ~inst[31];
    wire isOrDot = (op == 31) & (xop10 == 444) & inst[31];
    wire isAddi = op == 14;
    wire isB = (op == 18) & ~inst[30] & ~inst[31];
    wire isBa = (op == 18) & inst[30] & ~inst[31];
    wire isBl = (op == 18) & ~inst[30] & inst[31];
    wire isBla = (op == 18) & inst[30] & inst[31];
    wire isBc = (op == 16) & ~inst[30] & ~inst[31];
    wire isBca = (op == 16) & inst[30] & ~inst[31];
    wire isBcl = (op == 16) & ~inst[30] & inst[31];
    wire isBcla = (op == 16) & inst[30] & inst[31];
    wire isBclr = (op == 19) & (xop10 == 16) & ~inst[31];
    wire isBclrl = (op == 19) & (xop10 == 16) & inst[31];
    wire isLd = (op == 58) & (inst[30:31] == 0);
    wire isLdu = (op == 58) & (inst[30:31] == 1) & (ra != 0) & (ra != rt);
    wire isSc = (op == 17) & (inst[20:26] == 0) & (inst[30] == 1);

    //Combined Instructions
    wire allAdd = isAdd | isAddDot | isAddO | isAddODot;
    wire allOr = isOr | isOrDot;
    wire allB = isB | isBa | isBl | isBla;
    wire allBc = isBc | isBca | isBcl | isBcla;
    wire allBclr = isBclr | isBclrl;
    wire allLd = isLd | isLdu;

    /***********/
    /* Execute */
    /***********/

    wire [0:63]nextPC = isBranching ? branchTarget : (pc + 4);
    wire [0:63]ea = va0 + ds;

endmodule
