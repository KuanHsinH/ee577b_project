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
module cardinal_cpu (
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

    reg [0:31] IF_ID_reg;

    

endmodule
