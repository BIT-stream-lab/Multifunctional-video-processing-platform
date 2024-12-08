/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2023/03/23
*Module Name:
*File Name:
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

/*************uivtc(video timing controller)视频时序控制器*************
--版本号1.1
--以下是米联客设计的uivtc(video timing controller)视频时序控制器
--1.代码简洁，占用极少逻辑资源，代码结构清晰，逻辑设计严谨
--2.使用方便，只需要输入6个参数既可以实现对不同视频分辨率时序的控制
--3.该视频时序控制，一个时钟对应一个像素
--4.通常我们说的像素，比如1080P代表了1920*1080是指视频的有效显示区域，实际的视频还包含不能显示的区域，比如行同步，场同步时间
--5.通常我们说的行视频信号，也称之为视频的水平像素信号；场视频信号，也称之为视频的垂直像素信号；
*********************************************************************/

`timescale 1ns / 1ns //仿真时间刻度/精度

module uivtc#
(
parameter H_ActiveSize  =   1980,               //视频时间参数,行视频信号，一行有效(需要显示的部分)像素所占的时钟数，一个时钟对应一个有效像素
parameter H_FrameSize   =   1920+88+44+148,     //视频时间参数,行视频信号，一行视频信号总计占用的时钟数
parameter H_SyncStart   =   1920+88,            //视频时间参数,行同步开始，即多少时钟数后开始产生行同步信号 
parameter H_SyncEnd     =   1920+88+44,         //视频时间参数,行同步结束，即多少时钟数后停止产生行同步信号，之后就是行有效数据部分

parameter V_ActiveSize  =   1080,               //视频时间参数,场视频信号，一帧图像所占用的有效(需要显示的部分)行数量，通常说的视频分辨率即H_ActiveSize*V_ActiveSize
parameter V_FrameSize   =   1080+4+5+36,        //视频时间参数,场视频信号，一帧视频信号总计占用的行数量
parameter V_SyncStart   =   1080+4,             //视频时间参数,场同步开始，即多少行数后开始产生场同步信号 
parameter V_SyncEnd     =   1080+4+5            //视频时间参数,场同步结束，即多少场数后停止产生场同步信号，之后就是场有效数据部分
)
(
input           I_vtc_rstn,     //系统复位
input			I_vtc_clk,      //系统时钟
output			O_vtc_vs,       //场同步输出
output          O_vtc_hs,       //行同步输出
output          O_vtc_de_valid, //视频数据有效	
output          O_vtc_user,     //满足stream时序产生 user 信号,用于帧同步
output          O_vtc_last      //满足stream时序产生 later 信号,用于每行结束
);




reg [11:0] hcnt = 12'd0;    //视频水平方向，列计数器，寄存器
reg [11:0] vcnt = 12'd0;    //视频垂直方向，行计数器，寄存器   
reg [2 :0] rst_cnt = 3'd0;  //复位计数器，寄存器
wire rst_sync = rst_cnt[2]; //同步复位

always @(posedge I_vtc_clk or negedge I_vtc_rstn)begin //通过计数器产生同步复位
    if(I_vtc_rstn == 1'b0)
        rst_cnt <= 3'd0;
    else if(rst_cnt[2] == 1'b0)
        rst_cnt <= rst_cnt + 1'b1;
end    


//视频水平方向，列计数器
always @(posedge I_vtc_clk)begin
    if(rst_sync == 1'b0) //复位
        hcnt <= 12'd0;
    else if(hcnt < (H_FrameSize - 1'b1))//计数范围从0 ~ H_FrameSize-1
        hcnt <= hcnt + 1'b1;
    else 
        hcnt <= 12'd0;
end         

//视频垂直方向，行计数器，用于计数已经完成的行视频信号
always @(posedge I_vtc_clk)begin
    if(rst_sync == 1'b0)
        vcnt <= 12'd0;
    else if(hcnt == (H_ActiveSize  - 1'b1)) begin//视频水平方向，是否一行结束
           vcnt <= (vcnt == (V_FrameSize - 1'b1)) ? 12'd0 : vcnt + 1'b1;//视频垂直方向，行计数器加1，计数范围0~V_FrameSize - 1
    end
end 

wire hs_valid  =  hcnt < H_ActiveSize; //行信号有效像素部分
wire vs_valid  =  vcnt < V_ActiveSize; //场信号有效像素部分
wire vtc_hs    =  (hcnt >= H_SyncStart && hcnt < H_SyncEnd);//产生hs，行同步信号
wire vtc_vs	   =  (vcnt > V_SyncStart && vcnt <= V_SyncEnd);//产生vs，场同步信号      
wire vtc_de    =  hs_valid && vs_valid;//只有当视频水平方向，列有效和视频垂直方向，行同时有效，视频数据部分才是有效

//**********************  video stream video rgb  ***************************
//如果是输入RGB时序，那么转为stream时序
reg   vtc_vs_r1  ;
reg   vtc_hs_r1  ;
reg   vtc_de_r1  ;
reg   vtc_user_r1 ,vtc_user_r2;
reg   vtc_valid_r1,vtc_valid_r2;
reg   vtc_last_r2;
reg   vs_start;
 
always @(posedge I_vtc_clk )begin
    if(rst_sync == 1'b0) //复位
        vs_start <= 1'b0;
    else if(vtc_user_r1)//清除VS帧同步
        vs_start <= 1'b0;
    else if(vtc_vs && vtc_vs_r1==1'b0)//当vtc_vs发生上升沿跳变代表一帧开始
        vs_start <= 1'b1;
end  
      
always @(posedge I_vtc_clk  )begin
    vtc_vs_r1    <= vtc_vs;
    vtc_hs_r1    <= vtc_hs;
    vtc_user_r1  <= ~vtc_user_r1 & vs_start & vtc_de;//vtc_user延迟1拍
    vtc_last_r2  <= ~vtc_de & vtc_valid_r1; //产生stream video last 延迟于数据输入2拍
    vtc_valid_r1 <= vtc_de;//vtc_valid延迟1拍
    vtc_valid_r2 <= vtc_valid_r1;//vtc_valid对输入信号延迟2拍，以和vtc_last_r2信号配套同步
    vtc_user_r2  <= vtc_user_r1; //vtc_user 对输入信号延迟2拍，以和vtc_last_r2信号配套同步    
end    

assign O_vtc_vs       =  vtc_vs_r1;
assign O_vtc_hs       =  vtc_hs_r1;
assign O_vtc_de_valid =  vtc_valid_r2;
assign O_vtc_user     =  vtc_user_r2;
assign O_vtc_last     =  vtc_last_r2;


endmodule


