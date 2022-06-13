module i2c_control(
    clk,
    rstn,
    wr_req,
    rd_req,
    addr,
    addr_mode,
    wr_data,
    rd_data,
    device_id,
    rw_done,
    ack,
    i2c_sclk,
    i2c_sdat
);

input wire clk;
input wire rstn;
input wire wr_req;
input wire rd_req;
input wire [15:0] addr;
input wire addr_mode;
input wire [7:0] wr_data;
input wire [7:0] device_id;
output reg [7:0] rd_data;
output reg rw_done;
output reg ack;
output wire i2c_sclk;
inout i2c_sdat;

localparam
            WR      = 6'b000001,                     //写请求；
            STA     = 6'b000010,                     //起始位请求；
            RD      = 6'b000100,                     //读请求；
            STO     = 6'b001000,                     //停止位请求；
            ACK     = 6'b010000,                     //应答位请求；
            NACK    = 6'b100000;                     //无应答请求；

localparam
            IDLE         = 7'b0000001,               //空闲状态；
            WR_REG       = 7'b0000010,               //写状态；
            WAIT_WR_DONE = 7'b0000100,               //等待写完成状态；
            WR_REG_DONE  = 7'b0001000,               //写完成状态；
            RD_REG       = 7'b0010000,               //读状态；
            WAIT_RD_DONE = 7'b0100000,               //等待读完成状态；
            RD_REG_DONE  = 7'b1000000;               //读完成状态；

reg [5:0] cmd;
reg [7:0] tx_data;
reg go;
reg [6:0] state;
reg [7:0] cnt;
wire [15:0] reg_addr;
wire [7:0] rx_data;

task read_byte;
    input [5:0] ctrl_cmd;
    begin
        cmd <= ctrl_cmd;
        go <=1'b1;
    end
endtask

task write_byte;
    input [5:0] ctrl_cmd;
    input [7:0] wr_byte_data;
    begin
        cmd <= ctrl_cmd;
        tx_data <= wr_byte_data;
        go <= 1'b1;
    end
endtask

//1-16bit addr, 0-8bit addr;
assign reg_addr = (addr_mode) ? addr : {addr[7:0],addr[15:8]};

i2c_bit_shift u_i2c_bit_shift(
	.clk(clk),
	.rstn(rstn),
	.cmd(cmd),
	.go(go),
	.rx_data(rx_data),
	.tx_data(tx_data),
	.trans_done(trans_done),
	.ack_o(ack_o),
	.i2c_sclk(i2c_sclk),
	.i2c_sdat(i2c_sdat)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cmd <= 6'd0;
        tx_data <= 8'd0;
        go <= 1'b0;
        rd_data <= 8'd0;
        state <= IDLE;
        ack <= 1'b0;
        cnt <= 8'd0;
    end
    else begin
        case (state)
            IDLE:
                begin
                    cnt <= 8'd0;
                    ack <= 1'b0;
                    rw_done <= 1'b0;
                    if (wr_req) begin
                        state <= WR_REG;
                    end
                    else if (rd_req) begin
                        state <= RD_REG;
                    end
                    else begin
                        state <= IDLE;
                    end
                end
            WR_REG:
                begin
                    state <= WAIT_WR_DONE;
                    case (cnt) 
                        8'd0:   write_byte(WR|STA, device_id);
                        8'd1:   write_byte(WR, reg_addr[15:8]);
                        8'd2:   write_byte(WR, reg_addr[7:0]);
                        8'd3:   write_byte(WR|STO, wr_data);
                        default:;
                    endcase
                end
            WAIT_WR_DONE:
                begin
                    go <= 1'b0;
                    if (trans_done) begin
                        ack <= ack | ack_o;
                        case (cnt) 
                            8'd0:
                                begin
                                    cnt <= 8'd1;
                                    state <= WR_REG;
                                end
                            8'd1:
                                begin
                                    state <= WR_REG;
                                    if (addr_mode) begin
                                        cnt <= 8'd2;
                                    end
                                    else begin
                                        cnt <= 8'd3;
                                    end
                                end
                            8'd2:
                                begin
                                    cnt <= 8'd3;
                                    state <= WR_REG;
                                end
                            8'd3:
                                begin
                                    state <= WR_REG_DONE;
                                end
                            default:
                                begin
                                    state <= IDLE;
                                end
                        endcase
                    end
                end
            WR_REG_DONE:
                begin
                    rw_done <= 1'b1;
                    state <= IDLE;
                end
            RD_REG:
                begin
                    state <= WAIT_RD_DONE;
                    case (cnt)
                        8'd0:   write_byte(WR|STA, device_id);
                        8'd1:   write_byte(WR, reg_addr[15:8]);
                        8'd2:   write_byte(WR, reg_addr[7:0]);
                        8'd3:   write_byte(WR|STA, device_id|8'd1);
                        8'd4:   read_byte((RD|NACK|STO));
                        default:;
                    endcase
                end
            WAIT_RD_DONE:
                begin
                    go <= 1'b0;
                    if (trans_done) begin
                        ack <= ack | ack_o;
                        case (cnt) 
                            8'd0:
                                begin
                                    cnt <= 8'd1;
                                    state <= RD_REG;
                                end
                            8'd1:
                                begin
                                    state <= RD_REG;
                                    if (addr_mode) begin
                                        cnt <= 8'd2;
                                    end
                                    else begin
                                        cnt <= 8'd3;
                                    end
                                end
                            8'd2:
                                begin
                                    cnt <= 8'd3;
                                    state <= RD_REG;
                                end
                            8'd3:
                                begin
                                    cnt <= 8'd4;
                                    state <= RD_REG;
                                end
                            8'd4:
                                begin
                                    state <= RD_REG_DONE;
                                end
                            default:
                                begin
                                    state <= IDLE;
                                end
                        endcase
                    end
                end
            RD_REG_DONE:
                begin
                    rw_done <= 1'b1;
                    rd_data <= rx_data;
                    state <= IDLE;
                end
            default:
                begin
                    state <= IDLE;
                end
        endcase
    end
end

endmodule