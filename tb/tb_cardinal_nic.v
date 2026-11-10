`timescale 1ns/10ps

/////////////////////////////////////////////////////////////////////////////
// Cardinal NIC verification testbench (Phase 3)
//
// Exercises the NIC through its public processor and router interfaces:
//   - synchronous reset, including activity presented during reset
//   - processor register map addresses 00, 01, 10 and 11
//   - input-buffer ready/backpressure, read release and ignored writes
//   - output-buffer blocking, phase qualification, ignored writes and release
//   - VC0 and VC1 packet transfers
//   - simultaneous router receive and router send
//
// Inputs are driven on falling edges. State and transfers are checked after
// rising edges, matching the 4 ns / 250 MHz course timing.
// Packet buses use [0:63], so bit 0 is the VC bit.
/////////////////////////////////////////////////////////////////////////////
module tb_cardinal_nic;

    localparam integer CYCLE_TIME = 4;

    reg         clk;
    reg         reset;
    reg  [0:1]  addr;
    reg  [0:63] d_in;
    wire [0:63] d_out;
    reg         nicEn;
    reg         nicWrEn;

    reg         net_si;
    wire        net_ri;
    reg  [0:63] net_di;

    wire        net_so;
    reg         net_ro;
    wire [0:63] net_do;
    reg         net_polarity;

    reg  [0:63] expected_packet;
    reg  [0:63] input_packet_a;
    reg  [0:63] input_packet_b;
    reg  [0:63] input_packet_concurrent;
    reg  [0:63] packet_vc0;
    reg  [0:63] packet_vc1;
    reg  [0:63] replacement_packet;
    reg  [0:63] read_value;

    integer errors;
    integer send_events;

    cardinal_nic NIC (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .d_in(d_in),
        .d_out(d_out),
        .nicEn(nicEn),
        .nicWrEn(nicWrEn),
        .net_si(net_si),
        .net_ri(net_ri),
        .net_di(net_di),
        .net_so(net_so),
        .net_ro(net_ro),
        .net_do(net_do),
        .net_polarity(net_polarity)
    );

    always #(CYCLE_TIME / 2) clk = ~clk;

    // Model the mesh polarity: zero during reset, then toggle each rising edge.
    always @(posedge clk) begin
        if (reset)
            net_polarity <= 1'b0;
        else
            net_polarity <= ~net_polarity;
    end

    // Observe transfers the way the router does: at the rising edge.
    always @(posedge clk) begin
        if (!reset && (net_so === 1'b1)) begin
            send_events = send_events + 1;
            $display("%0t ns: accepted send #%0d, packet=%h polarity=%b",
                     $time, send_events, net_do, net_polarity);

            if (net_ro !== 1'b1) begin
                $display("ERROR: net_so was high while net_ro was not high");
                errors = errors + 1;
            end
            if (net_polarity !== ~net_do[0]) begin
                $display("ERROR: packet was offered in the wrong VC phase");
                errors = errors + 1;
            end
            if (net_do !== expected_packet) begin
                $display("ERROR: sent packet %h, expected %h",
                         net_do, expected_packet);
                errors = errors + 1;
            end
        end
    end

    task check_bit;
        input [8*64-1:0] test_name;
        input            actual;
        input            expected;
        begin
            if (actual !== expected) begin
                $display("ERROR at %0t ns: %0s got %b, expected %b",
                         $time, test_name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS at %0t ns: %0s = %b",
                         $time, test_name, actual);
            end
        end
    endtask

    task check_word;
        input [8*64-1:0] test_name;
        input [0:63]     actual;
        input [0:63]     expected;
        begin
            if (actual !== expected) begin
                $display("ERROR at %0t ns: %0s got %h, expected %h",
                         $time, test_name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS at %0t ns: %0s = %h",
                         $time, test_name, actual);
            end
        end
    endtask

    task check_count;
        input [8*64-1:0] test_name;
        input integer    actual;
        input integer    expected;
        begin
            if (actual != expected) begin
                $display("ERROR at %0t ns: %0s got %0d, expected %0d",
                         $time, test_name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS at %0t ns: %0s = %0d",
                         $time, test_name, actual);
            end
        end
    endtask

    // Drive a processor read before an edge and sample registered d_out after it.
    task cpu_load;
        input  [0:1]  selected_addr;
        output [0:63] value;
        begin
            @(negedge clk);
            addr   = selected_addr;
            nicEn  = 1'b1;
            nicWrEn = 1'b0;

            @(posedge clk);
            #1;
            value = d_out;

            @(negedge clk);
            nicEn   = 1'b0;
            nicWrEn = 1'b0;
        end
    endtask

    // Drive a processor store for one rising edge.
    task cpu_store;
        input [0:1]  selected_addr;
        input [0:63] value;
        begin
            @(negedge clk);
            addr    = selected_addr;
            d_in    = value;
            nicEn   = 1'b1;
            nicWrEn = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            nicEn   = 1'b0;
            nicWrEn = 1'b0;
        end
    endtask

    // Send one packet from the modeled router to the NIC.
    task router_inject;
        input [0:63] packet;
        begin
            @(negedge clk);
            net_di = packet;
            net_si = 1'b1;
            check_bit("net_ri before router injection", net_ri, 1'b1);

            @(posedge clk);
            #1;
            check_bit("net_ri after router injection", net_ri, 1'b0);

            @(negedge clk);
            net_si = 1'b0;
        end
    endtask

    // Exercise one queued output packet. The second attempted store should
    // be ignored. Optionally inject a router packet on the same edge that
    // the output packet is accepted.
    task exercise_output_packet;
        input [0:63] queued_packet;
        input [0:63] second_store;
        input        inject_on_send;
        input [0:63] concurrent_input_packet;

        reg [0:63] status_value;
        integer    sends_before;
        integer    wait_edges;
        begin
            expected_packet = queued_packet;

            // Prevent a send while the processor first fills the output buffer.
            net_ro = 1'b0;
            cpu_store(2'b10, queued_packet);
            check_word("net_do while output packet is queued",
                       net_do, queued_packet);

            cpu_load(2'b11, status_value);
            check_word("output status after address-10 store",
                       status_value, 64'h0000_0000_0000_0001);

            // Read from the write-only address: it must not consume the packet.
            cpu_load(2'b10, status_value);
            check_word("read from write-only address 10",
                       status_value, 64'd0);
            check_word("packet remains after address-10 read",
                       net_do, queued_packet);

            // A second store while full, and a write to read-only address 11,
            // must both leave the queued packet and its full state unchanged.
            cpu_store(2'b10, second_store);
            check_word("full output buffer rejects second store",
                       net_do, queued_packet);
            cpu_store(2'b11, second_store);
            cpu_load(2'b11, status_value);
            check_word("output status after ignored write to address 11",
                       status_value, 64'h0000_0000_0000_0001);
            check_word("packet survives ignored address-11 write",
                       net_do, queued_packet);

            // Ready low blocks the transfer. Data remains stable and SO stays low.
            repeat (3) begin
                @(posedge clk);
                #1;
                check_bit("net_so while router is not ready", net_so, 1'b0);
                check_word("net_do remains stable while blocked",
                           net_do, queued_packet);
            end

            // Make the router ready for one edge in the wrong phase.
            // The edge must not consume the packet.
            @(negedge clk);
            while (net_polarity !== queued_packet[0])
                @(negedge clk);
            net_ro = 1'b1;
            #1;
            check_bit("net_so in the wrong VC phase", net_so, 1'b0);
            sends_before = send_events;

            @(posedge clk);
            #1;
            check_word("packet remains after wrong-phase edge",
                       net_do, queued_packet);
            check_count("no send at wrong-phase edge",
                        send_events, sends_before);

            // The polarity toggles after that edge. Drop ready before the
            // next edge so this check remains a single wrong-phase attempt.
            @(negedge clk);
            net_ro = 1'b0;
            check_bit("net_so after blocking is restored", net_so, 1'b0);

            cpu_load(2'b11, status_value);
            check_word("output status remains full while blocked",
                       status_value, 64'h0000_0000_0000_0001);

            // Wait for the required phase, then let the router accept the packet.
            @(negedge clk);
            net_ro = 1'b1;
            wait_edges = 0;
            while ((net_so !== 1'b1) && (wait_edges < 6)) begin
                @(negedge clk);
                wait_edges = wait_edges + 1;
            end

            if (net_so !== 1'b1) begin
                $display("ERROR at %0t ns: timeout waiting for eligible net_so",
                         $time);
                errors = errors + 1;
                net_ro = 1'b0;
                // Clear the stuck packet so later test cases can still run.
                reset = 1'b1;
                @(posedge clk);
                #1;
                @(negedge clk);
                reset = 1'b0;
            end else begin
                check_word("net_do on eligible send edge",
                           net_do, queued_packet);

                if (inject_on_send) begin
                    net_di = concurrent_input_packet;
                    net_si = 1'b1;
                    check_bit("net_ri before simultaneous receive/send",
                              net_ri, 1'b1);
                end

                @(posedge clk);
                #1;
                check_count("send count after accepted packet",
                            send_events, sends_before + 1);
                check_bit("net_so after accepted packet",
                          net_so, 1'b0);
                check_word("net_do after output buffer empties",
                           net_do, 64'd0);

                if (inject_on_send)
                    check_bit("net_ri after simultaneous receive/send",
                              net_ri, 1'b0);

                @(negedge clk);
                net_ro = 1'b0;
                net_si = 1'b0;

                cpu_load(2'b11, status_value);
                check_word("output status after accepted send",
                           status_value, 64'd0);
            end
        end
    endtask

    initial begin
        clk         = 1'b0;
        reset       = 1'b1;
        addr        = 2'b10;
        d_in        = 64'h1234_5678_9ABC_DEF0;
        nicEn       = 1'b1;
        nicWrEn     = 1'b1;
        net_si      = 1'b1;
        net_di      = 64'hA135_2468_ACE0_1357;
        net_ro      = 1'b1;
        net_polarity = 1'b0;
        expected_packet = 64'd0;
        errors      = 0;
        send_events = 0;

        input_packet_a          = 64'h0123_4567_89AB_CDEF;
        input_packet_b          = 64'hFEDC_BA98_7654_3210;
        input_packet_concurrent = 64'h55AA_00FF_1234_ABCD;
        packet_vc0              = 64'h1234_5678_9ABC_DEF0;
        packet_vc1              = 64'h9234_5678_9ABC_DEF1;
        replacement_packet      = 64'h8123_4567_89AB_DEAD;

        // 1. Reset must dominate simultaneous network receive and CPU store.
        repeat (3) begin
            @(posedge clk);
            #1;
            check_bit("net_ri during reset", net_ri, 1'b1);
            check_bit("net_so during reset", net_so, 1'b0);
            check_word("net_do during reset", net_do, 64'd0);
            check_word("d_out during reset", d_out, 64'd0);
        end

        @(negedge clk);
        reset   = 1'b0;
        net_si  = 1'b0;
        net_ro  = 1'b0;
        nicEn   = 1'b0;
        nicWrEn = 1'b0;
        d_in    = 64'd0;
        net_di  = 64'd0;

        cpu_load(2'b01, read_value);
        check_word("input status after reset", read_value, 64'd0);
        cpu_load(2'b11, read_value);
        check_word("output status after reset", read_value, 64'd0);

        // 2. A disabled processor write must not queue an output packet.
        @(negedge clk);
        nicEn   = 1'b0;
        nicWrEn = 1'b1;
        addr    = 2'b10;
        d_in    = packet_vc0;
        @(posedge clk);
        #1;
        check_word("d_out when processor access is disabled", d_out, 64'd0);
        @(negedge clk);
        nicWrEn = 1'b0;
        cpu_load(2'b11, read_value);
        check_word("disabled write left output buffer empty",
                   read_value, 64'd0);

        // 3. Input receive, full-buffer backpressure, and processor release.
        router_inject(input_packet_a);
        check_bit("net_ri while input buffer is full", net_ri, 1'b0);

        cpu_load(2'b01, read_value);
        check_word("input status reports full", read_value,
                   64'h0000_0000_0000_0001);
        check_bit("status read does not free input buffer", net_ri, 1'b0);

        // A disabled addr-00 read must not consume the received packet.
        @(negedge clk);
        nicEn   = 1'b0;
        nicWrEn = 1'b0;
        addr    = 2'b00;
        @(posedge clk);
        #1;
        check_word("disabled input read returns zero", d_out, 64'd0);
        check_bit("disabled input read preserves packet", net_ri, 1'b0);
        @(negedge clk);

        // Stores to input-buffer/status addresses are ignored.
        cpu_store(2'b00, input_packet_b);
        cpu_store(2'b01, input_packet_b);
        check_bit("ignored stores preserve full input buffer", net_ri, 1'b0);

        // Attempt another router receive while full; it must not overwrite A.
        @(negedge clk);
        net_di = input_packet_b;
        net_si = 1'b1;
        check_bit("net_ri blocks second router packet", net_ri, 1'b0);
        @(posedge clk);
        #1;
        check_bit("input buffer remains full after blocked receive",
                  net_ri, 1'b0);
        @(negedge clk);
        net_si = 1'b0;

        cpu_load(2'b00, read_value);
        check_word("address 00 returns the original input packet",
                   read_value, input_packet_a);
        check_bit("address 00 read releases input buffer", net_ri, 1'b1);
        cpu_load(2'b01, read_value);
        check_word("input status after packet read", read_value, 64'd0);

        // 4. Output tests: both VC values, blocking, phase, and simultaneous I/O.
        exercise_output_packet(packet_vc0, replacement_packet,
                               1'b0, input_packet_concurrent);
        exercise_output_packet(packet_vc1, packet_vc0,
                               1'b1, input_packet_concurrent);

        if (net_ri === 1'b0) begin
            cpu_load(2'b01, read_value);
            check_word("simultaneous receive left input full",
                       read_value, 64'h0000_0000_0000_0001);
            cpu_load(2'b00, read_value);
            check_word("simultaneously received packet",
                       read_value, input_packet_concurrent);
            check_bit("input buffer empty after concurrent packet read",
                      net_ri, 1'b1);
        end else begin
            $display("ERROR at %0t ns: expected concurrent input packet was not captured",
                     $time);
            errors = errors + 1;
        end

        check_count("total accepted output packets", send_events, 2);

        if (errors == 0)
            $display("ALL CARDINAL NIC TESTS PASSED");
        else
            $display("ALL CARDINAL NIC TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule

