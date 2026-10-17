module in_buf #(
    PACKET_SIZE = 64
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
            full <= 1'b0;
            data_out <= {PACKET_SIZE{1'b0}};
        end
        else begin
            if(we && !full) begin
                data_out <= data_in;
                full <= 1'b1;
            end
            else if(re && full) begin
                data_out <= {PACKET_SIZE{1'b0}};
                full <= 1'b0;
            end
        end
    end    
endmodule