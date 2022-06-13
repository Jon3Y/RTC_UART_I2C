module hex_top(
    clk,
    rstn,
    disp_data,
    sh_cp,
    st_cp,
    ds
);

input wire clk;
input wire rstn;
input wire [31:0] disp_data;
output wire sh_cp;
output wire st_cp;
output wire ds;

wire [7:0] sel;
wire [6:0] seg;

hex8 u_hex8(
    .clk(clk),
    .rstn(rstn),
    .disp_data(disp_data),
    .disp_en(1'b1),
    .seg(seg),
    .sel(sel)
);

hc595_driver u_hc595_driver(
    .clk(clk),
    .rstn(rstn),
    .en(1'b1),
    .data({1'b1, seg, sel}),
    .ds(ds),
    .sh_cp(sh_cp),
    .st_cp(st_cp)
);

endmodule