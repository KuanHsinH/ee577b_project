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
module cardinal_cpu #(
    parameter INST_WIDTH = 32;
    parameter DATA_WIDTH = 64;
    parameter REG_ADDR_WIDTH = 6;
    parameter MEM_ADDR_WIDTH = 16;
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
    reg [0:INST_WIDTH-1] br_addr;

    //--------------------------------------------------------------------------

    // IF stage
    reg [0:INST_WIDTH-1] pc;  
    always @(posedge clk) begin
        if(reset) pc <= 0;
        else begin
            if(stall) pc <= pc;
            else begin
                pc <= br_taken ? br_addr : pc + 4;
            end
        end
    end

    // IF/ID reg
    reg [0:INST_WIDTH-1] IF_ID_reg; // only the instruction
    always @(posedge clk) begin
        if(reset) IF_ID_reg <= 'd0;
        else      IF_ID_reg <= inst_in;
    end

    //--------------------------------------------------------------------------

    // ID stage
    wire                      rf_we_ID;
    wire [0:7]                rf_wrByteEn_ID;
    wire [0:REG_ADDR_WIDTH-1] rA_addr_ID, rB_addr_ID, rD_addr_ID;
    
    wire        mem_en_ID, mem_we_ID;
    wire [0:15] mem_rdAddr_ID,  mem_wrAddr_ID;

    wire [0:1]  WW_ID;
    wire [0:5]  function_code_ID;
    wire [0:15] imm_addr_ID;
    wire [0:2]  op_type_ID;
    
    decoder dc1(
        .inst_in(IF_ID_reg),

        .rf_we(rf_wrByteEn_ID),
        .rA_addr(rA_addr_ID),
        .rA_addr(rB_addr_ID),
        .rD_addr(rD_addr_ID),
        .rf_wrByteEn(rf_wrByteEn_ID),

        .mem_en(mem_en_ID),
        .mem_we(mem_we_ID),
        .mem_rdAddr(mem_rdAddr_ID),
        .mem_wrAddr(mem_wrAddr_ID),

        .WW(WW_ID),
        .function_code(function_code_ID),
        .pc_Addr(imm_addr_ID),
        .op_type(op_type_ID)
    );

    // come from WB
    wire rf_wrEn;
    wire [0:7] rf_wrByteEn;
    wire [0:REG_ADDR_WIDTH-1] rf_wrAddr;
    wire [0:DATA_WIDTH-1]     rf_wrData;

    // come from ID
    wire [0:REG_ADDR_WIDTH-1] rf_rdAddr0, rf_rdAddr1;
    wire [0:DATA_WIDTH-1]     rf_rdData0, rf_rdData1;

    assign rf_rdAddr1 = rB_addr_ID;
    assign rf_rdAddr0 = (op_type_ID == R_BEZ) || (op_type_ID == R_BNEZ) || (op_type_ID == M_SD)
                        ? rD_addr_ID : rA_addr_ID;

    register_file rf1(
        .clk(clk),     
        .reset(reset),   

        .wrEn(rf_wrEn),    
        .wrAddr(rf_wrAddr),  
        .wrData(rf_wrData),  
        .wrByteEn(rf_wrByteEn),

        .rdAddr0(rf_rdAddr0), 
        .rdAddr1(rf_rdAddr1),

        .rdData0(rf_rdData0),  
        .rdData1(rf_rdData1)  
    );

    // forwarding
    reg [0:DATA_WIDTH-1] forward_rA_ID, forward_rB_ID, forward_rD_ID;
    
    // branch
    always @(*) begin
        if(((op_type_ID == R_BEZ) && (forward_rD_ID == 0)) 
        || ((op_type_ID == R_BNEZ) && (forward_rD_ID != 0))) begin
             br_taken = 1'b1;
        end
        else br_taken = 1'b0;
    end

endmodule


