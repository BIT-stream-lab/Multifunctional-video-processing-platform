/*
 * @Author: bit_stream 
 * @Date: 2024-12-12 18:40:53 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-12 19:38:34
 */


`timescale 1ns / 1ns //仿真时间刻度/精度

module uivtc_video_move#
(
parameter H_ActiveSize  =   1920,               //视频时间参数,行视频信号，一行有效(需要显示的部分)像素所占的时钟数，一个时钟对应一个有效像素
parameter H_FrameSize   =   1920+88+44+148,     //视频时间参数,行视频信号，一行视频信号总计占用的时钟数
parameter H_SyncStart   =   1920+88,            //视频时间参数,行同步开始，即多少时钟数后开始产生行同步信号 
parameter H_SyncEnd     =   1920+88+44,         //视频时间参数,行同步结束，即多少时钟数后停止产生行同步信号，之后就是行有效数据部分

parameter V_ActiveSize  =   1080,               //视频时间参数,场视频信号，一帧图像所占用的有效(需要显示的部分)行数量，通常说的视频分辨率即H_ActiveSize*V_ActiveSize
parameter V_FrameSize   =   1080+4+5+36,        //视频时间参数,场视频信号，一帧视频信号总计占用的行数量
parameter V_SyncStart   =   1080+4,             //视频时间参数,场同步开始，即多少行数后开始产生场同步信号 
parameter V_SyncEnd     =   1080+4+5,            //视频时间参数,场同步结束，即多少场数后停止产生场同步信号，之后就是场有效数据部分

parameter H2_ActiveSize =   640, //1280*720缩放后的视频
parameter V2_ActiveSize =   360,



parameter VTC0_X        =   0       ,
parameter VTC0_Y        =   0       ,
parameter VTC1_X        =   640     ,    
parameter VTC1_Y        =   0       ,
parameter VTC2_X        =   0     ,
parameter VTC2_Y        =   360     ,
parameter VTC3_X        =   640     ,
parameter VTC3_Y        =   360     

)
(
input           I_vtc_rstn,//系统复位
input			I_vtc_clk, //系统时钟
input           I_video_move_en,
output	reg		O_vtc_vs,  //场同步输出
output  reg     O_vtc_hs,  //行同步输出
output  reg     O_vtc_data_valid,   //视频数据有效
output  reg [31:0]O_vtc_data,    

output  reg     O_vtc0_de,
input   wire   [31:0] I_rd_ddr_data_0,
output  reg     O_vtc1_de,
input   wire   [31:0] I_rd_ddr_data_1,
output  reg     O_vtc2_de,
input   wire   [31:0] I_rd_ddr_data_2,
output  reg     O_vtc3_de,
input   wire   [31:0] I_rd_ddr_data_3
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
wire vtc_vs	 =  (vcnt > V_SyncStart && vcnt <= V_SyncEnd);//产生vs，场同步信号      
wire vtc_de    =  hs_valid && vs_valid;//只有当视频水平方向，列有效和视频垂直方向，行同时有效，视频数据部分才是有效



reg     [11:0]  video_0_block_x = VTC0_X    ;       //Video 0左上角横坐标
reg     [11:0]  video_0_block_y = VTC0_Y    ;       //Video 0左上角纵坐标
reg     [11:0]  video_1_block_x = VTC1_X    ;       //Video 1左上角横坐标
reg     [11:0]  video_1_block_y = VTC1_Y    ;       //Video 1左上角纵坐标
reg     [11:0]  video_2_block_x = VTC2_X    ;       //Video 2左上角横坐标
reg     [11:0]  video_2_block_y = VTC2_Y    ;       //Video 2左上角纵坐标
reg     [11:0]  video_3_block_x = VTC3_X    ;       //Video 2左上角横坐标
reg     [11:0]  video_3_block_y = VTC3_Y    ;       //Video 2左上角纵坐标




reg cnt_fs; //帧计数器

always@(posedge I_vtc_clk or negedge I_vtc_rstn) begin
    if (!I_vtc_rstn) begin
        cnt_fs <= 'd0;
    end else if (vtc_vs &(~O_vtc_vs)) begin
        cnt_fs <= cnt_fs + 1'b1;
    end else begin
        cnt_fs <= cnt_fs;
    end
end


reg   move_en ;  //视频框移动使能信号  

always @(posedge I_vtc_clk or negedge I_vtc_rstn ) begin
    if (!I_vtc_rstn) begin
        move_en <= 1'b0;
    end else if(cnt_fs&I_video_move_en&vtc_vs &(~O_vtc_vs)) begin
        move_en <= 1'b1;
    end else begin
        move_en <= 1'b0;
    end
end





reg             video_0_h_direct = 1'b1 ;   //视频框水平位移方向   1：右移    0：左移
reg             video_0_v_direct = 1'b1 ;   //视频框竖直位移方向   1：向下    0：向上  


//当移动到边界时，改变移动方向
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_0_h_direct <= 1'b1;                       //初始水平向右移动
        video_0_v_direct <= 1'b1;                       //初始竖直向下移动
    end 
    else begin
        if (video_0_block_x == 0 + 1'b1) begin     //到达左边界，水平向右
            video_0_h_direct <= 1'b1;
        end 
        else begin                              //到达右边界，水平向左  
            if(video_0_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
                video_0_h_direct <= 1'b0; 
            end
            else begin
                video_0_h_direct <= video_0_h_direct;
            end
        end
 
        if (video_0_block_y == 0 + 1'b1) begin     //到达上边界，竖直向下
            video_0_v_direct <= 1'b1;
        end 
        else begin                              //到达下边界，竖直向上
            if(video_0_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
                video_0_v_direct <= 1'b0;                           
            end
            else begin
                video_0_v_direct <= video_0_v_direct;
            end
        end 
    end
 end

reg             video_1_h_direct = 1'b0 ;   //视频框水平位移方向   1：右移    0：左移
reg             video_1_v_direct = 1'b1 ;   //视频框竖直位移方向   1：向下    0：向上  


//当移动到边界时，改变移动方向
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_1_h_direct <= 1'b0;                       //初始水平向左移动
        video_1_v_direct <= 1'b1;                       //初始竖直向下移动
    end 
    else begin
        if (video_1_block_x == 0 + 1'b1) begin     //到达左边界，水平向右
            video_1_h_direct <= 1'b1;
        end 
        else begin                              //到达右边界，水平向左  
            if(video_1_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
               video_1_h_direct <= 1'b0; 
            end
            else begin
                video_1_h_direct <= video_1_h_direct;
            end
        end
 
        if (video_1_block_y == 0 + 1'b1) begin     //到达上边界，竖直向下
            video_1_v_direct <= 1'b1;
        end 
        else begin                              //到达下边界，竖直向上
            if(video_1_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
               video_1_v_direct <= 1'b0;                           
            end
            else begin
                video_1_v_direct <= video_1_v_direct;
            end
        end 
    end
 end

reg             video_2_h_direct = 1'b1;   //视频框水平位移方向   1：右移    0：左移
reg             video_2_v_direct = 1'b0;   //视频框竖直位移方向   1：向下    0：向上  


//当移动到边界时，改变移动方向
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_2_h_direct <= 1'b1;                       //初始水平向右移动
        video_2_v_direct <= 1'b0;                       //初始竖直向上移动
    end 
    else begin
        if (video_2_block_x == 0 + 1'b1) begin     //到达左边界，水平向右
            video_2_h_direct <= 1'b1;
        end 
        else begin                              //到达右边界，水平向左  
            if(video_2_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
               video_2_h_direct <= 1'b0; 
            end
            else begin
                video_2_h_direct <= video_2_h_direct;
            end
        end
 
        if (video_2_block_y == 0 + 1'b1) begin     //到达上边界，竖直向下
            video_2_v_direct <= 1'b1;
        end 
        else begin                              //到达下边界，竖直向上
            if(video_2_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
               video_2_v_direct <= 1'b0;                           
            end
            else begin
                video_2_v_direct <= video_2_v_direct;
            end
        end 
    end
 end

reg             video_3_h_direct = 1'b0 ;   //视频框水平位移方向   1：右移    0：左移
reg             video_3_v_direct = 1'b0 ;   //视频框竖直位移方向   1：向下    0：向上  


//当移动到边界时，改变移动方向
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_3_h_direct <= 1'b0;                       //初始水平向右移动
        video_3_v_direct <= 1'b0;                       //初始竖直向上移动
    end 
    else begin
        if (video_3_block_x == 0 + 1'b1) begin     //到达左边界，水平向右
            video_3_h_direct <= 1'b1;
        end 
        else begin                              //到达右边界，水平向左  
            if(video_3_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
               video_3_h_direct <= 1'b0; 
            end
            else begin
                video_3_h_direct <= video_3_h_direct;
            end
        end
 
        if (video_3_block_y == 0 + 1'b1) begin     //到达上边界，竖直向下
            video_3_v_direct <= 1'b1;
        end 
        else begin                              //到达下边界，竖直向上
            if(video_3_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
               video_3_v_direct <= 1'b0;                           
            end
            else begin
                video_3_v_direct <= video_3_v_direct;
            end
        end 
    end
 end





//根据视频框移动方向，改变横纵坐标
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_0_block_x <= VTC0_X ;               //初始位置横坐标
        video_0_block_y <= VTC0_Y ;               //初始位置纵坐标
    end 
    else if(move_en == 1'b1)begin
        if (video_0_h_direct == 1'b1) begin
            video_0_block_x <= video_0_block_x + 1'b1;          //向右移动
        end 
        else begin
            video_0_block_x <= video_0_block_x -1'b1;           //向左移动
        end
 
        if (video_0_v_direct == 1'b1) begin
            video_0_block_y <= video_0_block_y + 1'b1;          //向下移动    
        end 
        else begin
            video_0_block_y <= video_0_block_y -1'b1;           //向上移动
        end
    end
    else begin
        video_0_block_x <= video_0_block_x;
        video_0_block_y <= video_0_block_y;
    end
end

//根据视频框移动方向，改变横纵坐标
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_1_block_x <= VTC1_X ;               //初始位置横坐标
        video_1_block_y <= VTC1_Y ;               //初始位置纵坐标
    end 
    else if(move_en == 1'b1)begin
        if (video_1_h_direct == 1'b1) begin
            video_1_block_x <= video_1_block_x + 1'b1;          //向右移动
        end 
        else begin
            video_1_block_x <= video_1_block_x -1'b1;           //向左移动
        end
 
        if (video_1_v_direct == 1'b1) begin
            video_1_block_y <= video_1_block_y + 1'b1;          //向下移动    
        end 
        else begin
            video_1_block_y <= video_1_block_y -1'b1;           //向上移动
        end
    end
    else begin
        video_1_block_x <= video_1_block_x;
        video_1_block_y <= video_1_block_y;
    end
end

//根据视频框移动方向，改变横纵坐标
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_2_block_x <= VTC2_X ;               //初始位置横坐标
        video_2_block_y <= VTC2_Y ;               //初始位置纵坐标
    end 
    else if(move_en == 1'b1)begin
        if (video_2_h_direct == 1'b1) begin
            video_2_block_x <= video_2_block_x + 1'b1;          //向右移动
        end 
        else begin
            video_2_block_x <= video_2_block_x -1'b1;           //向左移动
        end
 
        if (video_2_v_direct == 1'b1) begin
            video_2_block_y <= video_2_block_y + 1'b1;          //向下移动    
        end 
        else begin
            video_2_block_y <= video_2_block_y -1'b1;           //向上移动
        end
    end
    else begin
        video_2_block_x <= video_2_block_x;
        video_2_block_y <= video_2_block_y;
    end
end

//根据视频框移动方向，改变横纵坐标
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_3_block_x <= VTC3_X ;               //初始位置横坐标
        video_3_block_y <= VTC3_Y ;               //初始位置纵坐标
    end 
    else if(move_en == 1'b1)begin
        if (video_3_h_direct == 1'b1) begin
            video_3_block_x <= video_3_block_x + 1'b1;          //向右移动
        end 
        else begin
            video_3_block_x <= video_3_block_x -1'b1;           //向左移动
        end
 
        if (video_3_v_direct == 1'b1) begin
            video_3_block_y <= video_3_block_y + 1'b1;          //向下移动    
        end 
        else begin
            video_3_block_y <= video_3_block_y -1'b1;           //向上移动
        end
    end
    else begin
        video_3_block_x <= video_3_block_x;
        video_3_block_y <= video_3_block_y;
    end
end






wire hs0_valid  =  (hcnt>=video_0_block_x)&& (hcnt<(video_0_block_x+H2_ActiveSize));
wire vs0_valid  =  (vcnt>=video_0_block_y)&& (vcnt<(video_0_block_y+V2_ActiveSize));
wire hs1_valid  =  (hcnt>=video_1_block_x)&& (hcnt<(video_1_block_x+H2_ActiveSize));
wire vs1_valid  =  (vcnt>=video_1_block_y)&& (vcnt<(video_1_block_y+V2_ActiveSize));
wire hs2_valid  =  (hcnt>=video_2_block_x)&& (hcnt<(video_2_block_x+H2_ActiveSize));
wire vs2_valid  =  (vcnt>=video_2_block_y)&& (vcnt<(video_2_block_y+V2_ActiveSize));
wire hs3_valid  =  (hcnt>=video_3_block_x)&& (hcnt<(video_3_block_x+H2_ActiveSize));
wire vs3_valid  =  (vcnt>=video_3_block_y)&& (vcnt<(video_3_block_y+V2_ActiveSize));

wire vtc0_de    =  hs0_valid && vs0_valid;
wire vtc1_de    =  hs1_valid && vs1_valid;
wire vtc2_de    =  hs2_valid && vs2_valid;
wire vtc3_de    =  hs3_valid && vs3_valid;


reg O_vtc_de;


//完一次寄存打拍输出，有利于改善时序，尤其对于高分辨率，高速的信号，打拍可以改善内部时序，以运行于更高速度
always @(posedge I_vtc_clk)begin
	if(rst_sync == 1'b0)begin
		O_vtc_vs <= 1'b0;
		O_vtc_hs <= 1'b0;
		O_vtc_de <= 1'b0;
		O_vtc0_de <= 1'b0;
		O_vtc1_de <= 1'b0;
		O_vtc2_de <= 1'b0;
		O_vtc3_de <= 1'b0;
	end
    else begin
        O_vtc_vs <= vtc_vs; //场同步信号打拍输出
		O_vtc_hs <= vtc_hs; //行同步信号打拍输出
        O_vtc_de <= vtc_de;	//视频有效信号打拍输出
        O_vtc0_de <= vtc0_de;	
		O_vtc1_de <= vtc1_de;	
		O_vtc2_de <= vtc2_de;	
		O_vtc3_de <= vtc3_de;	
          
    end
end


always @(posedge I_vtc_clk)begin
    if (rst_sync == 1'b0) begin
        O_vtc_data<=32'd0;
    end else if (O_vtc3_de) begin
        O_vtc_data<=I_rd_ddr_data_3;
    end else if (O_vtc2_de) begin
        O_vtc_data<=I_rd_ddr_data_2;
    end else if (O_vtc1_de) begin
        O_vtc_data<=I_rd_ddr_data_1;
    end else if (O_vtc0_de) begin
        O_vtc_data<=I_rd_ddr_data_0;
    end  else begin
        O_vtc_data<=32'd0;
    end
end

always @(posedge I_vtc_clk)begin
    if (rst_sync==1'b0) begin
        O_vtc_data_valid<=1'b0;
    end else begin
        O_vtc_data_valid<=O_vtc_de;
    end
end


endmodule


