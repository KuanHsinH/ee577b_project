module gold_router (
    clk, reset, polarity,

    L2R_si, L2R_ri, L2R_di,
    R2L_si, R2L_ri, R2L_di,
    D2U_si, D2U_ri, D2U_di,
    U2D_si, U2D_ri, U2D_di,
    PE_si, PE_ri, PE_di,

    L2R_so, L2R_ro, L2R_do,
    R2L_so, R2L_ro, R2L_do,
    D2U_so, D2U_ro, D2U_do,
    U2D_so, U2D_ro, U2D_do,
    PE_so, PE_ro, PE_do,
);

    parameter PACKET_SIZE = 64;

    input                    clk, reset;

    input                    PE_si, L2R_si, R2L_si, D2U_si, U2D_si; // channel telling router that the packet is valid
    input [PACKET_SIZE-1:0]  PE_di, L2R_di, R2L_di, D2U_di, U2D_di; // inptu packet data
    output                   PE_ri, L2R_ri, R2L_ri, D2U_ri, U2D_ri; // router telling channel that buffer is empty, can accept

    output                   PE_so, L2R_so, R2L_so, D2U_so, U2D_so; // router telling channel it has packet to send
    output [PACKET_SIZE-1:0] PE_do, L2R_do, R2L_do, D2U_do, U2D_do; // output packet data
    input                    PE_ro, L2R_ro, R2L_ro, D2U_ro, U2D_ro; // channel telling router it can accept packet
    
endmodule