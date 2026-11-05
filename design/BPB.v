module BPB (
    clk,
    reset,
    is_branch,
    index_get_pred,
    index_update_pred,
    br_result, // taken = 1, not taken = 0
    pred_out
);

    input clk, reset;
    input [0:7] index_get_pred, index_update_pred;
    input is_branch, br_result;
    output pred_out;

    integer i;

    reg [0:1] predictor [0:255];
    wire [0:1] current_predictor;

    assign current_predictor = predictor[index_get_pred];
    assign pred_out = current_predictor[0] ? 1'b1 : 1'b0; // 00, 01: Not Taken, 10, 11: Taken

    always @(posedge clk) begin
        if(reset) begin
            for (i = 0; i<256; i = i+1) begin
                predictor[i] <= 2'b01;
            end
        end
        else begin
            if(is_branch) begin
                if(br_result == 1'b1) begin
                    predictor[index_update_pred] <= (predictor[index_update_pred] == 2'b11) ? predictor[index_update_pred] : predictor[index_update_pred] + 1'b1;
                end
                else begin
                    predictor[index_update_pred] <= (predictor[index_update_pred] == 2'b00) ? predictor[index_update_pred] : predictor[index_update_pred] - 1'b1;
                end
            end
        end
    end
    
endmodule