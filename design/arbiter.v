module arbiter (
    clk, reset, int_vc,
    req_0, req_1, req_2, req_3,
    grant_0, grant_1, grant_2, grant_3,
);

    // 3 has the highest priority, 0 has the lowest priority

    input clk, reset, int_vc;
    input req_0, req_1, req_2, req_3;
    output reg grant_0, grant_1, grant_2, grant_3;

    reg [3:0] mask_v0, mask_v1;
    reg [3:0] last_grant_v0, last_grant_v1;
    wire      contention =  ({req_0, req_1, req_2, req_3} == 4'b0000) ||
                            ({req_0, req_1, req_2, req_3} == 4'b0001) ||
                            ({req_0, req_1, req_2, req_3} == 4'b0010) ||
                            ({req_0, req_1, req_2, req_3} == 4'b0100) ||
                            ({req_0, req_1, req_2, req_3} == 4'b1000);

    always@(*) begin
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