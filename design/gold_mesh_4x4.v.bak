module gold_mesh_4x4 #(parameter PACKET_SIZE = 64) (
    input                      clk,
    input                      reset,

    input                      node0_pesi,
    output                     node0_peri,
    input  [PACKET_SIZE-1:0]   node0_pedi,
    output                     node0_peso,
    input                      node0_pero,
    output [PACKET_SIZE-1:0]   node0_pedo,
    output                     node0_polarity,

    input                      node1_pesi,
    output                     node1_peri,
    input  [PACKET_SIZE-1:0]   node1_pedi,
    output                     node1_peso,
    input                      node1_pero,
    output [PACKET_SIZE-1:0]   node1_pedo,
    output                     node1_polarity,

    input                      node2_pesi,
    output                     node2_peri,
    input  [PACKET_SIZE-1:0]   node2_pedi,
    output                     node2_peso,
    input                      node2_pero,
    output [PACKET_SIZE-1:0]   node2_pedo,
    output                     node2_polarity,

    input                      node3_pesi,
    output                     node3_peri,
    input  [PACKET_SIZE-1:0]   node3_pedi,
    output                     node3_peso,
    input                      node3_pero,
    output [PACKET_SIZE-1:0]   node3_pedo,
    output                     node3_polarity,

    input                      node4_pesi,
    output                     node4_peri,
    input  [PACKET_SIZE-1:0]   node4_pedi,
    output                     node4_peso,
    input                      node4_pero,
    output [PACKET_SIZE-1:0]   node4_pedo,
    output                     node4_polarity,

    input                      node5_pesi,
    output                     node5_peri,
    input  [PACKET_SIZE-1:0]   node5_pedi,
    output                     node5_peso,
    input                      node5_pero,
    output [PACKET_SIZE-1:0]   node5_pedo,
    output                     node5_polarity,

    input                      node6_pesi,
    output                     node6_peri,
    input  [PACKET_SIZE-1:0]   node6_pedi,
    output                     node6_peso,
    input                      node6_pero,
    output [PACKET_SIZE-1:0]   node6_pedo,
    output                     node6_polarity,

    input                      node7_pesi,
    output                     node7_peri,
    input  [PACKET_SIZE-1:0]   node7_pedi,
    output                     node7_peso,
    input                      node7_pero,
    output [PACKET_SIZE-1:0]   node7_pedo,
    output                     node7_polarity,

    input                      node8_pesi,
    output                     node8_peri,
    input  [PACKET_SIZE-1:0]   node8_pedi,
    output                     node8_peso,
    input                      node8_pero,
    output [PACKET_SIZE-1:0]   node8_pedo,
    output                     node8_polarity,

    input                      node9_pesi,
    output                     node9_peri,
    input  [PACKET_SIZE-1:0]   node9_pedi,
    output                     node9_peso,
    input                      node9_pero,
    output [PACKET_SIZE-1:0]   node9_pedo,
    output                     node9_polarity,

    input                      node10_pesi,
    output                     node10_peri,
    input  [PACKET_SIZE-1:0]   node10_pedi,
    output                     node10_peso,
    input                      node10_pero,
    output [PACKET_SIZE-1:0]   node10_pedo,
    output                     node10_polarity,

    input                      node11_pesi,
    output                     node11_peri,
    input  [PACKET_SIZE-1:0]   node11_pedi,
    output                     node11_peso,
    input                      node11_pero,
    output [PACKET_SIZE-1:0]   node11_pedo,
    output                     node11_polarity,

    input                      node12_pesi,
    output                     node12_peri,
    input  [PACKET_SIZE-1:0]   node12_pedi,
    output                     node12_peso,
    input                      node12_pero,
    output [PACKET_SIZE-1:0]   node12_pedo,
    output                     node12_polarity,

    input                      node13_pesi,
    output                     node13_peri,
    input  [PACKET_SIZE-1:0]   node13_pedi,
    output                     node13_peso,
    input                      node13_pero,
    output [PACKET_SIZE-1:0]   node13_pedo,
    output                     node13_polarity,

    input                      node14_pesi,
    output                     node14_peri,
    input  [PACKET_SIZE-1:0]   node14_pedi,
    output                     node14_peso,
    input                      node14_pero,
    output [PACKET_SIZE-1:0]   node14_pedo,
    output                     node14_polarity,

    input                      node15_pesi,
    output                     node15_peri,
    input  [PACKET_SIZE-1:0]   node15_pedi,
    output                     node15_peso,
    input                      node15_pero,
    output [PACKET_SIZE-1:0]   node15_pedo,
    output                     node15_polarity
);

    // Internal channels for each router. Node n is at X=n%4, Y=n/4.
    // The outer mesh edges are closed: incoming valid is 0 and outgoing
    // ready is 0 at each boundary.
    wire [15:0] l2r_si, l2r_ri, l2r_so, l2r_ro;
    wire [PACKET_SIZE-1:0] l2r_di [0:15];
    wire [PACKET_SIZE-1:0] l2r_do [0:15];
    wire [15:0] r2l_si, r2l_ri, r2l_so, r2l_ro;
    wire [PACKET_SIZE-1:0] r2l_di [0:15];
    wire [PACKET_SIZE-1:0] r2l_do [0:15];
    wire [15:0] d2u_si, d2u_ri, d2u_so, d2u_ro;
    wire [PACKET_SIZE-1:0] d2u_di [0:15];
    wire [PACKET_SIZE-1:0] d2u_do [0:15];
    wire [15:0] u2d_si, u2d_ri, u2d_so, u2d_ro;
    wire [PACKET_SIZE-1:0] u2d_di [0:15];
    wire [PACKET_SIZE-1:0] u2d_do [0:15];

    genvar n;
    generate
        for (n = 0; n < 16; n = n + 1) begin : gen_mesh_links
            localparam X = n % 4;
            localparam Y = n / 4;

            // L2R travels east: receive from west, send to east.
            if (X == 0) begin : no_west_l2r
                assign l2r_si[n] = 1'b0;
                assign l2r_di[n] = {PACKET_SIZE{1'b0}};
            end
            else begin : from_west_l2r
                assign l2r_si[n] = l2r_so[n-1];
                assign l2r_di[n] = l2r_do[n-1];
            end
            if (X == 3) begin : no_east_l2r
                assign l2r_ro[n] = 1'b0;
            end
            else begin : to_east_l2r
                assign l2r_ro[n] = l2r_ri[n+1];
            end

            // R2L travels west: receive from east, send to west.
            if (X == 3) begin : no_east_r2l
                assign r2l_si[n] = 1'b0;
                assign r2l_di[n] = {PACKET_SIZE{1'b0}};
            end
            else begin : from_east_r2l
                assign r2l_si[n] = r2l_so[n+1];
                assign r2l_di[n] = r2l_do[n+1];
            end
            if (X == 0) begin : no_west_r2l
                assign r2l_ro[n] = 1'b0;
            end
            else begin : to_west_r2l
                assign r2l_ro[n] = r2l_ri[n-1];
            end

            // D2U travels north: receive from south, send to north.
            if (Y == 3) begin : no_south_d2u
                assign d2u_si[n] = 1'b0;
                assign d2u_di[n] = {PACKET_SIZE{1'b0}};
            end
            else begin : from_south_d2u
                assign d2u_si[n] = d2u_so[n+4];
                assign d2u_di[n] = d2u_do[n+4];
            end
            if (Y == 0) begin : no_north_d2u
                assign d2u_ro[n] = 1'b0;
            end
            else begin : to_north_d2u
                assign d2u_ro[n] = d2u_ri[n-4];
            end

            // U2D travels south: receive from north, send to south.
            if (Y == 0) begin : no_north_u2d
                assign u2d_si[n] = 1'b0;
                assign u2d_di[n] = {PACKET_SIZE{1'b0}};
            end
            else begin : from_north_u2d
                assign u2d_si[n] = u2d_so[n-4];
                assign u2d_di[n] = u2d_do[n-4];
            end
            if (Y == 3) begin : no_south_u2d
                assign u2d_ro[n] = 1'b0;
            end
            else begin : to_south_u2d
                assign u2d_ro[n] = u2d_ri[n+4];
            end
        end
    endgenerate

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(0)
    ) router_0 (
        .clk(clk),
        .reset(reset),
        .polarity(node0_polarity),
        .L2R_si(l2r_si[0]),
        .L2R_ri(l2r_ri[0]),
        .L2R_di(l2r_di[0]),
        .L2R_so(l2r_so[0]),
        .L2R_ro(l2r_ro[0]),
        .L2R_do(l2r_do[0]),
        .R2L_si(r2l_si[0]),
        .R2L_ri(r2l_ri[0]),
        .R2L_di(r2l_di[0]),
        .R2L_so(r2l_so[0]),
        .R2L_ro(r2l_ro[0]),
        .R2L_do(r2l_do[0]),
        .D2U_si(d2u_si[0]),
        .D2U_ri(d2u_ri[0]),
        .D2U_di(d2u_di[0]),
        .D2U_so(d2u_so[0]),
        .D2U_ro(d2u_ro[0]),
        .D2U_do(d2u_do[0]),
        .U2D_si(u2d_si[0]),
        .U2D_ri(u2d_ri[0]),
        .U2D_di(u2d_di[0]),
        .U2D_so(u2d_so[0]),
        .U2D_ro(u2d_ro[0]),
        .U2D_do(u2d_do[0]),
        .PE_si(node0_pesi),
        .PE_ri(node0_peri),
        .PE_di(node0_pedi),
        .PE_so(node0_peso),
        .PE_ro(node0_pero),
        .PE_do(node0_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(1)
    ) router_1 (
        .clk(clk),
        .reset(reset),
        .polarity(node1_polarity),
        .L2R_si(l2r_si[1]),
        .L2R_ri(l2r_ri[1]),
        .L2R_di(l2r_di[1]),
        .L2R_so(l2r_so[1]),
        .L2R_ro(l2r_ro[1]),
        .L2R_do(l2r_do[1]),
        .R2L_si(r2l_si[1]),
        .R2L_ri(r2l_ri[1]),
        .R2L_di(r2l_di[1]),
        .R2L_so(r2l_so[1]),
        .R2L_ro(r2l_ro[1]),
        .R2L_do(r2l_do[1]),
        .D2U_si(d2u_si[1]),
        .D2U_ri(d2u_ri[1]),
        .D2U_di(d2u_di[1]),
        .D2U_so(d2u_so[1]),
        .D2U_ro(d2u_ro[1]),
        .D2U_do(d2u_do[1]),
        .U2D_si(u2d_si[1]),
        .U2D_ri(u2d_ri[1]),
        .U2D_di(u2d_di[1]),
        .U2D_so(u2d_so[1]),
        .U2D_ro(u2d_ro[1]),
        .U2D_do(u2d_do[1]),
        .PE_si(node1_pesi),
        .PE_ri(node1_peri),
        .PE_di(node1_pedi),
        .PE_so(node1_peso),
        .PE_ro(node1_pero),
        .PE_do(node1_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(2)
    ) router_2 (
        .clk(clk),
        .reset(reset),
        .polarity(node2_polarity),
        .L2R_si(l2r_si[2]),
        .L2R_ri(l2r_ri[2]),
        .L2R_di(l2r_di[2]),
        .L2R_so(l2r_so[2]),
        .L2R_ro(l2r_ro[2]),
        .L2R_do(l2r_do[2]),
        .R2L_si(r2l_si[2]),
        .R2L_ri(r2l_ri[2]),
        .R2L_di(r2l_di[2]),
        .R2L_so(r2l_so[2]),
        .R2L_ro(r2l_ro[2]),
        .R2L_do(r2l_do[2]),
        .D2U_si(d2u_si[2]),
        .D2U_ri(d2u_ri[2]),
        .D2U_di(d2u_di[2]),
        .D2U_so(d2u_so[2]),
        .D2U_ro(d2u_ro[2]),
        .D2U_do(d2u_do[2]),
        .U2D_si(u2d_si[2]),
        .U2D_ri(u2d_ri[2]),
        .U2D_di(u2d_di[2]),
        .U2D_so(u2d_so[2]),
        .U2D_ro(u2d_ro[2]),
        .U2D_do(u2d_do[2]),
        .PE_si(node2_pesi),
        .PE_ri(node2_peri),
        .PE_di(node2_pedi),
        .PE_so(node2_peso),
        .PE_ro(node2_pero),
        .PE_do(node2_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(3)
    ) router_3 (
        .clk(clk),
        .reset(reset),
        .polarity(node3_polarity),
        .L2R_si(l2r_si[3]),
        .L2R_ri(l2r_ri[3]),
        .L2R_di(l2r_di[3]),
        .L2R_so(l2r_so[3]),
        .L2R_ro(l2r_ro[3]),
        .L2R_do(l2r_do[3]),
        .R2L_si(r2l_si[3]),
        .R2L_ri(r2l_ri[3]),
        .R2L_di(r2l_di[3]),
        .R2L_so(r2l_so[3]),
        .R2L_ro(r2l_ro[3]),
        .R2L_do(r2l_do[3]),
        .D2U_si(d2u_si[3]),
        .D2U_ri(d2u_ri[3]),
        .D2U_di(d2u_di[3]),
        .D2U_so(d2u_so[3]),
        .D2U_ro(d2u_ro[3]),
        .D2U_do(d2u_do[3]),
        .U2D_si(u2d_si[3]),
        .U2D_ri(u2d_ri[3]),
        .U2D_di(u2d_di[3]),
        .U2D_so(u2d_so[3]),
        .U2D_ro(u2d_ro[3]),
        .U2D_do(u2d_do[3]),
        .PE_si(node3_pesi),
        .PE_ri(node3_peri),
        .PE_di(node3_pedi),
        .PE_so(node3_peso),
        .PE_ro(node3_pero),
        .PE_do(node3_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(4)
    ) router_4 (
        .clk(clk),
        .reset(reset),
        .polarity(node4_polarity),
        .L2R_si(l2r_si[4]),
        .L2R_ri(l2r_ri[4]),
        .L2R_di(l2r_di[4]),
        .L2R_so(l2r_so[4]),
        .L2R_ro(l2r_ro[4]),
        .L2R_do(l2r_do[4]),
        .R2L_si(r2l_si[4]),
        .R2L_ri(r2l_ri[4]),
        .R2L_di(r2l_di[4]),
        .R2L_so(r2l_so[4]),
        .R2L_ro(r2l_ro[4]),
        .R2L_do(r2l_do[4]),
        .D2U_si(d2u_si[4]),
        .D2U_ri(d2u_ri[4]),
        .D2U_di(d2u_di[4]),
        .D2U_so(d2u_so[4]),
        .D2U_ro(d2u_ro[4]),
        .D2U_do(d2u_do[4]),
        .U2D_si(u2d_si[4]),
        .U2D_ri(u2d_ri[4]),
        .U2D_di(u2d_di[4]),
        .U2D_so(u2d_so[4]),
        .U2D_ro(u2d_ro[4]),
        .U2D_do(u2d_do[4]),
        .PE_si(node4_pesi),
        .PE_ri(node4_peri),
        .PE_di(node4_pedi),
        .PE_so(node4_peso),
        .PE_ro(node4_pero),
        .PE_do(node4_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(5)
    ) router_5 (
        .clk(clk),
        .reset(reset),
        .polarity(node5_polarity),
        .L2R_si(l2r_si[5]),
        .L2R_ri(l2r_ri[5]),
        .L2R_di(l2r_di[5]),
        .L2R_so(l2r_so[5]),
        .L2R_ro(l2r_ro[5]),
        .L2R_do(l2r_do[5]),
        .R2L_si(r2l_si[5]),
        .R2L_ri(r2l_ri[5]),
        .R2L_di(r2l_di[5]),
        .R2L_so(r2l_so[5]),
        .R2L_ro(r2l_ro[5]),
        .R2L_do(r2l_do[5]),
        .D2U_si(d2u_si[5]),
        .D2U_ri(d2u_ri[5]),
        .D2U_di(d2u_di[5]),
        .D2U_so(d2u_so[5]),
        .D2U_ro(d2u_ro[5]),
        .D2U_do(d2u_do[5]),
        .U2D_si(u2d_si[5]),
        .U2D_ri(u2d_ri[5]),
        .U2D_di(u2d_di[5]),
        .U2D_so(u2d_so[5]),
        .U2D_ro(u2d_ro[5]),
        .U2D_do(u2d_do[5]),
        .PE_si(node5_pesi),
        .PE_ri(node5_peri),
        .PE_di(node5_pedi),
        .PE_so(node5_peso),
        .PE_ro(node5_pero),
        .PE_do(node5_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(6)
    ) router_6 (
        .clk(clk),
        .reset(reset),
        .polarity(node6_polarity),
        .L2R_si(l2r_si[6]),
        .L2R_ri(l2r_ri[6]),
        .L2R_di(l2r_di[6]),
        .L2R_so(l2r_so[6]),
        .L2R_ro(l2r_ro[6]),
        .L2R_do(l2r_do[6]),
        .R2L_si(r2l_si[6]),
        .R2L_ri(r2l_ri[6]),
        .R2L_di(r2l_di[6]),
        .R2L_so(r2l_so[6]),
        .R2L_ro(r2l_ro[6]),
        .R2L_do(r2l_do[6]),
        .D2U_si(d2u_si[6]),
        .D2U_ri(d2u_ri[6]),
        .D2U_di(d2u_di[6]),
        .D2U_so(d2u_so[6]),
        .D2U_ro(d2u_ro[6]),
        .D2U_do(d2u_do[6]),
        .U2D_si(u2d_si[6]),
        .U2D_ri(u2d_ri[6]),
        .U2D_di(u2d_di[6]),
        .U2D_so(u2d_so[6]),
        .U2D_ro(u2d_ro[6]),
        .U2D_do(u2d_do[6]),
        .PE_si(node6_pesi),
        .PE_ri(node6_peri),
        .PE_di(node6_pedi),
        .PE_so(node6_peso),
        .PE_ro(node6_pero),
        .PE_do(node6_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(7)
    ) router_7 (
        .clk(clk),
        .reset(reset),
        .polarity(node7_polarity),
        .L2R_si(l2r_si[7]),
        .L2R_ri(l2r_ri[7]),
        .L2R_di(l2r_di[7]),
        .L2R_so(l2r_so[7]),
        .L2R_ro(l2r_ro[7]),
        .L2R_do(l2r_do[7]),
        .R2L_si(r2l_si[7]),
        .R2L_ri(r2l_ri[7]),
        .R2L_di(r2l_di[7]),
        .R2L_so(r2l_so[7]),
        .R2L_ro(r2l_ro[7]),
        .R2L_do(r2l_do[7]),
        .D2U_si(d2u_si[7]),
        .D2U_ri(d2u_ri[7]),
        .D2U_di(d2u_di[7]),
        .D2U_so(d2u_so[7]),
        .D2U_ro(d2u_ro[7]),
        .D2U_do(d2u_do[7]),
        .U2D_si(u2d_si[7]),
        .U2D_ri(u2d_ri[7]),
        .U2D_di(u2d_di[7]),
        .U2D_so(u2d_so[7]),
        .U2D_ro(u2d_ro[7]),
        .U2D_do(u2d_do[7]),
        .PE_si(node7_pesi),
        .PE_ri(node7_peri),
        .PE_di(node7_pedi),
        .PE_so(node7_peso),
        .PE_ro(node7_pero),
        .PE_do(node7_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(8)
    ) router_8 (
        .clk(clk),
        .reset(reset),
        .polarity(node8_polarity),
        .L2R_si(l2r_si[8]),
        .L2R_ri(l2r_ri[8]),
        .L2R_di(l2r_di[8]),
        .L2R_so(l2r_so[8]),
        .L2R_ro(l2r_ro[8]),
        .L2R_do(l2r_do[8]),
        .R2L_si(r2l_si[8]),
        .R2L_ri(r2l_ri[8]),
        .R2L_di(r2l_di[8]),
        .R2L_so(r2l_so[8]),
        .R2L_ro(r2l_ro[8]),
        .R2L_do(r2l_do[8]),
        .D2U_si(d2u_si[8]),
        .D2U_ri(d2u_ri[8]),
        .D2U_di(d2u_di[8]),
        .D2U_so(d2u_so[8]),
        .D2U_ro(d2u_ro[8]),
        .D2U_do(d2u_do[8]),
        .U2D_si(u2d_si[8]),
        .U2D_ri(u2d_ri[8]),
        .U2D_di(u2d_di[8]),
        .U2D_so(u2d_so[8]),
        .U2D_ro(u2d_ro[8]),
        .U2D_do(u2d_do[8]),
        .PE_si(node8_pesi),
        .PE_ri(node8_peri),
        .PE_di(node8_pedi),
        .PE_so(node8_peso),
        .PE_ro(node8_pero),
        .PE_do(node8_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(9)
    ) router_9 (
        .clk(clk),
        .reset(reset),
        .polarity(node9_polarity),
        .L2R_si(l2r_si[9]),
        .L2R_ri(l2r_ri[9]),
        .L2R_di(l2r_di[9]),
        .L2R_so(l2r_so[9]),
        .L2R_ro(l2r_ro[9]),
        .L2R_do(l2r_do[9]),
        .R2L_si(r2l_si[9]),
        .R2L_ri(r2l_ri[9]),
        .R2L_di(r2l_di[9]),
        .R2L_so(r2l_so[9]),
        .R2L_ro(r2l_ro[9]),
        .R2L_do(r2l_do[9]),
        .D2U_si(d2u_si[9]),
        .D2U_ri(d2u_ri[9]),
        .D2U_di(d2u_di[9]),
        .D2U_so(d2u_so[9]),
        .D2U_ro(d2u_ro[9]),
        .D2U_do(d2u_do[9]),
        .U2D_si(u2d_si[9]),
        .U2D_ri(u2d_ri[9]),
        .U2D_di(u2d_di[9]),
        .U2D_so(u2d_so[9]),
        .U2D_ro(u2d_ro[9]),
        .U2D_do(u2d_do[9]),
        .PE_si(node9_pesi),
        .PE_ri(node9_peri),
        .PE_di(node9_pedi),
        .PE_so(node9_peso),
        .PE_ro(node9_pero),
        .PE_do(node9_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(10)
    ) router_10 (
        .clk(clk),
        .reset(reset),
        .polarity(node10_polarity),
        .L2R_si(l2r_si[10]),
        .L2R_ri(l2r_ri[10]),
        .L2R_di(l2r_di[10]),
        .L2R_so(l2r_so[10]),
        .L2R_ro(l2r_ro[10]),
        .L2R_do(l2r_do[10]),
        .R2L_si(r2l_si[10]),
        .R2L_ri(r2l_ri[10]),
        .R2L_di(r2l_di[10]),
        .R2L_so(r2l_so[10]),
        .R2L_ro(r2l_ro[10]),
        .R2L_do(r2l_do[10]),
        .D2U_si(d2u_si[10]),
        .D2U_ri(d2u_ri[10]),
        .D2U_di(d2u_di[10]),
        .D2U_so(d2u_so[10]),
        .D2U_ro(d2u_ro[10]),
        .D2U_do(d2u_do[10]),
        .U2D_si(u2d_si[10]),
        .U2D_ri(u2d_ri[10]),
        .U2D_di(u2d_di[10]),
        .U2D_so(u2d_so[10]),
        .U2D_ro(u2d_ro[10]),
        .U2D_do(u2d_do[10]),
        .PE_si(node10_pesi),
        .PE_ri(node10_peri),
        .PE_di(node10_pedi),
        .PE_so(node10_peso),
        .PE_ro(node10_pero),
        .PE_do(node10_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(11)
    ) router_11 (
        .clk(clk),
        .reset(reset),
        .polarity(node11_polarity),
        .L2R_si(l2r_si[11]),
        .L2R_ri(l2r_ri[11]),
        .L2R_di(l2r_di[11]),
        .L2R_so(l2r_so[11]),
        .L2R_ro(l2r_ro[11]),
        .L2R_do(l2r_do[11]),
        .R2L_si(r2l_si[11]),
        .R2L_ri(r2l_ri[11]),
        .R2L_di(r2l_di[11]),
        .R2L_so(r2l_so[11]),
        .R2L_ro(r2l_ro[11]),
        .R2L_do(r2l_do[11]),
        .D2U_si(d2u_si[11]),
        .D2U_ri(d2u_ri[11]),
        .D2U_di(d2u_di[11]),
        .D2U_so(d2u_so[11]),
        .D2U_ro(d2u_ro[11]),
        .D2U_do(d2u_do[11]),
        .U2D_si(u2d_si[11]),
        .U2D_ri(u2d_ri[11]),
        .U2D_di(u2d_di[11]),
        .U2D_so(u2d_so[11]),
        .U2D_ro(u2d_ro[11]),
        .U2D_do(u2d_do[11]),
        .PE_si(node11_pesi),
        .PE_ri(node11_peri),
        .PE_di(node11_pedi),
        .PE_so(node11_peso),
        .PE_ro(node11_pero),
        .PE_do(node11_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(12)
    ) router_12 (
        .clk(clk),
        .reset(reset),
        .polarity(node12_polarity),
        .L2R_si(l2r_si[12]),
        .L2R_ri(l2r_ri[12]),
        .L2R_di(l2r_di[12]),
        .L2R_so(l2r_so[12]),
        .L2R_ro(l2r_ro[12]),
        .L2R_do(l2r_do[12]),
        .R2L_si(r2l_si[12]),
        .R2L_ri(r2l_ri[12]),
        .R2L_di(r2l_di[12]),
        .R2L_so(r2l_so[12]),
        .R2L_ro(r2l_ro[12]),
        .R2L_do(r2l_do[12]),
        .D2U_si(d2u_si[12]),
        .D2U_ri(d2u_ri[12]),
        .D2U_di(d2u_di[12]),
        .D2U_so(d2u_so[12]),
        .D2U_ro(d2u_ro[12]),
        .D2U_do(d2u_do[12]),
        .U2D_si(u2d_si[12]),
        .U2D_ri(u2d_ri[12]),
        .U2D_di(u2d_di[12]),
        .U2D_so(u2d_so[12]),
        .U2D_ro(u2d_ro[12]),
        .U2D_do(u2d_do[12]),
        .PE_si(node12_pesi),
        .PE_ri(node12_peri),
        .PE_di(node12_pedi),
        .PE_so(node12_peso),
        .PE_ro(node12_pero),
        .PE_do(node12_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(13)
    ) router_13 (
        .clk(clk),
        .reset(reset),
        .polarity(node13_polarity),
        .L2R_si(l2r_si[13]),
        .L2R_ri(l2r_ri[13]),
        .L2R_di(l2r_di[13]),
        .L2R_so(l2r_so[13]),
        .L2R_ro(l2r_ro[13]),
        .L2R_do(l2r_do[13]),
        .R2L_si(r2l_si[13]),
        .R2L_ri(r2l_ri[13]),
        .R2L_di(r2l_di[13]),
        .R2L_so(r2l_so[13]),
        .R2L_ro(r2l_ro[13]),
        .R2L_do(r2l_do[13]),
        .D2U_si(d2u_si[13]),
        .D2U_ri(d2u_ri[13]),
        .D2U_di(d2u_di[13]),
        .D2U_so(d2u_so[13]),
        .D2U_ro(d2u_ro[13]),
        .D2U_do(d2u_do[13]),
        .U2D_si(u2d_si[13]),
        .U2D_ri(u2d_ri[13]),
        .U2D_di(u2d_di[13]),
        .U2D_so(u2d_so[13]),
        .U2D_ro(u2d_ro[13]),
        .U2D_do(u2d_do[13]),
        .PE_si(node13_pesi),
        .PE_ri(node13_peri),
        .PE_di(node13_pedi),
        .PE_so(node13_peso),
        .PE_ro(node13_pero),
        .PE_do(node13_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(14)
    ) router_14 (
        .clk(clk),
        .reset(reset),
        .polarity(node14_polarity),
        .L2R_si(l2r_si[14]),
        .L2R_ri(l2r_ri[14]),
        .L2R_di(l2r_di[14]),
        .L2R_so(l2r_so[14]),
        .L2R_ro(l2r_ro[14]),
        .L2R_do(l2r_do[14]),
        .R2L_si(r2l_si[14]),
        .R2L_ri(r2l_ri[14]),
        .R2L_di(r2l_di[14]),
        .R2L_so(r2l_so[14]),
        .R2L_ro(r2l_ro[14]),
        .R2L_do(r2l_do[14]),
        .D2U_si(d2u_si[14]),
        .D2U_ri(d2u_ri[14]),
        .D2U_di(d2u_di[14]),
        .D2U_so(d2u_so[14]),
        .D2U_ro(d2u_ro[14]),
        .D2U_do(d2u_do[14]),
        .U2D_si(u2d_si[14]),
        .U2D_ri(u2d_ri[14]),
        .U2D_di(u2d_di[14]),
        .U2D_so(u2d_so[14]),
        .U2D_ro(u2d_ro[14]),
        .U2D_do(u2d_do[14]),
        .PE_si(node14_pesi),
        .PE_ri(node14_peri),
        .PE_di(node14_pedi),
        .PE_so(node14_peso),
        .PE_ro(node14_pero),
        .PE_do(node14_pedo)
    );

    gold_router #(
        .PACKET_SIZE(PACKET_SIZE),
        .NODE_NUMBER(15)
    ) router_15 (
        .clk(clk),
        .reset(reset),
        .polarity(node15_polarity),
        .L2R_si(l2r_si[15]),
        .L2R_ri(l2r_ri[15]),
        .L2R_di(l2r_di[15]),
        .L2R_so(l2r_so[15]),
        .L2R_ro(l2r_ro[15]),
        .L2R_do(l2r_do[15]),
        .R2L_si(r2l_si[15]),
        .R2L_ri(r2l_ri[15]),
        .R2L_di(r2l_di[15]),
        .R2L_so(r2l_so[15]),
        .R2L_ro(r2l_ro[15]),
        .R2L_do(r2l_do[15]),
        .D2U_si(d2u_si[15]),
        .D2U_ri(d2u_ri[15]),
        .D2U_di(d2u_di[15]),
        .D2U_so(d2u_so[15]),
        .D2U_ro(d2u_ro[15]),
        .D2U_do(d2u_do[15]),
        .U2D_si(u2d_si[15]),
        .U2D_ri(u2d_ri[15]),
        .U2D_di(u2d_di[15]),
        .U2D_so(u2d_so[15]),
        .U2D_ro(u2d_ro[15]),
        .U2D_do(u2d_do[15]),
        .PE_si(node15_pesi),
        .PE_ri(node15_peri),
        .PE_di(node15_pedi),
        .PE_so(node15_peso),
        .PE_ro(node15_pero),
        .PE_do(node15_pedo)
    );

endmodule

