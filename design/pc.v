module pc #(
    parameter INST_WIDTH = 32;
)
(
    clk, reset, cnt
);

    input                        clk, reset;
    output reg [INST_WIDTH-1:0]  cnt;

    always @(posedge clk) begin
        if(reset) cnt <= 32'd0;
        else cnt <= cnt + 4'd4;
    end
    
endmodule