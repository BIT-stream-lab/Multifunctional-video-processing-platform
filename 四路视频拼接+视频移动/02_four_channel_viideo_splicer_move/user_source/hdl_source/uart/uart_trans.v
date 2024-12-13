/*
 * @Author: bit_stream 
 * @Date: 2024-12-12 19:09:02 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-12 19:11:11
 */

module uart_trans(
    input  I_sysclk,//系统时钟输入
    input  I_uart_rx,//uart rx接收信号
    output O_uart_tx, //uart tx发送信号
    output wire O_video_move_en
);


localparam SYSCLKHZ = 25_000_000;  //系统输入时钟

reg [11:0] rstn_cnt = 0;//上电后延迟复位
wire uart_rstn_i;//内部复位信号
wire uart_wreq,uart_rvalid;
wire [7:0]uart_wdata,uart_rdata;

assign uart_wreq  = uart_rvalid;//用uart rx接收数据有效的uart_rvalid信号，控制uart发送模块的发送请求
assign uart_wdata = uart_rdata; //接收的数据给发送模块发送
assign uart_rstn_i = rstn_cnt[11];//延迟复位设计，用计数器的高bit控制复位

//同步计数器实现复位
always @(posedge I_sysclk)begin
    if(rstn_cnt[11] == 1'b0)
        rstn_cnt <= rstn_cnt + 1'b1;
    else 
        rstn_cnt <= rstn_cnt;
end



reg [3:0]       reg_ctrl_command;
reg [3:0]       reg_value_command;

reg command_out_flag;

// 延迟一个周期
always @(posedge I_sysclk or negedge uart_rstn_i) begin
    if(!uart_rstn_i) begin
        command_out_flag <= 'b0;
    end
    else begin
        command_out_flag <= uart_rvalid;
    end
end

// 控制信号只有效一个时钟周期
always @(posedge I_sysclk or negedge uart_rstn_i) begin
    if(!uart_rstn_i) begin
        reg_ctrl_command <= 'b0;
        reg_value_command <= 'b0;
    end
    else if(uart_rvalid) begin
        reg_ctrl_command <= uart_rdata[7:4];
        reg_value_command <= uart_rdata[3:0];
    end
    else begin
        reg_ctrl_command <= reg_ctrl_command;
        reg_value_command <= reg_value_command;
    end
end


command_parsing u_command_parsing(
	.clk              	               ( I_sysclk                           ),
	.rst_n            	               ( uart_rstn_i                        ),
	.I_command_flag     	           ( command_out_flag                   ),
	.I_ctrl_command 	               ( reg_ctrl_command                   ),
	.I_value_command	               ( reg_value_command                  ),
	.O_video_move_en     	           ( O_video_move_en              )
);


//例化uart 发送模块
uiuart_tx#
(
.BAUD_DIV(SYSCLKHZ/115200-1)    
)
uart_tx_u 
(
.I_clk(I_sysclk),//系统时钟输入
.I_uart_rstn(uart_rstn_i), //系统复位
.I_uart_wreq(uart_wreq), //uart发送驱动的写请求信号，高电平有效
.I_uart_wdata(uart_wdata), //uart发送驱动的写数据
.O_uart_wbusy(),//uart 发送驱动的忙标志
.O_uart_tx(O_uart_tx)//uart 串行数据发送
);

//例化uart 接收
uiuart_rx#
(
.BAUD_DIV(SYSCLKHZ/115200-1)   
)
uiuart_rx_u 
(
.I_clk(I_sysclk), //系统时钟输入
.I_uart_rstn(uart_rstn_i),//系统复位
.I_uart_rx(I_uart_rx), //uart 串行数据接收
.O_uart_rdata(uart_rdata), //uart 接收数据
.O_uart_rvalid(uart_rvalid)//uart 接收数据有效，当O_uart_rvalid =1'b1 O_uart_rdata输出的数据有效
);

endmodule