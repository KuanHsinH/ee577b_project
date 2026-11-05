////////////////////////////////////////////////////////////////////////////
// Cardinal processor - top-level module (EE577B Project Phase 2)
//
// DO NOT CHANGE THE MODULE NAME OR THE PORT LIST BELOW.
// The grading testbench instantiates cardinal_cpu by these exact port names.
// If the module name, a port name, a direction or a width differs, the
// elaboration step (ncelab) stops with an error.
//
// Implement the 4-stage pipeline (IF, ID, EX/MEM, WB) described in the
// Phase 2 handout and the Cardinal Processor ISA manual. You may add any
// number of other modules and files in design/ (register file, ALU,
// decoder, ...); only this interface is fixed.
//
// Memory interface (models in include/, part of the testbench):
//   * Instruction memory: asynchronous. inst_in = IMEM[pc_out[22:29]].
//   * Data memory: synchronous. memEn, memWrEn, addr_out[24:31] and d_out
//     are sampled at a rising clock edge; a store is written at that edge,
//     and load data appears on d_in after that edge (for the next cycle).
////////////////////////////////////////////////////////////////////////////

// First Ver. of branch prediction : keeping BRANCH resolve in ID stage

module cardinal_cpu_bp_v1 #(
    parameter INST_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter REG_ADDR_WIDTH = 5,
    parameter MEM_ADDR_WIDTH = 16
)(
    input         clk,        // rising-edge clock
    input         reset,      // synchronous, active high
    input  [0:31] inst_in,    // instruction from the instruction memory
    input  [0:63] d_in,       // load data from the data memory
    output [0:31] pc_out,     // instruction memory address (byte address)
    output [0:31] addr_out,   // data memory address (64-bit word address)
    output        memEn,      // data memory enable (load or store)
    output        memWrEn,    // data memory write enable (store)
    output [0:63] d_out       // store data to the data memory
);

    // 6 bit function code
    localparam VAND   = 6'b000001,
               VOR    = 6'b000010,
               VXOR   = 6'b000011,
               VNOT   = 6'b000100,
               VMOV   = 6'b000101,
               VADD   = 6'b000110,
               VSUB   = 6'b000111,
               VMULEU = 6'b001000,
               VMULOU = 6'b001001,
               VSLL   = 6'b001010,
               VSRL   = 6'b001011,
               VSRA   = 6'b001100,
               VRTTH  = 6'b001101,
               VDIV   = 6'b001110,
               VMOD   = 6'b001111,
               VSQEU  = 6'b010000,
               VSQOU  = 6'b010001,
               VSQRT  = 6'b010010;
    
    // 6 bit opcode
    localparam R_ALU  = 6'b101010,
               M_LD   = 6'b100000,
               M_SD   = 6'b100001,
               R_BEZ  = 6'b100010,
               R_BNEZ = 6'b100011,
               VNOP   = 6'b111100;

    // 3 bit participation
    localparam participate_A = 3'b000,
               participate_U = 3'b001,
               participate_D = 3'b010,
               participate_E = 3'b011,
               participate_O = 3'b100;

    // Stall and branch signals
    wire stall;
    reg br_taken;
    wire [0:INST_WIDTH-1] br_addr;
    wire [0:15] imm_addr_ID;

    // EX results are also used by the forwarding logic in ID.
    wire [0:REG_ADDR_WIDTH-1] rD_addr_EX;
    wire                      rf_we_EX;
    wire [0:7]                rf_wrByteEn_EX;
    wire [0:DATA_WIDTH-1]     rf_wrData_EX;
    reg  [0:DATA_WIDTH-1]     forward_MUX_d0_ID, forward_MUX_d1_ID;

    assign br_addr = {16'b0, imm_addr_ID};
    assign stall = 1'b0; // No multi-cycle stall condition has been added yet.

    //--------------------------------------------------------------------------

    // IF stage
    reg [0:INST_WIDTH-1] pc;  

    // save the pc of the branch for recovering in case of misprediction
    reg [0:INST_WIDTH-1] IF_ID_pc; 

    reg IF_ID_pred_taken;
    wire mispredict_ID, br_pred_out;
    wire is_branch_IF = (inst_in[0:5] == R_BEZ) || (inst_in[0:5] == R_BNEZ);
    wire pred_taken_IF = is_branch_IF && br_pred_out;

    // if predict TAKEN, directly take the imm_addr to be the next pc
    // if the instruction is not a branch, is_branch is 0, prediction will not be made
    wire [0:INST_WIDTH-1] pred_next_pc_IF = pred_taken_IF ?
        {16'b0, inst_in[16:31]} : pc + 32'd4;

    // when prediction TAKEN is wrong, it recovers with IF_ID_pc + 4 
    // when prediction NOT TAKEN is wrong, it recovers with br_addr ({16'b0, imm_addr_ID})
    wire [0:INST_WIDTH-1] recovery_pc_ID = br_taken ? br_addr : IF_ID_pc + 32'd4;

    assign pc_out = pc;

    always @(posedge clk) begin
        if(reset) pc <= 0;
        else if(mispredict_ID) pc <= recovery_pc_ID; // after misprediction, recover to br_addr(if predict NOT TAKEN) or pc+4(if predict TAKEN)
        else if(stall) pc <= pc;
        else pc <= pred_next_pc_IF;
    end

    // IF/ID reg
    reg [0:INST_WIDTH-1] IF_ID_reg; // only the instruction
    always @(posedge clk) begin
        if(reset) IF_ID_reg <= 'd0;
        else if(mispredict_ID) IF_ID_reg <= {VNOP, 26'b0};  // Flush if mispredicted
        else if(stall) IF_ID_reg <= IF_ID_reg;  
        else IF_ID_reg <= inst_in;
    end

    // move the pc to ID stage for recovering and updating BPB
    always @(posedge clk) begin
        if (reset)              IF_ID_pc <= 0;
        else if (mispredict_ID) IF_ID_pc <= 0;
        else if (stall)         IF_ID_pc <= IF_ID_pc;
        else                    IF_ID_pc <= pc;
    end

    // move prediction result to ID stage for updating BPB
    always @(posedge clk) begin
        if (reset)              IF_ID_pred_taken <= 1'b0;
        else if (mispredict_ID) IF_ID_pred_taken <= 1'b0;
        else if (stall)         IF_ID_pred_taken <= IF_ID_pred_taken;
        else                    IF_ID_pred_taken <= pred_taken_IF;
    end

    //--------------------------------------------------------------------------

    // ID stage
    wire                      rf_we_ID;
    wire [0:7]                rf_wrByteEn_ID;
    wire [0:REG_ADDR_WIDTH-1] rA_addr_ID, rB_addr_ID, rD_addr_ID;
    
    wire        mem_en_ID, mem_we_ID;

    wire [0:1]  WW_ID;
    wire [0:2]  PPP_ID;
    wire [0:5]  function_code_ID;
    wire [0:5]  op_type_ID;
    wire        is_branch_ID;
    wire [0:7]  index_update_pred_ID = IF_ID_pc[22:29];
    
    decoder dc1(
        .inst_in(IF_ID_reg),

        .rf_we(rf_we_ID),
        .rA_addr(rA_addr_ID),
        .rB_addr(rB_addr_ID),
        .rD_addr(rD_addr_ID),
        .rf_wrByteEn(rf_wrByteEn_ID),

        .mem_en(mem_en_ID),
        .mem_we(mem_we_ID),

        .WW(WW_ID),
        .PPP(PPP_ID),
        .function_code(function_code_ID),
        .imm_Addr(imm_addr_ID),
        .op_type(op_type_ID),
        .is_branch(is_branch_ID)
    );

    BPB br_pred1(
        .clk(clk),
        .reset(reset),
        .is_branch(is_branch_ID && !stall),
        .index_get_pred(pc[22:29]), // use 8 bits as index to get branch prediction
        .index_update_pred(index_update_pred_ID),
        .br_result(br_taken),
        .pred_out(br_pred_out)
    );

    // come from WB
    wire rf_wrEn_WB;
    wire [0:7] rf_wrByteEn_WB;
    wire [0:REG_ADDR_WIDTH-1] rf_wrAddr_WB;
    wire [0:DATA_WIDTH-1]     rf_wrData_WB;

    // come from ID
    wire [0:REG_ADDR_WIDTH-1] rf_rdAddr0, rf_rdAddr1;
    wire [0:DATA_WIDTH-1]     rf_rdData0, rf_rdData1;

    assign rf_rdAddr1 = rB_addr_ID;
    assign rf_rdAddr0 = ((op_type_ID == M_SD) || (op_type_ID == R_BEZ) || (op_type_ID == R_BNEZ))
                        ? rD_addr_ID : rA_addr_ID;

    register_file rf1(
        .clk(clk),     
        .reset(reset),   

        .wrEn(rf_wrEn_WB),
        .wrAddr(rf_wrAddr_WB),
        .wrData(rf_wrData_WB),
        .wrByteEn(rf_wrByteEn_WB),

        .rdAddr0(rf_rdAddr0), 
        .rdAddr1(rf_rdAddr1),

        .rdData0(rf_rdData0),  
        .rdData1(rf_rdData1)  
    );

    // Match each ID source against the two older instructions that may write it.
    wire hazard_EX_d0 = rf_we_EX && (rD_addr_EX != 5'd0) &&
                        (rD_addr_EX == rf_rdAddr0);
    wire hazard_EX_d1 = rf_we_EX && (rD_addr_EX != 5'd0) &&
                        (rD_addr_EX == rf_rdAddr1);
    wire hazard_WB_d0 = rf_wrEn_WB && (rf_wrAddr_WB != 5'd0) &&
                        (rf_wrAddr_WB == rf_rdAddr0);
    wire hazard_WB_d1 = rf_wrEn_WB && (rf_wrAddr_WB != 5'd0) &&
                        (rf_wrAddr_WB == rf_rdAddr1);



    // assigning mem_addr and mem_en
    assign memEn = mem_en_ID;
    assign memWrEn = mem_we_ID;
    assign addr_out = {16'b0, imm_addr_ID};
    assign d_out = forward_MUX_d0_ID;
    
    // branch
    always @(*) begin
        if(((op_type_ID == R_BEZ) && (forward_MUX_d0_ID == 0))
        || ((op_type_ID == R_BNEZ) && (forward_MUX_d0_ID != 0))) begin
             br_taken = 1'b1;
        end
        else br_taken = 1'b0;
    end

    assign mispredict_ID = is_branch_ID && !stall &&
                           (br_taken != IF_ID_pred_taken); // used to update the BPB

    // ID/EX reg
    reg [0:176] ID_EX_reg;
    always @(posedge clk) begin
        if(reset) begin
            ID_EX_reg <= 0;
        end
        else begin
            if(stall) begin
                ID_EX_reg <= ID_EX_reg;
            end
            else begin
                ID_EX_reg[0:63] <= forward_MUX_d0_ID;
                ID_EX_reg[64:127] <= forward_MUX_d1_ID;
                ID_EX_reg[128:132] <= rD_addr_ID;
                ID_EX_reg[133] <= rf_we_ID;
                ID_EX_reg[134:141] <= rf_wrByteEn_ID;

                ID_EX_reg[142:144] <= PPP_ID;
                ID_EX_reg[145:146] <= WW_ID;
                ID_EX_reg[147:152] <= function_code_ID;
                ID_EX_reg[153:168] <= imm_addr_ID;
                ID_EX_reg[169:174] <= op_type_ID;

                ID_EX_reg[175] <= mem_en_ID;
                ID_EX_reg[176] <= mem_we_ID;
            end
        end
    end

    //----------------------------------------------------------------------

    // EX stage
    wire [0:DATA_WIDTH-1]     rA_EX            = ID_EX_reg[0:63];
    wire [0:DATA_WIDTH-1]     rB_EX            = ID_EX_reg[64:127];
    assign rD_addr_EX = ID_EX_reg[128:132];
    assign rf_we_EX = ID_EX_reg[133];
    assign rf_wrByteEn_EX = ID_EX_reg[134:141];

    wire [0:2]                PPP_EX           = ID_EX_reg[142:144]; // delete
    wire [0:1]                WW_EX            = ID_EX_reg[145:146];

    wire [0:5]                function_code_EX = ID_EX_reg[147:152];
    wire [0:15]               imm_addr_EX      = ID_EX_reg[153:168];
    wire [0:5]                op_type_EX       = ID_EX_reg[169:174]; // delete
    wire                      mem_en_EX        = ID_EX_reg[175];
    wire                      mem_we_EX        = ID_EX_reg[176];

    wire [0:DATA_WIDTH-1] ALU_out;

    ALU arithmetic1(
        .rA(rA_EX),
        .rB(rB_EX),
        .function_code(function_code_EX),
        .WW(WW_EX),
        .out(ALU_out)
    );

    // LD and R_ALU
    assign rf_wrData_EX = mem_en_EX ? d_in : ALU_out;

    // EX/WB reg
    reg [0:77] EX_WB_reg;
    always @(posedge clk) begin
        if(reset) begin
            EX_WB_reg <= 0;
        end
        else begin
            EX_WB_reg[0:63] <= rf_wrData_EX;
            EX_WB_reg[64:68] <= rD_addr_EX;
            EX_WB_reg[69] <= rf_we_EX;
            EX_WB_reg[70:77] <= rf_wrByteEn_EX;
        end
    end

    // Merge selected bytes from WB, then the newer EX result, into ID operands.
    always @(*) begin
        forward_MUX_d0_ID = rf_rdData0;
        forward_MUX_d1_ID = rf_rdData1;

        // WB to ID, read port 0
        if(hazard_WB_d0 && rf_wrByteEn_WB[0]) forward_MUX_d0_ID[0:7]   = rf_wrData_WB[0:7];
        if(hazard_WB_d0 && rf_wrByteEn_WB[1]) forward_MUX_d0_ID[8:15]  = rf_wrData_WB[8:15];
        if(hazard_WB_d0 && rf_wrByteEn_WB[2]) forward_MUX_d0_ID[16:23] = rf_wrData_WB[16:23];
        if(hazard_WB_d0 && rf_wrByteEn_WB[3]) forward_MUX_d0_ID[24:31] = rf_wrData_WB[24:31];
        if(hazard_WB_d0 && rf_wrByteEn_WB[4]) forward_MUX_d0_ID[32:39] = rf_wrData_WB[32:39];
        if(hazard_WB_d0 && rf_wrByteEn_WB[5]) forward_MUX_d0_ID[40:47] = rf_wrData_WB[40:47];
        if(hazard_WB_d0 && rf_wrByteEn_WB[6]) forward_MUX_d0_ID[48:55] = rf_wrData_WB[48:55];
        if(hazard_WB_d0 && rf_wrByteEn_WB[7]) forward_MUX_d0_ID[56:63] = rf_wrData_WB[56:63];

        // WB to ID, read port 1
        if(hazard_WB_d1 && rf_wrByteEn_WB[0]) forward_MUX_d1_ID[0:7]   = rf_wrData_WB[0:7];
        if(hazard_WB_d1 && rf_wrByteEn_WB[1]) forward_MUX_d1_ID[8:15]  = rf_wrData_WB[8:15];
        if(hazard_WB_d1 && rf_wrByteEn_WB[2]) forward_MUX_d1_ID[16:23] = rf_wrData_WB[16:23];
        if(hazard_WB_d1 && rf_wrByteEn_WB[3]) forward_MUX_d1_ID[24:31] = rf_wrData_WB[24:31];
        if(hazard_WB_d1 && rf_wrByteEn_WB[4]) forward_MUX_d1_ID[32:39] = rf_wrData_WB[32:39];
        if(hazard_WB_d1 && rf_wrByteEn_WB[5]) forward_MUX_d1_ID[40:47] = rf_wrData_WB[40:47];
        if(hazard_WB_d1 && rf_wrByteEn_WB[6]) forward_MUX_d1_ID[48:55] = rf_wrData_WB[48:55];
        if(hazard_WB_d1 && rf_wrByteEn_WB[7]) forward_MUX_d1_ID[56:63] = rf_wrData_WB[56:63];

        // EX to ID, read port 0 (newer than WB)
        if(hazard_EX_d0 && rf_wrByteEn_EX[0]) forward_MUX_d0_ID[0:7]   = rf_wrData_EX[0:7];
        if(hazard_EX_d0 && rf_wrByteEn_EX[1]) forward_MUX_d0_ID[8:15]  = rf_wrData_EX[8:15];
        if(hazard_EX_d0 && rf_wrByteEn_EX[2]) forward_MUX_d0_ID[16:23] = rf_wrData_EX[16:23];
        if(hazard_EX_d0 && rf_wrByteEn_EX[3]) forward_MUX_d0_ID[24:31] = rf_wrData_EX[24:31];
        if(hazard_EX_d0 && rf_wrByteEn_EX[4]) forward_MUX_d0_ID[32:39] = rf_wrData_EX[32:39];
        if(hazard_EX_d0 && rf_wrByteEn_EX[5]) forward_MUX_d0_ID[40:47] = rf_wrData_EX[40:47];
        if(hazard_EX_d0 && rf_wrByteEn_EX[6]) forward_MUX_d0_ID[48:55] = rf_wrData_EX[48:55];
        if(hazard_EX_d0 && rf_wrByteEn_EX[7]) forward_MUX_d0_ID[56:63] = rf_wrData_EX[56:63];

        // EX to ID, read port 1 (newer than WB)
        if(hazard_EX_d1 && rf_wrByteEn_EX[0]) forward_MUX_d1_ID[0:7]   = rf_wrData_EX[0:7];
        if(hazard_EX_d1 && rf_wrByteEn_EX[1]) forward_MUX_d1_ID[8:15]  = rf_wrData_EX[8:15];
        if(hazard_EX_d1 && rf_wrByteEn_EX[2]) forward_MUX_d1_ID[16:23] = rf_wrData_EX[16:23];
        if(hazard_EX_d1 && rf_wrByteEn_EX[3]) forward_MUX_d1_ID[24:31] = rf_wrData_EX[24:31];
        if(hazard_EX_d1 && rf_wrByteEn_EX[4]) forward_MUX_d1_ID[32:39] = rf_wrData_EX[32:39];
        if(hazard_EX_d1 && rf_wrByteEn_EX[5]) forward_MUX_d1_ID[40:47] = rf_wrData_EX[40:47];
        if(hazard_EX_d1 && rf_wrByteEn_EX[6]) forward_MUX_d1_ID[48:55] = rf_wrData_EX[48:55];
        if(hazard_EX_d1 && rf_wrByteEn_EX[7]) forward_MUX_d1_ID[56:63] = rf_wrData_EX[56:63];
    end


    //-----------------------------------------------------------------

    // WB stage
    assign rf_wrData_WB = EX_WB_reg[0:63];
    assign rf_wrAddr_WB = EX_WB_reg[64:68];
    assign rf_wrEn_WB = EX_WB_reg[69];
    assign rf_wrByteEn_WB = EX_WB_reg[70:77];

endmodule


