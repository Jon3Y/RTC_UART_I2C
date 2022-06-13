module hc595_driver(
    clk,
    rstn,
    en,
    data,
    ds,
    sh_cp,
    st_cp
);

input wire clk;
input wire rstn;
input wire en;
input wire [15:0] data;
output reg ds;
output reg sh_cp;
output reg st_cp;

//data reg;
reg [15:0] data_r;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_r <= 16'd0;
    end
    else if (en) begin
        data_r <= data;
    end
    else begin
        data_r <= data_r;
    end
end

//4 clk_divider;
reg clk_4;
reg div_cnt;
reg clk_4_d;
wire clk_4_pos;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        div_cnt <= 1'b0;
    end
    else if (div_cnt == 1'b1) begin
        div_cnt <= 1'b0;
    end
    else begin
        div_cnt <= div_cnt + 1'b1;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
       clk_4 <= 1'b0;
    end
    else if (div_cnt == 1'b1) begin
       clk_4 <= ~clk_4;
    end
    else begin
        clk_4 <= clk_4;
    end
end

always @(posedge clk  or negedge rstn) begin
    if (!rstn) begin
        clk_4_d <= 1'b0;
    end
    else begin
        clk_4_d <= clk_4;
    end
end

assign clk_4_pos = clk_4 & (!clk_4_d);


//sh_cnt;
reg [5:0] sh_cp_edge_cnt;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sh_cp_edge_cnt <= 6'd0;
    end
    else if(sh_cp_edge_cnt == 6'd32) begin
        sh_cp_edge_cnt <= 6'd0;
    end
    else if (clk_4_pos) begin
        sh_cp_edge_cnt <= sh_cp_edge_cnt + 1'b1;
    end
    else begin
        sh_cp_edge_cnt <= sh_cp_edge_cnt;
    end    
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        ds <= 1'b0;
        st_cp <= 1'b0;
        sh_cp <= 1'b0;
    end
    else begin
        case (sh_cp_edge_cnt)
            1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31: begin
                sh_cp <= 1'b1;
            end
            0:    begin
                ds <= data_r[15];
                sh_cp <= 1'b0;
                st_cp <= 1'b0;
            end
            2:    begin
                ds <= data_r[14];
                sh_cp <= 1'b0;
            end
            4:    begin
                ds <= data_r[13];
                sh_cp <= 1'b0;
            end
            6:    begin
                ds <= data_r[12];
                sh_cp <= 1'b0;
            end
            8:    begin
                ds <= data_r[11];
                sh_cp <= 1'b0;
            end
            10:    begin
                ds <= data_r[10];
                sh_cp <= 1'b0;
            end
            12:    begin
                ds <= data_r[9];
                sh_cp <= 1'b0;
            end
            14:    begin
                ds <= data_r[8];
                sh_cp <= 1'b0;
            end
            16:    begin
                ds <= data_r[7];
                sh_cp <= 1'b0;
            end
            18:    begin
                ds <= data_r[6];
                sh_cp <= 1'b0;
            end
            20:    begin
                ds <= data_r[5];
                sh_cp <= 1'b0;
            end
            22:    begin
                ds <= data_r[4];
                sh_cp <= 1'b0;
            end
            24:    begin
                ds <= data_r[3];
                sh_cp <= 1'b0;
            end
            26:    begin
                ds <= data_r[2];
                sh_cp <= 1'b0;
            end
            28:    begin
                ds <= data_r[1];
                sh_cp <= 1'b0;
            end
            30:    begin
                ds <= data_r[0];
                sh_cp <= 1'b0;
            end
            32:    begin
                st_cp <= 1'b1;
            end
            default:    begin
                ds <= 1'b0;
                sh_cp <= 1'b0;
                st_cp <= 1'b0;
            end
        endcase
    end
end

endmodule