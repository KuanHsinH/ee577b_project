/////////////////////////////////////////////////////////////////////////////
// CPU-only testbench with branch-prediction performance counters.
//
// Run one program with +IMEM=<file> +DMEM=<file> +EXPECTED=<file>.
// +DUMP=<file> sets the output dump (default dmem.dump; final run wins).
// With +EXPECTED, the SAME program runs twice after separate resets and
// memory reloads, catching processor state that was not cleared by reset.
// +RUNS=<n> overrides this (default: 2 with EXPECTED, otherwise 1).
// +MAX_CYCLES=<n> and +DUMP_WORDS=<n> override the defaults below.
//
// This file measures cardinal_cpu as a static not-taken comparison.
// Use tb_cardinal_cpu_bp_metrics.v to measure cardinal_cpu_bp_v1.
// This bench tests the CPU only; it does not instantiate a NIC or mesh.
/////////////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps

`define CPU_CYCLE_TIME 4
`define CPU_DEFAULT_MAX_CYCLES 5000
`define CPU_DEFAULT_DUMP_WORDS 128

`include "./include/dmem.v"
`include "./include/imem.v"

module tb_cardinal_cpu_metrics;

reg CLK, RESET;
wire [0:31] pc_out, inst_in, addr_out;
wire [0:63] d_out, d_in;
wire memEn, memWrEn;

reg [8*256:1] imem_file, dmem_file, dump_file, expected_file;
reg [8*256:1] line, word1, word2, word3, word4;
reg [0:63] expected;
reg [255:0] seen_addresses;
integer dump_fd, expected_fd, file_fd;
integer i, address, parsed, checked, cycle_number;
integer run_number, runs, max_cycles, dump_words;
integer run_errors, total_errors;
reg check_expected, finished;

// A shadow valid bit distinguishes real VNOP instructions from the VNOP
// bubbles inserted by the CPU when it flushes IF/ID. Each real instruction
// reaching ID is counted once. With this in-order pipeline and the five-cycle
// drain below, those instructions complete before metrics are reported.
reg id_valid;
integer instruction_count, branch_count, misprediction_count, flush_count;
integer end_fetch_cycles;
wire fetch_valid = (inst_in !== 32'h0000_0000) && ((^inst_in) !== 1'bx);
wire id_is_branch = id_valid &&
    ((CPU.IF_ID_reg[0:5] == 6'b100010) ||
     (CPU.IF_ID_reg[0:5] == 6'b100011));
wire cpu_stall = CPU.stall;
wire flush_now = CPU.br_taken;

cardinal_cpu CPU (
    .clk      (CLK),
    .reset    (RESET),
    .inst_in  (inst_in),
    .d_in     (d_in),
    .pc_out   (pc_out),
    .addr_out (addr_out),
    .memEn    (memEn),
    .memWrEn  (memWrEn),
    .d_out    (d_out)
);

imem IM (
    .memAddr (pc_out[22:29]),
    .dataOut (inst_in)
);

dmem DM (
    .clk     (CLK),
    .memEn   (memEn),
    .memWrEn (memWrEn),
    .memAddr (addr_out[24:31]),
    .dataIn  (d_out),
    .dataOut (d_in)
);

always #(`CPU_CYCLE_TIME / 2.0) CLK = ~CLK;

// Count cycles and reject invalid memory-control signals after reset.
always @(posedge CLK) begin
    if (RESET) begin
        cycle_number <= 0;
    end else begin
        cycle_number <= cycle_number + 1;
        if ((memEn !== 1'b0) && (memEn !== 1'b1)) begin
            run_errors = run_errors + 1;
            if (run_errors <= 10)
                $display("ERROR run %0d cycle %0d: memEn is unknown", run_number, cycle_number);
        end
        if ((memWrEn !== 1'b0) && (memWrEn !== 1'b1)) begin
            run_errors = run_errors + 1;
            if (run_errors <= 10)
                $display("ERROR run %0d cycle %0d: memWrEn is unknown", run_number, cycle_number);
        end
        if ((memWrEn === 1'b1) && (memEn !== 1'b1)) begin
            run_errors = run_errors + 1;
            if (run_errors <= 10)
                $display("ERROR run %0d cycle %0d: write enable without memory enable", run_number, cycle_number);
        end
        if ((memEn === 1'b1) && (^addr_out[24:31] === 1'bx)) begin
            run_errors = run_errors + 1;
            if (run_errors <= 10)
                $display("ERROR run %0d cycle %0d: memory address is unknown", run_number, cycle_number);
        end
    end
end

// Count events at the clock edge that accepts an ID-stage instruction.
// The original CPU fetches PC+4, equivalent to a static not-taken guess:
// every taken branch is a miss and causes one IF/ID flush. These two counts
// should match because each event flushes one younger instruction.
always @(posedge CLK) begin
    if (RESET) begin
        id_valid <= 1'b0;
        instruction_count <= 0;
        branch_count <= 0;
        misprediction_count <= 0;
        flush_count <= 0;
    end else if (!cpu_stall) begin
        if (id_valid) begin
            instruction_count <= instruction_count + 1;
            if (id_is_branch) begin
                branch_count <= branch_count + 1;
                if (flush_now)
                    misprediction_count <= misprediction_count + 1;
            end
        end
        if (flush_now)
            flush_count <= flush_count + 1;
        id_valid <= flush_now ? 1'b0 : fetch_valid;
    end
end

task report_metrics;
    real accuracy_percent, cpi;
    begin
        $display("Run %0d metrics: CPU = cardinal_cpu (static not-taken comparison)", run_number);
        $display("  Cycles to end fetch = %0d; cycles including 5-cycle drain = %0d",
                 end_fetch_cycles, cycle_number);
        $display("  Completed instructions = %0d; resolved branches = %0d",
                 instruction_count, branch_count);
        $display("  Mispredictions = %0d; IF/ID flushes = %0d",
                 misprediction_count, flush_count);
        if (branch_count > 0) begin
            accuracy_percent = 100.0 * $itor(branch_count - misprediction_count)
                                     / $itor(branch_count);
            $display("  Branch accuracy = %0.2f%%", accuracy_percent);
        end else
            $display("  Branch accuracy = N/A (no branches)");
        if (instruction_count > 0) begin
            cpi = $itor(cycle_number) / $itor(instruction_count);
            $display("  CPI (including drain) = %0.4f", cpi);
        end else
            $display("  CPI = N/A (no completed instructions)");
    end
endtask

task load_memories;
    integer j;
    begin
        file_fd = $fopen(imem_file, "r");
        if (file_fd == 0) begin
            $display("TEST FAILED: cannot open instruction file %0s", imem_file);
            $finish;
        end
        $fclose(file_fd);

        file_fd = $fopen(dmem_file, "r");
        if (file_fd == 0) begin
            $display("TEST FAILED: cannot open data file %0s", dmem_file);
            $finish;
        end
        $fclose(file_fd);

        // Remove stale data from a prior run. Unspecified locations remain
        // unknown, as they would in the original uninitialized memories.
        for (j = 0; j < 256; j = j + 1) begin
            IM.MEM[j] = 32'hxxxx_xxxx;
            DM.MEM[j] = 64'hxxxx_xxxx_xxxx_xxxx;
        end
        $readmemh(imem_file, IM.MEM);
        $readmemh(dmem_file, DM.MEM);
    end
endtask

task dump_memory;
    integer j;
    begin
        dump_fd = $fopen(dump_file, "w");
        if (dump_fd == 0) begin
            run_errors = run_errors + 1;
            $display("ERROR run %0d: cannot create dump %0s", run_number, dump_file);
        end else begin
            for (j = 0; j < dump_words; j = j + 1)
                $fdisplay(dump_fd, "Memory location #%d : %h ", j, DM.MEM[j]);
            $fclose(dump_fd);
            $display("Run %0d: dumped %0d data words to %0s", run_number, dump_words, dump_file);
        end
    end
endtask

task compare_memory;
    begin
        expected_fd = $fopen(expected_file, "r");
        if (expected_fd == 0) begin
            run_errors = run_errors + 1;
            $display("ERROR run %0d: cannot open expected dump %0s", run_number, expected_file);
        end else begin
            checked = 0;
            seen_addresses = 256'b0;
            line = 0;
            while ($fgets(line, expected_fd)) begin
                // Blank lines are harmless; every nonblank line must match
                // "Memory location # <address> : <hex-value>".
                if ($sscanf(line, "%s", word1) == 1) begin
                    parsed = $sscanf(line, "%s %s %s %d %s %h",
                                     word1, word2, word3, address, word4, expected);
                    if ((parsed != 6) || (word1 != "Memory") ||
                        (word2 != "location") || (word3 != "#") ||
                        (word4 != ":")) begin
                        run_errors = run_errors + 1;
                        $display("ERROR run %0d: malformed expected-dump line: %0s", run_number, line);
                    end else if ((address < 0) || (address >= 256)) begin
                        run_errors = run_errors + 1;
                        $display("ERROR run %0d: expected-dump address %0d is out of range", run_number, address);
                    end else if (seen_addresses[address]) begin
                        run_errors = run_errors + 1;
                        $display("ERROR run %0d: address %0d occurs twice in expected dump", run_number, address);
                    end else begin
                        seen_addresses[address] = 1'b1;
                        checked = checked + 1;
                        if (DM.MEM[address] !== expected) begin
                            run_errors = run_errors + 1;
                            $display("MISMATCH run %0d at memory[%0d]: expected %h, got %h",
                                     run_number, address, expected, DM.MEM[address]);
                        end
                    end
                end
                line = 0;
            end
            $fclose(expected_fd);
            if (checked == 0) begin
                run_errors = run_errors + 1;
                $display("ERROR run %0d: no valid locations in %0s", run_number, expected_file);
            end else begin
                $display("Run %0d: compared %0d memory locations", run_number, checked);
            end
        end
    end
endtask

initial begin
    if (!$value$plusargs("IMEM=%s", imem_file)) imem_file = "imem.fill";
    if (!$value$plusargs("DMEM=%s", dmem_file)) dmem_file = "dmem.fill";
    if (!$value$plusargs("DUMP=%s", dump_file)) dump_file = "dmem.dump";
    check_expected = $value$plusargs("EXPECTED=%s", expected_file);

    runs = check_expected ? 2 : 1;
    max_cycles = `CPU_DEFAULT_MAX_CYCLES;
    dump_words = `CPU_DEFAULT_DUMP_WORDS;
    if ($value$plusargs("RUNS=%d", runs)) begin end
    if ($value$plusargs("MAX_CYCLES=%d", max_cycles)) begin end
    if ($value$plusargs("DUMP_WORDS=%d", dump_words)) begin end
    if ((runs < 1) || (max_cycles < 1) ||
        (dump_words < 1) || (dump_words > 256)) begin
        $display("TEST FAILED: invalid RUNS, MAX_CYCLES, or DUMP_WORDS option");
        $finish;
    end

    CLK = 0;
    RESET = 1;
    cycle_number = 0;
    total_errors = 0;
    run_errors = 0;

    for (run_number = 1; run_number <= runs; run_number = run_number + 1) begin
        RESET = 1;
        run_errors = 0;
        end_fetch_cycles = 0;
        repeat (5) @(negedge CLK);
        // Reload after reset has flushed any outstanding store from the
        // previous run, before allowing the CPU to fetch the next program.
        load_memories;
        RESET = 0;

        finished = 0;
        while (!finished) begin
            @(negedge CLK);
            if (inst_in === 32'h0000_0000) begin
                finished = 1;
                end_fetch_cycles = cycle_number;
                $display("Run %0d: end-of-program fetched after %0d cycles", run_number, cycle_number);
            end else if (cycle_number >= max_cycles) begin
                finished = 1;
                run_errors = run_errors + 1;
                $display("ERROR run %0d: no end-of-program word after %0d cycles", run_number, max_cycles);
            end
        end

        // Match the TA bench's five-cycle pipeline-drain rule.
        repeat (5) @(negedge CLK);
        dump_memory;
        if (check_expected) compare_memory;
        report_metrics;

        if ((run_errors == 0) && check_expected)
            $display("Run %0d: PASS", run_number);
        else if (run_errors == 0)
            $display("Run %0d: completed (no EXPECTED file)", run_number);
        else
            $display("Run %0d: FAIL (%0d errors)", run_number, run_errors);
        total_errors = total_errors + run_errors;
    end

    if (total_errors == 0) begin
        if (check_expected)
            $display("TEST PASSED: all %0d run(s) matched the expected dump", runs);
        else
            $display("SIMULATION COMPLETED: %0d run(s); no expected dump was supplied", runs);
    end else begin
        $display("TEST FAILED: %0d error(s) across %0d run(s)", total_errors, runs);
    end
    $finish;
end

endmodule
