module adjust_time(
    clk,
    rstn,
    uart_rx_data,
    uart_data_valid,
    set_done,
    set_time,
    time_2_set,
    set_date,
    date_2_set
);

input wire clk;
input wire rstn;
input wire [7:0] uart_rx_data;
input wire uart_data_valid;
input wire set_done;
output reg set_time;
output reg [23:0] time_2_set;
output reg set_date;
output reg [31:0] date_2_set;

reg [103:0] rx_data;            //f0f1f2_YYMMDDWW_HHMMSS_f2f1f0;
wire data_check;
reg data_check_d;
wire data_check_pos;
reg set_state;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        rx_data <= 104'd0;
    end
    else if (uart_data_valid) begin
        rx_data <= {rx_data[95:0],uart_rx_data};
    end
    else begin
        rx_data <= rx_data;
    end
end

assign data_check = ({rx_data[103:80], rx_data[23:0]} == 48'hf0f1f2_f2f1f0);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_check_d <= 1'b0;
    end
    else begin
        data_check_d <= data_check;
    end
end

assign data_check_pos = (data_check & (!data_check_d));

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        set_time <= 1'b0;
    end
    else if (set_done) begin
        set_time <= 1'b0;
    end
    else if (data_check_pos) begin
        set_time <= 1'b1;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        time_2_set <= 24'd0;
        date_2_set <= 32'd0;
    end
    else if (data_check_pos) begin
        time_2_set <= rx_data[47:24];
        date_2_set <= rx_data[79:48];
    end
    else begin
        time_2_set <= time_2_set;
        date_2_set <= date_2_set;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        set_state <= 1'b0;
    end
    else if (set_time) begin
        set_state <= 1'b1;
    end
    else if (set_date) begin
        set_state <= 1'b0;
    end
    else begin
        set_state <= set_state;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        set_date <= 1'b0;
    end
    else if (set_done && set_state) begin
        set_date <= 1'b1;
    end
    else if (set_done && (!set_state)) begin
        set_date <= 1'b0;
    end
    else begin
        set_date <= set_date;
    end
end

endmodule