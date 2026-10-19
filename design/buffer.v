module buffer #(
    parameter PACKET_SIZE = 64
) (
    clk, reset, we, re, data_in,
    full, data_out
);

    input clk, reset, we, re;
    input [PACKET_SIZE-1:0] data_in;
    output reg full;
    output reg [PACKET_SIZE-1:0] data_out;

    always@(posedge clk) begin
        if(reset) begin
            full        <= 1'b0;
            data_out    <= {PACKET_SIZE{1'b0}};
        end
        else begin
            if(we && !full) begin
                data_out    <= data_in;
                full        <= 1'b1;
            end
            else if(re && full) begin
                data_out    <= {PACKET_SIZE{1'b0}};
                full        <= 1'b0;
            end
        end
    end    
endmodule

    /*
    Bits (P=64)   Bits (general)   Field            Value written by the testbench
    -----------   --------------   --------------   ---------------------------------
    [63]          [P-1]            VC               0 = VC0, 1 = VC1
    [62]          [P-2]            reserved         0
    [61:60]       [P-3:P-4]        destination x    D % 4  (D = destination node)
    [59:58]       [P-5:P-6]        destination y    D / 4
    [57:56]       [P-7:P-8]        reserved         0
    [55:48]       [P-9:P-16]       hop field        (1 << H) - 1, H = |dx| + |dy|
    [47:32]       [P-17:P-32]      source           source node number S (0..15)
    [31:0]        [P-33:0]         payload          unique packet ID
    */