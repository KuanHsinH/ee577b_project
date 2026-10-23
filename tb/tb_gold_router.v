`timescale 1ns/1ps

// Standalone directed testbench for gold_router at node 5 = (1,1).
// It checks reset, all five ingress ready signals, XY forwarding, hop-field
// decrement, output backpressure/consumption, and the PE delivery path.
module tb_gold_router;
    parameter PACKET_SIZE = 64;

    localparam PE  = 0;
    localparam U2D = 1;
    localparam D2U = 2;
    localparam R2L = 3;
    localparam L2R = 4;

    reg clk, reset;
    reg [4:0] si, ro;
    reg [PACKET_SIZE-1:0] di [0:4];
    wire [4:0] ri, so;
    wire [PACKET_SIZE-1:0] dout [0:4];
    wire polarity;
    integer router_log_fd;
    reg pe_protocol_violation;

    gold_router #(.PACKET_SIZE(PACKET_SIZE), .NODE_NUMBER(5)) dut (
        .clk(clk), .reset(reset), .polarity(polarity),
        .L2R_si(si[L2R]), .L2R_ri(ri[L2R]), .L2R_di(di[L2R]),
        .R2L_si(si[R2L]), .R2L_ri(ri[R2L]), .R2L_di(di[R2L]),
        .D2U_si(si[D2U]), .D2U_ri(ri[D2U]), .D2U_di(di[D2U]),
        .U2D_si(si[U2D]), .U2D_ri(ri[U2D]), .U2D_di(di[U2D]),
        .PE_si(si[PE]), .PE_ri(ri[PE]), .PE_di(di[PE]),
        .L2R_so(so[L2R]), .L2R_ro(ro[L2R]), .L2R_do(dout[L2R]),
        .R2L_so(so[R2L]), .R2L_ro(ro[R2L]), .R2L_do(dout[R2L]),
        .D2U_so(so[D2U]), .D2U_ro(ro[D2U]), .D2U_do(dout[D2U]),
        .U2D_so(so[U2D]), .U2D_ro(ro[U2D]), .U2D_do(dout[U2D]),
        .PE_so(so[PE]), .PE_ro(ro[PE]), .PE_do(dout[PE])
    );

    initial clk = 1'b0;
    always #2 clk = ~clk;

    function [PACKET_SIZE-1:0] make_packet;
        input vc;
        input [1:0] dx, dy;
        input [7:0] hops;
        input [31:0] id;
        begin
            make_packet = {vc, 1'b0, dx, dy, 2'b00, hops, 16'd5, id};
        end
    endfunction

    function [PACKET_SIZE-1:0] make_packet_from;
        input [15:0] src;
        input vc;
        input [1:0] dx, dy;
        input [7:0] hops;
        input [31:0] id;
        begin
            make_packet_from = {vc, 1'b0, dx, dy, 2'b00, hops, src, id};
        end
    endfunction

    function selected_output_full;
        input integer out_port;
        input vc;
        begin
            if (vc)
                selected_output_full = dut.out_buf_full_vc1[out_port];
            else
                selected_output_full = dut.out_buf_full_vc0[out_port];
        end
    endfunction

    task run_case;
        input integer in_port;
        input integer out_port;
        input vc;
        input [1:0] dx, dy;
        input [7:0] hops;
        input [31:0] id;
        reg [PACKET_SIZE-1:0] packet, expected;
        integer cycles;
        reg seen;
        begin
            // Start each case with known empty buffers and VC1 receive phase.
            @(negedge clk);
            reset = 1'b1;
            si = 5'b0;
            ro = 5'b0;
            repeat (2) @(posedge clk);
            #0.1;
            if (polarity !== 1'b0 || so !== 5'b0 || ri !== 5'b11111) begin
                $display("FAIL: reset interface state is polarity=%b so=%b ri=%b", polarity, so, ri);
                $finish(1);
            end
            $fdisplay(router_log_fd,
                      "TEST=SWITCH_CASE_START Time=%0.3f ns Input=%0d Output=%0d VC=%0d ID=%0d",
                      $realtime, in_port, out_port, vc, id);

            packet = make_packet(vc, dx, dy, hops, id);
            expected = packet;
            expected[55:48] = packet[55:48] >> 1;

            @(negedge clk);
            reset = 1'b0;
            // VC1 is received during polarity 0; VC0 is received during
            // polarity 1, so advance once before offering a VC0 packet.
            if (!vc) begin
                @(posedge clk); #0.1;
                @(negedge clk);
            end
            di[in_port] = packet;
            si[in_port] = 1'b1;
            if (ri[in_port] !== 1'b1) begin
                $display("FAIL: ingress %0d not ready for VC1", in_port);
                $finish(1);
            end

            // Capture occurs at the offered phase. The matching internal VC
            // forwards on its next active phase, then the output VC is visible.
            @(posedge clk); #0.1;
            @(negedge clk); si[in_port] = 1'b0;
            cycles = 0;
            seen = 1'b0;
            if (out_port == PE) begin
                // PE_so must remain low while PE_ro is low. Observe the PE
                // output buffer directly so this test can still record and
                // drain the packet even if the current RTL violates that rule.
                while (!seen && cycles < 10) begin
                    @(posedge clk); #0.1;
                    if (selected_output_full(PE, vc) === 1'b1) seen = 1'b1;
                    cycles = cycles + 1;
                end
                if (!seen) begin
                    $display("FAIL: PE output buffer did not capture packet id=%0d", id);
                    $finish(1);
                end
                if (id == 32'd16)
                    $display("SCREENSHOT: ROUTER_PE_BLOCKED_THEN_RELEASED (zoom around 500-516 ns), time = %0.3f ns",
                             $realtime);
                if (so[PE] !== 1'b0) begin
                    pe_protocol_violation = 1'b1;
                    $fdisplay(router_log_fd,
                              "ASSERTION=PE_SO_HIGH_WHILE_PE_RO_LOW Time=%0.3f ns ID=%0d",
                              $realtime, id);
                    $display("FAIL: PE_so=%b while PE_ro=0 for id=%0d", so[PE], id);
                end
                if (polarity === ~vc && dout[PE] !== expected) begin
                    $display("FAIL: blocked PE output data=%h expected=%h", dout[PE], expected);
                    $finish(1);
                end
                repeat (2) begin
                    @(posedge clk); #0.1;
                    if (selected_output_full(PE, vc) !== 1'b1 ||
                        (polarity === ~vc && dout[PE] !== expected)) begin
                        $display("FAIL: blocked PE packet was not held unchanged");
                        $finish(1);
                    end
                    if (so[PE] !== 1'b0) begin
                        pe_protocol_violation = 1'b1;
                        $fdisplay(router_log_fd,
                                  "ASSERTION=PE_SO_HIGH_WHILE_PE_RO_LOW Time=%0.3f ns ID=%0d",
                                  $realtime, id);
                    end
                end
                @(negedge clk); ro[PE] = 1'b1;
                #0.1;
                if (so[PE] !== 1'b1 || dout[PE] !== expected) begin
                    $display("FAIL: PE packet did not become valid after PE_ro was raised");
                    $finish(1);
                end
                @(posedge clk);
                @(negedge clk); ro[PE] = 1'b0;
            end else begin
                while (!seen && cycles < 10) begin
                    @(posedge clk); #0.1;
                    if (selected_output_full(out_port, vc) === 1'b1) seen = 1'b1;
                    cycles = cycles + 1;
                end
                if (!seen) begin
                    $display("FAIL: no output %0d for input %0d, destination=(%0d,%0d), hop=%h",
                             out_port, in_port, dx, dy, hops);
                    $finish(1);
                end
                if (so[out_port] !== 1'b0 ||
                    (polarity === ~vc && dout[out_port] !== expected)) begin
                    $display("FAIL: blocked output mismatch input=%0d output=%0d so=%b data=%h expected=%h",
                             in_port, out_port, so[out_port], dout[out_port], expected);
                    $finish(1);
                end
                repeat (2) begin
                    @(posedge clk); #0.1;
                    if (selected_output_full(out_port, vc) !== 1'b1) begin
                        $display("FAIL: output buffer %0d lost packet under backpressure", out_port);
                        $finish(1);
                    end
                    if (so[out_port] !== 1'b0) begin
                        $display("FAIL: output %0d asserted SO while RO was low", out_port);
                        $finish(1);
                    end
                    if (polarity === ~vc &&
                        dout[out_port] !== expected) begin
                        $display("FAIL: output %0d did not hold packet under backpressure", out_port);
                        $finish(1);
                    end
                end
                @(negedge clk); ro[out_port] = 1'b1;
                #0.1;
                if (so !== (5'b00001 << out_port) || dout[out_port] !== expected) begin
                    $display("FAIL: output %0d did not assert SO with RO and buffered data",
                             out_port);
                    $finish(1);
                end
                @(posedge clk);
                @(negedge clk); ro[out_port] = 1'b0;
            end
            $fdisplay(router_log_fd,
                      "TEST=SWITCH_CASE_END Time=%0.3f ns Input=%0d Output=%0d VC=%0d ID=%0d",
                      $realtime, in_port, out_port, vc, id);
            $display("PASS: input %0d routed to output %0d, hop=%h (%0.3f ns)",
                     in_port, out_port, dout[out_port][55:48], $realtime);
        end
    endtask

    task run_all_legal_switches;
        input vc;
        input integer id_base;
        begin
            // Every legal XY input-to-output connection at router 5:
            // PE has four directional outputs; lateral inputs can continue
            // or turn vertically; vertical inputs continue or deliver to PE.
            run_case(PE,  L2R, vc, 2'd2, 2'd1, 8'h01, id_base + 0);
            run_case(PE,  R2L, vc, 2'd0, 2'd1, 8'h01, id_base + 1);
            run_case(PE,  U2D, vc, 2'd1, 2'd2, 8'h01, id_base + 2);
            run_case(PE,  D2U, vc, 2'd1, 2'd0, 8'h01, id_base + 3);
            run_case(L2R, L2R, vc, 2'd2, 2'd1, 8'h01, id_base + 4);
            run_case(L2R, D2U, vc, 2'd1, 2'd0, 8'h01, id_base + 5);
            run_case(L2R, U2D, vc, 2'd1, 2'd2, 8'h01, id_base + 6);
            run_case(L2R, PE,  vc, 2'd1, 2'd1, 8'h00, id_base + 7);
            run_case(R2L, R2L, vc, 2'd0, 2'd1, 8'h01, id_base + 8);
            run_case(R2L, D2U, vc, 2'd1, 2'd0, 8'h01, id_base + 9);
            run_case(R2L, U2D, vc, 2'd1, 2'd2, 8'h01, id_base + 10);
            run_case(R2L, PE,  vc, 2'd1, 2'd1, 8'h00, id_base + 11);
            run_case(U2D, U2D, vc, 2'd1, 2'd2, 8'h01, id_base + 12);
            run_case(U2D, PE,  vc, 2'd1, 2'd1, 8'h00, id_base + 13);
            run_case(D2U, D2U, vc, 2'd1, 2'd0, 8'h01, id_base + 14);
            run_case(D2U, PE,  vc, 2'd1, 2'd1, 8'h00, id_base + 15);
        end
    endtask

    function [4:0] arbiter_contenders;
        input integer out_port;
        begin
            case (out_port)
                L2R: arbiter_contenders = (5'b00001 | 5'b10000); // PE, L2R
                R2L: arbiter_contenders = (5'b00001 | 5'b01000); // PE, R2L
                D2U: arbiter_contenders = (5'b00001 | 5'b00100 | 5'b01000 | 5'b10000); // PE,L2R,R2L,D2U
                U2D: arbiter_contenders = (5'b00001 | 5'b00010 | 5'b01000 | 5'b10000); // PE,L2R,R2L,U2D
                PE:  arbiter_contenders = (5'b00010 | 5'b00100 | 5'b01000 | 5'b10000); // U2D,D2U,R2L,L2R
                default: arbiter_contenders = 5'b0;
            endcase
        end
    endfunction

    function integer arbiter_contender_count;
        input integer out_port;
        begin
            if (out_port == L2R || out_port == R2L)
                arbiter_contender_count = 2;
            else
                arbiter_contender_count = 4;
        end
    endfunction

    // The active arbiter starts after last_grant=0, then rotates from the
    // request index following the previous winner. These ranks are the exact
    // request-index mapping used by gold_router's five output arbiters.
    function integer arbiter_expected_input;
        input integer out_port;
        input integer rank;
        begin
            case (out_port)
                L2R: begin
                    if (rank == 0) arbiter_expected_input = PE;
                    else           arbiter_expected_input = L2R;
                end
                R2L: begin
                    if (rank == 0) arbiter_expected_input = PE;
                    else           arbiter_expected_input = R2L;
                end
                D2U: begin
                    case (rank)
                        0: arbiter_expected_input = PE;
                        1: arbiter_expected_input = L2R;
                        2: arbiter_expected_input = R2L;
                        default: arbiter_expected_input = D2U;
                    endcase
                end
                U2D: begin
                    case (rank)
                        0: arbiter_expected_input = PE;
                        1: arbiter_expected_input = L2R;
                        2: arbiter_expected_input = R2L;
                        default: arbiter_expected_input = U2D;
                    endcase
                end
                PE: begin
                    case (rank)
                        0: arbiter_expected_input = L2R;
                        1: arbiter_expected_input = R2L;
                        2: arbiter_expected_input = D2U;
                        default: arbiter_expected_input = U2D;
                    endcase
                end
                default: arbiter_expected_input = -1;
            endcase
        end
    endfunction

    function request_is_active;
        input integer out_port;
        input integer in_port;
        begin
            request_is_active = 1'b0;
            case (out_port)
                L2R: begin
                    if (in_port == L2R) request_is_active = dut.req_L2R_L2R;
                    if (in_port == PE)  request_is_active = dut.req_PE_L2R;
                end
                R2L: begin
                    if (in_port == R2L) request_is_active = dut.req_R2L_R2L;
                    if (in_port == PE)  request_is_active = dut.req_PE_R2L;
                end
                D2U: begin
                    if (in_port == D2U) request_is_active = dut.req_D2U_D2U;
                    if (in_port == R2L) request_is_active = dut.req_R2L_D2U;
                    if (in_port == L2R) request_is_active = dut.req_L2R_D2U;
                    if (in_port == PE)  request_is_active = dut.req_PE_D2U;
                end
                U2D: begin
                    if (in_port == U2D) request_is_active = dut.req_U2D_U2D;
                    if (in_port == R2L) request_is_active = dut.req_R2L_U2D;
                    if (in_port == L2R) request_is_active = dut.req_L2R_U2D;
                    if (in_port == PE)  request_is_active = dut.req_PE_U2D;
                end
                PE: begin
                    if (in_port == U2D) request_is_active = dut.req_U2D_PE;
                    if (in_port == D2U) request_is_active = dut.req_D2U_PE;
                    if (in_port == R2L) request_is_active = dut.req_R2L_PE;
                    if (in_port == L2R) request_is_active = dut.req_L2R_PE;
                end
            endcase
        end
    endfunction

    function grant_is_active;
        input integer out_port;
        input integer in_port;
        begin
            grant_is_active = 1'b0;
            case (out_port)
                L2R: begin
                    if (in_port == L2R) grant_is_active = dut.grant_L2R_L2R;
                    if (in_port == PE)  grant_is_active = dut.grant_PE_L2R;
                end
                R2L: begin
                    if (in_port == R2L) grant_is_active = dut.grant_R2L_R2L;
                    if (in_port == PE)  grant_is_active = dut.grant_PE_R2L;
                end
                D2U: begin
                    if (in_port == D2U) grant_is_active = dut.grant_D2U_D2U;
                    if (in_port == R2L) grant_is_active = dut.grant_R2L_D2U;
                    if (in_port == L2R) grant_is_active = dut.grant_L2R_D2U;
                    if (in_port == PE)  grant_is_active = dut.grant_PE_D2U;
                end
                U2D: begin
                    if (in_port == U2D) grant_is_active = dut.grant_U2D_U2D;
                    if (in_port == R2L) grant_is_active = dut.grant_R2L_U2D;
                    if (in_port == L2R) grant_is_active = dut.grant_L2R_U2D;
                    if (in_port == PE)  grant_is_active = dut.grant_PE_U2D;
                end
                PE: begin
                    if (in_port == U2D) grant_is_active = dut.grant_U2D_PE;
                    if (in_port == D2U) grant_is_active = dut.grant_D2U_PE;
                    if (in_port == R2L) grant_is_active = dut.grant_R2L_PE;
                    if (in_port == L2R) grant_is_active = dut.grant_L2R_PE;
                end
            endcase
        end
    endfunction

    function [15:0] source_for_input;
        input integer in_port;
        begin
            case (in_port)
                PE:  source_for_input = 16'd5;
                L2R: source_for_input = 16'd4;
                R2L: source_for_input = 16'd6;
                D2U: source_for_input = 16'd9;
                U2D: source_for_input = 16'd1;
                default: source_for_input = 16'd5;
            endcase
        end
    endfunction

    task run_arbitration_case;
        input integer out_port;
        input vc;
        reg [4:0] mask;
        reg [4:0] observed_requests;
        reg [1:0] dx, dy;
        reg [7:0] hops;
        reg [PACKET_SIZE-1:0] packet, expected;
        integer in_port, rank, cycles, winner, packet_source, packet_id;
        reg transferred;
        begin
            @(negedge clk);
            reset = 1'b1;
            si = 5'b0;
            ro = 5'b11111;
            for (in_port = 0; in_port < 5; in_port = in_port + 1)
                di[in_port] = {PACKET_SIZE{1'b0}};
            repeat (2) @(posedge clk);
            #0.1;
            if (polarity !== 1'b0 || so !== 5'b0 || ri !== 5'b11111) begin
                $display("FAIL: arbitration reset failed before output=%0d VC=%0d", out_port, vc);
                $finish(1);
            end
            @(negedge clk);
            reset = 1'b0;
            if (!vc) begin
                @(posedge clk); #0.1;
                @(negedge clk);
            end

            mask = arbiter_contenders(out_port);
            case (out_port)
                L2R: begin dx = 2'd2; dy = 2'd1; hops = 8'h01; end
                R2L: begin dx = 2'd0; dy = 2'd1; hops = 8'h01; end
                D2U: begin dx = 2'd1; dy = 2'd0; hops = 8'h01; end
                U2D: begin dx = 2'd1; dy = 2'd2; hops = 8'h01; end
                default: begin dx = 2'd1; dy = 2'd1; hops = 8'h00; end
            endcase
            for (in_port = 0; in_port < 5; in_port = in_port + 1) begin
                if (mask[in_port]) begin
                    packet_source = source_for_input(in_port);
                    packet_id = 10000 + out_port * 100 + vc * 10 + in_port;
                    di[in_port] = make_packet_from(packet_source, vc, dx, dy,
                                                   hops, packet_id);
                    if (ri[in_port] !== 1'b1) begin
                        $display("FAIL: input %0d not ready for arbitration case output=%0d VC=%0d",
                                 in_port, out_port, vc);
                        $finish(1);
                    end
                end
            end
            $fdisplay(router_log_fd,
                      "TEST=ARBITRATION_START Time=%0.3f ns Output=%0d VC=%0d RequestMask=%b",
                      $realtime, out_port, vc, mask);
            si = mask;
            @(posedge clk); #0.1;

            observed_requests = 5'b0;
            for (in_port = 0; in_port < 5; in_port = in_port + 1)
                if (request_is_active(out_port, in_port))
                    observed_requests[in_port] = 1'b1;
            if (observed_requests !== mask) begin
                $display("FAIL: output %0d VC%0d simultaneous requests=%b expected=%b",
                         out_port, vc, observed_requests, mask);
                $finish(1);
            end
            winner = arbiter_expected_input(out_port, 0);
            for (in_port = 0; in_port < 5; in_port = in_port + 1) begin
                if (grant_is_active(out_port, in_port) !== (in_port == winner)) begin
                    $display("FAIL: output %0d VC%0d initial grant mismatch at input %0d; expected input %0d",
                             out_port, vc, in_port, winner);
                    $finish(1);
                end
            end
            $display("ARB: time=%0.3f ns output=%0d VC=%0d initial winner input=%0d",
                     $realtime, out_port, vc, winner);
            $fdisplay(router_log_fd,
                      "TEST=ARBITRATION_INITIAL_PRIORITY Time=%0.3f ns Output=%0d VC=%0d WinnerInput=%0d",
                      $realtime, out_port, vc, winner);
            @(negedge clk); si = 5'b0;

            for (rank = 0; rank < arbiter_contender_count(out_port); rank = rank + 1) begin
                winner = arbiter_expected_input(out_port, rank);
                packet_source = source_for_input(winner);
                packet_id = 10000 + out_port * 100 + vc * 10 + winner;
                packet = make_packet_from(packet_source, vc, dx, dy, hops, packet_id);
                expected = packet;
                expected[55:48] = packet[55:48] >> 1;
                cycles = 0;
                transferred = 1'b0;
                while (!transferred && cycles < 30) begin
                    @(posedge clk);
                    if (so[out_port] === 1'b1 && ro[out_port] === 1'b1) begin
                        if (dout[out_port] !== expected) begin
                            $display("FAIL: output %0d VC%0d delivered input %0d packet=%h expected=%h",
                                     out_port, vc, winner, dout[out_port], expected);
                            $finish(1);
                        end
                        transferred = 1'b1;
                        $display("ARB: time=%0.3f ns output=%0d VC=%0d winner input=%0d rank=%0d",
                                 $realtime, out_port, vc, winner, rank);
                        $fdisplay(router_log_fd,
                                  "TEST=ARBITRATION_WIN Time=%0.3f ns Output=%0d VC=%0d Rank=%0d WinnerInput=%0d PacketValue=%0d",
                                  $realtime, out_port, vc, rank, winner, packet_id);
                    end
                    #0.1;
                    cycles = cycles + 1;
                end
                if (!transferred) begin
                    $display("FAIL: arbitration output %0d VC%0d timed out waiting for rank %0d input %0d",
                             out_port, vc, rank, winner);
                    $finish(1);
                end
                if (rank + 1 < arbiter_contender_count(out_port)) begin
                    winner = arbiter_expected_input(out_port, rank + 1);
                    if (!request_is_active(out_port, winner) ||
                        !grant_is_active(out_port, winner)) begin
                        $display("FAIL: output %0d VC%0d did not rotate priority to input %0d after contention",
                                 out_port, vc, winner);
                        $finish(1);
                    end
                end
            end
            $fdisplay(router_log_fd,
                      "TEST=ARBITRATION_END Time=%0.3f ns Output=%0d VC=%0d",
                      $realtime, out_port, vc);
        end
    endtask

    integer i, output_index, vc_index;
    initial begin
        reset = 1'b1;
        si = 5'b0;
        ro = 5'b0;
        pe_protocol_violation = 1'b0;
        router_log_fd = $fopen("router_waveform_times.out", "w");
        if (router_log_fd == 0) begin
            $display("FAIL: could not open router_waveform_times.out in the simulation directory");
            $finish(1);
        end
        for (i = 0; i < 5; i = i + 1) di[i] = {PACKET_SIZE{1'b0}};

        $fdisplay(router_log_fd, "TEST=RESET_START Time=%0.3f ns", $realtime);
        repeat (2) @(posedge clk);
        #0.1;
        if (polarity !== 1'b0 || so !== 5'b0 || ri !== 5'b11111) begin
            $display("FAIL: router reset waveform check failed");
            $finish(1);
        end
        $fdisplay(router_log_fd, "TEST=RESET_END Time=%0.3f ns", $realtime);

        $fdisplay(router_log_fd, "TEST=ALL_LEGAL_SWITCHES_VC1_START Time=%0.3f ns", $realtime);
        run_all_legal_switches(1'b1, 32'd1);
        $fdisplay(router_log_fd, "TEST=ALL_LEGAL_SWITCHES_VC1_END Time=%0.3f ns", $realtime);
        $fdisplay(router_log_fd, "TEST=ALL_LEGAL_SWITCHES_VC0_START Time=%0.3f ns", $realtime);
        run_all_legal_switches(1'b0, 32'd101);
        $fdisplay(router_log_fd, "TEST=ALL_LEGAL_SWITCHES_VC0_END Time=%0.3f ns", $realtime);

        for (vc_index = 0; vc_index < 2; vc_index = vc_index + 1) begin
            for (output_index = 0; output_index < 5; output_index = output_index + 1)
                run_arbitration_case(output_index, vc_index[0]);
        end

        if (pe_protocol_violation) begin
            $display("FAIL: PE_so violated the required PE_ro backpressure rule.");
            $fdisplay(router_log_fd, "RESULT=FAIL PE_SO_ASSERTED_WHILE_PE_RO_LOW Time=%0.3f ns", $realtime);
            $fclose(router_log_fd);
            $finish(1);
        end
        $fdisplay(router_log_fd, "RESULT=PASS ALL_ROUTER_TESTS Time=%0.3f ns", $realtime);
        $fclose(router_log_fd);
        $display("ALL GOLD_ROUTER SWITCHING AND ARBITRATION TESTS PASSED.");
        $finish;
    end
endmodule

