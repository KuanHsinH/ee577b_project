module in_ctrl #(
    parameter PACKET_SIZE = 64,
    parameter ROUTER_X\ = 0, ROUTER_Y = 0;
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     polarity,

    // External input link (from neighboring router or local PE)
    input  wire [PACKET_SIZE-1:0]   data_in,
    input  wire                     si,
    output wire                     ri,

    // Internal request/grant interface
    output reg  [4:0]               req,
    output reg  [PACKET_SIZE-1:0]   routed_data,
    input  wire [4:0]               grant
);

    // One full-packet register and one valid bit per VC.
    reg [PACKET_SIZE-1:0] buffer_vc0;
    reg [PACKET_SIZE-1:0] buffer_vc1;
    reg                   valid_vc0;
    reg                   valid_vc1;

    // Internal forwarding uses the VC selected by polarity.
    wire active_valid;
    wire [1:0] active_dest_x;
    wire [1:0] active_dest_y;

    assign active_valid  = (polarity == 1'b0) ? valid_vc0 : valid_vc1;
    assign active_dest_x = (polarity == 1'b0)
                         ? buffer_vc0[PACKET_SIZE-3 -: 2]
                         : buffer_vc1[PACKET_SIZE-3 -: 2];
    assign active_dest_y = (polarity == 1'b0)
                         ? buffer_vc0[PACKET_SIZE-5 -: 2]
                         : buffer_vc1[PACKET_SIZE-5 -: 2];

    // External reception uses the opposite VC phase.
    // Assert ready during reset as required by the mesh/PE interface rules.
    assign ri = reset ? 1'b1 :
                ((polarity == 1'b0) ? !valid_vc1 : !valid_vc0);

    // Decode one output request from the active input VC.
    // X is routed first; Y is considered only after X matches.
    // req and routed_data are combinational so an output controller can
    // grant the request and capture routed_data at the same rising edge.
    localparam PE = 0, U2D = 1, D2U = 2, R2L = 3, L2R = 4; 
    always @* begin
        req         = 5'b00000;
        routed_data = {PACKET_SIZE{1'b0}};

        if (!reset && active_valid) begin
            if (polarity == 1'b0)
                routed_data = buffer_vc0;
            else
                routed_data = buffer_vc1;

            if (active_dest_x > LOCAL_X) req[L2R] = 1'b1; 
            else if (active_dest_x < LOCAL_X) req[R2L] = 1'b1; 
            else if (active_dest_y > LOCAL_Y) req[U2D] = 1'b1; 
            else if (active_dest_y < LOCAL_Y) req[D2U] = 1'b1; 
            else req[PE] = 1'b1; 
            end
        end
    end

    // A local input VC is released only when its requested output grants it.
    // In the same edge, the opposite VC may receive an external packet. These
    // are independent registers, so receive and forward can happen together.
    always @(posedge clk) begin
        if (reset) begin
            buffer_vc0 <= {PACKET_SIZE{1'b0}};
            buffer_vc1 <= {PACKET_SIZE{1'b0}};
            valid_vc0  <= 1'b0;
            valid_vc1  <= 1'b0;
        end else if (polarity == 1'b0) begin
            // Internal stage operates on VC0.
            if (valid_vc0 && (|(req & grant)))
                valid_vc0 <= 1'b0;

            // External stage receives VC1 during polarity 0.
            if (si && ri) begin
                buffer_vc1 <= data_in;
                valid_vc1  <= 1'b1;
            end
        end else begin
            // Internal stage operates on VC1.
            if (valid_vc1 && (|(req & grant)))
                valid_vc1 <= 1'b0;

            // External stage receives VC0 during polarity 1.
            if (si && ri) begin
                buffer_vc0 <= data_in;
                valid_vc0  <= 1'b1;
            end
        end
    end

endmodule
