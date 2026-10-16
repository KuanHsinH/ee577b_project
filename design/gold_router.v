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
    wire                     ext_vc = ~polarity; 

    input                    PE_si, L2R_si, R2L_si, D2U_si, U2D_si; // channel telling router that the packet is valid
    input [PACKET_SIZE-1:0]  PE_di, L2R_di, R2L_di, D2U_di, U2D_di; // input packet data
    output reg               PE_ri, L2R_ri, R2L_ri, D2U_ri, U2D_ri; // router telling channel that buffer is empty, can accept

    output                   PE_so, L2R_so, R2L_so, D2U_so, U2D_so; // router telling channel it has packet to send
    output [PACKET_SIZE-1:0] PE_do, L2R_do, R2L_do, D2U_do, U2D_do; // output packet data
    input                    PE_ro, L2R_ro, R2L_ro, D2U_ro, U2D_ro; // channel telling router it can accept packet
    
    wire 

    reg [PACKET_SIZE-1:0] in_buf_E[4:0];  // even input buffer
    reg [PACKET_SIZE-1:0] in_buf_O[4:0];  // odd input buffer

    reg [4:0] in_buf_E_full;
    reg [4:0] in_buf_O_full;

    reg [PACKET_SIZE-1:0] out_buf_E[4:0]; // even output buffer
    reg [PACKET_SIZE-1:0] out_buf_O[4:0]; // odd output buffer

    reg [4:0] out_buf_E_full;
    reg [4:0] out_buf_O_full;

    // input control
    always @(*) begin
        L2R_ri = polarity ? ~in_buf_E_full[L2R] : ~in_buf_O_full[L2R];
        R2L_ri = polarity ? ~in_buf_E_full[R2L] : ~in_buf_O_full[R2L];
        D2U_ri = polarity ? ~in_buf_E_full[D2U] : ~in_buf_O_full[D2U];
        U2D_ri = polarity ? ~in_buf_E_full[U2D] : ~in_buf_O_full[U2D];
        PE_ri  = polarity ? ~in_buf_E_full[PE]  : ~in_buf_O_full[PE];
    end

    // polarity control
    always @(posedge clk) begin
        if(reset)   polarity <= 0;
        else        polarity <= ~polarity;
    end

    // input buffer accepting external packets
    always@(posedge clk) begin
        if(reset) begin
            in_buf_E_full <= 5'b0;
            in_buf_O_full <= 5'b0;
        end
        else begin
            if(L2R_si && L2R_ri) begin
                if(ext_vc) begin
                    in_buf_O[L2R]       <= L2R_di;
                    in_buf_O_full[L2R]  <= 1'b1;
                end
                else begin
                    in_buf_E[L2R]       <= L2R_di;
                    in_buf_E_full[L2R]  <= 1'b1;
                end
            end

            if(R2L_si && R2L_ri) begin
                if(ext_vc) begin
                    in_buf_O[R2L]       <= R2L_di;
                    in_buf_O_full[R2L]  <= 1'b1;
                end
                else begin
                    in_buf_E[R2L]       <= R2L_di;
                    in_buf_E_full[R2L]  <= 1'b1;
                end
            end

            if(D2U_si && D2U_ri) begin
                if(ext_vc) begin
                    in_buf_O[D2U]       <= D2U_di;
                    in_buf_O_full[D2U]  <= 1'b1;
                end
                else begin
                    in_buf_E[D2U]       <= D2U_di;
                    in_buf_E_full[D2U]  <= 1'b1;
                end
            end

            if(U2D_si && U2D_ri) begin
                if(ext_vc) begin
                    in_buf_O[U2D]       <= U2D_di;
                    in_buf_O_full[U2D]  <= 1'b1;
                end
                else begin
                    in_buf_E[U2D]       <= U2D_di;
                    in_buf_E_full[U2D]  <= 1'b1;
                end
            end

            if(PE_si && PE_ri) begin
                if(ext_vc) begin
                    in_buf_O[PE]        <= PE_di;
                    in_buf_O_full[PE]   <= 1'b1;
                end
                else begin
                    in_buf_E[PE]        <= PE_di;
                    in_buf_E_full[PE]   <= 1'b1;
                end
            end
        end
    end

    // extracting packets from input buffer to output buffer
    // use a flag to indicate I want to forward to a specific output buffer
    // L2R
    // can go to L2R, D2U, U2D, PE

    wire       forwarding_E_L2R = !polarity && in_buf_E_full[4] && !in_buf_E[VC_BIT];
    reg  [4:0] in_buf_route_E_L2R_to;

    always@(*) begin
        if(forwarding_E_L2R) begin
            if(in_buf_E[L2R][HOP_MSB:HOP_LSB] == 8'd0) begin
                in_buf_route_E_L2R_to[PE] = 1'b1;
            end
            else if(in_buf_E[DEST_X_MSB:DEST_X_LSB] != ) // dont know how to determine if it arrives as the destination x
        end
    end

endmodule