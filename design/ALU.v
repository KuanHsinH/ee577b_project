`include "/tools/synopsys/syn/Y-2026.03/dw/sim_ver/DW_div.v"
`include "/tools/synopsys/syn/Y-2026.03/dw/sim_ver/DW_sqrt.v"
`include "/tools/synopsys/syn/Y-2026.03/dw/sim_ver/DW01_addsub.v"
`include "/tools/synopsys/syn/Y-2026.03/dw/sim_ver/DW02_mult.v"
`include "/tools/synopsys/syn/Y-2026.03/dw/sim_ver/DW_div.v"

module ALU #(
    parameter DATA_WIDTH = 64;
) (
    rA, rB,
    function_code, WW,
    op_type,
    pc_Addr,
    out
);

    // op_type
    localparam R_ALU  = 3'b001,
               M_LD   = 3'b010,
               M_SD   = 3'b011,
               R_BEZ  = 3'b100,
               R_BNEZ = 3'b101,
               VNOP   = 3'b000;

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

    input [0:DATA_WIDTH-1] rA, rB;
    input [0:5]            function_code;
    input [0:1]            WW;
    input [0:2]            op_type;
    input [0:15]           pc_Addr;
    
    output reg [0:DATA_WIDTH-1] out;

    // add/sub
    wire  add_sub = (function_code == VADD) ? 1'b0 : 1'b1;
    wire  [0:DATA_WIDTH-1] sum_diff;

    assign ci[0] = (WW == 2'b00) ? 1'b0 : co[1];
    assign ci[1] = ((WW == 2'b00) || (WW == 2'b01)) ? 1'b0 : co[2];
    assign ci[2] = (WW == 2'b00) ? 1'b0 : co[3];
    assign ci[3] = ((WW == 2'b00) || (WW == 2'b01) || (WW == 2'b10)) ? 1'b0 : co[4];
    assign ci[4] = (WW == 2'b00) ? 1'b0 : co[5];
    assign ci[5] = ((WW == 2'b00) || (WW == 2'b01)) ? 1'b0 : co[6];
    assign ci[6] = (WW == 2'b00) ? 1'b0 : co[7];

    // instantiating add/sub
    DW01_addsub #(.width(8))
    addsub_0 ( .A(rA[0:7]), .B(rB[0:7]), .CI(ci[0]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[0:7]), .CO(co[0]) );

    DW01_addsub #(.width(8))
    addsub_1 ( .A(rA[8:15]), .B(rB[8:15]), .CI(ci[1]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[8:15]), .CO(co[1]) );

    DW01_addsub #(.width(8))
    addsub_2 ( .A(rA[16:23]), .B(rB[16:23]), .CI(ci[2]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[16:23]), .CO(co[2]) );   
    
    DW01_addsub #(.width(8))
    addsub_3 ( .A(rA[24:31]), .B(rB[24:31]), .CI(ci[3]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[24:31]), .CO(co[3]) );

    DW01_addsub #(.width(8))
    addsub_4 ( .A(rA[32:39]), .B(rB[32:39]), .CI(ci[4]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[32:39]), .CO(co[4]) );

    DW01_addsub #(.width(8))
    addsub_5 ( .A(rA[40:47]), .B(rB[40:47]), .CI(ci[5]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[40:47]), .CO(co[5]) );

    DW01_addsub #(.width(8))
    addsub_6 ( .A(rA[48:55]), .B(rB[48:55]), .CI(ci[6]), .ADD_SUB(add_sub), 
         .SUM(sum_diff[48:55]), .CO(co[6]) );   
    
    DW01_addsub #(.width(8))
    addsub_7 ( .A(rA[56:63]), .B(rB[56:63]), .CI(1'b0), .ADD_SUB(add_sub), 
         .SUM(sum_diff[56:63]), .CO(co[7]) );

    //----------------------------------------------------------------------

    // mul

    // assigning out
    always@(*) begin    
        case (op_type)
            // NOP
            VNOP: out = 64'd0; 

            // R_ALU
            R_ALU: begin
                case (function_code)
                    VAND:   out = rA & rB;
                    VOR:    out = rA | rB;
                    VXOR:   out = rA ^ rB;
                    VNOT:   out = ~rA;
                    VMOV:   out = rA;  
                    VADD:   out = sum_diff;
                    VSUB:   out = sum_diff;
                    VMULEU: begin
                        case (WW)
                            2'b00: begin
                                out[0:15]  = rA[0:7]   * rB[0:7];
                                out[16:31] = rA[16:23] * rB[16:23];
                                out[32:47] = rA[32:39] * rB[32:39];
                                out[48:63] = rA[48:55] * rB[48:55];
                            end
                            2'b01: begin
                                out[0:31]  = rA[0:15]  * rB[0:15];
                                out[32:63] = rA[32:47] * rB[32:47];
                            end
                            2'b10: begin
                                out        = rA[0:31]  * rB[0:31];
                            end
                            default: out   = 64'd0;
                        endcase
                    end
                    VMULOU: begin
                        case (WW)
                            2'b00: begin
                                out[0:15]  = rA[8:15]  * rB[8:15];
                                out[16:31] = rA[24:31] * rB[24:31];
                                out[32:47] = rA[40:47] * rB[40:47];
                                out[48:63] = rA[56:63] * rB[56:63];
                            end
                            2'b01: begin
                                out[0:31]  = rA[16:31] * rB[16:31];
                                out[32:63] = rA[48:63] * rB[48:63];
                            end
                            2'b10: begin
                                out        = rA[32:63]  * rB[32:63];
                            end
                            default: out   = 64'd0;
                        endcase
                    end
                    VSLL: begin
                        case (WW)
                            2'b00: begin
                                out[0:7]   = rA[0:7]   << rB[5:7];
                                out[8:15]  = rA[8:15]  << rB[13:15];
                                out[16:23] = rA[16:23] << rB[21:23];
                                out[24:31] = rA[24:31] << rB[29:31];
                                out[32:39] = rA[32:39] << rB[37:39];
                                out[40:47] = rA[40:47] << rB[45:47];
                                out[48:55] = rA[48:55] << rB[53:55];
                                out[56:63] = rA[56:63] << rB[61:63];
                            end
                            2'b01: begin 
                                out[0:15]  = rA[0:15]  << rB[12:15];
                                out[16:31] = rA[16:31] << rB[28:31];
                                out[32:47] = rA[32:47] << rB[44:47];
                                out[48:63] = rA[48:63] << rB[60:63];
                            end
                            2'b10: begin 
                                out[0:31]  = rA[0:31]  << rB[27:31];
                                out[32:63] = rA[32:63] << rB[59:63];
                            end
                            2'b11: begin 
                                out        = rA << rB[58:63];
                            end
                            default: out   = 64'd0;
                        endcase
                    end
                    VSRL: begin
                        case (WW)
                            2'b00: begin
                                out[0:7]   = rA[0:7]   >> rB[5:7];
                                out[8:15]  = rA[8:15]  >> rB[13:15];
                                out[16:23] = rA[16:23] >> rB[21:23];
                                out[24:31] = rA[24:31] >> rB[29:31];
                                out[32:39] = rA[32:39] >> rB[37:39];
                                out[40:47] = rA[40:47] >> rB[45:47];
                                out[48:55] = rA[48:55] >> rB[53:55];
                                out[56:63] = rA[56:63] >> rB[61:63];
                            end
                            2'b01: begin 
                                out[0:15]  = rA[0:15]  >> rB[12:15];
                                out[16:31] = rA[16:31] >> rB[28:31];
                                out[32:47] = rA[32:47] >> rB[44:47];
                                out[48:63] = rA[48:63] >> rB[60:63];
                            end
                            2'b10: begin 
                                out[0:31]  = rA[0:31]  >> rB[27:31];
                                out[32:63] = rA[32:63] >> rB[59:63];
                            end
                            2'b11: begin 
                                out        = rA >> rB[58:63];
                            end
                            default: out   = 64'd0;
                        endcase
                    end
                    VSRA: begin
                        case (WW)
                            2'b00: begin
                                out[0:7]   = $signed(rA[0:7])   >>> rB[5:7];
                                out[8:15]  = $signed(rA[8:15])  >>> rB[13:15];
                                out[16:23] = $signed(rA[16:23]) >>> rB[21:23];
                                out[24:31] = $signed(rA[24:31]) >>> rB[29:31];
                                out[32:39] = $signed(rA[32:39]) >>> rB[37:39];
                                out[40:47] = $signed(rA[40:47]) >>> rB[45:47];
                                out[48:55] = $signed(rA[48:55]) >>> rB[53:55];
                                out[56:63] = $signed(rA[56:63]) >>> rB[61:63];
                            end

                            2'b01: begin 
                                out[0:15]  = $signed(rA[0:15])  >>> rB[12:15];
                                out[16:31] = $signed(rA[16:31]) >>> rB[28:31];
                                out[32:47] = $signed(rA[32:47]) >>> rB[44:47];
                                out[48:63] = $signed(rA[48:63]) >>> rB[60:63];
                            end

                            2'b10: begin 
                                out[0:31]  = $signed(rA[0:31])  >>> rB[27:31];
                                out[32:63] = $signed(rA[32:63]) >>> rB[59:63];
                            end

                            2'b11: begin 
                                out = $signed(rA) >>> rB[58:63];
                            end
                            default: out   = 64'd0;
                        endcase
                    end
                    VRTTH: begin
                        case (WW)
                            2'b00: begin
                                out[0:7]   = {rA[4:7],   rA[0:3]};  
                                out[8:15]  = {rA[12:15], rA[8:11]};
                                out[16:23] = {rA[20:23], rA[16:19]};
                                out[24:31] = {rA[28:31], rA[24:27]};
                                out[32:39] = {rA[36:39], rA[32:35]};
                                out[40:47] = {rA[44:47], rA[40:43]};
                                out[48:55] = {rA[52:55], rA[48:51]};
                                out[56:63] = {rA[60:63], rA[56:59]};
                            end
                            2'b01: begin
                                out[0:15]  = {rA[8:15],  rA[0:7]};
                                out[16:31] = {rA[24:31], rA[16:23]};
                                out[32:47] = {rA[40:47], rA[32:39]};
                                out[48:63] = {rA[56:63], rA[48:55]};
                            end

                            2'b10: begin 
                                out[0:31]  = {rA[16:31], rA[0:15]};
                                out[32:63] = {rA[48:63], rA[32:47]};
                            end

                            2'b11: begin 
                                out = {rA[32:63], rA[0:31]};
                            end
                            default: out = 64'd0;
                        endcase
                    end
                endcase
            end
            default: 
        endcase
    end
    
endmodule