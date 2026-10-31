module decoder(
    inst_in, 
    regfile_we,
    regfile_rdAddr0, 
    regfile_rdAddr1,
    regfile_wrAddr,
    regfile_wrByteEn,
    WW,
    function_code,
    mem_we,
    mem_rdAddr,
    mem_wrAddr,
    pc_Addr,
    op_type
);

    input      [0:31] inst_in;

    output reg        regfile_we;
    output reg [0:4]  regfile_rdAddr0, regfile_rdAddr1, regfile_wrAddr;
    output reg [0:7]  regfile_wrByteEn;

    output reg [0:1]  WW;

    output reg [0:5]  function_code;

    output reg        mem_we;
    output reg [0:15] mem_rdAddr, mem_wrAddr;

    output reg [0:15] pc_Addr;
    output reg [0:2]  op_type;

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
    localparam R_ALU  = 6'b101010,  // 001
               M_LD   = 6'b100000,  // 010
               M_SD   = 6'b100001,  // 011
               R_BEZ  = 6'b100010,  // 100
               R_BNEZ = 6'b100011,  // 101
               VNOP   = 6'b111100;  // 000

    // 3 bit participation
    localparam participate_A = 3'b000,
               participate_U = 3'b001,
               participate_D = 3'b010,
               participate_E = 3'b011,
               participate_O = 3'b100;

    // decoding opcode
    always@(*)begin

        // initialize
        regfile_we       = 1'b0;
        regfile_wrAddr   = 5'd0;
        regfile_rdAddr0  = 5'd0;
        regfile_rdAddr1  = 5'd0;
        regfile_wrByteEn = 8'd0;
    
        WW               = 2'd0;
        function_code    = 6'd0;
    
        mem_we           = 1'b0;
        mem_rdAddr       = 16'd0;
        mem_wrAddr       = 16'd0;
    
        pc_Addr          = 16'd0;
        op_type          = 3'b000; // NOP

        case (inst_in[0:5])
            R_ALU: begin
                if(inst_in[26:31] == 6'd0 || inst_in[26:31] > 6'd18) regfile_we = 1'b0;
                else                                                 regfile_we = 1'b1;
                regfile_wrAddr  = inst_in[6:10];    // rD
                regfile_rdAddr0 = inst_in[11:15];   // rA
                regfile_rdAddr1 = inst_in[16:20];   // rB

                WW              = inst_in[24:25];
                function_code   = inst_in[26:31];
                
                op_type         = 3'b001; // R_ALU

                case (inst_in[21:23])
                    participate_A: regfile_wrByteEn = 8'b1111_1111;
                    participate_U: regfile_wrByteEn = 8'b1111_0000;
                    participate_D: regfile_wrByteEn = 8'b0000_1111;
                    participate_E: begin
                        case (inst_in[24:25])
                            2'b00:      regfile_wrByteEn = 8'b1010_1010;
                            2'b01:      regfile_wrByteEn = 8'b1100_1100;
                            2'b10:      regfile_wrByteEn = 8'b1111_0000;
                            2'b11:      regfile_wrByteEn = 8'b1111_1111;
                            default:    regfile_wrByteEn = 8'b0000_0000;
                        endcase
                    end
                    participate_O: begin
                        case (inst_in[24:25])
                            2'b00:      regfile_wrByteEn = 8'b0101_0101;
                            2'b01:      regfile_wrByteEn = 8'b0011_0011;
                            2'b10:      regfile_wrByteEn = 8'b0000_1111;
                            2'b11:      regfile_wrByteEn = 8'b0000_0000;
                            default:    regfile_wrByteEn = 8'b0000_0000;
                        endcase
                    end
                    default:            regfile_wrByteEn = 8'b0000_0000;
                endcase
            end

            M_LD: begin
                regfile_we       = 1'b1;
                regfile_wrAddr   = inst_in[6:10];
                regfile_wrByteEn = 8'b1111_1111;

                mem_we           = 1'b0;
                mem_rdAddr       = inst_in[16:31];

                op_type          = 3'b010; // LD
            end

            M_SD: begin
                regfile_we       = 1'b0;
                regfile_rdAddr0  = inst_in[6:10];

                mem_we           = 1'b1;
                mem_wrAddr       = inst_in[16:31];

                op_type          = 3'b011; // SD
            end

            R_BEZ: begin
                regfile_we       = 1'b0;
                regfile_rdAddr0  = inst_in[6:10];
                pc_Addr          = inst_in[16:31];
                op_type          = 2'b100; // BEZ
            end

            R_BNEZ: begin
                regfile_we       = 1'b0;
                regfile_rdAddr0  = inst_in[6:10];
                pc_Addr          = inst_in[16:31];
                op_type          = 3'b101; // BNEZ
            end

            default: begin
                regfile_we       = 1'b0;
                regfile_wrAddr   = 5'd0;
                regfile_rdAddr0  = 5'd0;
                regfile_rdAddr1  = 5'd0;
                regfile_wrByteEn = 8'd0;
            
                WW               = 2'd0;
                function_code    = 6'd0;
        
                mem_we           = 1'b0;
                mem_rdAddr       = 16'd0;
                mem_wrAddr       = 16'd0;
            
                pc_Addr          = 16'd0;
                op_type          = 3'b000;
            end
        endcase
    end
    
endmodule