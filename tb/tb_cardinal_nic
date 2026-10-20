`timescale 1ns/1ps

// Cover all 4 processor addresses and legal/illegal read/write modes
// empty/full buffer behavior; input and output backpressure; both VC phases;
// every (dest_x,dest_y) pair in a 4x4 mesh for VC0 and VC1; simultaneous
// receive/transmit; full-buffer overwrite protection; and reset priority.
//
// Packet layout matches the provided 64-bit packet constructor:
// {vc, reserved, dest_x[1:0], dest_y[1:0], reserved[1:0], hop[7:0],
//  source[15:0], payload[31:0]}.
//------------------------------------------------------------------------------
module tb_cardinal_nic;
    parameter integer PACKET_SIZE = 64;

    reg clk;
    reg reset;
    reg [1:0] addr;
    reg [PACKET_SIZE-1:0] d_in;
    wire [PACKET_SIZE-1:0] d_out;
    reg nicEn;
    reg nicEnWr;

    reg net_si;
    wire net_ri;
    reg [PACKET_SIZE-1:0] net_di;
    wire net_so;
    reg net_ro;
    wire [PACKET_SIZE-1:0] net_do;
    reg net_polarity;

    integer errors;
    integer a;
    integer vc_i;
    integer dx_i;
    integer dy_i;
    reg [PACKET_SIZE-1:0] packet;
    reg [PACKET_SIZE-1:0] packet_a;
    reg [PACKET_SIZE-1:0] packet_b;
    reg [PACKET_SIZE-1:0] expected_status;

    cardinal_nic #(.PACKET_SIZE(PACKET_SIZE)) dut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .d_in(d_in),
        .d_out(d_out),
        .nicEn(nicEn),
        .nicEnWr(nicEnWr),
        .net_si(net_si),
        .net_ri(net_ri),
        .net_di(net_di),
        .net_so(net_so),
        .net_ro(net_ro),
        .net_do(net_do),
        .net_polarity(net_polarity)
    );

    // 100 MHz test clock; timing itself is not part of the NIC specification.
    initial clk = 1'b0;
    always #5 clk = ~clk;

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

    task check_bit;
        input actual;
        input expected;
        input [8*120-1:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL @%0t: %0s; expected=%b actual=%b",
                         $time, label_text, expected, actual);
                errors = errors + 1;
            end
        end
    endtask

    task check_packet;
        input [PACKET_SIZE-1:0] actual;
        input [PACKET_SIZE-1:0] expected;
        input [8*120-1:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL @%0t: %0s", $time, label_text);
                $display("      expected=%h", expected);
                $display("      actual  =%h", actual);
                errors = errors + 1;
            end
        end
    endtask

    task check_status;
        input [1:0] status_addr;
        input expected;
        input [8*120-1:0] label_text;
        begin
            nicEn = 1'b1;
            nicEnWr = 1'b0;
            addr = status_addr;
            #1;
            expected_status = {{(PACKET_SIZE-1){1'b0}}, expected};
            check_packet(d_out, expected_status, label_text);
        end
    endtask

    task store_output;
        input [PACKET_SIZE-1:0] p;
        begin
            @(negedge clk);
            nicEn = 1'b1;
            nicEnWr = 1'b1;
            addr = 2'b10;
            d_in = p;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        errors = 0;
        reset = 1'b1;
        addr = 2'b00;
        d_in = {PACKET_SIZE{1'b0}};
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        net_si = 1'b0;
        net_di = {PACKET_SIZE{1'b0}};
        net_ro = 1'b0;
        net_polarity = 1'b0;

        packet_a = make_packet(1'b1, 2'd2, 2'd3, 8'hA5, 16'h1234, 32'hCAFE0001);
        packet_b = make_packet(1'b0, 2'd0, 2'd1, 8'h3C, 16'h5678, 32'hBEEF0002);

        // ------------------------------------------------------------------
        // 1. Reset initializes both empty buffers and handshakes.
        // ------------------------------------------------------------------
        repeat (2) @(posedge clk);
        #1;
        check_bit(net_ri, 1'b1, "reset leaves input channel ready");
        check_bit(net_so, 1'b0, "reset leaves output send low");
        check_packet(net_do, {PACKET_SIZE{1'b0}}, "reset output data is zero");
        check_status(2'b01, 1'b0, "input status is empty after reset");
        check_status(2'b11, 1'b0, "output status is empty after reset");

        @(negedge clk);
        reset = 1'b0;
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        #1;

        // ------------------------------------------------------------------
        // 2. Disabled reads and write-mode reads return zero for all addresses.
        // ------------------------------------------------------------------
        for (a = 0; a < 4; a = a + 1) begin
            @(negedge clk);
            addr = a[1:0];
            nicEn = 1'b0;
            nicEnWr = 1'b0;
            #1;
            check_packet(d_out, {PACKET_SIZE{1'b0}}, "d_out is zero when nicEn=0");

            nicEn = 1'b0;
            nicEnWr = 1'b1;
            #1;
            check_packet(d_out, {PACKET_SIZE{1'b0}}, "d_out is zero when disabled with write-enable high");

            nicEn = 1'b1;
            nicEnWr = 1'b1;
            #1;
            check_packet(d_out, {PACKET_SIZE{1'b0}}, "d_out is zero during processor write");
            // This section checks read-port mux behavior only; do not leave
            // a legal addr=10 store enabled across the next active edge.
            nicEn = 1'b0;
            nicEnWr = 1'b0;
        end

        // Empty input-buffer reads return zero in this implementation (allowed
        // by the spec, which defines empty-buffer reads as unspecified).
        @(negedge clk);
        nicEn = 1'b1;
        nicEnWr = 1'b0;
        addr = 2'b00;
        #1;
        check_packet(d_out, {PACKET_SIZE{1'b0}}, "empty input-buffer read returns zero");

        // ------------------------------------------------------------------
        // 3. Stores to read-only addresses 00, 01, and 11 are ignored.
        // ------------------------------------------------------------------
        for (a = 0; a < 4; a = a + 1) begin
            if (a != 2) begin
                @(negedge clk);
                nicEn = 1'b1;
                nicEnWr = 1'b1;
                addr = a[1:0];
                d_in = ~packet_a;
                net_si = 1'b0;
                @(posedge clk);
                #1;
                check_bit(net_ri, 1'b1, "illegal processor write does not fill input buffer");
                check_status(2'b01, 1'b0, "illegal write leaves input status empty");
                check_status(2'b11, 1'b0, "illegal write leaves output status empty");
            end
        end

        // ------------------------------------------------------------------
        // 4. Output buffer write, full-buffer overwrite protection, and reads.
        // ------------------------------------------------------------------
        net_ro = 1'b0;
        net_polarity = 1'b0; // VC1 is eligible at polarity 0.
        store_output(packet_a);
        check_status(2'b11, 1'b1, "legal store sets output status full");
        check_packet(net_do, packet_a, "output packet is visible while buffered");
        check_bit(net_so, 1'b0, "output send waits while router is not ready");

        // An attempted write while full must not corrupt packet_a.
        @(negedge clk);
        nicEn = 1'b1;
        nicEnWr = 1'b1;
        addr = 2'b10;
        d_in = packet_b;
        net_ro = 1'b0;
        @(posedge clk);
        #1;
        check_status(2'b11, 1'b1, "output buffer remains full after rejected overwrite");
        check_packet(net_do, packet_a, "rejected overwrite preserves original output packet");

        // Address 10 is write-only; attempting to read it returns zero.
        @(negedge clk);
        nicEn = 1'b1;
        nicEnWr = 1'b0;
        addr = 2'b10;
        #1;
        check_packet(d_out, {PACKET_SIZE{1'b0}}, "output-buffer read returns zero");

        // Wrong phase must stall an occupied output buffer even when net_ro=1.
        @(negedge clk);
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        net_ro = 1'b1;
        net_polarity = 1'b1; // packet_a VC=1; wrong phase
        #1;
        check_bit(net_so, 1'b0, "wrong VC polarity blocks output send");
        check_packet(net_do, packet_a, "packet remains visible during wrong phase");
        @(posedge clk);
        #1;
        check_status(2'b11, 1'b1, "wrong phase does not consume output packet");
        check_packet(net_do, packet_a, "packet is held across wrong-phase clock edge");

        // Correct phase but no router readiness must also hold the packet.
        @(negedge clk);
        nicEn = 1'b0;
        net_polarity = 1'b0;
        net_ro = 1'b0;
        #1;
        check_bit(net_so, 1'b0, "correct VC phase still waits for net_ro");
        check_packet(net_do, packet_a, "packet data remains stable under backpressure");

        // Simultaneously transmit packet_a and receive packet_b: the two
        // directions are independent and may complete on the same rising edge.
        net_ro = 1'b1;
        net_si = 1'b1;
        net_di = packet_b;
        #1;
        check_bit(net_so, 1'b1, "matching phase plus net_ro asserts net_so");
        check_bit(net_ri, 1'b1, "empty input buffer is ready for simultaneous receive");
        @(posedge clk);
        #1;
        check_bit(net_so, 1'b0, "net_so deasserts after output transfer");
        check_packet(net_do, {PACKET_SIZE{1'b0}}, "net_do returns zero after output buffer empties");
        check_bit(net_ri, 1'b0, "input buffer becomes full after simultaneous receive");
        check_status(2'b11, 1'b0, "output buffer is empty after transfer");
        check_status(2'b01, 1'b1, "input buffer is full after simultaneous receive");

        // Read and consume packet_b from the input channel.
        @(negedge clk);
        net_si = 1'b0;
        nicEn = 1'b1;
        nicEnWr = 1'b0;
        addr = 2'b00;
        #1;
        check_packet(d_out, packet_b, "input-buffer read returns received packet");
        @(posedge clk);
        #1;
        check_bit(net_ri, 1'b1, "reading input packet releases input buffer");
        check_packet(d_out, {PACKET_SIZE{1'b0}}, "consumed input packet is no longer readable");

        // A processor store on the exact edge an occupied packet transmits is
        // still ignored: the buffer was full before that edge.
        store_output(packet_a);
        @(negedge clk);
        nicEn = 1'b1;
        nicEnWr = 1'b1;
        addr = 2'b10;
        d_in = packet_b;
        net_ro = 1'b1;
        net_polarity = 1'b0;
        net_si = 1'b0;
        #1;
        check_bit(net_so, 1'b1, "occupied packet transmits during concurrent CPU store");
        @(posedge clk);
        #1;
        check_status(2'b11, 1'b0, "concurrent store is ignored when old packet transmits");
        check_packet(net_do, {PACKET_SIZE{1'b0}}, "output remains empty after concurrent store");

        // ------------------------------------------------------------------
        // 5. Exhaust output routing-phase eligibility for all 16 mesh
        //    destination coordinates and both VC values (32 packets total).
        //    NIC forwards destination fields opaquely; mesh routing is in router.
        // ------------------------------------------------------------------
        net_ro = 1'b0;
        net_si = 1'b0;
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        for (vc_i = 0; vc_i < 2; vc_i = vc_i + 1) begin
            for (dx_i = 0; dx_i < 4; dx_i = dx_i + 1) begin
                for (dy_i = 0; dy_i < 4; dy_i = dy_i + 1) begin
                    packet = make_packet(vc_i[0], dx_i[1:0], dy_i[1:0],
                                         8'h5A,
                                         (16'd1000 + vc_i*100 + dx_i*10 + dy_i),
                                         (32'h12340000 | (vc_i << 8) | (dx_i << 4) | dy_i));
                    store_output(packet);
                    check_packet(net_do, packet, "output buffer preserves every tested 4x4 destination packet");

                    // A packet with VC=1 is blocked at polarity=1; VC=0 is
                    // blocked at polarity=0. This is exactly vc != ~polarity.
                    @(negedge clk);
                    nicEn = 1'b0;
                    nicEnWr = 1'b0;
                    net_ro = 1'b1;
                    net_polarity = vc_i[0];
                    #1;
                    check_bit(net_so, 1'b0, "wrong phase blocks each VC/destination combination");
                    check_packet(net_do, packet, "blocked packet remains unchanged");
                    @(posedge clk);
                    #1;
                    check_packet(net_do, packet, "blocked packet survives a rising edge");
                    check_status(2'b11, 1'b1, "blocked output packet remains marked full");

                    @(negedge clk);
                    nicEn = 1'b0;
                    net_polarity = ~vc_i[0];
                    net_ro = 1'b0;
                    #1;
                    check_bit(net_so, 1'b0, "matching phase cannot send without net_ro");
                    net_ro = 1'b1;
                    #1;
                    check_bit(net_so, 1'b1, "matching phase and net_ro send each VC/destination packet");
                    check_packet(net_do, packet, "transmitted packet data matches stored packet");
                    @(posedge clk);
                    #1;
                    check_bit(net_so, 1'b0, "send clears after each transfer");
                    check_packet(net_do, {PACKET_SIZE{1'b0}}, "output data clears when output buffer empties");
                    check_status(2'b11, 1'b0, "output status clears after each transfer");
                end
            end
        end

        // ------------------------------------------------------------------
        // 6. Input reception tests every VC and destination pair; checks ready,
        //    full-buffer backpressure, read data, status bit placement and consume.
        // ------------------------------------------------------------------
        net_ro = 1'b0;
        net_si = 1'b0;
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        for (vc_i = 0; vc_i < 2; vc_i = vc_i + 1) begin
            for (dx_i = 0; dx_i < 4; dx_i = dx_i + 1) begin
                for (dy_i = 0; dy_i < 4; dy_i = dy_i + 1) begin
                    packet = make_packet(vc_i[0], dx_i[1:0], dy_i[1:0],
                                         8'hC3,
                                         (16'd2000 + vc_i*100 + dx_i*10 + dy_i),
                                         (32'hABCD0000 | (vc_i << 8) | (dx_i << 4) | dy_i));

                    @(negedge clk);
                    nicEn = 1'b0;
                    nicEnWr = 1'b0;
                    net_si = 1'b1;
                    net_di = packet;
                    #1;
                    check_bit(net_ri, 1'b1, "empty input buffer advertises ready");
                    @(posedge clk);
                    #1;
                    check_bit(net_ri, 1'b0, "accepted packet makes input buffer full");

                    // Try to overwrite the full input buffer. net_ri=0 must
                    // prevent capture even though net_si remains asserted.
                    @(negedge clk);
                    net_si = 1'b1;
                    net_di = ~packet;
                    nicEn = 1'b0;
                    nicEnWr = 1'b0;
                    addr = 2'b00; // Disabled processor read must not consume it.
                    #1;
                    check_bit(net_ri, 1'b0, "full input buffer deasserts ready");
                    @(posedge clk);
                    #1;
                    check_bit(net_ri, 1'b0, "full input buffer stays full under backpressure");

                    // Inspect packet and status before the read-consume edge.
                    nicEn = 1'b1;
                    nicEnWr = 1'b0;
                    addr = 2'b00;
                    #1;
                    check_packet(d_out, packet, "input buffer preserves received packet exactly");
                    addr = 2'b01;
                    #1;
                    expected_status = {{(PACKET_SIZE-1){1'b0}}, 1'b1};
                    check_packet(d_out, expected_status, "input status is in LSB and all other bits are zero");

                    // Reading address 00 consumes the packet at the next edge.
                    @(negedge clk);
                    net_si = 1'b0;
                    addr = 2'b00;
                    #1;
                    check_packet(d_out, packet, "input data remains available until consume edge");
                    @(posedge clk);
                    #1;
                    check_bit(net_ri, 1'b1, "input buffer becomes ready after read");
                    check_packet(d_out, {PACKET_SIZE{1'b0}}, "input data read returns zero after consume");
                    check_status(2'b01, 1'b0, "input status clears after read");
                    nicEn = 1'b0;
                    nicEnWr = 1'b0;
                end
            end
        end

        // ------------------------------------------------------------------
        // 7. Reset priority with both buffers occupied and activity attempted.
        // ------------------------------------------------------------------
        net_ro = 1'b0;
        net_si = 1'b0;
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        store_output(packet_a);
        @(negedge clk);
        net_si = 1'b1;
        net_di = packet_b;
        @(posedge clk);
        #1;
        check_status(2'b01, 1'b1, "input buffer filled before reset-priority test");
        check_status(2'b11, 1'b1, "output buffer filled before reset-priority test");

        @(negedge clk);
        reset = 1'b1;
        net_si = 1'b1;
        net_ro = 1'b1;
        net_polarity = 1'b0;
        nicEn = 1'b1;
        nicEnWr = 1'b1;
        addr = 2'b10;
        d_in = ~packet_b;
        @(posedge clk);
        #1;
        check_bit(net_ri, 1'b1, "reset clears input full state despite net_si");
        check_bit(net_so, 1'b0, "reset clears output send state");
        check_packet(net_do, {PACKET_SIZE{1'b0}}, "reset empties output data channel");
        check_status(2'b01, 1'b0, "reset clears input status");
        check_status(2'b11, 1'b0, "reset clears output status");

        @(negedge clk);
        reset = 1'b0;
        net_si = 1'b0;
        net_ro = 1'b0;
        nicEn = 1'b0;
        nicEnWr = 1'b0;
        #1;
        check_bit(net_ri, 1'b1, "input is ready after reset is deasserted");
        check_bit(net_so, 1'b0, "output send stays low after reset is deasserted");

        if (errors == 0) begin
            $display("\nALL CARDINAL NIC TESTS PASSED.");
        end else begin
            $display("\nCARDINAL NIC TESTS FAILED: %0d error(s).", errors);
        end
        $finish;
    end
endmodule
