/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2023/03/23
*Module Name:hdmi_tx
*File Name:hdmi_tx.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.1
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/
/********************************************************************
本IP由上海安路科技提供，米联客根据自己使用习惯接口部分增加了RGB输入接口方式，
核心功能描述如下：
HDMI Transmitter工作需要两个时钟，像素时钟pixel_clk和串行发送时钟serial_clk。两个时钟都是通过PLL生成，其中serial_clk的频率是pixel_clk频率的五倍。
HDMI Transmitter的三个接口EDID_Read_interface、Video_interface和Audio_interface都是工作在pixel_clk时钟域下，因此用户逻辑需要使用pixel_clk来生成音视频数据。
HDMI Transmitter的pixel_clk频率和serial_clk频率需要根据显示分辨率进行计算。以1080p60的分辨率为例，有效分辨率为1920x1080，在计算频率的时候需要加上消隐区，
图像总的长宽为2200x1125，每秒60帧，因此像素时钟的频率为：
F_pixel=Htotal×Vtotal×FrameRate
F_pixel=2200×1125×60=148500000Hz=148.5MHz
串行发送时钟serial_clk频率为像素时钟频率的五倍，因此串行发送时钟频率为：
F_serial=5×F_pixel=5×148.5MHz=742.5MHz

1-最高支持1080p60显示分辨率。
2-支持两路音频输入。
3-支持RGB444和YUV444。
4-支持内部视频测试源。
5-支持EDID读取。
*********************************************************************/
`timescale 1ns / 1ns //仿真时间刻度/精度


module hdmi_tx#(
    parameter H_ActiveSize  =   1980, //视频时间参数,行视频信号，一行有效(需要显示的部分)像素所占的时钟数，一个时钟对应一个有效像素
    parameter H_SyncStart   =   1920+88, //视频时间参数,行同步开始，即多少时钟数后开始产生行同步信号 
    parameter H_SyncEnd     =   1920+88+44, //视频时间参数,行同步结束，即多少时钟数后停止产生行同步信号，之后就是行有效数据部分
    parameter H_FrameSize   =   1920+88+44+148,  //视频时间参数,行视频信号，一行视频信号总计占用的时钟数

    parameter V_ActiveSize  =   1080,  //视频时间参数,场视频信号，一帧图像所占用的有效(需要显示的部分)行数量，通常说的视频分辨率即H_ActiveSize*V_ActiveSize
    parameter V_SyncStart   =   1080+4, //视频时间参数,场同步开始，即多少行数后开始产生场同步信号 
    parameter V_SyncEnd     =   1080+4+5,//视频时间参数,场同步结束，多少行后停止产生长同步信号
    parameter V_FrameSize   =   1080+4+5+36,  //视频时间参数,场视频信号，一帧视频信号总计占用的行数量      
    
    parameter VIDEO_TPG         = "Enable",//"Enable”:使能测试视频源，外部视频输入无效;"Disable”:禁用测试视频源
    parameter VIDEO_FORMAT      = "RGB444",//“RGB444”:外部输入视频格式为RGB;“YUV444”:外部输入视频格式为YUV
    parameter VIDEO_VIC         = 16,//VIDEO_VIC参数用于设定HDMI辅助视频信息包中的VIC参数,具体看APUG058

    parameter AUDIO_CTS         = 148500,//音频时钟参数“CTS”
    parameter AUDIO_N           = 6144,  //音频时钟参数“N”
    parameter AUDIO_SAMPLE_RATE = "48K", //音频采样率

    parameter IIC_SCL_DIV       = 125   //EDID IIC时钟分频系数
)(
    
    input wire       I_pixel_clk, //像素时钟
    input wire       I_serial_clk,//串行发送时钟
    input wire       I_rst, //异步复位信号，高电平有效

    input wire       I_edid_read_trig,//EDID读触发信号
    output wire      O_edid_read_valid,//EDID读有效信号
    output wire[7:0] O_edid_read_data,//EDID读数据
    
///**********************  video rgb input  *****************************  
    input wire       I_video_rgb_enable,  //是否使能RGB输入接口，设置1使能，否则采用stream video时序接口
    input wire       I_video_in_de, //RGB 输入de有效
    input wire       I_video_in_vs, //RGB 输入VS 帧同步
///**********************  video stream input  ***************************
    input wire       I_video_in_user,  //视频输入帧起始信号
    input wire       I_video_in_valid, //视频输入有效信号
    input wire       I_video_in_last,  //视频输入行结束信号
    output wire      O_video_in_ready, //视频输入ready信号
    input wire[23:0] I_video_in_data,  //视频输入数据
///*********************  audio stream input  ***************************
    input wire       I_audio_valid,     //音频输入有效信号
    input wire[23:0] I_audio_left_data, //音频左声道数据
    input wire[23:0] I_audio_right_data,//音频左声道数据

    output wire      O_edid_iic_scl,    //EDID IIC时钟信号
    inout wire       IO_edid_iic_sda,   //EDID IIC数据信号

    output           O_hdmi_clk_p, //HDMI输出时钟P端
    output    [2:0]  O_hdmi_tx_p,  //HDMI输出数据P端

    output wire      O_tmds_ch0_p, //HDMI数据通道0
    output wire      O_tmds_ch1_p, //HDMI数据通道1
    output wire      O_tmds_ch2_p, //HDMI数据通道2
    output wire      O_tmds_clk_p  //HDMI时钟通道
);

//重新计算视频信号参数,以符合安路IP参数
    localparam HTOTAL            = H_FrameSize;  //一行总长度，包括行消隐和行有效，单位为时钟个数
    localparam HSA               = H_SyncEnd   - H_SyncStart;//行同步脉冲宽度，单位为时钟个数
    localparam HFP               = H_SyncStart - H_ActiveSize;//行显示前沿，单位为时钟个数
    localparam HBP               = H_FrameSize - H_SyncEnd;//行显示后沿，单位为时钟个数
    localparam HACTIVE           = H_ActiveSize;//一行有效显示长度，单位为时钟个数
    
    localparam VTOTAL            = V_FrameSize;//总列数，包括场消隐和场有效部分，单位为图像行数
    localparam VSA               = V_SyncEnd - V_SyncStart;//场同步脉冲宽度，单位为图像行数
    localparam VFP               = V_SyncStart - V_ActiveSize;//场显示前沿，单位为图像行数
    localparam VBP               = V_FrameSize - V_SyncEnd;//场显示后沿，单位为图像行数
    localparam VACTIVE           = V_ActiveSize;//有效列数，单位为图像行数

//**********************  video stream input  ***************************
//如果是输入RGB时序，那么转为stream时序，否则仅对信号打一个节拍
    reg       I_video_in_de_r1;
    reg       I_video_in_vs_r1;
    reg       I_video_in_user_r1,I_video_in_user_r2;
    reg       I_video_in_valid_r1,I_video_in_valid_r2;
    reg       I_video_in_last_r2;
    reg[23:0] I_video_in_data_r1,I_video_in_data_r2;
    reg       O_video_in_ready_r;
    reg       vs_start;
  
    always @(posedge I_pixel_clk)begin
    	I_video_in_de_r1 <= I_video_in_de;
    	I_video_in_vs_r1 <= I_video_in_vs;
    end
      
    always @(posedge I_pixel_clk or posedge I_rst )begin
    	if(I_rst)begin
        	I_video_in_last_r2  <= 1'b0;
            I_video_in_valid_r1 <= 1'b0;
            I_video_in_data_r1  <= 24'd0;
            I_video_in_user_r1  <= 1'b0;
            I_video_in_valid_r2 <= 1'b0;
            I_video_in_data_r2  <= 24'd0;
            I_video_in_user_r2  <= 1'b0;
        end    
    	else if(I_video_rgb_enable == 1'b1)begin
        	I_video_in_last_r2  <= ~I_video_in_de & I_video_in_de_r1; //产生stream video last 延迟于数据输入2拍
            I_video_in_valid_r1 <= I_video_in_de;//I_video_in_valid延迟1拍
            I_video_in_data_r1  <= I_video_in_data;//I_video_in_data延迟1拍
            I_video_in_user_r1  <= ~I_video_in_user_r1 & vs_start & I_video_in_de;//I_video_in_user延迟1拍
            
            I_video_in_valid_r2 <= I_video_in_valid_r1;//I_video_in_valid对输入信号延迟2拍，以和I_video_in_last_r2信号配套同步
            I_video_in_data_r2  <= I_video_in_data_r1; //I_video_in_data 对输入信号延迟2拍，以和I_video_in_last_r2信号配套同步
            I_video_in_user_r2  <= I_video_in_user_r1; //I_video_in_user 对输入信号延迟2拍，以和I_video_in_last_r2信号配套同步 
        end     
        else begin
        	I_video_in_last_r2  <= I_video_in_last; //I_video_in_last对输入信号直接寄存1次
            I_video_in_valid_r2 <= I_video_in_valid;//I_video_in_valid对输入信号直接寄存1次
            I_video_in_data_r2  <= I_video_in_data;//I_video_in_data对输入信号直接寄存1次
            I_video_in_user_r2  <= I_video_in_user;//I_video_in_user对输入信号直接寄存1次      
        end 
    end
    
    always @(posedge I_pixel_clk or posedge I_rst )begin
    	if(I_rst)
        	vs_start <= 1'b0;
    	else if(I_video_in_user_r1)//清除VS帧同步
        	vs_start <= 1'b0;
        else if(I_video_in_vs && I_video_in_vs_r1==1'b0)//当I_video_in_vs发生上升沿跳变代表一帧开始
            vs_start <= 1'b1;
    end       	
            
       
    wire[9:0]   S_ch0_tmds_code_data;               
    wire[9:0]   S_ch1_tmds_code_data;               
    wire[9:0]   S_ch2_tmds_code_data;               
    wire[9:0]   S_clk_tmds_code_data;

//音频部分
    hdmi_edid_wrapper #(
        .IIC_SCL_DIV ( IIC_SCL_DIV )
    ) u_hdmi_edid_wrapper(
        .I_clk             ( I_pixel_clk       ),
        .I_rst             ( I_rst             ),
 
        .I_edid_read_trig  ( I_edid_read_trig  ),
        .O_edid_read_valid ( O_edid_read_valid ),
        .O_edid_read_data  ( O_edid_read_data  ),
 
        .O_iic_scl         ( O_edid_iic_scl    ),
        .IO_iic_sda        ( IO_edid_iic_sda   )
    );

//HDMI IP
    hdmi_tx_controller_wrapper #(
        .HTOTAL               ( HTOTAL            ),
        .HSA                  ( HSA               ),
        .HFP                  ( HFP               ),
        .HBP                  ( HBP               ),
        .HACTIVE              ( HACTIVE           ),
        .VTOTAL               ( VTOTAL            ),
        .VSA                  ( VSA               ),
        .VFP                  ( VFP               ),
        .VBP                  ( VBP               ),
        .VACTIVE              ( VACTIVE           ),

        .VIDEO_TPG            ( VIDEO_TPG         ),
        .VIDEO_FORMAT         ( VIDEO_FORMAT      ),
        .VIDEO_VIC            ( VIDEO_VIC         ),
        
        .AUDIO_CTS            ( AUDIO_CTS         ),
        .AUDIO_N              ( AUDIO_N           ),
        .AUDIO_SAMPLE_RATE    ( AUDIO_SAMPLE_RATE )
    )u_hdmi_tx_controller_wrapper(
        .I_pixel_clk          ( I_pixel_clk          ),
        .I_rst                ( I_rst                ),

        .I_video_in_user      ( I_video_in_user_r2   ),
        .I_video_in_valid     ( I_video_in_valid_r2  ),
        .I_video_in_last      ( I_video_in_last_r2   ),
        .I_video_in_data      ( I_video_in_data_r2   ),
        .O_video_in_ready     ( O_video_in_ready     ),

        .I_audio_valid        ( I_audio_valid        ),
        .I_audio_left_data    ( I_audio_left_data    ),
        .I_audio_right_data   ( I_audio_right_data   ),

        .O_ch0_tmds_code_data ( S_ch0_tmds_code_data ),
        .O_ch1_tmds_code_data ( S_ch1_tmds_code_data ),
        .O_ch2_tmds_code_data ( S_ch2_tmds_code_data ),
        .O_clk_tmds_code_data ( S_clk_tmds_code_data )
    );

    
    hdmi_phy_wrapper u_hdmi2phy_wrapper(
        .I_pixel_clk        ( I_pixel_clk          ),
        .I_serial_clk       ( I_serial_clk         ),
        .I_rst              ( I_rst                ),

        .I_tmds_channel_0   ( S_ch0_tmds_code_data ),
        .I_tmds_channel_1   ( S_ch1_tmds_code_data ),
        .I_tmds_channel_2   ( S_ch2_tmds_code_data ),
        .I_tmds_channel_clk ( S_clk_tmds_code_data ),

        .O_tmds_ch0_p       ( O_hdmi_tx_p[0]       ),
        .O_tmds_ch1_p       ( O_hdmi_tx_p[1]       ),
        .O_tmds_ch2_p       ( O_hdmi_tx_p[2]       ),
        .O_tmds_clk_p       ( O_hdmi_clk_p         )
    );



endmodule