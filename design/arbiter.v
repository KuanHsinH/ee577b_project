module arbiter (
    clk, reset, int_vc,
    req_0, req_1, req_2, req_3,
    grant_0, grant_1, grant_2, grant_3
);

    input clk, reset, int_vc;
    input req_0, req_1, req_2, req_3;
    output reg grant_0, grant_1, grant_2, grant_3;

    // Encoded index of the most recently granted request:
    // 0 = req_0, 1 = req_1, 2 = req_2, 3 = req_3
    reg [1:0] last_grant_v0;
    reg [1:0] last_grant_v1;

    wire [3:0] request_vec;
    reg  [3:0] selected_grant;

    assign request_vec = {req_3, req_2, req_1, req_0};

    // Choose the first active request after the previous winner.
    // Resetting last_grant to 0 makes the initial order 3, 2, 1, 0.
    function [3:0] choose_grant;
        input [3:0] request;
        input [1:0] last_grant;

        begin
            choose_grant = 4'b0000;

            case (last_grant)
                2'd0: begin // order: 3, 2, 1, 0
                    if      (request[3]) choose_grant = 4'b1000;
                    else if (request[2]) choose_grant = 4'b0100;
                    else if (request[1]) choose_grant = 4'b0010;
                    else if (request[0]) choose_grant = 4'b0001;
                end

                2'd1: begin // order: 0, 3, 2, 1
                    if      (request[0]) choose_grant = 4'b0001;
                    else if (request[3]) choose_grant = 4'b1000;
                    else if (request[2]) choose_grant = 4'b0100;
                    else if (request[1]) choose_grant = 4'b0010;
                end

                2'd2: begin // order: 1, 0, 3, 2
                    if      (request[1]) choose_grant = 4'b0010;
                    else if (request[0]) choose_grant = 4'b0001;
                    else if (request[3]) choose_grant = 4'b1000;
                    else if (request[2]) choose_grant = 4'b0100;
                end

                2'd3: begin // order: 2, 1, 0, 3
                    if      (request[2]) choose_grant = 4'b0100;
                    else if (request[1]) choose_grant = 4'b0010;
                    else if (request[0]) choose_grant = 4'b0001;
                    else if (request[3]) choose_grant = 4'b1000;
                end
            endcase
        end
    endfunction

    // Arbitrate using the pointer for the active VC.
    always @(*) begin
        if (int_vc)
            selected_grant = choose_grant(request_vec, last_grant_v1);
        else
            selected_grant = choose_grant(request_vec, last_grant_v0);

        grant_0 = selected_grant[0];
        grant_1 = selected_grant[1];
        grant_2 = selected_grant[2];
        grant_3 = selected_grant[3];
    end

    // Advance only the pointer for the active VC, and only after a grant.
    always @(posedge clk) begin
        if (reset) begin
            last_grant_v0 <= 2'd0;
            last_grant_v1 <= 2'd0;
        end
        else if (int_vc) begin
            if      (grant_0) last_grant_v1 <= 2'd0;
            else if (grant_1) last_grant_v1 <= 2'd1;
            else if (grant_2) last_grant_v1 <= 2'd2;
            else if (grant_3) last_grant_v1 <= 2'd3;
        end
        else begin
            if      (grant_0) last_grant_v0 <= 2'd0;
            else if (grant_1) last_grant_v0 <= 2'd1;
            else if (grant_2) last_grant_v0 <= 2'd2;
            else if (grant_3) last_grant_v0 <= 2'd3;
        end
    end

endmodule

module old_arbiter (
    clk, reset, int_vc,
    req_0, req_1, req_2, req_3,
    grant_0, grant_1, grant_2, grant_3
);

    // 3 has the highest priority, 0 has the lowest priority

    input clk, reset, int_vc;
    input req_0, req_1, req_2, req_3;
    output reg grant_0, grant_1, grant_2, grant_3;

    reg [3:0] mask_v0, mask_v1;
    reg [3:0] last_grant_v0, last_grant_v1;
    wire      contention = (req_0 && req_1) || (req_0 && req_2) || (req_0 && req_3) ||
                           (req_1 && req_2) || (req_1 && req_3) || 
                           (req_2 && req_3);

    always@(*) begin

        last_grant_v0 = 4'd0;
        last_grant_v1 = 4'd0;

        if(int_vc) begin
            if(req_3 && mask_v1[3]) begin
                grant_0 = 1'b0;
                grant_1 = 1'b0;
                grant_2 = 1'b0;
                grant_3 = 1'b1;
                last_grant_v1 = 4'b1000;
            end
            else if(req_2 && mask_v1[2]) begin
                grant_0 = 1'b0;
                grant_1 = 1'b0;
                grant_2 = 1'b1;
                grant_3 = 1'b0;
                last_grant_v1 = 4'b0100;
            end
            else if(req_1 && mask_v1[1]) begin
                grant_0 = 1'b0;
                grant_1 = 1'b1;
                grant_2 = 1'b0;
                grant_3 = 1'b0;
                last_grant_v1 = 4'b0010;
            end
            else if(req_0 && mask_v1[0]) begin
                grant_0 = 1'b1;
                grant_1 = 1'b0;
                grant_2 = 1'b0;
                grant_3 = 1'b0;
                last_grant_v1 = 4'b0001;
            end
            else begin
                grant_0 = 1'b0;
                grant_1 = 1'b0;
                grant_2 = 1'b0;
                grant_3 = 1'b0;
                last_grant_v1 = 4'b0000;                
            end
        end
        else begin
            if(req_3 && mask_v0[3]) begin
                grant_0 = 1'b0;
                grant_1 = 1'b0;
                grant_2 = 1'b0;
                grant_3 = 1'b1;
                last_grant_v0 = 4'b1000;
            end
            else if(req_2 && mask_v0[2]) begin
                grant_0 = 1'b0;
                grant_1 = 1'b0;
                grant_2 = 1'b1;
                grant_3 = 1'b0;
                last_grant_v0 = 4'b0100;
            end
            else if(req_1 && mask_v0[1]) begin
                grant_0 = 1'b0;
                grant_1 = 1'b1;
                grant_2 = 1'b0;
                grant_3 = 1'b0;
                last_grant_v0 = 4'b0010;
            end
            else if(req_0 && mask_v0[0]) begin
                grant_0 = 1'b1;
                grant_1 = 1'b0;
                grant_2 = 1'b0;
                grant_3 = 1'b0;
                last_grant_v0 = 4'b0001;
            end
            else begin
                grant_0 = 1'b0;
                grant_1 = 1'b0;
                grant_2 = 1'b0;
                grant_3 = 1'b0;    
                last_grant_v0 = 4'b0000;            
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            mask_v0 <= 4'b1111;
            mask_v1 <= 4'b1111;
        end
        else begin
            if(contention) begin
                if(int_vc) begin
                    case (last_grant_v1)
                        4'b0001: mask_v1 <= {mask_v1[3:1], 1'b0};
                        4'b0010: mask_v1 <= {mask_v1[3:2], 1'b0, mask_v1[0]};
                        4'b0100: mask_v1 <= {mask_v1[3], 1'b0, mask_v1[1:0]};
                        4'b1000: mask_v1 <= {1'b0, mask_v1[2:0]};
                        default: mask_v1 <= 4'b1111;
                    endcase
                end
                else begin
                    case (last_grant_v0)
                        4'b0001: mask_v0 <= {mask_v0[3:1], 1'b0};
                        4'b0010: mask_v0 <= {mask_v0[3:2], 1'b0, mask_v0[0]};
                        4'b0100: mask_v0 <= {mask_v0[3], 1'b0, mask_v0[1:0]};
                        4'b1000: mask_v0 <= {1'b0, mask_v0[2:0]};
                        default: mask_v0 <= 4'b1111;
                    endcase
                end
            end
            else begin
                if(int_vc) mask_v1 <= 4'b1111;
                else       mask_v0 <= 4'b1111;
            end
            
        end
    end
    
endmodule