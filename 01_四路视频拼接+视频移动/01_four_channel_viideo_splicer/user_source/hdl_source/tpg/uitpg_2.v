
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2019/12/17
*Module Name:rgb_to_hdmi
*File Name:rgb_to_hdmi.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.1
*Signal description
*1) I_ input
*2) O_ output
*3) IO_ input output
*3) S_ system internal signal
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/

/*********uitpg(video test Pattern Generator)测试视频发生器***********
--版本号1.1
--以下是米联客设计的uitpg(video test Pattern Generator)测试视频发生器
--1.代码简洁，占用极少逻辑资源，代码结构清晰，逻辑设计严谨
--2.该测试视频发生器通过产生彩条、渐变、纯色、棋方格，产生测试图形
*********************************************************************/

`timescale 1ns / 1ns//仿真时间刻度/精度

module uitpg_2
(
input			I_tpg_clk, //系统时钟
input           I_tpg_rstn,//系统复位
input			I_tpg_vs,  //场同步输入
input           I_tpg_hs,  //行同步输入
input           I_tpg_de,  //视频数据有效输入	
output			O_tpg_vs,  //场同步输出
output          O_tpg_hs,  //行同步输出
output          O_tpg_de,  //视频数据有效输出	 
output [23:0]	O_tpg_data //有效测试数据
);

reg         tpg_vs_r   = 1'b0; //对vs信号寄存
reg         tpg_hs_r   = 1'b0; //对hs信号寄存
reg [7 :0]  grid_data  = 8'd0; //grid棋方格寄存器
reg [23:0]  color_bar  = 24'd0;//RGB 彩条寄存器
reg [10:0]  dis_mode   = 11'd0;//显示模式寄存器
reg [7 :0]  r_reg      = 8'd0; //红寄存器
reg [7 :0]  g_reg      = 8'd0; //绿寄存器
reg [7 :0]  b_reg      = 8'd0; //蓝寄存器


always @(posedge I_tpg_clk)begin
    tpg_vs_r <= I_tpg_vs; //对vs信号寄存一次
    tpg_hs_r <= I_tpg_hs; //对hs信号寄存一次
end

reg [11:0]v_cnt = 12'd0; //视频垂直方向，行计数器
reg [11:0]h_cnt = 12'd0; //视频水平方向，列计数器

//h_cnt计数器模块
always @(posedge I_tpg_clk)
	h_cnt <= I_tpg_de ? h_cnt + 1'b1 : 12'd0; //计数行有效像素,当de无效，重置 h_cnt=0

//v_cnt计数器模块
always @(posedge I_tpg_clk)
  if(I_tpg_vs) //通过vs产生同步复位
	v_cnt <= 12'd0; //重置v_cnt=0
  else 
	v_cnt <= ((!tpg_hs_r)&&I_tpg_hs) ? v_cnt + 1'b1 : v_cnt; //hs信号的上升沿，v_cnt计数，这种方式可以不管hs有效是高电平还是低电平的情况,v_cnt 视频垂直方向，行计数器，计数行数量

//显示模式切换
always @(posedge I_tpg_clk)
   if(I_tpg_rstn==1'b0)
	dis_mode <= 0;
   else 
    dis_mode <= ((!tpg_vs_r)&&I_tpg_vs) ? dis_mode + 1'b1 : dis_mode;

//grid_data发生器	
always @(posedge I_tpg_clk)begin
	grid_data <= ((v_cnt[4]==1'b1) ^ (h_cnt[4]==1'b1)) ? 8'h00 : 8'hff; //方格大小16*16，黑白交替
end

//RGB彩条发生器
always @(posedge I_tpg_clk)
begin
	if(h_cnt==260)
	color_bar	<=	24'hff0000;//红
	else if(h_cnt==420)
	color_bar	<=	24'h00ff00;//绿
	else if(h_cnt==580)
	color_bar	<=	24'h0000ff;//蓝
	else if(h_cnt==740)
	color_bar	<=	24'hff00ff;//紫
	else if(h_cnt==900)
	color_bar	<=	24'hffff00;//黄
	else if(h_cnt==1060)
	color_bar	<=	24'h00ffff;//青蓝
	else if(h_cnt==1220)
	color_bar	<=	24'hffffff;//白
	else if(h_cnt==1380)
	color_bar	<=	24'h000000;//黑
	else
	color_bar	<=	color_bar;
end

//测试图形输出
always @(posedge I_tpg_clk)begin
    case(dis_mode[10:7]) // 截取高位，控制切换显示速度
        4'd0:begin
			r_reg <= grid_data;                 // 方格
            g_reg <= grid_data;
            b_reg <= grid_data;
		end
        4'd1:begin
			r_reg <= v_cnt[7:0];                 // 垂直渐变
            g_reg <= v_cnt[7:0];
            b_reg <= v_cnt[7:0];
		end
        4'd2:begin
			r_reg <= 8'b11111111;               // 白色
            g_reg <= 8'b11111111;
            b_reg <= 8'b11111111;
		end			  
        4'd3:begin     
			r_reg <= color_bar[23:16];           // 彩条
            g_reg <= color_bar[15:8];
            b_reg <= color_bar[7:0];
		end					  
        4'd4:begin     
			r_reg <= 0;                          // 黑色
			g_reg <= 0;
			b_reg <= 0;
		end
        4'd5:begin     
			r_reg <= v_cnt[7:0];                 // 红垂直渐变
            g_reg <= 0;
            b_reg <= 0;
		end
        4'd6:begin     
			r_reg <= h_cnt[7:0];                // 水平渐变
            g_reg <= h_cnt[7:0];
            b_reg <= h_cnt[7:0];
		end
        4'd7:begin    
			r_reg <= 0;                           // 蓝色
            g_reg <= 0; 
            b_reg <= 8'b11111111;  
		end
        4'd8:begin
			r_reg <= 8'b11111111;               // 红色                     
            g_reg <= 0;
            b_reg <= 0;
		end
        4'd9:begin  
			r_reg <= 0;                          // 绿垂直渐变
            g_reg <= h_cnt[7:0];
            b_reg <= 0;
		end
        4'd10:begin     
			r_reg <= 0;                          // 蓝垂直渐变
            g_reg <= 0;
            b_reg <= h_cnt[7:0];
		end
        4'd11:begin     
			r_reg <= color_bar[23:16];           // 彩条
            g_reg <= color_bar[15:8];
            b_reg <= color_bar[7:0];			
		end	
		default:
	    begin     
			r_reg <= color_bar[23:16];           // 彩条
            g_reg <= color_bar[15:8];
            b_reg <= color_bar[7:0];			
		end					  
    endcase
end


assign O_tpg_data = {r_reg,g_reg,b_reg};//测试图形RGB数据输出
assign O_tpg_vs = I_tpg_vs;  //VS同步信号
assign O_tpg_hs = I_tpg_hs;  //HS同步信号
assign O_tpg_de = I_tpg_de;  //DE数据有效信号

endmodule
