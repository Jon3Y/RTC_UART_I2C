module time_send_uart(
    clk,
    rstn,
    date_time_en,
    time_data,
    date_data,
    uart_tx
);

input wire clk;
input wire rstn;
input wire date_time_en;
input wire [23:0] time_data;
input wire [31:0] date_data;
output wire uart_tx;

wire uart_tx_done;
wire uart_tx_en;
wire [7:0] uart_tx_data;
wire [47:0] date_time;

assign date_time = {date_data[31:8], time_data[23:0]};

time_send u_time_send(
    .clk(clk),
    .rstn(rstn),
    .date_time_en(date_time_en),
    .date_time(date_time),
    .uart_tx_done(uart_tx_done),
    .uart_tx_en(uart_tx_en),
    .uart_tx_data(uart_tx_data)
);

uart_byte_tx u_uart_byte_tx(
    .clk(clk),
    .rstn(rstn),
    .send_en(uart_tx_en),
    .data(uart_tx_data),
    .baud_set(3'd0),
    .uart_tx(uart_tx),
    .tx_done(uart_tx_done),
    .uart_state()
);

endmodule