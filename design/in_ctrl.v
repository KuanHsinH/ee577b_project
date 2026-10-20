
module in_ctrl #(
    parameter integer PACKET_SIZE = 64,
    parameter integer ROUTER_X = 0,
    parameter integer ROUTER_Y = 0
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   polarity,

    input  wire [PACKET_SIZE-1:0] data_in,
    input  wire                   si,
    output wire                   ri,

    output reg  [4:0]             req,
    output reg  [PACKET_SIZE-1:0] routed_data,
    input  wire [4:0]             grant
);

    reg [PACKET_SIZE-1:0] buffer_vc0;
    reg [PACKET_SIZE-1:0] buffer_vc1;
    reg                   valid_vc0;
    reg                   valid_vc1;

    // The active VC supplies the internal request.
    wire active_valid;
    wire [1:0] active_dest_x;
    wire [1:0] active_dest_y;

    assign active_valid = (polarity == 1'b0)
                        ? valid_vc0 : valid_vc1;


    // [63] VC, [62] reserved, [61:60] dest_x, [59:58] dest_y.
    assign active_dest_x = (polarity == 1'b0)
                         ? buffer_vc0[PACKET_SIZE-3 -: 2]
                         : buffer_vc1[PACKET_SIZE-3 -: 2];

    assign active_dest_y = (polarity == 1'b0)
                         ? buffer_vc0[PACKET_SIZE-5 -: 2]
                         : buffer_vc1[PACKET_SIZE-5 -: 2];

    // During reset, report ready
    // Otherwise, accept into the VC opposite to the active phase
    assign ri = reset ? 1'b1 :
                ((polarity == 1'b0) ? !valid_vc1 : !valid_vc0);

    // Request encoding:
    // bit 0 = PE, bit 1 = U2D, bit 2 = D2U,
    // bit 3 = R2L, bit 4 = L2R.
    localparam integer PE  = 0;
    localparam integer U2D = 1;
    localparam integer D2U = 2;
    localparam integer R2L = 3;
    localparam integer L2R = 4;

    // Combinational request and packet forwarding
    always @* begin
        req         = 5'b00000;
        routed_data = {PACKET_SIZE{1'b0}};

        if (!reset && active_valid) begin
            if (polarity == 1'b0)
                routed_data = buffer_vc0;
            else
                routed_data = buffer_vc1;

            // XY routing
            if (active_dest_x > ROUTER_X)
                req[L2R] = 1'b1;
            else if (active_dest_x < ROUTER_X)
                req[R2L] = 1'b1;
            else if (active_dest_y > ROUTER_Y)
                req[U2D] = 1'b1;
            else if (active_dest_y < ROUTER_Y)
                req[D2U] = 1'b1;
            else
                req[PE] = 1'b1;
        end
    end

    // Sequential buffer control
    always @(posedge clk) begin
        if (reset) begin
            buffer_vc0 <= {PACKET_SIZE{1'b0}};
            buffer_vc1 <= {PACKET_SIZE{1'b0}};
            valid_vc0  <= 1'b0;
            valid_vc1  <= 1'b0;
        end else if (polarity == 1'b0) begin
            // VC0 is active internally
            // Release it only when its requested output is granted
            if (valid_vc0 && (|(req & grant)))
                valid_vc0 <= 1'b0;

            // VC1 receives externally during this phase
            if (si && ri) begin
                buffer_vc1 <= data_in;
                valid_vc1  <= 1'b1;
            end
        end else begin
            // VC1 is active internally
            if (valid_vc1 && (|(req & grant)))
                valid_vc1 <= 1'b0;

            // VC0 receives externally during this phase
            if (si && ri) begin
                buffer_vc0 <= data_in;
                valid_vc0  <= 1'b1;
            end
        end
    end

endmodule

