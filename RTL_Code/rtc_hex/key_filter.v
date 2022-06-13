module key_filter(
    clk,
    rstn,
    key_in,
    key_flag,
    key_state
);

input wire clk;
input wire rstn;
input wire key_in;
output reg key_flag;
output reg key_state;

reg key_in_sync0;
reg key_in_sync1;
reg key_in_dly0;
reg key_in_dly1;

//one bit CDC;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        key_in_sync0 <= 1'b0;
        key_in_sync1 <= 1'b0;
    end
    else begin
        key_in_sync0 <= key_in;
        key_in_sync1 <= key_in_sync0;
    end
end

//edge detect;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        key_in_dly0 <= 1'b0;
        key_in_dly1 <= 1'b0;
    end
    else begin
        key_in_dly0 <= key_in_sync1;
        key_in_dly1 <= key_in_dly0;
    end
end

assign key_in_pedge = key_in_dly0 & (!key_in_dly1);
assign key_in_nedge = (!key_in_dly0) & key_in_dly1;

//counter 20ms;
reg [19:0] cnt;
reg cnt_full;
reg cnt_en;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cnt <= 20'd0;
    end
    else if (cnt_en) begin
        cnt <= cnt + 1'b1;
    end
    else begin
        cnt <= 20'd0;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cnt_full <= 1'b0;
    end
    else if (cnt == 20'd999_999) begin
        cnt_full <= 1'b1;
    end
    else begin
        cnt_full <= 1'b0;
    end
end

//fsm design;
parameter   IDEL = 2'd0,
            JITTER0 = 2'd1,
            DOWN = 2'd2,
            JITTER1 = 2'd3;

reg [1:0] state;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state <= IDEL;
        cnt_en <= 1'b0;
        key_flag <= 1'b0;
        key_state <= 1'b1;
    end
    else begin
        case (state)
            IDEL:   begin
                key_flag <= 1'b0;
                if (key_in_nedge) begin
                    state <= JITTER0;
                    cnt_en <= 1'b1;
                end
                else begin
                state <= IDEL;
                end
            end
            JITTER0:    begin
                if (cnt_full) begin
                    key_flag <= 1'b1;
                    key_state <= 1'b0;
                    cnt_en <= 1'b0; 
                    state <= DOWN;
                end
                else if (key_in_pedge) begin
                    state <= IDEL;
                    cnt_en <= 1'b0; 
                end
                else begin
                    state <= JITTER0;
                end
            end
            DOWN:   begin
                key_flag <= 1'b0;
                if (key_in_pedge) begin
                    state <= JITTER1;
                    cnt_en <= 1'b1;
                end
                else begin
                    state <= DOWN;
                end
            end
            JITTER1:    begin
                if (cnt_full)  begin
                    key_flag <= 1'b1;
                    key_state <= 1'b1;
                    cnt_en <= 1'b0;
                    state <= IDEL;
                end
                else if (key_in_nedge) begin
                    cnt_en <= 1'b0;
                    state <= DOWN;
                end
                else begin
                    state <= JITTER1;
                end
            end
        endcase
    end
end

endmodule