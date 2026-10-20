`timescale 1ns/1ps

// Unit test for in_ctrl.
// Tests reset behavior, XY routing, backpressure/holding, and simultaneous
// forwarding of one VC while receiving the other VC.

module tb_in_ctrl;
    parameter PACKET_SIZE = 64;
    localparam NODE_ID = 5;
    localparam ROUTER_X = NODE_ID % 4;
    localparam ROUTER_Y = NODE_ID / 4;
    reg clk;
    reg reset;
    reg polarity;
    reg [PACKET_SIZE-1:0] data_in;
    reg si;
    reg [4:0] grant;

    wire ri;
    wire [4:0] req;
    wire [PACKET_SIZE-1:0] routed_data;

    in_ctrl #(
        .PACKET_SIZE(PACKET_SIZE),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) dut (
        .clk(clk),
        .reset(reset),
        .polarity(polarity),
        .data_in(data_in),
        .si(si),
        .ri(ri),
        .req(req),
        .routed_data(routed_data),
        .grant(grant)
    );
    // 250 MHz main clock, 4 ns period
    initial clk = 1'b0;
    always #2 clk = ~clk;

    // Mimic the shared top-level polarity register:
    // During reset polarity is 0; after reset it toggles on every rising edge.
    always @(posedge clk) begin
        if (reset)
            polarity <= 1'b0;
        else
            polarity <= ~polarity;
    end

    function [PACKET_SIZE-1:0] make_packet;
        input vc;
        input [1:0] dest_x;
        input [1:0] dest_y;
        input [7:0] hop_field;
        input [15:0] source;
        input [31:0] payload;
        begin
            make_packet = {vc, 1'b0, dest_x, dest_y, 2'b00,
                           hop_field, source, payload};
        end
    endfunction

    reg [PACKET_SIZE-1:0] packet1;
    reg [PACKET_SIZE-1:0] packet2;

    initial begin
        reset   = 1'b1;
        si      = 1'b0;
        data_in = {PACKET_SIZE{1'b0}};
        grant   = 5'b00000;
        polarity = 1'b0;

        // Local node 5 is (1,1)
        // Packet 1 targets (2,3), so XY routing must request L2R
        packet1 = make_packet(1'b1, 2'd2, 2'd3, 8'h0F, 16'd1, 32'd7);
        // Packet 2 targets (0,1), so XY routing must request R2L
        packet2 = make_packet(1'b0, 2'd0, 2'd1, 8'h01, 16'd9, 32'd8);

        // Keep reset asserted for two rising edges, polarity=0
        repeat (2) @(negedge clk);
        reset   = 1'b0;
        data_in = packet1;
        si      = 1'b1; // polarity 0 accepts VC1

        // Next rising edge captures packet1 into VC1, polarity then becomes 1
        @(posedge clk);
        #0.1;
        if (req !== 5'b10000 || routed_data !== packet1) begin
            $display("FAIL: packet1 was not routed L2R after capture.");
            $finish;
        end
        $display("PASS: packet1 captured and requests L2R.");

        // Do not grant yet, packet must remain buffered while phases alternate
        @(negedge clk);
        si      = 1'b0;
        data_in = {PACKET_SIZE{1'b0}};
        grant   = 5'b00000;

        @(posedge clk); // polarity 1: VC1 active internally, no grant
        #0.1;
        if (req !== 5'b00000 || ri !== 1'b0) begin
            $display("FAIL: expected VC1 to be held while inactive and input VC1 full.");
            $finish;
        end

        @(negedge clk); // polarity 0; VC1 remains occupied
        if (ri !== 1'b0) begin
            $display("FAIL: ri should be low because the incoming VC1 buffer is full.");
            $finish;
        end

        @(posedge clk); // no grant; phase returns to VC1 after edge
        #0.1;
        if (req !== 5'b10000 || routed_data !== packet1) begin
            $display("FAIL: packet1 was not held unchanged under backpressure.");
            $finish;
        end
        $display("PASS: packet1 remains buffered until granted.");

        // At polarity 1, receive VC0 packet2 while granting packet1 (VC1).
        // This verifies simultaneous operations on the two independent VCs.
        @(negedge clk);
        grant   = 5'b10000; // grant packet1's EAST request
        data_in = packet2;
        si      = 1'b1;     // polarity 1 accepts VC0
        if (ri !== 1'b1) begin
            $display("FAIL: expected ri=1 because the incoming VC0 buffer is empty.");
            $finish;
        end

        @(posedge clk);
        #0.1;
        if (req !== 5'b01000 || routed_data !== packet2) begin
            $display("FAIL: did not consume packet1 and capture packet2 correctly.");
            $finish;
        end
        if (ri !== 1'b1) begin
            $display("FAIL: ri should be high after packet1's VC1 buffer is released.");
            $finish;
        end
        $display("PASS: packet1 forwarded while packet2 was received; packet2 requests R2L.");

        // Hold packet2 without a grant, then grant it during the next VC0 phase.
        @(negedge clk);
        si      = 1'b0;
        grant   = 5'b00000;

        @(posedge clk); // polarity 0 internally processes VC0, but no grant
        #0.1;
        if (req !== 5'b00000 || ri !== 1'b0) begin
            $display("FAIL: expected packet2 to remain buffered and VC0 input blocked.");
            $finish;
        end

        @(negedge clk); // polarity 1; input VC0 is still full
        if (ri !== 1'b0) begin
            $display("FAIL: ri should be low while packet2 occupies VC0.");
            $finish;
        end

        @(posedge clk); // no grant, packet2 remains; polarity returns to 0
        #0.1;
        if (req !== 5'b01000 || routed_data !== packet2) begin
            $display("FAIL: packet2 was not held unchanged while waiting for grant.");
            $finish;
        end

        @(negedge clk);
        grant = 5'b01000; // grant packet2's R2L request
        si    = 1'b0;

        @(posedge clk);
        #0.1;
        if (req !== 5'b00000 || ri !== 1'b1) begin
            $display("FAIL: packet2 was not released after grant.");
            $finish;
        end

        $display("PASS: packet2 was released after its R2L grant.");
            $display("ALL INPUT-CONTROLLER TESTS PASSED.");
            $finish;
        end
    endmodule
