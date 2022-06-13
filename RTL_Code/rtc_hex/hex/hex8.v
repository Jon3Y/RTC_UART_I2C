module hex8(
    clk,
    rstn,
    disp_data,
    disp_en,
    seg,
    sel
);

input wire clk;
input wire rstn;
input wire [31:0] disp_data;
input wire disp_en;
output reg [6:0] seg;
output wire [7:0] sel;

reg [15:0] div_cnt;
reg clk_1K;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        div_cnt <= 15'd0;
    end
    else if (div_cnt == 15'd24_999) begin
        div_cnt <= 15'd0;
    end
    else begin
        div_cnt <= div_cnt + 1'b1;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        clk_1K <= 1'b0;
    end
    else if (div_cnt == 15'd24_999) begin
        clk_1K <= ~clk_1K;
    end
    else begin
        clk_1K <= clk_1K;
    end
end

reg [7:0] sel_r;
always @(posedge clk_1K or negedge rstn) begin
    if(!rstn) begin
        sel_r <= 8'b0000_0001;
    end
    else begin
        sel_r <= {sel_r[6:0],sel_r[7]};
    end
end

reg [7:0] data_temp;
always @(*) begin
    case (sel_r)
        8'b0000_0001:   data_temp = disp_data[3:0];
        8'b0000_0010:   data_temp = disp_data[7:4];
        8'b0000_0100:   data_temp = disp_data[11:8];
        8'b0000_1000:   data_temp = disp_data[15:12];
        8'b0001_0000:   data_temp = disp_data[19:16];
        8'b0010_0000:   data_temp = disp_data[23:20];
        8'b0100_0000:   data_temp = disp_data[27:24];
        8'b1000_0000:   data_temp = disp_data[31:28];
        default:        data_temp = 4'd0;
    endcase   
end

assign sel = (disp_en) ? sel_r : 8'd0; 

always @(*) begin
    case (data_temp)
        4'd0:       seg = 7'b1000000;
        4'd1:       seg = 7'b1111001;
        4'd2:       seg = 7'b0100100;
        4'd3:       seg = 7'b0110000;
        4'd4:       seg = 7'b0011001;
        4'd5:       seg = 7'b0010010;
        4'd6:       seg = 7'b0000010;
        4'd7:       seg = 7'b1111000;        
        4'd8:       seg = 7'b0000000;
        4'd9:       seg = 7'b0010000;
        4'd10:      seg = 7'b0001000;
        4'd11:      seg = 7'b0000011;
        4'd12:      seg = 7'b1000110;
        4'd13:      seg = 7'b0100001;
        4'd14:      seg = 7'b0000110;
        4'd15:      seg = 7'b0111111;           //f -> '-';
    endcase
end

endmodule