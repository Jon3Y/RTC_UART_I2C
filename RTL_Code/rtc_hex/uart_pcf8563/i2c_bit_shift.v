module i2c_bit_shift(
    clk,
    rstn,
    cmd,
    go,
    tx_data,
    i2c_sclk,
    i2c_sdat,
    trans_done,
    rx_data,
    ack_o 
);

input wire clk;
input wire rstn;
input wire [5:0] cmd;
input wire go;
input wire [7:0] tx_data;
inout i2c_sdat;
output reg i2c_sclk;
output reg trans_done;
output reg [7:0] rx_data;
output reg ack_o;

localparam
            IDLE = 3'd0,                             //空闲状态；
            GEN_STA = 3'd1,                          //产生起始信号；
            WR_DATA = 3'd2,                          //写数据状态；
            RD_DATA = 3'd3,                          //读数据状态；                                                                    
            CHECK_ACK = 3'd4,                        //检测应答状态；
            GEN_ACK = 3'd5,                          //产生应答状态；
            GEN_STO = 3'd6;                          //产生停止信号；

localparam
            WR = 6'b000001,                          //写请求；
            STA = 6'b000010,                         //起始位请求；
            RD = 6'b000100,                          //读请求；
            STO = 6'b001000,                         //停止位请求；
            ACK = 6'b010000,                         //应答位请求；
            NACK = 6'b100000;                        //无应答请求；

parameter SYS_CLOCK = 50_000_000;
parameter SCL_CLOCK = 400_000;
parameter SCL_CNT_M = (SYS_CLOCK/SCL_CLOCK/4 - 1);

reg i2c_sdat_o;
reg i2c_sdat_oe;
reg [19:0] div_cnt;
reg en_div_cnt;
reg [2:0] state;
reg [4:0] cnt;
reg go_r;
wire go_d;
wire sclk_plus;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        go_r <= 1'b0;
    end
    else begin
        go_r <= go;
    end
end
assign go_d = go | go_r;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        div_cnt <= 20'd0;
    end
    else if (en_div_cnt) begin
        if (div_cnt == SCL_CNT_M) begin
            div_cnt <= 20'd0;
        end
        else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end
    else begin
        div_cnt <= 20'd0;
    end
end

assign sclk_plus = (div_cnt == SCL_CNT_M);
assign i2c_sdat = ((!i2c_sdat_o) & i2c_sdat_oe) ? 1'b0 : 1'bz;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        rx_data <= 8'd0;
        i2c_sdat_o <= 1'b1;
        i2c_sdat_oe <= 1'b0;
        en_div_cnt <= 1'b0;
        trans_done <= 1'b0;
        ack_o <= 1'b0;
        state <= IDLE;
        cnt <= 5'd0;
    end
    else begin
        case (state)
            IDLE:
                begin
                    cnt <= 5'd0;
                    trans_done <= 1'b0;
                    i2c_sdat_oe <= 1'b1;
                    if (go_d) begin
                        en_div_cnt <= 1'b1;
                        if (cmd & STA) begin
                            state <= GEN_STA;
                        end
                        else if (cmd & WR) begin
                            state <= WR_DATA;
                        end
                        else if (cmd & RD) begin
                            state <= RD_DATA;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end
                    else begin
                        en_div_cnt <= 1'b0;
                        state <= IDLE;
                    end
                end
            GEN_STA:
                begin
                    if (sclk_plus) begin
                        if (cnt == 5'd3) begin
                            cnt <= 5'd0;
                        end
                        else begin
                            cnt <= cnt + 1'b1;
                        end
                        case (cnt)
                            5'd0:   begin   
                                    i2c_sdat_o <= 1'b1;
                                    i2c_sdat_oe <= 1'b1;
                                    end
                            5'd1:   begin
                                    i2c_sclk <= 1'b1;
                                    end
                            5'd2:   begin
                                    i2c_sdat_o <= 1'b0;
                                    i2c_sclk <= 1'b1;
                                    end
                            5'd3:   begin
                                    i2c_sclk <= 1'b0;
                                    end
                            default:begin
                                    i2c_sdat_o <= 1'b1;
                                    i2c_sclk <= 1'b1;
                                    end
                        endcase
                        if (cnt == 5'd3) begin
                            if (cmd & WR) begin
                                state <= WR_DATA;
                            end
                            else if (cmd & RD) begin
                                state <= RD_DATA;
                            end
                        end
                    end
                end
            WR_DATA:
                begin
                    if (sclk_plus) begin
                        if (cnt == 5'd31) begin
                            cnt <= 5'd0;
                        end
                        else begin
                            cnt <= cnt + 1'b1;
                        end
                        case (cnt)
                            0,4,8,12,16,20,24,28:
                                begin
                                    i2c_sdat_o <= tx_data[7-cnt[4:2]];
                                    i2c_sdat_oe <= 1'd1;
                                end
                            1,5,9,13,17,21,25,29:
                                begin
                                    i2c_sclk <= 1'b1;
                                end
                            2,6,10,14,18,22,26,30:
                                begin
                                    i2c_sclk <= 1'b1;
                                end
                            3,7,11,15,19,23,27,31:
                                begin
                                    i2c_sclk <= 1'b0;
                                end
                            default:
                                begin
                                    i2c_sdat_o <= 1'b1;
                                    i2c_sclk <= 1'b1;
                                end
                        endcase
                        if (cnt == 5'd31) begin
                            state <= CHECK_ACK;
                        end
                    end
                end
            RD_DATA:
                begin
                    if (sclk_plus) begin
                        if (cnt == 5'd31) begin
                            cnt <= 5'd0;
                        end
                        else begin
                            cnt <= cnt + 1'b1;
                        end
                        case (cnt)
                            0,4,8,12,16,20,24,28:
                                begin
                                    i2c_sdat_oe <= 1'b0;
                                    i2c_sclk <= 1'b0;
                                end
                            1,5,9,13,17,21,25,29:
                                begin
                                    i2c_sclk <= 1'b1;
                                end
                            2,6,10,14,18,22,26,30:
                                begin
                                    i2c_sclk <= 1'b1;
                                    rx_data <= {rx_data[6:0],i2c_sdat};
                                end
                            3,7,11,15,19,23,27,31:
                                begin
                                    i2c_sclk <= 1'b0;
                                end
                            default:
                                begin
                                    i2c_sdat_o <= 1'b1;
                                    i2c_sclk <= 1'b1;
                                end
                        endcase
                        if (cnt == 5'd31) begin
                            state <= GEN_ACK;
                        end
                    end
                end
            CHECK_ACK:
                begin
                    if (sclk_plus) begin
                        if (cnt == 5'd3) begin
                            cnt <= 5'd0;
                        end
                        else begin
                            cnt <= cnt + 1'b1;
                        end
                        case (cnt)
                            5'd0:   begin   
                                    i2c_sclk <= 1'b0;
                                    i2c_sdat_oe <= 1'b0;
                                    end
                            5'd1:   begin
                                    i2c_sclk <= 1'b1;
                                    end
                            5'd2:   begin
                                    ack_o <= i2c_sdat;
                                    i2c_sclk <= 1'b1;
                                    end
                            5'd3:   begin
                                    i2c_sclk <= 1'b0;
                                    end
                            default:begin
                                    i2c_sdat_o <= 1'b1;
                                    i2c_sclk <= 1'b1;
                                    end
                        endcase
                        if (cnt == 5'd3) begin
                            if (cmd & STO) begin
                                state <= GEN_STO;
                            end
                            else begin
                                state <= IDLE;
                                trans_done <= 1'b1;
                            end
                        end
                    end
                end
            GEN_ACK:
                begin
                    if (sclk_plus) begin
                        if (cnt == 5'd3) begin
                            cnt <= 5'd0;
                            if (cmd & STO) begin
                                state <= GEN_STO;
                                i2c_sclk <= 1'b0;
                            end
                            else begin
                                state <= IDLE;
                                trans_done <= 1'b1;
                            end
                        end
                        else begin
                            cnt = cnt + 1'b1;
                        end
                        case (cnt)
                            5'd0:   begin        
                                    if (cmd & ACK) begin
                                        i2c_sdat_o <= 1'b0;
                                        i2c_sclk <= 1'b0;
                                        i2c_sdat_oe <= 1'b1;
                                    end
                                    else if (cmd & NACK) begin
                                        i2c_sdat_o <= 1'b1;
                                        i2c_sclk <= 1'b0;
                                        i2c_sdat_oe <= 1'b1;
                                    end
                                    end
                            5'd1:   begin
                                    i2c_sclk <= 1'b0;
                                    end
                            5'd2:   begin
                                    i2c_sclk <= 1'b1;
                                    end
                            5'd3:   begin
                                    end
                            default:begin
                                    i2c_sdat_o <= 1'b1;
                                    i2c_sclk <= 1'b1;
                                    end
                        endcase
                    end
                end
            GEN_STO:
                begin
                    if (sclk_plus) begin
                        if (cnt == 5'd3) begin
                            cnt <= 5'd0;
                            state <= IDLE;
                            trans_done <= 1'b1;
                        end
                        else begin
                            cnt = cnt + 1'b1;
                        end
                        case (cnt)
                            5'd0:   begin
                                    i2c_sclk <= 1'b0; 
                                    end
                            5'd1:   begin
                                    i2c_sclk <= 1'b0;
                                    i2c_sdat_oe <= 1'b1;
                                    i2c_sdat_o <= 1'b0;
                                    end
                            5'd2:   begin
                                    i2c_sclk <= 1'b1;    
                                    end
                            5'd3:   begin
                                    i2c_sclk <= 1'b1;
                                    i2c_sdat_o <= 1'b1;   
                                    end
                            default:begin
                                    i2c_sclk <= 1'b1;
                                    end
                        endcase
                    end
                end
            default:
                begin
                    state <= IDLE;
                end
        endcase
    end
end

endmodule