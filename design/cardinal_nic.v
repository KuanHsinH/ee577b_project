module cardinal_nic #(
    parameter integer PACKET_SIZE = 64
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire [1:0]               addr,
    input  wire [PACKET_SIZE-1:0]   d_in,
    output reg  [PACKET_SIZE-1:0]   d_out,
    input  wire                     nicEn,
    input  wire                     nicEnWr,

    input  wire                     net_si,
    output reg                      net_ri,
    input  wire [PACKET_SIZE-1:0]   net_di,

    output reg                      net_so,
    input  wire                     net_ro,
    output reg  [PACKET_SIZE-1:0]   net_do,
    input  wire                     net_polarity
);

    reg [PACKET_SIZE-1:0] in_buf;
    reg [PACKET_SIZE-1:0] out_buf;
    reg                   in_full;
    reg                   out_full;

    wire input_read = nicEn && !nicEnWr && (addr == 2'b00) && in_full;
    wire output_write = nicEn && nicEnWr && (addr == 2'b10);

    // Processor-to-NIC and NIC-to-processor register map:
    // 00: input packet buffer (read-only)
    // 01: input status (read-only, status in LSB)
    // 10: output packet buffer (write-only)
    // 11: output status (read-only, status in LSB)

    // Network input handshake: ready exactly when the input buffer is empty.
    always @* begin
        net_ri = !in_full;
    end

    // Network output handshake. A packet remains visible on net_do while
    // buffered, even if the router is not ready or the VC phase does not match.
    // This design follows the Cardinal phase convention: VC1 sends when
    // net_polarity=0; VC0 sends when net_polarity=1.
    always @* begin
        net_so = 1'b0;
        net_do = {PACKET_SIZE{1'b0}};

        if (out_full) begin
            net_do = out_buf;
            if (net_ro && (out_buf[PACKET_SIZE-1] == ~net_polarity))
                net_so = 1'b1;
        end
    end

    // A read ofinput buffer address 00 consumes the packet at that edge.
    always @* begin
        d_out = {PACKET_SIZE{1'b0}};

        if (nicEn && !nicEnWr) begin
            case (addr)
                2'b00: begin
                    if (in_full)
                        d_out = in_buf;
                end
                2'b01: d_out[0] = in_full;
                2'b10: d_out = {PACKET_SIZE{1'b0}};
                2'b11: d_out[0] = out_full;
                default: d_out = {PACKET_SIZE{1'b0}};
            endcase
        end
    end

    // Synchronous, active-high reset. Writes to occupied output buffers and
    // writes to read-only registers are ignored. Independent directions may
    // receive and transmit in the same clock cycle.
    always @(posedge clk) begin
        if (reset) begin
            in_buf  <= {PACKET_SIZE{1'b0}};
            out_buf <= {PACKET_SIZE{1'b0}};
            in_full <= 1'b0;
            out_full <= 1'b0;
        end else begin
            // Router -> PE. net_ri is low whenever the input buffer is full.
            if (net_si && net_ri) begin
                in_buf  <= net_di;
                in_full <= 1'b1;
            end else if (input_read) begin
                in_full <= 1'b0;
            end

            // NIC -> router. net_so already includes net_ro and VC matching.
            // Since out_full is evaluated before the edge, a simultaneous CPU
            // write while occupied is ignored even if this edge transmits it.
            if (net_so) begin
                out_full <= 1'b0;
            end else if (output_write && !out_full) begin
                out_buf  <= d_in;
                out_full <= 1'b1;
            end
        end
    end

endmodule
