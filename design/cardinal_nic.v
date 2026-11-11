////////////////////////////////////////////////////////////////////////////
// Cardinal Network Interface Component - top-level module (EE577B Phase 3)
//
// DO NOT CHANGE THE MODULE NAME OR THE PORT LIST BELOW.
// The NIC grading testbench instantiates cardinal_nic by these exact port
// names (Figure 2 and Table 1 of the corrected NIC specification). The
// write enable is named nicWrEn, as in the corrected specification and in
// the Phase 3 handout; if your Project 1 NIC uses nicEnWr,
// rename the port.
//
// Register map (Table 2), selected by addr[0:1]:
//   00  input channel buffer        read only; a read empties the buffer
//   01  input channel status        read only
//   10  output channel buffer       write only
//   11  output channel status       read only
// Unsupported accesses are ignored. A store to an occupied output buffer is
// ignored. A status read returns the bit on d_out[63], d_out[0:62] = 0.
//
// Timing:
//   * Processor side: addr, d_in, nicEn and nicWrEn are sampled at the
//     rising clock edge; the selected register appears on d_out after that
//     edge (like the data memory). d_out is 0 after an edge at which nicEn
//     was 0.
//   * Network input channel: when net_si is 1 at a rising edge, net_di is
//     latched into the input buffer and net_ri (buffer empty) drops.
//   * Network output channel: the router samples net_so and net_do at
//     rising edges. A packet is taken at an edge where net_so = 1; at that
//     edge net_ro must be 1 and net_polarity must be ~vc (vc = bit 0 of
//     the packet; specification Figure 3, the phase in which the mesh
//     transfers that VC). This is the opposite of the Project 1 NIC
//     testbench rule. net_so may be registered (decided at the previous
//     edge, where the sampled polarity equals vc) or combinational.
//     Release the buffer only at an edge where net_so and net_ro are both
//     1 (the router accepted the packet); otherwise keep it and offer it
//     again.
//   * Reset (synchronous, active high): both buffers empty, both status
//     registers 0, net_so = 0, net_ri = 1, d_out = 0.
//
// Bit numbering: Phase 3 uses the Phase 2 processor convention, [0:63]
// with bit 0 the MSB (vc bit) and bit 63 the LSB (status bit on d_out).
// Project 1 declared the same ports as [63:0]. You may keep [63:0] and
// [1:0] declarations in this module: ports connect by name, MSB to MSB,
// so your Project 1 code (d_in[63] = vc, addr[1] = high address bit)
// stays right. Do not mix: a module declared [0:63] must use d_in[0] for
// the vc bit and addr[0] for the high address bit.
////////////////////////////////////////////////////////////////////////////
module cardinal_nic (
    input         clk,          // rising-edge clock
    input         reset,        // synchronous, active high
    // processor side
    input  [0:1]  addr,         // register select (Table 2)
    input  [0:63] d_in,         // packet from the processor
    output reg [0:63] d_out,        // register content to the processor
    input         nicEn,        // NIC enable
    input         nicWrEn,      // NIC write enable
    // router side, network input channel (router -> processor)
    input         net_si,       // router sends a packet
    output        net_ri,       // input channel buffer is empty
    input  [0:63] net_di,       // packet from the router
    // router side, network output channel (processor -> router)
    output        net_so,       // NIC sends a packet
    input         net_ro,       // router can accept a packet
    output [0:63] net_do,       // packet to the router
    input         net_polarity  // polarity of the connected router
);

    reg [0:63] input_buf;
    reg [0:63] output_buf;
    reg        input_buf_full;
    reg        output_buf_full;

    assign net_ri = ~input_buf_full;

    // Present the queued packet before the sampling edge, net_do is only
    // meaningful while net_so is asserted; drive zero when the buffer is empty.
    assign net_do = output_buf_full ? output_buf : 64'd0;

    // VC is bit 0 for [0:63]
    assign net_so = output_buf_full && net_ro &&
                    (net_polarity ^ output_buf[0]);

    always @(posedge clk) begin
        if (reset) begin
            d_out           <= 64'd0;
            input_buf_full  <= 1'b0;
            output_buf_full <= 1'b0;
        end else begin
            // Router-to-NIC receive path.
            if (net_si && net_ri) begin
                input_buf      <= net_di;
                input_buf_full <= 1'b1;
            end

            // NIC-to-router send path, packet data stays in output_buf;
            // clearing the full flag marks it as accepted and no longer pending.
            if (net_so && net_ro)
                output_buf_full <= 1'b0;

            // Processor register access is independent of both network paths.
            if (!nicEn) begin
                d_out <= 64'd0;
            end else begin
                case (addr)
                    2'b00: begin
                        if (!nicWrEn && input_buf_full) begin
                            d_out          <= input_buf;
                            input_buf_full <= 1'b0;
                        end else begin
                            // Empty read or unsupported write to read-only address.
                            d_out <= 64'd0;
                        end
                    end

                    2'b01: begin
                        if (!nicWrEn)
                            d_out <= {63'b0, input_buf_full};
                        else
                            d_out <= 64'd0;
                    end

                    2'b10: begin
                        // Queue a processor packet only if the output buffer
                        // is empty; a write while full leaves the old packet intact.
                        d_out <= 64'd0;
                        if (nicWrEn && !output_buf_full) begin
                            output_buf      <= d_in;
                            output_buf_full <= 1'b1;
                        end
                    end

                    2'b11: begin
                        if (!nicWrEn)
                            d_out <= {63'b0, output_buf_full};
                        else
                            d_out <= 64'd0;
                    end

                    default: d_out <= 64'd0;
                endcase
            end
        end
    end
endmodule
