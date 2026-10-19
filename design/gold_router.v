module gold_router #(
    parameter PACKET_SIZE = 64,
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0

)(
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
    PE_so, PE_ro, PE_do
);

    localparam L2R = 4;
    localparam R2L = 3;
    localparam D2U = 2;
    localparam U2D = 1;
    localparam PE  = 0;

    /*
    Bits (P=64)   Bits (general)   Field            Value written by the testbench
    -----------   --------------   --------------   ---------------------------------
    [63]          [P-1]            VC               0 = VC0, 1 = VC1
    [62]          [P-2]            reserved         0
    [61:60]       [P-3:P-4]        destination x    D % 4  (D = destination node)
    [59:58]       [P-5:P-6]        destination y    D / 4
    [57:56]       [P-7:P-8]        reserved         0
    [55:48]       [P-9:P-16]       hop field        (1 << H) - 1, H = |dx| + |dy|
    [47:32]       [P-17:P-32]      source           source node number S (0..15)
    [31:0]        [P-33:0]         payload          unique packet ID
    */

    // Single-bit fields
    localparam VC_BIT          = PACKET_SIZE - 1;
    localparam RESERVED_BIT    = PACKET_SIZE - 2;

    // Destination coordinates
    localparam DEST_X_MSB      = PACKET_SIZE - 3;
    localparam DEST_X_LSB      = PACKET_SIZE - 4;
    localparam DEST_Y_MSB      = PACKET_SIZE - 5;
    localparam DEST_Y_LSB      = PACKET_SIZE - 6;

    // Reserved bits
    localparam RESERVED_MSB    = PACKET_SIZE - 7;
    localparam RESERVED_LSB    = PACKET_SIZE - 8;

    // Hop field
    localparam HOP_MSB         = PACKET_SIZE - 9;
    localparam HOP_LSB         = PACKET_SIZE - 16;

    // Source node ID
    localparam SOURCE_MSB      = PACKET_SIZE - 17;
    localparam SOURCE_LSB      = PACKET_SIZE - 32;

    // Payload
    localparam PAYLOAD_MSB     = PACKET_SIZE - 33;

    input                    clk, reset;

    // 0 for even polarity, 1 for odd polarity
    // int_vc = polarity, ext_vc = ~polarity

    output reg               polarity;
    wire                     int_vc = polarity;  
    wire                     ext_vc = ~polarity; 

    input                    PE_si, L2R_si, R2L_si, D2U_si, U2D_si; // channel telling router that the packet is valid
    input [PACKET_SIZE-1:0]  PE_di, L2R_di, R2L_di, D2U_di, U2D_di; // input packet data
    output reg               PE_ri, L2R_ri, R2L_ri, D2U_ri, U2D_ri; // router telling channel that buffer is empty, can accept

    output reg                   PE_so, L2R_so, R2L_so, D2U_so, U2D_so; // router telling channel it has packet to send
    output reg [PACKET_SIZE-1:0] PE_do, L2R_do, R2L_do, D2U_do, U2D_do; // output packet data
    input                        PE_ro, L2R_ro, R2L_ro, D2U_ro, U2D_ro; // channel telling router it can accept packet

    // polarity control
    always @(posedge clk) begin
        if(reset)   polarity <= 0;
        else        polarity <= ~polarity;
    end

    // 10 input buffers
    wire [4:0] in_buf_full_vc0;
    wire [4:0] in_buf_full_vc1;

    reg  [4:0] in_buf_we_vc0;
    reg  [4:0] in_buf_we_vc1;

    reg  [4:0] in_buf_re_vc0;
    reg  [4:0] in_buf_re_vc1;

    wire [PACKET_SIZE-1:0] in_buf_do_vc0[4:0];
    wire [PACKET_SIZE-1:0] in_buf_do_vc1[4:0];

    // ri
    always@(*) begin
        L2R_ri = ext_vc ? !in_buf_full_vc1[L2R] : !in_buf_full_vc0[L2R];
        R2L_ri = ext_vc ? !in_buf_full_vc1[R2L] : !in_buf_full_vc0[R2L];
        D2U_ri = ext_vc ? !in_buf_full_vc1[D2U] : !in_buf_full_vc0[D2U];
        U2D_ri = ext_vc ? !in_buf_full_vc1[U2D] : !in_buf_full_vc0[U2D];
        PE_ri  = ext_vc ? !in_buf_full_vc1[PE]  : !in_buf_full_vc0[PE];
    end

    // we for in_buf
    always@(*) begin
        if(ext_vc == 1'b0) begin
            if(L2R_si && L2R_ri) in_buf_we_vc0[L2R] = 1'b1;
            else                 in_buf_we_vc0[L2R] = 1'b0;

            if(R2L_si && R2L_ri) in_buf_we_vc0[R2L] = 1'b1;
            else                 in_buf_we_vc0[R2L] = 1'b0;

            if(D2U_si && D2U_ri) in_buf_we_vc0[D2U] = 1'b1;
            else                 in_buf_we_vc0[D2U] = 1'b0;

            if(U2D_si && U2D_ri) in_buf_we_vc0[U2D] = 1'b1;
            else                 in_buf_we_vc0[U2D] = 1'b0;

            if(PE_si && PE_ri)   in_buf_we_vc0[PE]  = 1'b1;
            else                 in_buf_we_vc0[PE]  = 1'b0;
        end
        else begin
            if(L2R_si && L2R_ri) in_buf_we_vc1[L2R] = 1'b1;
            else                 in_buf_we_vc1[L2R] = 1'b0;

            if(R2L_si && R2L_ri) in_buf_we_vc1[R2L] = 1'b1;
            else                 in_buf_we_vc1[R2L] = 1'b0;

            if(D2U_si && D2U_ri) in_buf_we_vc1[D2U] = 1'b1;
            else                 in_buf_we_vc1[D2U] = 1'b0;

            if(U2D_si && U2D_ri) in_buf_we_vc1[U2D] = 1'b1;
            else                 in_buf_we_vc1[U2D] = 1'b0;

            if(PE_si && PE_ri)   in_buf_we_vc1[PE]  = 1'b1;
            else                 in_buf_we_vc1[PE]  = 1'b0;
        end
    end

    // vc0 input buffers
    buffer in_buf_L2R_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[L2R]), 
        .re(in_buf_re_vc0[L2R]),
        .data_in(L2R_di),
        .full(in_buf_full_vc0[L2R]), 
        .data_out(in_buf_do_vc0[L2R])
    );

    buffer in_buf_R2L_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[R2L]), 
        .re(in_buf_re_vc0[R2L]),
        .data_in(R2L_di),
        .full(in_buf_full_vc0[R2L]), 
        .data_out(in_buf_do_vc0[R2L])
    );

    buffer in_buf_D2U_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[D2U]), 
        .re(in_buf_re_vc0[D2U]),
        .data_in(D2U_di),
        .full(in_buf_full_vc0[D2U]), 
        .data_out(in_buf_do_vc0[D2U])
    );

    buffer in_buf_U2D_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[U2D]), 
        .re(in_buf_re_vc0[U2D]),
        .data_in(U2D_di),
        .full(in_buf_full_vc0[U2D]), 
        .data_out(in_buf_do_vc0[U2D])
    );

    buffer in_buf_PE_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[PE]), 
        .re(in_buf_re_vc0[PE]),
        .data_in(PE_di),
        .full(in_buf_full_vc0[PE]), 
        .data_out(in_buf_do_vc0[PE])
    );

    //vc1 input buffers
    buffer in_buf_L2R_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[L2R]), 
        .re(in_buf_re_vc1[L2R]),
        .data_in(L2R_di),
        .full(in_buf_full_vc1[L2R]), 
        .data_out(in_buf_do_vc1[L2R])
    );

    buffer in_buf_R2L_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[R2L]), 
        .re(in_buf_re_vc1[R2L]),
        .data_in(R2L_di),
        .full(in_buf_full_vc1[R2L]), 
        .data_out(in_buf_do_vc1[R2L])
    );

    buffer in_buf_D2U_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[D2U]), 
        .re(in_buf_re_vc1[D2U]),
        .data_in(D2U_di),
        .full(in_buf_full_vc1[D2U]), 
        .data_out(in_buf_do_vc1[D2U])
    );

    buffer in_buf_U2D_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[U2D]), 
        .re(in_buf_re_vc1[U2D]),
        .data_in(U2D_di),
        .full(in_buf_full_vc1[U2D]), 
        .data_out(in_buf_do_vc1[U2D])
    );

    buffer in_buf_PE_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[PE]), 
        .re(in_buf_re_vc1[PE]),
        .data_in(PE_di),
        .full(in_buf_full_vc1[PE]), 
        .data_out(in_buf_do_vc1[PE])
    );

    // input buffers requesting signals
    reg req_L2R_L2R, req_L2R_D2U, req_L2R_U2D, req_L2R_PE;
    reg req_R2L_R2L, req_R2L_D2U, req_R2L_U2D, req_R2L_PE;
    reg req_D2U_D2U, req_D2U_PE;
    reg req_U2D_U2D, req_U2D_PE;
    reg req_PE_L2R,  req_PE_R2L,  req_PE_D2U,  req_PE_U2D;

    // grant signals
    wire grant_L2R_L2R, grant_PE_L2R;
    wire grant_R2L_R2L, grant_PE_R2L;
    wire grant_D2U_D2U, grant_L2R_D2U, grant_R2L_D2U, grant_PE_D2U;
    wire grant_U2D_U2D, grant_L2R_U2D, grant_R2L_U2D, grant_PE_U2D;
    wire grant_L2R_PE,  grant_R2L_PE,  grant_D2U_PE,  grant_U2D_PE;

    arbiter arbiter_out_buf_L2R
    (
        .clk(clk),
        .reset(reset),
        .int_vc(int_vc),
        .req_0(1'b0), 
        .req_1(1'b0), 
        .req_2(req_L2R_L2R), 
        .req_3(req_PE_L2R),
        .grant_0(), 
        .grant_1(), 
        .grant_2(grant_L2R_L2R), 
        .grant_3(grant_PE_L2R)
    );

    arbiter arbiter_out_buf_R2L
    (
        .clk(clk),
        .reset(reset),
        .int_vc(int_vc),
        .req_0(1'b0), 
        .req_1(1'b0), 
        .req_2(req_R2L_R2L), 
        .req_3(req_PE_R2L),
        .grant_0(), 
        .grant_1(), 
        .grant_2(grant_R2L_R2L), 
        .grant_3(grant_PE_R2L)
    );

    arbiter arbiter_out_buf_D2U
    (
        .clk(clk),
        .reset(reset),
        .int_vc(int_vc),
        .req_0(req_D2U_D2U), 
        .req_1(req_R2L_D2U), 
        .req_2(req_L2R_D2U), 
        .req_3(req_PE_D2U),
        .grant_0(grant_D2U_D2U), 
        .grant_1(grant_L2R_D2U), 
        .grant_2(grant_R2L_D2U), 
        .grant_3(grant_PE_D2U)
    );

    arbiter arbiter_out_buf_U2D
    (
        .clk(clk),
        .reset(reset),
        .int_vc(int_vc),
        .req_0(req_U2D_U2D), 
        .req_1(req_R2L_U2D), 
        .req_2(req_L2R_U2D), 
        .req_3(req_PE_U2D),
        .grant_0(grant_U2D_U2D), 
        .grant_1(grant_L2R_U2D), 
        .grant_2(grant_R2L_U2D), 
        .grant_3(grant_PE_U2D)
    );

    arbiter arbiter_out_buf_PE
    (
        .clk(clk),
        .reset(reset),
        .int_vc(int_vc),
        .req_0(req_U2D_PE), 
        .req_1(req_D2U_PE), 
        .req_2(req_R2L_PE), 
        .req_3(req_L2R_PE),
        .grant_0(grant_U2D_PE), 
        .grant_1(grant_D2U_PE), 
        .grant_2(grant_R2L_PE), 
        .grant_3(grant_L2R_PE)
    );

    wire [4:0] out_buf_full_vc0;
    wire [4:0] out_buf_full_vc1;

    reg  [4:0] out_buf_we_vc0;
    reg  [4:0] out_buf_we_vc1;

    reg  [4:0] out_buf_re_vc0;
    reg  [4:0] out_buf_re_vc1;

    reg  [PACKET_SIZE-1:0] out_buf_di_vc0[4:0];
    reg  [PACKET_SIZE-1:0] out_buf_di_vc1[4:0];

    wire [PACKET_SIZE-1:0] out_buf_do_vc0[4:0];
    wire [PACKET_SIZE-1:0] out_buf_do_vc1[4:0];

    // input forwarding to output buffers
    always@(*) begin

        {req_L2R_L2R, req_L2R_D2U, req_L2R_U2D, req_L2R_PE} = 4'd0;
        {req_R2L_R2L, req_R2L_D2U, req_R2L_U2D, req_R2L_PE} = 4'd0;
        {req_D2U_D2U, req_D2U_PE}                           = 2'd0;
        {req_U2D_U2D, req_U2D_PE}                           = 2'd0;
        {req_PE_L2R,  req_PE_R2L,  req_PE_D2U,  req_PE_U2D} = 4'd0;

        ///////////////////////////
        /////////  vc0  ///////////
        ///////////////////////////

        if(int_vc == 1'b0) begin

            // L2R vc0 request logic
            if(!out_buf_full_vc0[L2R] &&
            in_buf_full_vc0[L2R] &&
            in_buf_do_vc0[L2R][HOP_LSB] &&
            in_buf_do_vc0[L2R][DEST_X_MSB:DEST_X_LSB] > ROUTER_X) begin
                req_L2R_L2R = 1'b1;
            end

            else if(!out_buf_full_vc0[U2D] &&
            in_buf_full_vc0[L2R] &&
            in_buf_do_vc0[L2R][HOP_LSB] &&
            in_buf_do_vc0[L2R][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_L2R_U2D = 1'b1;
            end

            else if(!out_buf_full_vc0[D2U] &&
            in_buf_full_vc0[L2R] &&
            in_buf_do_vc0[L2R][HOP_LSB] &&
            in_buf_do_vc0[L2R][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_L2R_D2U = 1'b1;
            end

            else if(!out_buf_full_vc0[PE] &&
            in_buf_full_vc0[L2R] &&
            in_buf_do_vc0[L2R][HOP_LSB] == 1'b0) begin
                req_L2R_PE = 1'b1;
            end

            //////////////////////////////////////////

            // R2L vc0 request logic
            if(!out_buf_full_vc0[R2L] &&
            in_buf_full_vc0[R2L] &&
            in_buf_do_vc0[R2L][HOP_LSB] &&
            in_buf_do_vc0[R2L][DEST_X_MSB:DEST_X_LSB] < ROUTER_X) begin
                req_R2L_R2L = 1'b1;
            end

            else if(!out_buf_full_vc0[U2D] &&
            in_buf_full_vc0[R2L] &&
            in_buf_do_vc0[R2L][HOP_LSB] &&
            in_buf_do_vc0[R2L][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_R2L_U2D = 1'b1;
            end

            else if(!out_buf_full_vc0[D2U] &&
            in_buf_full_vc0[R2L] &&
            in_buf_do_vc0[R2L][HOP_LSB] &&
            in_buf_do_vc0[R2L][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_R2L_D2U = 1'b1;
            end

            else if(!out_buf_full_vc0[PE] &&
            in_buf_full_vc0[R2L] &&
            in_buf_do_vc0[R2L][HOP_LSB] == 1'b0) begin
                req_R2L_PE = 1'b1;
            end

            //////////////////////////////////////////

            // D2U vc0 request logic
            if(!out_buf_full_vc0[D2U] &&
            in_buf_full_vc0[D2U] &&
            in_buf_do_vc0[D2U][HOP_LSB] &&
            in_buf_do_vc0[D2U][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_D2U_D2U = 1'b1;
            end

            else if(!out_buf_full_vc0[PE] &&
            in_buf_full_vc0[D2U] &&
            in_buf_do_vc0[D2U][HOP_LSB] == 1'b0) begin
                req_D2U_PE = 1'b1;
            end

            //////////////////////////////////////////

            // U2D vc0 request logic
            if(!out_buf_full_vc0[U2D] &&
            in_buf_full_vc0[U2D] &&
            in_buf_do_vc0[U2D][HOP_LSB] &&
            in_buf_do_vc0[U2D][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_U2D_U2D = 1'b1;
            end

            else if(!out_buf_full_vc0[PE] &&
            in_buf_full_vc0[U2D] &&
            in_buf_do_vc0[U2D][HOP_LSB] == 1'b0) begin
                req_U2D_PE = 1'b1;
            end

            //////////////////////////////////////////

            // PE vc0 request logic
            if(!out_buf_full_vc0[L2R] &&
            in_buf_full_vc0[PE] &&
            in_buf_do_vc0[PE][HOP_LSB] &&
            in_buf_do_vc0[PE][DEST_X_MSB:DEST_X_LSB] > ROUTER_X) begin
                req_PE_L2R = 1'b1;
            end

            else if(!out_buf_full_vc0[R2L] &&
            in_buf_full_vc0[PE] &&
            in_buf_do_vc0[PE][HOP_LSB] &&
            in_buf_do_vc0[PE][DEST_X_MSB:DEST_X_LSB] < ROUTER_X) begin
                req_PE_R2L = 1'b1;
            end

            else if(!out_buf_full_vc0[U2D] &&
            in_buf_full_vc0[PE] &&
            in_buf_do_vc0[PE][HOP_LSB] &&
            in_buf_do_vc0[PE][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_PE_U2D = 1'b1;
            end

            else if(!out_buf_full_vc0[D2U] &&
            in_buf_full_vc0[PE] &&
            in_buf_do_vc0[PE][HOP_LSB] &&
            in_buf_do_vc0[PE][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_PE_D2U = 1'b1;
            end
        end

        ///////////////////////////
        /////////  vc1  ///////////
        ///////////////////////////

        else begin
            // L2R vc1 request logic
            if(!out_buf_full_vc1[L2R] &&
            in_buf_full_vc1[L2R] &&
            in_buf_do_vc1[L2R][HOP_LSB] &&
            in_buf_do_vc1[L2R][DEST_X_MSB:DEST_X_LSB] > ROUTER_X) begin
                req_L2R_L2R = 1'b1;
            end

            else if(!out_buf_full_vc1[U2D] &&
            in_buf_full_vc1[L2R] &&
            in_buf_do_vc1[L2R][HOP_LSB] &&
            in_buf_do_vc1[L2R][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_L2R_U2D = 1'b1;
            end

            else if(!out_buf_full_vc1[D2U] &&
            in_buf_full_vc1[L2R] &&
            in_buf_do_vc1[L2R][HOP_LSB] &&
            in_buf_do_vc1[L2R][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_L2R_D2U = 1'b1;
            end

            else if(!out_buf_full_vc1[PE] &&
            in_buf_full_vc1[L2R] &&
            in_buf_do_vc1[L2R][HOP_LSB] == 1'b0) begin
                req_L2R_PE = 1'b1;
            end

            //////////////////////////////////////////

            // R2L vc1 request logic
            if(!out_buf_full_vc1[R2L] &&
            in_buf_full_vc1[R2L] &&
            in_buf_do_vc1[R2L][HOP_LSB] &&
            in_buf_do_vc1[R2L][DEST_X_MSB:DEST_X_LSB] < ROUTER_X) begin
                req_R2L_R2L = 1'b1;
            end

            else if(!out_buf_full_vc1[U2D] &&
            in_buf_full_vc1[R2L] &&
            in_buf_do_vc1[R2L][HOP_LSB] &&
            in_buf_do_vc1[R2L][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_R2L_U2D = 1'b1;
            end

            else if(!out_buf_full_vc1[D2U] &&
            in_buf_full_vc1[R2L] &&
            in_buf_do_vc1[R2L][HOP_LSB] &&
            in_buf_do_vc1[R2L][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_R2L_D2U = 1'b1;
            end

            else if(!out_buf_full_vc1[PE] &&
            in_buf_full_vc1[R2L] &&
            in_buf_do_vc1[R2L][HOP_LSB] == 1'b0) begin
                req_R2L_PE = 1'b1;
            end

            //////////////////////////////////////////

            // D2U vc1 request logic
            if(!out_buf_full_vc1[D2U] &&
            in_buf_full_vc1[D2U] &&
            in_buf_do_vc1[D2U][HOP_LSB] &&
            in_buf_do_vc1[D2U][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_D2U_D2U = 1'b1;
            end

            else if(!out_buf_full_vc1[PE] &&
            in_buf_full_vc1[D2U] &&
            in_buf_do_vc1[D2U][HOP_LSB] == 1'b0) begin
                req_D2U_PE = 1'b1;
            end

            //////////////////////////////////////////

            // U2D vc1 request logic
            if(!out_buf_full_vc1[U2D] &&
            in_buf_full_vc1[U2D] &&
            in_buf_do_vc1[U2D][HOP_LSB] &&
            in_buf_do_vc1[U2D][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_U2D_U2D = 1'b1;
            end

            else if(!out_buf_full_vc1[PE] &&
            in_buf_full_vc1[U2D] &&
            in_buf_do_vc1[U2D][HOP_LSB] == 1'b0) begin
                req_U2D_PE = 1'b1;
            end

            //////////////////////////////////////////

            // PE vc1 request logic
            if(!out_buf_full_vc1[L2R] &&
            in_buf_full_vc1[PE] &&
            in_buf_do_vc1[PE][HOP_LSB] &&
            in_buf_do_vc1[PE][DEST_X_MSB:DEST_X_LSB] > ROUTER_X) begin
                req_PE_L2R = 1'b1;
            end

            else if(!out_buf_full_vc1[R2L] &&
            in_buf_full_vc1[PE] &&
            in_buf_do_vc1[PE][HOP_LSB] &&
            in_buf_do_vc1[PE][DEST_X_MSB:DEST_X_LSB] < ROUTER_X) begin
                req_PE_R2L = 1'b1;
            end

            else if(!out_buf_full_vc1[U2D] &&
            in_buf_full_vc1[PE] &&
            in_buf_do_vc1[PE][HOP_LSB] &&
            in_buf_do_vc1[PE][DEST_Y_MSB:DEST_Y_LSB] > ROUTER_Y) begin
                req_PE_U2D = 1'b1;
            end

            else if(!out_buf_full_vc1[D2U] &&
            in_buf_full_vc1[PE] &&
            in_buf_do_vc1[PE][HOP_LSB] &&
            in_buf_do_vc1[PE][DEST_Y_MSB:DEST_Y_LSB] < ROUTER_Y) begin
                req_PE_D2U = 1'b1;
            end
        end
    end

    

    // vc0 output buffers
    buffer out_buf_L2R_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc0[L2R]), 
        .re(out_buf_re_vc0[L2R]),
        .data_in(out_buf_di_vc0[L2R]),
        .full(out_buf_full_vc0[L2R]), 
        .data_out(out_buf_do_vc0[L2R])
    );

    buffer out_buf_R2L_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc0[R2L]), 
        .re(out_buf_re_vc0[R2L]),
        .data_in(out_buf_di_vc0[R2L]),
        .full(out_buf_full_vc0[R2L]), 
        .data_out(out_buf_do_vc0[R2L])
    );

    buffer out_buf_D2U_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc0[D2U]), 
        .re(out_buf_re_vc0[D2U]),
        .data_in(out_buf_di_vc0[D2U]),
        .full(out_buf_full_vc0[D2U]), 
        .data_out(out_buf_do_vc0[D2U])
    );

    buffer out_buf_U2D_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc0[U2D]), 
        .re(out_buf_re_vc0[U2D]),
        .data_in(out_buf_di_vc0[U2D]),
        .full(out_buf_full_vc0[U2D]), 
        .data_out(out_buf_do_vc0[U2D])
    );

    buffer out_buf_PE_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc0[PE]), 
        .re(out_buf_re_vc0[PE]),
        .data_in(out_buf_di_vc0[PE]),
        .full(out_buf_full_vc0[PE]), 
        .data_out(out_buf_do_vc0[PE])
    );

    // vc1 output buffers
    buffer out_buf_L2R_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc1[L2R]), 
        .re(out_buf_re_vc1[L2R]),
        .data_in(out_buf_di_vc1[L2R]),
        .full(out_buf_full_vc1[L2R]), 
        .data_out(out_buf_do_vc1[L2R])
    );

    buffer out_buf_R2L_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc1[R2L]), 
        .re(out_buf_re_vc1[R2L]),
        .data_in(out_buf_di_vc1[R2L]),
        .full(out_buf_full_vc1[R2L]), 
        .data_out(out_buf_do_vc1[R2L])
    );

    buffer out_buf_D2U_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc1[D2U]), 
        .re(out_buf_re_vc1[D2U]),
        .data_in(out_buf_di_vc1[D2U]),
        .full(out_buf_full_vc1[D2U]), 
        .data_out(out_buf_do_vc1[D2U])
    );

    buffer out_buf_U2D_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc1[U2D]), 
        .re(out_buf_re_vc1[U2D]),
        .data_in(out_buf_di_vc1[U2D]),
        .full(out_buf_full_vc1[U2D]), 
        .data_out(out_buf_do_vc1[U2D])
    );

    buffer out_buf_PE_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(out_buf_we_vc1[PE]), 
        .re(out_buf_re_vc1[PE]),
        .data_in(out_buf_di_vc1[PE]),
        .full(out_buf_full_vc1[PE]), 
        .data_out(out_buf_do_vc1[PE])
    );

    always@(*) begin

        in_buf_re_vc0 = 5'd0;
        in_buf_re_vc1 = 5'd0;

        out_buf_we_vc0 = 5'd0;
        out_buf_we_vc1 = 5'd0;

        // CAUTION: no initialization for out_buf_di_vc0 and out_buf_di_vc1, so they will hold their previous values if no grant is given

        // vc0
        if(int_vc == 1'b0) begin
            if(grant_L2R_L2R) begin
                in_buf_re_vc0[L2R]  = 1'b1;
                out_buf_we_vc0[L2R] = 1'b1;
                out_buf_di_vc0[L2R] = {in_buf_do_vc0[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[L2R][HOP_MSB:HOP_LSB] >> 1,
                                       in_buf_do_vc0[L2R][SOURCE_MSB:0]};
            end

            if(grant_PE_L2R) begin
                in_buf_re_vc0[PE]   = 1'b1;
                out_buf_we_vc0[L2R] = 1'b1;
                out_buf_di_vc0[L2R] = {in_buf_do_vc0[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[PE][HOP_MSB:HOP_LSB] >> 1,
                                       in_buf_do_vc0[PE][SOURCE_MSB:0]};
            end

            if(grant_R2L_R2L) begin
                in_buf_re_vc0[R2L]  = 1'b1;
                out_buf_we_vc0[R2L] = 1'b1;
                out_buf_di_vc0[R2L] = {in_buf_do_vc0[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[R2L][SOURCE_MSB:0]};
            end
                
            if(grant_PE_R2L) begin
                in_buf_re_vc0[PE]   = 1'b1;
                out_buf_we_vc0[R2L] = 1'b1;
                out_buf_di_vc0[R2L] = {in_buf_do_vc0[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[PE][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[PE][SOURCE_MSB:0]};          
            end

            if(grant_D2U_D2U) begin
                in_buf_re_vc0[D2U]  = 1'b1;
                out_buf_we_vc0[D2U] = 1'b1;
                out_buf_di_vc0[D2U] = {in_buf_do_vc0[D2U][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[D2U][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[D2U][SOURCE_MSB:0]};
            end

            if(grant_L2R_D2U) begin
                in_buf_re_vc0[L2R]  = 1'b1;
                out_buf_we_vc0[D2U] = 1'b1;
                out_buf_di_vc0[D2U] = {in_buf_do_vc0[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[L2R][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[L2R][SOURCE_MSB:0]};
            end

            if(grant_R2L_D2U) begin
                in_buf_re_vc0[R2L]  = 1'b1;
                out_buf_we_vc0[D2U] = 1'b1;
                out_buf_di_vc0[D2U] = {in_buf_do_vc0[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[R2L][SOURCE_MSB:0]};
            end

            if(grant_PE_D2U) begin
                in_buf_re_vc0[PE]   = 1'b1;
                out_buf_we_vc0[D2U] = 1'b1;
                out_buf_di_vc0[D2U] = {in_buf_do_vc0[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[PE][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[PE][SOURCE_MSB:0]};
            end

            if(grant_U2D_U2D) begin
                in_buf_re_vc0[U2D]  = 1'b1;
                out_buf_we_vc0[U2D] = 1'b1;
                out_buf_di_vc0[U2D] = {in_buf_do_vc0[U2D][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[U2D][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[U2D][SOURCE_MSB:0]};
            end

            if(grant_L2R_U2D) begin
                in_buf_re_vc0[L2R]  = 1'b1;
                out_buf_we_vc0[U2D] = 1'b1;
                out_buf_di_vc0[U2D] = {in_buf_do_vc0[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[L2R][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[L2R][SOURCE_MSB:0]};
            end

            if(grant_R2L_U2D) begin
                in_buf_re_vc0[R2L]  = 1'b1;
                out_buf_we_vc0[U2D] = 1'b1;
                out_buf_di_vc0[U2D] = {in_buf_do_vc0[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[R2L][SOURCE_MSB:0]};
            end

            if(grant_PE_U2D) begin
                in_buf_re_vc0[PE]   = 1'b1;
                out_buf_we_vc0[U2D] = 1'b1;
                out_buf_di_vc0[U2D] = {in_buf_do_vc0[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc0[PE][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc0[PE][SOURCE_MSB:0]};
            end

            if(grant_L2R_PE) begin
                in_buf_re_vc0[L2R] = 1'b1;
                out_buf_we_vc0[PE] = 1'b1;
                out_buf_di_vc0[PE] = {in_buf_do_vc0[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                      in_buf_do_vc0[L2R][HOP_MSB:HOP_LSB] >> 1,   
                                      in_buf_do_vc0[L2R][SOURCE_MSB:0]};
            end

            if(grant_R2L_PE) begin
                in_buf_re_vc0[R2L] = 1'b1;
                out_buf_we_vc0[PE] = 1'b1;
                out_buf_di_vc0[PE] = {in_buf_do_vc0[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                      in_buf_do_vc0[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                      in_buf_do_vc0[R2L][SOURCE_MSB:0]};
            end

            if(grant_D2U_PE) begin
                in_buf_re_vc0[D2U] = 1'b1;
                out_buf_we_vc0[PE] = 1'b1;
                out_buf_di_vc0[PE] = {in_buf_do_vc0[D2U][PACKET_SIZE-1:HOP_MSB+1],
                                      in_buf_do_vc0[D2U][HOP_MSB:HOP_LSB] >> 1,   
                                      in_buf_do_vc0[D2U][SOURCE_MSB:0]};
            end
        end
        
        // vc1
        else begin
            if(grant_L2R_L2R) begin
                in_buf_re_vc1[L2R]  = 1'b1;
                out_buf_we_vc1[L2R] = 1'b1;
                out_buf_di_vc1[L2R] = {in_buf_do_vc1[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[L2R][HOP_MSB:HOP_LSB] >> 1,
                                       in_buf_do_vc1[L2R][SOURCE_MSB:0]};
            end

            if(grant_PE_L2R) begin
                in_buf_re_vc1[PE]   = 1'b1;
                out_buf_we_vc1[L2R] = 1'b1;
                out_buf_di_vc1[L2R] = {in_buf_do_vc1[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[PE][HOP_MSB:HOP_LSB] >> 1,
                                       in_buf_do_vc1[PE][SOURCE_MSB:0]};
            end

            if(grant_R2L_R2L) begin
                in_buf_re_vc1[R2L]  = 1'b1;
                out_buf_we_vc1[R2L] = 1'b1;
                out_buf_di_vc1[R2L] = {in_buf_do_vc1[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[R2L][SOURCE_MSB:0]};
            end
                
            if(grant_PE_R2L) begin
                in_buf_re_vc1[PE]   = 1'b1;
                out_buf_we_vc1[R2L] = 1'b1;
                out_buf_di_vc1[R2L] = {in_buf_do_vc1[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[PE][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[PE][SOURCE_MSB:0]};          
            end

            if(grant_D2U_D2U) begin
                in_buf_re_vc1[D2U]  = 1'b1;
                out_buf_we_vc1[D2U] = 1'b1;
                out_buf_di_vc1[D2U] = {in_buf_do_vc1[D2U][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[D2U][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[D2U][SOURCE_MSB:0]};
            end

            if(grant_L2R_D2U) begin
                in_buf_re_vc1[L2R]  = 1'b1;
                out_buf_we_vc1[D2U] = 1'b1;
                out_buf_di_vc1[D2U] = {in_buf_do_vc1[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[L2R][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[L2R][SOURCE_MSB:0]};
            end

            if(grant_R2L_D2U) begin
                in_buf_re_vc1[R2L]  = 1'b1;
                out_buf_we_vc1[D2U] = 1'b1;
                out_buf_di_vc1[D2U] = {in_buf_do_vc1[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[R2L][SOURCE_MSB:0]};
            end

            if(grant_PE_D2U) begin
                in_buf_re_vc1[PE]   = 1'b1;
                out_buf_we_vc1[D2U] = 1'b1;
                out_buf_di_vc1[D2U] = {in_buf_do_vc1[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[PE][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[PE][SOURCE_MSB:0]};
            end

            if(grant_U2D_U2D) begin
                in_buf_re_vc1[U2D]  = 1'b1;
                out_buf_we_vc1[U2D] = 1'b1;
                out_buf_di_vc1[U2D] = {in_buf_do_vc1[U2D][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[U2D][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[U2D][SOURCE_MSB:0]};
            end

            if(grant_L2R_U2D) begin
                in_buf_re_vc1[L2R]  = 1'b1;
                out_buf_we_vc1[U2D] = 1'b1;
                out_buf_di_vc1[U2D] = {in_buf_do_vc1[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[L2R][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[L2R][SOURCE_MSB:0]};
            end

            if(grant_R2L_U2D) begin
                in_buf_re_vc1[R2L]  = 1'b1;
                out_buf_we_vc1[U2D] = 1'b1;
                out_buf_di_vc1[U2D] = {in_buf_do_vc1[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[R2L][SOURCE_MSB:0]};
            end

            if(grant_PE_U2D) begin
                in_buf_re_vc1[PE]   = 1'b1;
                out_buf_we_vc1[U2D] = 1'b1;
                out_buf_di_vc1[U2D] = {in_buf_do_vc1[PE][PACKET_SIZE-1:HOP_MSB+1],
                                       in_buf_do_vc1[PE][HOP_MSB:HOP_LSB] >> 1,   
                                       in_buf_do_vc1[PE][SOURCE_MSB:0]};
            end

            if(grant_L2R_PE) begin
                in_buf_re_vc1[L2R] = 1'b1;
                out_buf_we_vc1[PE] = 1'b1;
                out_buf_di_vc1[PE] = {in_buf_do_vc1[L2R][PACKET_SIZE-1:HOP_MSB+1],
                                      in_buf_do_vc1[L2R][HOP_MSB:HOP_LSB] >> 1,   
                                      in_buf_do_vc1[L2R][SOURCE_MSB:0]};
            end

            if(grant_R2L_PE) begin
                in_buf_re_vc1[R2L] = 1'b1;
                out_buf_we_vc1[PE] = 1'b1;
                out_buf_di_vc1[PE] = {in_buf_do_vc1[R2L][PACKET_SIZE-1:HOP_MSB+1],
                                      in_buf_do_vc1[R2L][HOP_MSB:HOP_LSB] >> 1,   
                                      in_buf_do_vc1[R2L][SOURCE_MSB:0]};
            end

            if(grant_D2U_PE) begin
                in_buf_re_vc1[D2U] = 1'b1;
                out_buf_we_vc1[PE] = 1'b1;
                out_buf_di_vc1[PE] = {in_buf_do_vc1[D2U][PACKET_SIZE-1:HOP_MSB+1],
                                      in_buf_do_vc1[D2U][HOP_MSB:HOP_LSB] >> 1,   
                                      in_buf_do_vc1[D2U][SOURCE_MSB:0]};
            end
        end
    end

    // output control
    always@(*)begin
        L2R_so = ext_vc ? (out_buf_full_vc1[L2R] & L2R_ro) : (out_buf_full_vc0[L2R] & L2R_ro);
        R2L_so = ext_vc ? (out_buf_full_vc1[R2L] & R2L_ro) : (out_buf_full_vc0[R2L] & R2L_ro);
        D2U_so = ext_vc ? (out_buf_full_vc1[D2U] & D2U_ro) : (out_buf_full_vc0[D2U] & D2U_ro);
        U2D_so = ext_vc ? (out_buf_full_vc1[U2D] & U2D_ro) : (out_buf_full_vc0[U2D] & U2D_ro);
        PE_so  = ext_vc ? (out_buf_full_vc1[PE]  & PE_ro)  : (out_buf_full_vc0[PE]  & PE_ro);

        L2R_do = ext_vc ? out_buf_do_vc1[L2R] : out_buf_do_vc0[L2R];
        R2L_do = ext_vc ? out_buf_do_vc1[R2L] : out_buf_do_vc0[R2L];
        D2U_do = ext_vc ? out_buf_do_vc1[D2U] : out_buf_do_vc0[D2U];
        U2D_do = ext_vc ? out_buf_do_vc1[U2D] : out_buf_do_vc0[U2D];
        PE_do  = ext_vc ? out_buf_do_vc1[PE]  : out_buf_do_vc0[PE];

        out_buf_re_vc1[L2R] = ext_vc ? (L2R_ro & L2R_so) : 1'b0;
        out_buf_re_vc1[R2L] = ext_vc ? (R2L_ro & R2L_so) : 1'b0;
        out_buf_re_vc1[D2U] = ext_vc ? (D2U_ro & D2U_so) : 1'b0;
        out_buf_re_vc1[U2D] = ext_vc ? (U2D_ro & U2D_so) : 1'b0;
        out_buf_re_vc1[PE]  = ext_vc ? (PE_ro  & PE_so)  : 1'b0;

        out_buf_re_vc0[L2R] = ext_vc ? 1'b0 : (L2R_ro & L2R_so);
        out_buf_re_vc0[R2L] = ext_vc ? 1'b0 : (R2L_ro & R2L_so);
        out_buf_re_vc0[D2U] = ext_vc ? 1'b0 : (D2U_ro & D2U_so);
        out_buf_re_vc0[U2D] = ext_vc ? 1'b0 : (U2D_ro & U2D_so);
        out_buf_re_vc0[PE]  = ext_vc ? 1'b0 : (PE_ro  & PE_so);
    end

    
    
endmodule