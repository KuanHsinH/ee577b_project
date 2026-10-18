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
    parameter PACKET_SIZE = 64;

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

    output                   PE_so, L2R_so, R2L_so, D2U_so, U2D_so; // router telling channel it has packet to send
    output [PACKET_SIZE-1:0] PE_do, L2R_do, R2L_do, D2U_do, U2D_do; // output packet data
    input                    PE_ro, L2R_ro, R2L_ro, D2U_ro, U2D_ro; // channel telling router it can accept packet

    wire [4:0] in_buf_full_vc0;
    wire [4:0] in_buf_full_vc1;

    reg  [4:0] in_buf_we_vc0;
    reg  [4:0] in_buf_we_vc1;

    wire [PACKET_SIZE-1:0] in_buf_do_vc0[4:0];
    wire [PACKET_SIZE-1:0] in_buf_do_vc1[4:0];

    // polarity control
    always @(posedge clk) begin
        if(reset)   polarity <= 0;
        else        polarity <= ~polarity;
    end

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
    in_buf in_buf_L2R_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[L2R]), 
        .re(),
        .data_in(L2R_di),
        .full(in_buf_full_vc0[L2R]), 
        .data_out(in_buf_do_vc0[L2R])
    );

    in_buf in_buf_R2L_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[R2L]), 
        .re(),
        .data_in(R2L_di),
        .full(in_buf_full_vc0[R2L]), 
        .data_out(in_buf_do_vc0[R2L])
    );

    in_buf in_buf_D2U_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[D2U]), 
        .re(),
        .data_in(D2U_di),
        .full(in_buf_full_vc0[D2U]), 
        .data_out(in_buf_do_vc0[D2U])
    );

    in_buf in_buf_U2D_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[U2D]), 
        .re(),
        .data_in(U2D_di),
        .full(in_buf_full_vc0[U2D]), 
        .data_out(in_buf_do_vc0[U2D])
    );

    in_buf in_buf_PE_vc0 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc0[PE]), 
        .re(),
        .data_in(PE_di),
        .full(in_buf_full_vc0[PE]), 
        .data_out(in_buf_do_vc0[PE])
    );

    //vc1 input buffers
    in_buf in_buf_L2R_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[L2R]), 
        .re(),
        .data_in(L2R_di),
        .full(in_buf_full_vc1[L2R]), 
        .data_out(in_buf_do_vc1[L2R])
    );

    in_buf in_buf_R2L_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[R2L]), 
        .re(),
        .data_in(R2L_di),
        .full(in_buf_full_vc1[R2L]), 
        .data_out(in_buf_do_vc1[R2L])
    );

    in_buf in_buf_D2U_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[D2U]), 
        .re(),
        .data_in(D2U_di),
        .full(in_buf_full_vc1[D2U]), 
        .data_out(in_buf_do_vc1[D2U])
    );

    in_buf in_buf_U2D_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[U2D]), 
        .re(),
        .data_in(U2D_di),
        .full(in_buf_full_vc1[U2D]), 
        .data_out(in_buf_do_vc1[U2D])
    );

    in_buf in_buf_PE_vc1 
    (
        .clk(clk), 
        .reset(reset),
        .we(in_buf_we_vc1[PE]), 
        .re(),
        .data_in(PE_di),
        .full(in_buf_full_vc1[PE]), 
        .data_out(in_buf_do_vc1[PE])
    );

    // input buffers requesting signals
    wire req_L2R_L2R, req_L2R_D2U, req_L2R_U2D, req_L2R_PE;
    wire req_R2L_R2L, req_R2L_D2U, req_R2L_U2D, req_R2L_PE;
    wire req_D2U_D2U, req_D2U_PE;
    wire req_U2D_U2D, req_U2D_PE;

    always@(*) begin
        
    end
    
endmodule