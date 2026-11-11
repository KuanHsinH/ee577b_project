`timescale 1ns/10ps
////////////////////////////////////////////////////////////////////////////
// Tile-level test: one NIC plus one Project 1 router at node 5.
//
// The testbench models (1) processor accesses to the NIC's mapped registers,
// and (2) the neighboring router on the R2L/L2R links. It verifies:
//   - NIC-to-router injection, router routing, output backpressure, hop update
//   - neighbor-to-router reception, routing to the PE/NIC, processor read
//   - input-buffer status and ready after the processor consumes the packet
//
// This is intentionally before CPU integration: the processor-side stimulus
// is driven at the NIC interface, not through the Phase 2 CPU pipeline.
////////////////////////////////////////////////////////////////////////////
module tb_cardinal_node;

    reg clk;
    reg reset;

    reg  [0:1]  nic_addr;
    reg  [0:63] nic_din;
    wire [0:63] nic_dout;
    reg         nic_en;
    reg         nic_wren;

    reg         l2r_si;
    wire        l2r_ri;
    reg  [63:0] l2r_di;
    wire        l2r_so;
    reg         l2r_ro;
    wire [63:0] l2r_do;

    reg         r2l_si;
    wire        r2l_ri;
    reg  [63:0] r2l_di;
    wire        r2l_so;
    reg         r2l_ro;
    wire [63:0] r2l_do;

    reg         d2u_si;
    wire        d2u_ri;
    reg  [63:0] d2u_di;
    wire        d2u_so;
    reg         d2u_ro;
    wire [63:0] d2u_do;

    reg         u2d_si;
    wire        u2d_ri;
    reg  [63:0] u2d_di;
    wire        u2d_so;
    reg         u2d_ro;
    wire [63:0] u2d_do;

    wire        polarity;

    reg [63:0] tx_packet;
    reg [63:0] tx_after_router;
    reg [63:0] rx_packet;
    reg [63:0] rx_after_router;
    integer receive_wait_cycles;

    cardinal_node #(
        .PACKET_SIZE(64),
        .NODE_NUMBER(5)
    ) DUT (
        .clk(clk),
        .reset(reset),

        .addr(nic_addr),
        .d_in(nic_din),
        .d_out(nic_dout),
        .nicEn(nic_en),
        .nicWrEn(nic_wren),

        .L2R_si(l2r_si), .L2R_ri(l2r_ri), .L2R_di(l2r_di),
        .L2R_so(l2r_so), .L2R_ro(l2r_ro), .L2R_do(l2r_do),

        .R2L_si(r2l_si), .R2L_ri(r2l_ri), .R2L_di(r2l_di),
        .R2L_so(r2l_so), .R2L_ro(r2l_ro), .R2L_do(r2l_do),

        .D2U_si(d2u_si), .D2U_ri(d2u_ri), .D2U_di(d2u_di),
        .D2U_so(d2u_so), .D2U_ro(d2u_ro), .D2U_do(d2u_do),

        .U2D_si(u2d_si), .U2D_ri(u2d_ri), .U2D_di(u2d_di),
        .U2D_so(u2d_so), .U2D_ro(u2d_ro), .U2D_do(u2d_do),

        .polarity(polarity)
    );

    // 250 MHz clock: 4 ns period.
    initial begin
        clk = 1'b0;
        forever #2 clk = ~clk;
    end

    // Packet fields follow the Project 1 mesh format.
    function [63:0] make_packet;
        input        vc;
        input [1:0]  dest_x;
        input [1:0]  dest_y;
        input [7:0]  hop;
        input [15:0] source;
        input [31:0] payload;
        begin
            make_packet = {vc, 1'b0, dest_x, dest_y, 2'b00,
                           hop, source, payload};
        end
    endfunction

    task fail;
        input [8*120-1:0] message;
        begin
            $display("FAIL: %0s at %0t ns", message, $time);
            $finish(1);
        end
    endtask

    // Watchdog catches a missed handshake instead of hanging forever.
    initial begin
        repeat (250) @(posedge clk);
        $display("FAIL: tile test watchdog expired");
        $finish(1);
    end

    initial begin
        reset = 1'b1;

        nic_addr = 2'b00;
        nic_din  = 64'd0;
        nic_en   = 1'b0;
        nic_wren = 1'b0;

        l2r_si = 1'b0; l2r_di = 64'd0; l2r_ro = 1'b0;
        r2l_si = 1'b0; r2l_di = 64'd0; r2l_ro = 1'b1;
        d2u_si = 1'b0; d2u_di = 64'd0; d2u_ro = 1'b1;
        u2d_si = 1'b0; u2d_di = 64'd0; u2d_ro = 1'b1;

        // Node 5 is (x=1,y=1). The first packet goes east to node 6.
        tx_packet = make_packet(1'b1, 2'd2, 2'd1, 8'h01,
                                16'd5, 32'hA11C_E001);
        tx_after_router = tx_packet;
        tx_after_router[55:48] = tx_packet[55:48] >> 1;

        // Node 6 originated this one-hop packet with hop=1. Its router
        // shifts the hop field before the link, so node 5 receives hop=0.
        rx_packet = make_packet(1'b1, 2'd1, 2'd1, 8'h00,
                                16'd6, 32'hB22D_F002);
        rx_after_router = rx_packet;
        rx_after_router[55:48] = rx_packet[55:48] >> 1;

        // Synchronous reset initializes both the router's VC state and NIC.
        repeat (3) @(posedge clk);
        #0.1;
        if (polarity !== 1'b0) fail("router polarity did not reset to zero");
        if (DUT.nic.net_ri !== 1'b1) fail("NIC input was not ready after reset");
        if (DUT.nic.net_so !== 1'b0) fail("NIC send asserted during reset");

        // Store the packet into the NIC output buffer (register address 10).
        @(negedge clk);
        reset   = 1'b0;
        nic_addr = 2'b10;
        nic_din  = tx_packet;
        nic_en   = 1'b1;
        nic_wren = 1'b1;
        @(posedge clk);
        #0.1;
        nic_en   = 1'b0;
        nic_wren = 1'b0;
        nic_addr = 2'b00;
        nic_din  = 64'd0;

        // Hold the east link blocked until the router has queued the packet.
        wait (DUT.router.out_buf_full_vc1[4] === 1'b1);
        if (l2r_so !== 1'b0) fail("router sent while east neighbor was blocked");

        repeat (3) @(posedge clk);
        #0.1;
        if (DUT.router.out_buf_full_vc1[4] !== 1'b1)
            fail("blocked packet was not retained in the router output buffer");
        if (l2r_so !== 1'b0)
            fail("router asserted send while east neighbor was not ready");

        // The packet becomes visible on the selected VC phase. Accept it.
        @(negedge clk);
        l2r_ro = 1'b1;
        wait (l2r_so === 1'b1);
        if (l2r_do !== tx_after_router)
            fail("outgoing packet data or hop update was incorrect");
        @(posedge clk);
        #0.1;
        if (DUT.router.out_buf_full_vc1[4] !== 1'b0)
            fail("router did not release the output buffer after acceptance");
        l2r_ro = 1'b0;
        $display("PASS: NIC packet routed east; backpressure held it and hop updated");

        // Inject a packet from node 6 into node 5. The external link transfers
        // VC1 when polarity is 0; drive the packet on a falling edge.
        @(negedge clk);
        while ((polarity !== 1'b0) || (r2l_ri !== 1'b1))
            @(negedge clk);
        r2l_di = rx_packet;
        r2l_si = 1'b1;
        @(posedge clk);
        if (r2l_ri !== 1'b1) fail("neighbor injected without router readiness");
        #0.1;
        @(negedge clk);
        r2l_si = 1'b0;
        r2l_di = 64'd0;

        // Router delivers through its PE output; the NIC captures the packet.
        receive_wait_cycles = 0;
        while ((DUT.nic.net_ri !== 1'b0) && (receive_wait_cycles < 12)) begin
            @(posedge clk);
            #0.1;
            receive_wait_cycles = receive_wait_cycles + 1;
        end
        if (DUT.nic.net_ri !== 1'b0)
            fail("router did not deliver the neighbor packet to the NIC");
        if (DUT.nic.input_buf !== rx_after_router)
            fail("router-to-NIC packet data or hop update was incorrect");
        $display("PASS: neighbor packet routed to the NIC input buffer");

        // Read address 01 (input status): it reports one while packet is queued.
        @(negedge clk);
        nic_addr = 2'b01;
        nic_en   = 1'b1;
        nic_wren = 1'b0;
        @(posedge clk);
        #0.1;
        if (nic_dout !== 64'd1)
            fail("input status did not report a full buffer");

        // Read address 00: return the packet and release the input buffer.
        @(negedge clk);
        nic_addr = 2'b00;
        @(posedge clk);
        #0.1;
        if (nic_dout !== rx_after_router)
            fail("processor read did not return the received packet");
        if (DUT.nic.net_ri !== 1'b1)
            fail("NIC input was not re-opened after packet read");

        // Confirm status changes to empty after the consuming read.
        @(negedge clk);
        nic_addr = 2'b01;
        @(posedge clk);
        #0.1;
        if (nic_dout !== 64'd0)
            fail("input status remained full after packet read");
        nic_en = 1'b0;

        $display("PASS: processor read returned the packet and freed the NIC");
        $display("ALL SINGLE-NODE ROUTER/NIC TESTS PASSED.");
        $finish;
    end

endmodule
