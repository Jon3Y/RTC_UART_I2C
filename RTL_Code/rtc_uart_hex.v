module rtc_uart_hex(
    clk,
    rstn,
    key_in,
    uart_rx,
    uart_tx,
    sh_cp,
    st_cp,
    ds,
    i2c_sclk,
    i2c_sdat
);

input wire clk;
input wire rstn;
input wire key_in;
input wire uart_rx;
output wire uart_tx;
output wire sh_cp;
output wire st_cp;
output wire ds;
output wire i2c_sclk;
inout i2c_sdat;

wire [23:0] time_data;
wire [31:0] date_data;
wire [31:0] disp_data;
wire disp_data_sel;
wire read_done;

assign disp_data = disp_data_sel ? {time_data[23:16], 4'hf, time_data[15:8], 4'hf, time_data[7:0]} : {8'h20, date_data[31:8]};

uart_pcf8563_ctrl u_uart_pcf8563_ctrl(
    .clk(clk),
    .rstn(rstn),
    .uart_rx(uart_rx),
    .time_read(time_data),
    .date_read(date_data),
    .read_done(read_done),
    .i2c_sclk(i2c_sclk),
    .i2c_sdat(i2c_sdat)
);

hex_top u_hex_top(
    .clk(clk),
    .rstn(rstn),
    .disp_data(disp_data),
    .sh_cp(sh_cp),
    .st_cp(st_cp),
    .ds(ds)
);

key_filter u_key_filter(
    .clk(clk),
    .rstn(rstn),
    .key_in(key_in),
    .key_flag(),
    .key_state(disp_data_sel)
);

time_send_uart u_time_send_uart(
    .clk(clk),
    .rstn(rstn),
    .date_time_en(read_done),
    .time_data(time_data),
    .date_data(date_data),
    .uart_tx(uart_tx)
);

endmodule