module uart_adjust_time(
    clk,
    rstn,
    uart_rx,
    set_done,
    set_time,
    set_date,
    time_2_set,
    date_2_set
);

input wire clk;
input wire rstn;
input wire uart_rx;
input wire set_done;
output wire set_time;
output wire set_date;
output wire [23:0] time_2_set;
output wire [31:0] date_2_set;

wire [7:0] uart_rx_data;
wire uart_data_valid;


uart_byte_rx u_uart_byte_rx(
    .clk(clk),
    .rstn(rstn),
    .uart_rx(uart_rx),
    .baud_set(3'd0),
    .data_byte(uart_rx_data),
    .rx_done(uart_data_valid)
);

adjust_time u_adjust_time(
    .clk(clk),
    .rstn(rstn),
    .uart_rx_data(uart_rx_data),
    .uart_data_valid(uart_data_valid),
    .set_done(set_done),
    .set_time(set_time),
    .set_date(set_date),
    .time_2_set(time_2_set),
    .date_2_set(date_2_set)
);

endmodule