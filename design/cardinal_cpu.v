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
    localparam VAND   = 000001,
               VOR    = 000010,
               VXOR   = 000011,
               VNOT   = 000100,
               VMOV   = 000101,
               VADD   = 000110,
               VSUB   = 000111,
               VMULEU = 001000,
               VMULOU = 001001,
               VSLL   = 001010,
               VSRL   = 001011,
               VSRA   = 001100,
               VRTTH  = 001101,
               VDIV   = 001110,
               VMOD   = 001111,
               VSQEU  = 010000,
               VSQOU  = 010001,
               VSQRT  = 010010;
    
    // 6 bit opcode
    localparam R_ALU  = 101010,
               M_LD   = 100000,
               M_SD   = 100001,
               R_BEZ  = 100010,
               R_BNEZ = 100011,
               VNOP   = 111100;

    // 3 bit participation
    localparam participate_A = 000,
               participate_U = 001,
               participate_D = 010,
               participate_E = 011,
               participate_O = 100;

    // IF/ID
    reg [0:INST_WIDTH-1]     IF_ID_reg; // only the instruction

    // ID/EX wire
    wire [0:REG_ADDR_WIDTH-1] decoder_regfile_rdAddr0, decoder_regfile_rdAddr1;
    wire [0:DATA_WIDTH-1]     regfile_rA, regfile_rB;

    wire                      decoder_regfile_we;
    wire [0:REG_ADDR_WIDTH-1] decoder_regfile_wrAddr;
    wire [0:7]                decoder_regfile_wrByteEn;

    wire [0:1]                decoder_WW;
    wire [0:5]                decoder_function_code;

    wire                      decoder_mem_we;
    wire [0:MEM_ADDR_WIDTH-1] decoder_mem_rdAddr, decoder_mem_wrAddr;

    wire [0:15]               decoder_pc_Addr;

    // ID/EX reg
    reg [0:DATA_WIDTH-1]     ID_EX_rA, ID_EX_rB;

    reg                      ID_EX_regfile_we;
    reg [0:REG_ADDR_WIDTH-1] ID_EX_regfile_wrAddr;
    reg [0:7]                ID_EX_regfile_wrByteEn;

    reg [0:1]                ID_EX_WW;
    reg [0:5]                ID_EX_function_code;

    reg                      ID_EX_mem_we;
    reg [0:MEM_ADDR_WIDTH-1] ID_EX_mem_rdAddr, ID_EX_mem_wrAddr;

    reg [0:15]               ID_EX_pc_Addr;
    
    // decoder module
    decoder d1(
        .inst_in(IF_ID_reg),

        .regfile_rdAddr0(decoder_regfile_rdAddr0),
        .regfile_rdAddr1(decoder_regfile_rdAddr1),

        .regfile_we(decoder_regfile_we),
        .regfile_wrAddr(decoder_regfile_wrAddr),
        .regfile_wrByteEn(decoder_regfile_wrByteEn),

        .WW(decoder_WW),
        .function_code(decoder_function_code),

        .mem_we(decoder_mem_we),
        .mem_rdAddr(decoder_mem_rdAddr),
        .mem_wrAddr(decoder_mem_wrAddr),

        .pc_Addr(decoder_pc_Addr),
        
        // CAUTION: NOT YET ASSIGNED
        .branch(),
        .compare_bez()
    );

    // regfile module
    register_file(
        .clk(clk),     
        .reset(reset),   

        // shoulg get from WB stage
        .wrEn(),    
        .wrAddr(),  
        .wrData(),  
        .wrByteEn(),

        .rdAddr0(decoder_regfile_rdAddr0), 
        .rdData0(regfile_rA), 
        .rdAddr1(decoder_regfile_rdAddr1), 
        .rdData1(regfile_rB)
    );

    // IF/ID reg statement
    always @(posedge clk) begin
        if(reset) IF_ID_reg <= 'd0;
        else      IF_ID_reg <= inst_in;
    end

    // ID/EX reg statement
    always @(posedge clk) begin
        if(reset) begin
            ID_EX_rA                <= 'd0;
            ID_EX_rB                <= 'd0;

            ID_EX_regfile_we        <= 1'b0;
            ID_EX_regfile_wrAddr    <= 'd0;
            ID_EX_regfile_wrByteEn  <= 'd0;

            ID_EX_WW                <= 'd0;
            ID_EX_function_code     <= 'd0;

            ID_EX_mem_we            <= 1'b0;
            ID_EX_mem_rdAddr        <= 'd0;
            ID_EX_mem_wrAddr        <= 'd0;

            ID_EX_pc_Addr           <= 'd0;
        end
        else begin
            ID_EX_rA                <= regfile_rA;
            ID_EX_rB                <= regfile_rB;

            ID_EX_regfile_we        <= decoder_regfile_we;
            ID_EX_regfile_wrAddr    <= decoder_regfile_wrAddr;
            ID_EX_regfile_wrByteEn  <= decoder_regfile_wrByteEn;

            ID_EX_WW                <= decoder_WW;
            ID_EX_function_code     <= decoder_function_code;

            ID_EX_mem_we            <= decoder_mem_we;
            ID_EX_mem_rdAddr        <= decoder_mem_rdAddr;
            ID_EX_mem_wrAddr        <= decoder_mem_wrAddr;

            ID_EX_pc_Addr           <= decoder_pc_Addr;
        end
    end

    

endmodule


