module time_send(
    clk,
    rstn,
    date_time_en,
    date_time,
    uart_tx_done,
    uart_tx_en,
    uart_tx_data
);

input wire clk;
input wire rstn;
input wire date_time_en;
input wire [47:0] date_time;
input wire uart_tx_done;
output reg uart_tx_en;
output reg [7:0] uart_tx_data;

reg [47:0] date_time_d;
reg date_time_change;
reg [95:0] date_time_ascii;
reg [4:0] send_byte_cnt;
reg send_en;

always @(posedge clk or posedge rstn) begin
    if (!rstn) begin
        date_time_d <= 48'd0;
    end
    else if (date_time_en) begin
        date_time_d <= date_time;
    end
    else begin
        date_time_d <= date_time_d;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        date_time_change <= 1'b0;
    end
    else if (date_time_en && (date_time != date_time_d)) begin
        date_time_change <= 1'b1;
    end
    else begin
        date_time_change <= 1'b0;
    end
end

always @(posedge clk) begin
    if (date_time_change) begin
        date_time_ascii[95:88]  <=  {{(4){1'b0}}, date_time_d[47:44]} + 8'h30;
        date_time_ascii[87:80]  <=  {{(4){1'b0}}, date_time_d[43:40]} + 8'h30;
        date_time_ascii[79:72]  <=  {{(4){1'b0}}, date_time_d[39:36]} + 8'h30;
        date_time_ascii[71:64]  <=  {{(4){1'b0}}, date_time_d[35:32]} + 8'h30;
        date_time_ascii[63:56]  <=  {{(4){1'b0}}, date_time_d[31:28]} + 8'h30;
        date_time_ascii[55:48]  <=  {{(4){1'b0}}, date_time_d[27:24]} + 8'h30;
        date_time_ascii[47:40]  <=  {{(4){1'b0}}, date_time_d[23:20]} + 8'h30;
        date_time_ascii[39:32]  <=  {{(4){1'b0}}, date_time_d[19:16]} + 8'h30;
        date_time_ascii[31:24]  <=  {{(4){1'b0}}, date_time_d[15:12]} + 8'h30;
        date_time_ascii[23:16]  <=  {{(4){1'b0}}, date_time_d[11:8]}  + 8'h30;
        date_time_ascii[15:8]   <=  {{(4){1'b0}}, date_time_d[7:4]}   + 8'h30;
        date_time_ascii[7:0]    <=  {{(4){1'b0}}, date_time_d[3:0]}   + 8'h30;
    end
    else begin
        date_time_ascii <= date_time_ascii;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        send_byte_cnt <= 5'd0; 
    end
    else if (date_time_change) begin
        send_byte_cnt <= 5'd1;
    end
    else if ((send_byte_cnt == 5'd21) && uart_tx_done) begin
        send_byte_cnt <= 5'd0;
    end
    else if (uart_tx_done) begin
        send_byte_cnt <= send_byte_cnt + 1'b1;
    end
    else begin
        send_byte_cnt <= send_byte_cnt;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        send_en <= 1'b0;
    end
    else if (date_time_change || uart_tx_done) begin
        send_en <= 1'b1;
    end
    else begin
        send_en <= 1'b0;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        uart_tx_data <= 8'd0;
        uart_tx_en <= 1'b0;
    end
    else if (send_en) begin
        case (send_byte_cnt) 
            5'd1 : begin uart_tx_data <= 8'h32;                     uart_tx_en <= 1'b1; end     //2
            5'd2 : begin uart_tx_data <= 8'h30;                     uart_tx_en <= 1'b1; end     //0
            5'd3 : begin uart_tx_data <= date_time_ascii[95:88];    uart_tx_en <= 1'b1; end     //2
            5'd4 : begin uart_tx_data <= date_time_ascii[87:80];    uart_tx_en <= 1'b1; end     //2
            5'd5 : begin uart_tx_data <= 8'h2d;                     uart_tx_en <= 1'b1; end     //-
            5'd6 : begin uart_tx_data <= date_time_ascii[79:72];    uart_tx_en <= 1'b1; end     //0 M
            5'd7 : begin uart_tx_data <= date_time_ascii[71:64];    uart_tx_en <= 1'b1; end     //5
            5'd8 : begin uart_tx_data <= 8'h2d;                     uart_tx_en <= 1'b1; end     //-
            5'd9 : begin uart_tx_data <= date_time_ascii[63:56];    uart_tx_en <= 1'b1; end     //2 D
            5'd10: begin uart_tx_data <= date_time_ascii[55:48];    uart_tx_en <= 1'b1; end     //7
            5'd11: begin uart_tx_data <= 8'h20;                     uart_tx_en <= 1'b1; end     //space
            5'd12: begin uart_tx_data <= date_time_ascii[47:40];    uart_tx_en <= 1'b1; end     //1 h
            5'd13: begin uart_tx_data <= date_time_ascii[39:32];    uart_tx_en <= 1'b1; end     //2
            5'd14: begin uart_tx_data <= 8'h3a;                     uart_tx_en <= 1'b1; end     //:
            5'd15: begin uart_tx_data <= date_time_ascii[31:24];    uart_tx_en <= 1'b1; end     //0 m
            5'd16: begin uart_tx_data <= date_time_ascii[23:16];    uart_tx_en <= 1'b1; end     //0
            5'd17: begin uart_tx_data <= 8'h3a;                     uart_tx_en <= 1'b1; end     //:
            5'd18: begin uart_tx_data <= date_time_ascii[15:8];     uart_tx_en <= 1'b1; end     //0 s
            5'd19: begin uart_tx_data <= date_time_ascii[7:0];      uart_tx_en <= 1'b1; end     //0
            5'd20: begin uart_tx_data <= 8'h0a;                     uart_tx_en <= 1'b1; end
            default:begin uart_tx_data <= 'd0;                      uart_tx_en <= 1'b0; end
      endcase
    end
    else begin
        uart_tx_data <= uart_tx_data;
        uart_tx_en <= 1'b0;
    end
end

endmodule