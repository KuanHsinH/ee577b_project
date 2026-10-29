////////////////////////////////////////////////////////////////////////////
// Register file (EE577B Project Phase 2)
//
// Requirements (Phase 2 handout, item 3e, and the Phase 2 lecture):
//   * 32 registers x 64 bits.
//   * 3 ports: 2 read ports and 1 write port. Each port has a 5-bit address
//     and 64-bit data. The write port has a write enable (wrEn); the read
//     ports have no enable.
//   * Reads are asynchronous; writes are synchronous (rising edge).
//   * Synchronous active-high reset clears every register.
//   * Register 0 is hard-wired to 64'h0000_0000_0000_0000 and read-only.
//   * Must be synthesizable.
//   * If your ISA version has the PPP participation field, each byte of the
//     write data must be writable independently (selective write-back).
//
// The interface below is a suggestion. Only cardinal_cpu's interface is
// fixed; you may change this module's name and ports.
////////////////////////////////////////////////////////////////////////////
module register_file (
    input         clk,
    input         reset,
    input         wrEn,       // write enable
    input  [0:4]  wrAddr,     // write address
    input  [0:63] wrData,     // write data
    input  [0:7]  wrByteEn,   // optional: byte k write enable (bits [8k:8k+7])
    input  [0:4]  rdAddr0,    // read port 0 address
    output [0:63] rdData0,    // read port 0 data
    input  [0:4]  rdAddr1,    // read port 1 address
    output [0:63] rdData1     // read port 1 data
);

    reg  [0:63] data [0:31];
    integer i; 

    assign rdData0 = (rdAddr0 == 5'd0) ? 64'd0 : data[rdAddr0];
    assign rdData1 = (rdAddr1 == 5'd0) ? 64'd0 : data[rdAddr1];

    always @(posedge clk) begin
        if(reset) begin
            for(i = 0; i < 32; i = i + 1) begin
                data[i] <= 64'd0;
            end
        end
        else begin
            if(wrEn && wrAddr != 5'd0) begin
                if(wrByteEn[0]) data[wrAddr][0:7]   <= wrData[0:7];
                if(wrByteEn[1]) data[wrAddr][8:15]  <= wrData[8:15];
                if(wrByteEn[2]) data[wrAddr][16:23] <= wrData[16:23];
                if(wrByteEn[3]) data[wrAddr][24:31] <= wrData[24:31];
                if(wrByteEn[4]) data[wrAddr][32:39] <= wrData[32:39];
                if(wrByteEn[5]) data[wrAddr][40:47] <= wrData[40:47];
                if(wrByteEn[6]) data[wrAddr][48:55] <= wrData[48:55];
                if(wrByteEn[7]) data[wrAddr][56:63] <= wrData[56:63];
            end
        end
    end

endmodule
