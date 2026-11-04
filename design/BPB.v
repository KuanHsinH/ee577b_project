module BPB (
    clk,
    reset,
    index_get_pred,
    index_update_pred,
    br_result,
    pred_out
);

    input clk, reset;
    input [0:7] index_get_pred, index_update_pred;
    input br_result;
    output pred_out;

    integer i;

    reg [0:1] predictor [0:255];

    always @(posedge clk) begin
        if(reset) begin
            for (i = 0; i<256; i = i+1) begin
                predictor[i] <= 2'b00;
            end
        end
        else begin
            
        end
    end
    
endmodule