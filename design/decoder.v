module decoder(
    inst_in, 
    rf_we,
    rA_addr, 
    rB_addr,
    rD_addr,
    rf_wrByteEn,
    WW,
    PPP,
    function_code,
    mem_en,
    mem_we,
    imm_Addr,
    op_type,
    is_branch
);

    input      [0:31] inst_in;

    output reg        rf_we;
    output reg [0:4]  rA_addr, rB_addr, rD_addr;
    output reg [0:7]  rf_wrByteEn;

    output reg [0:1]  WW;
    output     [0:2]  PPP;

    output reg [0:5]  function_code;

    output reg        mem_en, mem_we;

    output reg [0:15] imm_Addr;
    output     [0:5]  op_type;

    output reg        is_branch;

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
               
    assign PPP = inst_in[21:23];
    assign op_type = inst_in[0:5];

    // decoding opcode
    always@(*)begin

        // initialize
        rf_we    = 1'b0;
        rD_addr  = 5'd0;
        rA_addr  = 5'd0;
        rB_addr  = 5'd0;
        rf_wrByteEn = 8'd0;
    
        WW               = 2'd0;
        function_code    = 6'd0;
    
        mem_en           = 1'b0;
        mem_we           = 1'b0;
    
        imm_Addr         = 16'd0;

        is_branch        = 1'b0;

        case (inst_in[0:5])
            R_ALU: begin
                if(inst_in[26:31] == 6'd0 || inst_in[26:31] > 6'd18) rf_we = 1'b0;
                else                                                 rf_we = 1'b1;
                rD_addr = inst_in[6:10];    // rD
                rA_addr = inst_in[11:15];   // rA
                rB_addr = inst_in[16:20];   // rB

                WW              = inst_in[24:25];
                function_code   = inst_in[26:31];

                case (inst_in[21:23])
                    participate_A: rf_wrByteEn = 8'b1111_1111;
                    participate_U: rf_wrByteEn = 8'b1111_0000;
                    participate_D: rf_wrByteEn = 8'b0000_1111;
                    participate_E: rf_wrByteEn = 8'b1010_1010;
                    participate_O: rf_wrByteEn = 8'b0101_0101;
                    default: rf_wrByteEn = 8'b0000_0000;
                endcase
            end

            M_LD: begin
                rf_we       = 1'b1;
                rD_addr     = inst_in[6:10];
                rf_wrByteEn = 8'b1111_1111;

                mem_en     = 1'b1;
                mem_we     = 1'b0;
                imm_Addr   = inst_in[16:31];
            end

            M_SD: begin
                rf_we      = 1'b0;
                rD_addr    = inst_in[6:10];

                mem_en     = 1'b1;
                mem_we     = 1'b1;
                imm_Addr   = inst_in[16:31];
            end

            R_BEZ: begin
                rf_we    = 1'b0;
                rD_addr  = inst_in[6:10];
                imm_Addr = inst_in[16:31];
                is_branch = 1'b1;
            end

            R_BNEZ: begin
                rf_we    = 1'b0;
                rD_addr  = inst_in[6:10];
                imm_Addr = inst_in[16:31];
                is_branch = 1'b1;
            end

            default: begin
                rf_we    = 1'b0;
                rD_addr  = 5'd0;
                rA_addr  = 5'd0;
                rB_addr  = 5'd0;
                rf_wrByteEn = 8'd0;
            
                WW            = 2'd0;
                function_code = 6'd0;

                mem_en        = 1'b0;
                mem_we        = 1'b0;
            
                imm_Addr      = 16'd0;

                is_branch = 1'b0;
            end
        endcase
    end
    
endmodule
