////////////////////////////////////////////////////////////////////////////
// One Phase 3 tile for bring-up.
//
// The processor-side bus here is the NIC register interface. The first
// integration testbench drives it directly; cardinal_cpu is connected later
// when its Phase 2 pipeline has been extended for the NIC.
////////////////////////////////////////////////////////////////////////////
module cardinal_node #(
    parameter PACKET_SIZE = 64,
    parameter NODE_NUMBER = 5
) (
    input clk,
    input reset,

    // Processor-side access to the NIC register map.
    input  [0:1]  addr,
    input  [0:63] d_in,
    output [0:63] d_out,
    input         nicEn,
    input         nicWrEn,

    // Cardinal link from the node on the left into this router.
    input                    L2R_si,
    output                   L2R_ri,
    input  [PACKET_SIZE-1:0] L2R_di,
    output                   L2R_so,
    input                    L2R_ro,
    output [PACKET_SIZE-1:0] L2R_do,

    // Cardinal link from the node on the right into this router.
    input                    R2L_si,
    output                   R2L_ri,
    input  [PACKET_SIZE-1:0] R2L_di,
    output                   R2L_so,
    input                    R2L_ro,
    output [PACKET_SIZE-1:0] R2L_do,

    // Cardinal link from the node below into this router.
    input                    D2U_si,
    output                   D2U_ri,
    input  [PACKET_SIZE-1:0] D2U_di,
    output                   D2U_so,
    input                    D2U_ro,
    output [PACKET_SIZE-1:0] D2U_do,

    // Cardinal link from the node above into this router.
    input                    U2D_si,
    output                   U2D_ri,
    input  [PACKET_SIZE-1:0] U2D_di,
    output                   U2D_so,
    input                    U2D_ro,
    output [PACKET_SIZE-1:0] U2D_do,

    output                   polarity
);

    // The NIC and Project 1 router use opposite vector declarations:
    // NIC [0:63], router [63:0]. Connecting by named port preserves bit
    // position (NIC bit 0 is the router's MSB / VC bit).
    wire        net_si;
    wire        net_ri;
    wire        net_so;
    wire        net_ro;
    wire [0:63] net_di;
    wire [0:63] net_do;

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(NODE_NUMBER)
    ) router (
        .clk(clk),
        .reset(reset),
        .polarity(polarity),

        .L2R_si(L2R_si), .L2R_ri(L2R_ri), .L2R_di(L2R_di),
        .R2L_si(R2L_si), .R2L_ri(R2L_ri), .R2L_di(R2L_di),
        .D2U_si(D2U_si), .D2U_ri(D2U_ri), .D2U_di(D2U_di),
        .U2D_si(U2D_si), .U2D_ri(U2D_ri), .U2D_di(U2D_di),

        .PE_si(net_so), .PE_ri(net_ro), .PE_di(net_do),

        .L2R_so(L2R_so), .L2R_ro(L2R_ro), .L2R_do(L2R_do),
        .R2L_so(R2L_so), .R2L_ro(R2L_ro), .R2L_do(R2L_do),
        .D2U_so(D2U_so), .D2U_ro(D2U_ro), .D2U_do(D2U_do),
        .U2D_so(U2D_so), .U2D_ro(U2D_ro), .U2D_do(U2D_do),

        .PE_so(net_si), .PE_ro(net_ri), .PE_do(net_di)
    );

    cardinal_nic nic (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .d_in(d_in),
        .d_out(d_out),
        .nicEn(nicEn),
        .nicWrEn(nicWrEn),

        .net_si(net_si),
        .net_ri(net_ri),
        .net_di(net_di),
        .net_so(net_so),
        .net_ro(net_ro),
        .net_do(net_do),
        .net_polarity(polarity)
    );

endmodule
