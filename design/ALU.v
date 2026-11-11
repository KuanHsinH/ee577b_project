module ALU #(
    parameter DATA_WIDTH = 64
) (
    rA, rB,
    function_code, WW,
    out
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

    input [0:DATA_WIDTH-1] rA, rB;
    input [0:5]            function_code;
    input [0:1]            WW;
    
    output reg [0:DATA_WIDTH-1] out;

    //----------------------------------------------------------------------

    // add/sub
    wire  add_sub = (function_code == VADD) ? 1'b0 : 1'b1;
    wire  [0:DATA_WIDTH-1] sum_diff;
    wire  [0:6] ci;
    wire  [0:7] co;

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

    wire [0:DATA_WIDTH-1] prod_b, prod_h, prod_w;

    reg [0:(DATA_WIDTH/2)-1] mul_inA, mul_inB;

    always @(*) begin
        case (function_code)
            VMULEU: begin
                case (WW)
                    2'b00: begin
                        mul_inA = {rA[0:7], rA[16:23], rA[32:39], rA[48:55]};
                        mul_inB = {rB[0:7], rB[16:23], rB[32:39], rB[48:55]};
                    end 
                    2'b01: begin
                        mul_inA = {rA[0:15], rA[32:47]};
                        mul_inB = {rB[0:15], rB[32:47]};
                    end
                    2'b10: begin
                        mul_inA = rA[0:31];
                        mul_inB = rB[0:31];
                    end
                    default: begin
                        mul_inA = 32'd0;
                        mul_inB = 32'd0;
                    end
                endcase
            end 
            VMULOU: begin
                case (WW)
                    2'b00: begin
                        mul_inA = {rA[8:15], rA[24:31], rA[40:47], rA[56:63]};
                        mul_inB = {rB[8:15], rB[24:31], rB[40:47], rB[56:63]};
                    end 
                    2'b01: begin
                        mul_inA = {rA[16:31], rA[48:63]};
                        mul_inB = {rB[16:31], rB[48:63]};
                    end
                    2'b10: begin
                        mul_inA = rA[32:63];
                        mul_inB = rB[32:63];
                    end
                    default: begin
                        mul_inA = 32'd0;
                        mul_inB = 32'd0;
                    end
                endcase
            end
            VSQEU: begin
                case (WW)
                    2'b00: begin
                        mul_inA = {rA[0:7], rA[16:23], rA[32:39], rA[48:55]};
                        mul_inB = {rA[0:7], rA[16:23], rA[32:39], rA[48:55]};
                    end 
                    2'b01: begin
                        mul_inA = {rA[0:15], rA[32:47]};
                        mul_inB = {rA[0:15], rA[32:47]};
                    end
                    2'b10: begin
                        mul_inA = rA[0:31];
                        mul_inB = rA[0:31];
                    end
                    default: begin
                        mul_inA = 32'd0;
                        mul_inB = 32'd0;
                    end
                endcase
            end
            VSQOU: begin
                case (WW)
                    2'b00: begin
                        mul_inA = {rA[8:15], rA[24:31], rA[40:47], rA[56:63]};
                        mul_inB = {rA[8:15], rA[24:31], rA[40:47], rA[56:63]};
                    end 
                    2'b01: begin
                        mul_inA = {rA[16:31], rA[48:63]};
                        mul_inB = {rA[16:31], rA[48:63]};
                    end
                    2'b10: begin
                        mul_inA = rA[32:63];
                        mul_inB = rA[32:63];
                    end
                    default: begin
                        mul_inA = 32'd0;
                        mul_inB = 32'd0;
                    end 
                endcase
            end
            default:    {mul_inA, mul_inB} = 64'd0;
        endcase
    end

    // WW = 00
    DW02_mult #(.A_width(8), .B_width(8))
    mul0 ( .A(mul_inA[0:7]), .B(mul_inB[0:7]), .TC(1'b0), .PRODUCT(prod_b[0:15]) );

    DW02_mult #(.A_width(8), .B_width(8))
    mul1 ( .A(mul_inA[8:15]), .B(mul_inB[8:15]), .TC(1'b0), .PRODUCT(prod_b[16:31]) );

    DW02_mult #(.A_width(8), .B_width(8))
    mul2 ( .A(mul_inA[16:23]), .B(mul_inB[16:23]), .TC(1'b0), .PRODUCT(prod_b[32:47]) );

    DW02_mult #(.A_width(8), .B_width(8))
    mul3 ( .A(mul_inA[24:31]), .B(mul_inB[24:31]), .TC(1'b0), .PRODUCT(prod_b[48:63]) );

    // WW = 01
    DW02_mult #(.A_width(16), .B_width(16))
    mul4 ( .A(mul_inA[0:15]), .B(mul_inB[0:15]), .TC(1'b0), .PRODUCT(prod_h[0:31]) );

    DW02_mult #(.A_width(16), .B_width(16))
    mul5 ( .A(mul_inA[16:31]), .B(mul_inB[16:31]), .TC(1'b0), .PRODUCT(prod_h[32:63]) );

    // WW = 10
    DW02_mult #(.A_width(32), .B_width(32))
    mul6 ( .A(mul_inA[0:31]), .B(mul_inB[0:31]), .TC(1'b0), .PRODUCT(prod_w[0:63]) );

    //----------------------------------------------------------------------

    // shift
    reg [0:3] shift_b_0, shift_b_1, shift_b_2, shift_b_3, shift_b_4, shift_b_5, shift_b_6, shift_b_7;
    reg [0:4] shift_h_0, shift_h_1, shift_h_2, shift_h_3;
    reg [0:5] shift_w_0, shift_w_1;
    reg [0:6] shift_d_0;

    wire [0:DATA_WIDTH-1] shift_out_b, shift_out_h, shift_out_w, shift_out_d;

    wire data_tc_ctrl = (function_code == VSRA) ? 1'b1 : 1'b0;

    always @(*) begin
        if(function_code == VSLL) begin
            case (WW)
                2'b00: begin
                    shift_b_0 = {1'b0, rB[5:7]};
                    shift_b_1 = {1'b0, rB[13:15]};
                    shift_b_2 = {1'b0, rB[21:23]};
                    shift_b_3 = {1'b0, rB[29:31]};
                    shift_b_4 = {1'b0, rB[37:39]};
                    shift_b_5 = {1'b0, rB[45:47]};
                    shift_b_6 = {1'b0, rB[53:55]};
                    shift_b_7 = {1'b0, rB[61:63]};
                end
                2'b01: begin
                    shift_h_0 = {1'b0, rB[12:15]};
                    shift_h_1 = {1'b0, rB[28:31]};
                    shift_h_2 = {1'b0, rB[44:47]};
                    shift_h_3 = {1'b0, rB[60:63]};
                end
                2'b10: begin
                    shift_w_0 = {1'b0, rB[27:31]};
                    shift_w_1 = {1'b0, rB[59:63]};
                end
                2'b11: begin
                    shift_d_0 = {1'b0, rB[58:63]};
                end
                default: begin
                    shift_b_0 = 'd0;
                    shift_b_1 = 'd0;
                    shift_b_2 = 'd0;
                    shift_b_3 = 'd0;
                    shift_b_4 = 'd0;
                    shift_b_5 = 'd0;
                    shift_b_6 = 'd0;
                    shift_b_7 = 'd0;

                    shift_h_0 = 'd0;
                    shift_h_1 = 'd0;
                    shift_h_2 = 'd0;
                    shift_h_3 = 'd0;

                    shift_w_0 = 'd0;
                    shift_w_1 = 'd0;

                    shift_d_0 = 'd0;
                end
            endcase
        end
        else begin // VSRL, VSRA
            case (WW)
                2'b00: begin
                    shift_b_0 = ~({1'b0, rB[5:7]}) + 1'b1;
                    shift_b_1 = ~({1'b0, rB[13:15]}) + 1'b1;
                    shift_b_2 = ~({1'b0, rB[21:23]}) + 1'b1;
                    shift_b_3 = ~({1'b0, rB[29:31]}) + 1'b1;
                    shift_b_4 = ~({1'b0, rB[37:39]}) + 1'b1;
                    shift_b_5 = ~({1'b0, rB[45:47]}) + 1'b1;
                    shift_b_6 = ~({1'b0, rB[53:55]}) + 1'b1;
                    shift_b_7 = ~({1'b0, rB[61:63]}) + 1'b1;
                end
                2'b01: begin
                    shift_h_0 = ~({1'b0, rB[12:15]}) + 1'b1;
                    shift_h_1 = ~({1'b0, rB[28:31]}) + 1'b1;
                    shift_h_2 = ~({1'b0, rB[44:47]}) + 1'b1;
                    shift_h_3 = ~({1'b0, rB[60:63]}) + 1'b1;
                end
                2'b10: begin
                    shift_w_0 = ~({1'b0, rB[27:31]}) + 1'b1;
                    shift_w_1 = ~({1'b0, rB[59:63]}) + 1'b1;
                end
                2'b11: begin
                    shift_d_0 = ~({1'b0, rB[58:63]}) + 1'b1;
                end
                default: begin
                    shift_b_0 = 'd0;
                    shift_b_1 = 'd0;
                    shift_b_2 = 'd0;
                    shift_b_3 = 'd0;
                    shift_b_4 = 'd0;
                    shift_b_5 = 'd0;
                    shift_b_6 = 'd0;
                    shift_b_7 = 'd0;

                    shift_h_0 = 'd0;
                    shift_h_1 = 'd0;
                    shift_h_2 = 'd0;
                    shift_h_3 = 'd0;

                    shift_w_0 = 'd0;
                    shift_w_1 = 'd0;

                    shift_d_0 = 'd0;
                end
            endcase
        end
    end

    // WW = 00
    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_0 ( .data_in(rA[0:7]),   .data_tc(data_tc_ctrl),   .sh(shift_b_0),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[0:7]) );

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_1 ( .data_in(rA[8:15]),   .data_tc(data_tc_ctrl),   .sh(shift_b_1),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[8:15]) );

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_2 ( .data_in(rA[16:23]),   .data_tc(data_tc_ctrl),   .sh(shift_b_2),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[16:23]) );

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_3 ( .data_in(rA[24:31]),   .data_tc(data_tc_ctrl),   .sh(shift_b_3),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[24:31]) );     

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_4 ( .data_in(rA[32:39]),   .data_tc(data_tc_ctrl),   .sh(shift_b_4),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[32:39]) );

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_5 ( .data_in(rA[40:47]),   .data_tc(data_tc_ctrl),   .sh(shift_b_5),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[40:47]) );

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_6 ( .data_in(rA[48:55]),   .data_tc(data_tc_ctrl),   .sh(shift_b_6),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[48:55]) );

    DW_shifter #(.data_width(8), .sh_width(4))
    shift_byte_7 ( .data_in(rA[56:63]),   .data_tc(data_tc_ctrl),   .sh(shift_b_7),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_b[56:63]) );

    // WW = 01
    DW_shifter #(.data_width(16), .sh_width(5))
    shift_half_0 ( .data_in(rA[0:15]),   .data_tc(data_tc_ctrl),   .sh(shift_h_0),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_h[0:15]) );

    DW_shifter #(.data_width(16), .sh_width(5))
    shift_half_1 ( .data_in(rA[16:31]),   .data_tc(data_tc_ctrl),   .sh(shift_h_1),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_h[16:31]) );

    DW_shifter #(.data_width(16), .sh_width(5))
    shift_half_2 ( .data_in(rA[32:47]),   .data_tc(data_tc_ctrl),   .sh(shift_h_2),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_h[32:47]) );

    DW_shifter #(.data_width(16), .sh_width(5))
    shift_half_3 ( .data_in(rA[48:63]),   .data_tc(data_tc_ctrl),   .sh(shift_h_3),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_h[48:63]) );  

    // WW = 10
    DW_shifter #(.data_width(32), .sh_width(6))
    shift_word_0 ( .data_in(rA[0:31]),   .data_tc(data_tc_ctrl),   .sh(shift_w_0),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_w[0:31]) );

    DW_shifter #(.data_width(32), .sh_width(6))
    shift_word_1 ( .data_in(rA[32:63]),   .data_tc(data_tc_ctrl),   .sh(shift_w_1),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_w[32:63]) );    

    // WW = 11
    DW_shifter #(.data_width(64), .sh_width(7))
    shift_dword_0 ( .data_in(rA[0:63]),   .data_tc(data_tc_ctrl),   .sh(shift_d_0),
         .sh_tc(1'b1),   .sh_mode(1'b1),
         .data_out(shift_out_d[0:63]) );    

    //---------------------------------------------------------------------------------

    // div 
    wire [0:DATA_WIDTH-1] quotient_b, quotient_h, quotient_w, quotient_d;
    wire [0:DATA_WIDTH-1] remainder_b, remainder_h, remainder_w, remainder_d;
    wire [0:DATA_WIDTH-1] divisor = ((function_code == VDIV) || (function_code == VMOD)) ? rB : 64'd1;

    // WW = 00
    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_0 (.a(rA[0:7]), .b(divisor[0:7]),
        .quotient(quotient_b[0:7]), .remainder(remainder_b[0:7]),
        .divide_by_0());

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_1 (.a(rA[8:15]), .b(divisor[8:15]),
        .quotient(quotient_b[8:15]), .remainder(remainder_b[8:15]),
        .divide_by_0());  

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_2 (.a(rA[16:23]), .b(divisor[16:23]),
        .quotient(quotient_b[16:23]), .remainder(remainder_b[16:23]),
        .divide_by_0());

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_3 (.a(rA[24:31]), .b(divisor[24:31]),
        .quotient(quotient_b[24:31]), .remainder(remainder_b[24:31]),
        .divide_by_0());   

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_4 (.a(rA[32:39]), .b(divisor[32:39]),
        .quotient(quotient_b[32:39]), .remainder(remainder_b[32:39]),
        .divide_by_0());

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_5 (.a(rA[40:47]), .b(divisor[40:47]),
        .quotient(quotient_b[40:47]), .remainder(remainder_b[40:47]),
        .divide_by_0());  

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_6 (.a(rA[48:55]), .b(divisor[48:55]),
        .quotient(quotient_b[48:55]), .remainder(remainder_b[48:55]),
        .divide_by_0());

    DW_div #(8, 8, 1'b0, 1'b0)
    div_b_7 (.a(rA[56:63]), .b(divisor[56:63]),
        .quotient(quotient_b[56:63]), .remainder(remainder_b[56:63]),
        .divide_by_0());

    // WW = 01
    DW_div #(16, 16, 1'b0, 1'b0)
    div_h_0 (.a(rA[0:15]), .b(divisor[0:15]),
        .quotient(quotient_h[0:15]), .remainder(remainder_h[0:15]),
        .divide_by_0());

    DW_div #(16, 16, 1'b0, 1'b0)
    div_h_1 (.a(rA[16:31]), .b(divisor[16:31]),
        .quotient(quotient_h[16:31]), .remainder(remainder_h[16:31]),
        .divide_by_0());  

    DW_div #(16, 16, 1'b0, 1'b0)
    div_h_2 (.a(rA[32:47]), .b(divisor[32:47]),
        .quotient(quotient_h[32:47]), .remainder(remainder_h[32:47]),
        .divide_by_0());

    DW_div #(16, 16, 1'b0, 1'b0)
    div_h_3 (.a(rA[48:63]), .b(divisor[48:63]),
        .quotient(quotient_h[48:63]), .remainder(remainder_h[48:63]),
        .divide_by_0()); 

    // WW = 10
    DW_div #(32, 32, 1'b0, 1'b0)
    div_w_0 (.a(rA[0:31]), .b(divisor[0:31]),
        .quotient(quotient_w[0:31]), .remainder(remainder_w[0:31]),
        .divide_by_0());

    DW_div #(32, 32, 1'b0, 1'b0)
    div_w_1 (.a(rA[32:63]), .b(divisor[32:63]),
        .quotient(quotient_w[32:63]), .remainder(remainder_w[32:63]),
        .divide_by_0());

    // WW = 11
    DW_div #(64, 64, 1'b0, 1'b0)
    div_d_0 (.a(rA[0:63]), .b(divisor[0:63]),
        .quotient(quotient_d[0:63]), .remainder(remainder_d[0:63]),
        .divide_by_0());

    //----------------------------------------------------------------

    // sqrt
    wire [0:DATA_WIDTH-1] sqrt_b, sqrt_h, sqrt_w, sqrt_d;

    // WW = 00
    DW_sqrt #(8, 1'b0)
    sqrt_b_0 (.a(rA[0:7]), .root(sqrt_b[4:7]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_1 (.a(rA[8:15]), .root(sqrt_b[12:15]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_2 (.a(rA[16:23]), .root(sqrt_b[20:23]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_3 (.a(rA[24:31]), .root(sqrt_b[28:31]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_4 (.a(rA[32:39]), .root(sqrt_b[36:39]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_5 (.a(rA[40:47]), .root(sqrt_b[44:47]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_6 (.a(rA[48:55]), .root(sqrt_b[52:55]));

    DW_sqrt #(8, 1'b0)
    sqrt_b_7 (.a(rA[56:63]), .root(sqrt_b[60:63]));

    assign sqrt_b[0:3]   = 4'b0;
    assign sqrt_b[8:11]  = 4'b0;
    assign sqrt_b[16:19] = 4'b0;
    assign sqrt_b[24:27] = 4'b0;
    assign sqrt_b[32:35] = 4'b0;
    assign sqrt_b[40:43] = 4'b0;
    assign sqrt_b[48:51] = 4'b0;
    assign sqrt_b[56:59] = 4'b0;

    // WW = 01
    DW_sqrt #(16, 1'b0)
    sqrt_h_0 (.a(rA[0:15]), .root(sqrt_h[8:15]));

    DW_sqrt #(16, 1'b0)
    sqrt_h_1 (.a(rA[16:31]), .root(sqrt_h[24:31]));

    DW_sqrt #(16, 1'b0)
    sqrt_h_2 (.a(rA[32:47]), .root(sqrt_h[40:47]));

    DW_sqrt #(16, 1'b0)
    sqrt_h_3 (.a(rA[48:63]), .root(sqrt_h[56:63]));

    assign sqrt_h[0:7]   = 8'b0;
    assign sqrt_h[16:23] = 8'b0;
    assign sqrt_h[32:39] = 8'b0;
    assign sqrt_h[48:55] = 8'b0;

    // WW = 10
    DW_sqrt #(32, 1'b0)
    sqrt_w_0 (.a(rA[0:31]), .root(sqrt_w[16:31]));

    DW_sqrt #(32, 1'b0)
    sqrt_w_1 (.a(rA[32:63]), .root(sqrt_w[48:63]));

    assign sqrt_w[0:15]   = 16'b0;
    assign sqrt_w[32:47]  = 16'b0;

    // WW = 11
    DW_sqrt #(64, 1'b0)
    sqrt_d_0 (.a(rA[0:63]), .root(sqrt_d[32:63]));

    assign sqrt_d[0:31] = 32'b0;

    // assigning out
    always@(*) begin    
        // R_ALU
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
                    2'b00: out = prod_b;
                    2'b01: out = prod_h;
                    2'b10: out = prod_w;
                    default: out = 64'd0;
                endcase
            end
            VMULOU: begin
                case (WW)
                    2'b00: out = prod_b;
                    2'b01: out = prod_h;
                    2'b10: out = prod_w;
                    default: out = 64'd0;
                endcase
            end
            VSLL: begin
                case (WW)
                    2'b00: out = shift_out_b;
                    2'b01: out = shift_out_h;
                    2'b10: out = shift_out_w;
                    2'b11: out = shift_out_d;
                    default: out = 64'd0;
                endcase
            end
            VSRL: begin
                case (WW)
                    2'b00: out = shift_out_b;
                    2'b01: out = shift_out_h;
                    2'b10: out = shift_out_w;
                    2'b11: out = shift_out_d;
                    default: out = 64'd0;
                endcase
            end
            VSRA: begin
                case (WW)
                    2'b00: out = shift_out_b;
                    2'b01: out = shift_out_h;
                    2'b10: out = shift_out_w;
                    2'b11: out = shift_out_d;
                    default: out = 64'd0;
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
            VDIV: begin
                case (WW)
                    2'b00: out = quotient_b;
                    2'b01: out = quotient_h;
                    2'b10: out = quotient_w;
                    2'b11: out = quotient_d;
                    default: out = 64'd0;
                endcase
            end
            VMOD: begin
                case (WW)
                    2'b00: out = remainder_b;
                    2'b01: out = remainder_h;
                    2'b10: out = remainder_w;
                    2'b11: out = remainder_d;
                    default: out = 64'd0;
                endcase
            end
            VSQEU: begin
                case (WW)
                    2'b00: out = prod_b;
                    2'b01: out = prod_h;
                    2'b10: out = prod_w;
                    default: out = 64'd0;
                endcase
            end
            VSQOU: begin
                case (WW)
                    2'b00: out = prod_b;
                    2'b01: out = prod_h;
                    2'b10: out = prod_w;
                    default: out = 64'd0;
                endcase
            end
            VSQRT: begin
                case (WW)
                    2'b00: out = sqrt_b;
                    2'b01: out = sqrt_h;
                    2'b10: out = sqrt_w;
                    2'b11: out = sqrt_d;
                    default: out = 64'd0;
                endcase
            end
            default: out = 64'd0;
        endcase
    end
    
endmodule
