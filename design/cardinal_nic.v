module cardinal_nic 
#(
	parameter PACKET_SIZE = 64
)
 
(
    input         clk, reset,
    input  [1:0]  addr,
    input  [PACKET_SIZE:0] d_in,
    output [PACKET_SIZE:0] d_out,
    input         nicEn, nicEnWr,
    input         net_si,
    output        net_ri,
    input  [PACKET_SIZE:0] net_di,
    output        net_so,
    input         net_ro,
    output [{ACKET_SIZE:0] net_do,
    input         net_polarity
);
reg [63:0] in_buf;
    reg [63:0] out_buf;

    reg in_full;
    reg out_full;

    // ---------------------------------------------------------
    // Processor interface controls
    // ---------------------------------------------------------

    wire input_read =
        nicEn && !nicEnWr &&
        (addr == 2'b00) && in_full;

    wire output_write =
        nicEn && nicEnWr &&
        (addr == 2'b10);

    // ---------------------------------------------------------
    // Router-to-NiC receive handshake
    // ---------------------------------------------------------

    always @(*) begin
        // Accept a packet whenever the input buffer is empty.
        net_ri = !in_full;
    end

    // ---------------------------------------------------------
    // NiC-to-router transmit handshake
    // ---------------------------------------------------------

    always @(*) begin
        net_so = 1'b0;
        net_do = 64'b0;

        if (out_full) begin
            net_do = out_buf;

            // External VC = ~polarity.
            // VC1 transfers at polarity 0.
            // VC0 transfers at polarity 1.
            if (net_ro &&
                (out_buf[63] == ~net_polarity)) begin
                net_so = 1'b1;
            end
        end
    end

    // ---------------------------------------------------------
    // Processor register reads
    // ---------------------------------------------------------

    always @(*) begin
        // Default: zero unless an enabled read is selected.
        d_out = 64'b0;

        if (nicEn && !nicEnWr) begin
            case (addr)

                2'b00: begin
                    // Read the received packet.
                    if (in_full)
                        d_out = in_buf;
                end

                2'b01: begin
                    // Input-buffer status in bit 63.
                    d_out[63] = in_full;
                end

                2'b10: begin
                    // Not a read address.
                    d_out = 64'b0;
                end

                2'b11: begin
                    // Output-buffer status in bit 63.
                    d_out[63] = out_full;
                end

                default: begin
                    d_out = 64'b0;
                end

            endcase
        end
    end

    // Sequential buffer operations

    always @(posedge clk) begin
        if (reset) begin
            in_buf  <= 64'b0;
            out_buf <= 64'b0;

            in_full  <= 1'b0;
            out_full <= 1'b0;
        end
        else begin

            // Receive a packet from the router
            if (net_si && net_ri) begin
                in_buf  <= net_di;
                in_full <= 1'b1;
            end
            else if (input_read) begin
                // Reading address 00 consumes the packet
                in_full <= 1'b0;
            end

            // Transmit a packet to the router
            if (net_so && net_ro) begin
                // Remove the packet on the transfer edge
                out_full <= 1'b0;
            end
            else if (output_write && !out_full) begin
                // Store a new packet only when the buffer is empty
                out_buf  <= d_in;
                out_full <= 1'b1;
            end

        end
    end

endmodule


