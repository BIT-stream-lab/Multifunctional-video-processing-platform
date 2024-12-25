/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2023/08/07
*Module Name:uiuart_rx
*File Name:uiuart_rx.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) I_ input
*2) O_ output
*3) IO_ input output
*4) S_ system internal signal
*5) _n activ low
*6) _dg debug signal 
*7) _r delay or register
*8) _s state mechine
*********************************************************************/

/*******************************UART接收驱动*********************
--以下是米联客设计的UART接收驱动器
--1.代码简洁，占用极少逻辑资源，代码结构清晰，逻辑设计严谨
--2.O_uart_rvalid有效，代表数据O_uart_rdata有效
--3.抗干扰设计，对每个bit采用8倍采样，如果采样到低电平的次数大于高电平，则为0，否则为1
*********************************************************************/

`timescale 1ns / 1ns//仿真时间刻度/精度


module uiuart_rx#
(
 parameter integer  BAUD_DIV     = 10416  //波特率分频参数，BAUD_DIV=系统时钟频率/波特率-1 比如100M系统时钟，波特率115200 BAUD_DIV= 100_000_000/115200-1
)
(
input I_clk, //系统时钟输入
input I_uart_rstn,//系统复位输入
input I_uart_rx,//uart rx 总线信号输入
output [7:0] O_uart_rdata,//uart rx接收到的数据输出
output O_uart_rvalid// uart rx 接收数据有效信号，当为1的时候O_uart_rdata数据有效
);

localparam  BAUD_DIV_SAMP = (BAUD_DIV/8)-1;                            //多次采样，按照波特率系数的八分之一进行采样

wire bps_en       ; //波特率使能信号
wire samp_en      ; //采样使能信号
wire bit_cap_done ; //uart rx总线信号采样有效数据完成
wire uart_rx_done ; //uart 1byte 接收完成
wire bit_data     ; //接收的1bit数据
wire I_uart_rxnt  ; //I_uart_rxnt的启动信号检测，当变为低电平，代表可能存在起始位(UART 起始位为低电平)

reg [13:0]  baud_div = 14'd0;//波特率分频计数器
reg [13:0]  samp_cnt = 14'd0;//采样计数器
reg [4 :0]  I_uart_rx_r = 5'd0;//异步采集多次寄存
reg [3 :0]  bit_cnt=4'd0;//bit 计数器
reg [3 :0]  cap_cnt=4'd0;//cap 计数器
reg [4 :0]  rx_bit_tmp = 5'd0;//rx_bit_tmp用于多次采样，通过计算采样到高电平次数和低电平次数，判断本次采样是高电平还是低电平
reg [7 :0]  rx_data = 8'd0;//数据接收寄存器

reg bps_start_en_r = 1'b0;
reg bit_cap_done_r = 1'b0;
reg bps_start_en,start_check_done,start_check_failed;

assign bps_en       =   (baud_div == (BAUD_DIV - 1'b1));                     //完成一次波特率传输信号
assign samp_en      =   (samp_cnt == (BAUD_DIV_SAMP - 1'b1 ));               //完成一次波特率采样信号
assign bit_cap_done =   (cap_cnt  == 3'd7);//采样计数
assign uart_rx_done =   (bit_cnt  == 9)&&(baud_div == BAUD_DIV >> 1);//当停止位开始，提前半停止位，发送uart_rx_done信号，以便提前准备进入下一个数据的接收

assign bit_data     =   (rx_bit_tmp < 5'd15) ? 0 : 1; //rx_bit_tmp用于多次采样，通过计算采样到高电平次数和低电平次数，判断本次采样是高电平还是低电平，提高抗干扰能力
//连续5次信号拉低，判断开始传输
assign I_uart_rxnt  =   I_uart_rx_r[4] | I_uart_rx_r[3] | I_uart_rx_r[2] | I_uart_rx_r[1] | I_uart_rx_r[0];
assign O_uart_rdata   =   rx_data;
assign O_uart_rvalid  =   uart_rx_done;   

//波特率计数器
always@(posedge I_clk)begin
    if(bps_start_en && baud_div < BAUD_DIV)                 //baud_div计数，目标值BAUD_DIV 
        baud_div <= baud_div + 1'b1;
    else 
        baud_div <= 14'd0;
end

//8bit采样使能，8倍波特率采样，也就是这个计数器，用于产生8倍过采样
always@(posedge I_clk)begin
    if(bps_start_en && samp_cnt < BAUD_DIV_SAMP)             //bps_start_en高电平有效，开始对bit进行采样，samp_cnt以8倍于波特率速度对每个bit采样
        samp_cnt <= samp_cnt + 1'b1;                         //samp_cnt计数+1       
    else 
        samp_cnt <= 14'd0;                                   //samp_cnt计数清零
end

//uart rx bus asynchronous to Synchronous
always@(posedge I_clk)begin 
    I_uart_rx_r <= {I_uart_rx_r[3:0],I_uart_rx};             //I_uart_rx的数据存入I_uart_rx_r进行缓存
end

//uart接收启动检查
always@(posedge I_clk)begin
    if(I_uart_rstn == 1'b0 || uart_rx_done || start_check_failed) //bps_start_en拉低的三种情况，复位、接收完成、校验失败
        bps_start_en    <= 1'b0;                                               //接收结束
    else if((I_uart_rxnt == 1'b0)&(bps_start_en==1'b0))//当判断到I_uart_rxnt == 1'b0，并且总线之前空闲(bps_start_en==1'b0，代表总线空闲)
        bps_start_en    <= 1'b1;//使能波特率计数器使能
end

//uart接收启动使能
always@(posedge I_clk)begin
        bps_start_en_r    <= bps_start_en;                              //bps_start_en信号打一拍，方便后续上升沿捕捉
end

always@(posedge I_clk)begin
    if(I_uart_rstn == 1'b0 || start_check_failed)begin//当系统复位，或者start_check_failed，重置start_check_done和start_check_failed
        start_check_done    <= 1'b0;
        start_check_failed  <= 1'b0;
    end    
    else if(bps_start_en == 1'b1&&bps_start_en_r == 1'b0) begin//当检测到start信号，也重置start_check_done和start_check_failed
        start_check_done    <= 1'b0;
        start_check_failed  <= 1'b0;
    end
    else if((bit_cap_done&&bit_cap_done_r==1'b0)&&(start_check_done == 1'b0))begin//第一个波特率采样，用于判断是否一个有效的起始位，如果不是有效的，start_check_failed设置为1
        start_check_failed <= bit_data ? 1'b1 : 1'b0;
        start_check_done   <= 1'b1;//不管是否start_check_failed==1，都会设置start_check_done=1，但是start_check_failed==1，会下一个系统时钟重置start_check_done=0
    end     
end

//bits 计数器
always@(posedge I_clk)begin
    if(I_uart_rstn == 1'b0 || uart_rx_done || bps_start_en == 1'b0)//复位、接收完成、或者总线空闲(bps_start_en == 1'b0),重置bit_cnt
        bit_cnt   <= 4'd0;                                                    
    else if(bps_en)//每一个bps_en有效，加1
        bit_cnt <= bit_cnt + 1'b1;  // bit_cnt计数器用于计算当前采样了第几个bit 
end

//8次过采样，提高抗干扰
always@(posedge I_clk)begin
    if(I_uart_rstn == 1'b0 || bps_en == 1'b1 || bps_start_en == 1'b0) begin //当I_uart_rstn=0或者bps_en=1或者bps_start_en==0，重置cap_cnt和rx_bit_tmp
        cap_cnt     <= 4'd0;
        rx_bit_tmp  <= 5'd15; 
    end
    else if(samp_en)begin//bit采样使能
        cap_cnt     <= cap_cnt + 1'b1;//cap_cnt用于记录了当前是第几次过采样，1个bit采样8次
        rx_bit_tmp  <= I_uart_rx_r[4] ? rx_bit_tmp + 1'b1 :  rx_bit_tmp - 1'b1;   //多次采样，如果是高电平+1,如果是低电平-1，最终看本次bit采样结束rx_bit_tmp如果小于15代表是低电平
    end                                                                                   
end

//寄存一次bit_cap_done，用于产生高电平触发脉冲下面用到
always@(posedge I_clk)
    bit_cap_done_r <= bit_cap_done;


always@(posedge I_clk)begin
    if(I_uart_rstn == 1'b0 || bps_start_en == 1'b0)//当复位或者总线空闲，重置rx_data
        rx_data  <= 8'd0;  
    else if(start_check_done&&(bit_cap_done&&bit_cap_done_r==1'b0)&&bit_cnt < 9)//当start_check_done有效，并且bit_cnt<9,每次bit_cap_done有效，完成一次移位寄存
        rx_data  <= {bit_data,rx_data[7:1]};                                         //串并转换，将数据存入rx_data 中，共8位
end

endmodule


