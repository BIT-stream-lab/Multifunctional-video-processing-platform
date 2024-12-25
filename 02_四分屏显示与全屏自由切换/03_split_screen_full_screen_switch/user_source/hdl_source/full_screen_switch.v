/*
 * @Author: bit_stream 
 * @Date: 2024-12-22 16:47:27 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-24 16:47:40
 */


module full_screen_switch#(
    parameter AXI_DATA_WIDTH = 256,
    parameter AXI_ADDR_WIDTH = 29 
)
(

	//ddr ip signal
    input   wire            O_axi_clk   ,
    input   wire            pll_locked  ,

    //uart ctrl signal
    input  wire    [3:0]    I_screen_switch,   //该信号用于选择哪个屏幕进行显示，跨时钟域信号（多bit，慢时钟到快时钟）采用独热码与状态机处理
	input  wire             I_full_rstn,       //该模块的复位信号，在分屏显示时，对该模块进行复位（单bit，慢时钟到快时钟）采用打两拍进行处理
    //pll signal
	
	input	wire        clk_75m,
	input	wire        S_pll_lock,//pll ok

    //hdmi in siganl
	input	wire 			I0_clk		,
	input	wire 			I0_vtc_vs		,
	input	wire 			I0_vtc_data_valid,
	input	wire [31:0]		I0_vtc_data	,	

	input	wire 			I1_clk		,
	input	wire 			I1_vtc_vs		,
	input	wire 			I1_vtc_data_valid,
	input	wire [31:0]		I1_vtc_data	,	

	input	wire 			I2_clk		,
	input	wire 			I2_vtc_vs		,
	input	wire 			I2_vtc_data_valid,
	input	wire [31:0]		I2_vtc_data	,	

	input	wire 			I3_clk		,
	input	wire 			I3_vtc_vs		,
	input	wire 			I3_vtc_data_valid,
	input	wire [31:0]		I3_vtc_data	,	



	 //fdma signal
	output	wire [AXI_ADDR_WIDTH-1:  0]       fdma_waddr_full , 
	output	wire                              fdma_wareq_full , 
	output	wire [15: 0]                      fdma_wsize_full , 
	input	wire                              fdma_wbusy_full,
	output	wire [AXI_DATA_WIDTH-1 : 0]       fdma_wdata_full , 
	input	wire                             fdma_wvalid_full,

	
	output	wire [AXI_ADDR_WIDTH-1:  0]        fdma_raddr_full,  
    output	wire                               fdma_rareq_full,  
    output	wire [15: 0]                       fdma_rsize_full,                                
    input	wire                               fdma_rbusy_full, 			
    input	wire [AXI_DATA_WIDTH-1 : 0]        fdma_rdata_full, 
    input	wire                              fdma_rvalid_full, 

    //hdmi out siganl
	output	wire 			O_vtc_vs		,
	output	reg 			O_vtc_de_valid,
	output	reg [31:0]		O_vtc_data		
);


//---------跨时钟域信号处理-----------

//发送端的信号I_screen_switch对应的功能解释
//I_screen_switch=4'b0001,video 0全屏
//I_screen_switch=4'b0010,video 1全屏
//I_screen_switch=4'b0100,video 2全屏
//I_screen_switch=4'b1000,video 3全屏

//先对输入至接收端信号在接收时钟为ddr_ip_clk情况下打两拍处理，此情况可能会导致同步失序
reg [3:0]  screen_switch_dly1_ddr_clk;
reg [3:0]  screen_switch_dly2_ddr_clk;

always @(posedge O_axi_clk or negedge pll_locked) begin
	if (~pll_locked) begin
		screen_switch_dly1_ddr_clk <= 'd0;
		screen_switch_dly2_ddr_clk <= 'd0;
	end else begin
		screen_switch_dly1_ddr_clk <= I_screen_switch;
		screen_switch_dly2_ddr_clk <= screen_switch_dly1_ddr_clk;
	end
end

//接收端状态
//这个状态的状态转移取决于独热码里“热”的那一位，即 1 的位置。
localparam VIDEO_0  = 3'd0;
localparam VIDEO_1  = 3'd1;
localparam VIDEO_2  = 3'd2;
localparam VIDEO_3  = 3'd3;

//接收端状态机，接收时钟域为ddr_clk
reg [2:0] state_ddr_clk;

always @(posedge O_axi_clk or negedge pll_locked) begin
	if (~pll_locked) begin
		state_ddr_clk <= VIDEO_0; //默认VIDEO_0全屏
	end else begin
		case (state_ddr_clk)
			VIDEO_0:begin
				if (screen_switch_dly2_ddr_clk[3] == 1'b1) begin
					state_ddr_clk <= VIDEO_3;
				end else if (screen_switch_dly2_ddr_clk[2] == 1'b1) begin
					state_ddr_clk <= VIDEO_2;
				end else if (screen_switch_dly2_ddr_clk[1] == 1'b1) begin
					state_ddr_clk <= VIDEO_1;
				end else begin
					state_ddr_clk <= VIDEO_0;
				end
			end 
			VIDEO_1:begin
				if (screen_switch_dly2_ddr_clk[3] == 1'b1) begin
					state_ddr_clk <= VIDEO_3;
				end else if (screen_switch_dly2_ddr_clk[2] == 1'b1) begin
					state_ddr_clk <= VIDEO_2;
				end else if (screen_switch_dly2_ddr_clk[0] == 1'b1) begin
					state_ddr_clk <= VIDEO_0;
				end else begin
					state_ddr_clk <= VIDEO_1;
				end
			end
			VIDEO_2:begin
				if (screen_switch_dly2_ddr_clk[3] == 1'b1) begin
					state_ddr_clk <= VIDEO_3;
				end else if (screen_switch_dly2_ddr_clk[1] == 1'b1) begin
					state_ddr_clk <= VIDEO_1;
				end else if (screen_switch_dly2_ddr_clk[0] == 1'b1) begin
					state_ddr_clk <= VIDEO_0;
				end else begin
					state_ddr_clk <= VIDEO_2;
				end
			end
			VIDEO_3:begin
				if (screen_switch_dly2_ddr_clk[2] == 1'b1) begin
					state_ddr_clk <= VIDEO_2;
				end else if (screen_switch_dly2_ddr_clk[1] == 1'b1) begin
					state_ddr_clk <= VIDEO_1;
				end else if (screen_switch_dly2_ddr_clk[0] == 1'b1) begin
					state_ddr_clk <= VIDEO_0;
				end else begin
					state_ddr_clk <= VIDEO_3;
				end
			end
			default: begin
				state_ddr_clk <= VIDEO_0;
			end
		endcase
	end
end


//-------------跨时钟域信号处理---------------
reg full_rstn_dly1;
reg full_rstn_dly2;

always@(posedge O_axi_clk)begin
	if (~pll_locked) begin
		full_rstn_dly1 <= 1'b0;
		full_rstn_dly2 <= 1'b0; 
	end else begin
		full_rstn_dly1  <= I_full_rstn;
		full_rstn_dly2  <= full_rstn_dly1;
	end
end

reg full_rstn;

//复位处理，什么时候复位？在没有进行写请求/读请求时进行复位
always @(posedge O_axi_clk) begin
	if (fdma_wareq_full == 1'b0 && fdma_rareq_full == 1'b0) begin
		full_rstn <= full_rstn_dly2;
	end
end

//-----由于在全屏显示时，只需要写入一路的视频数据，对不必写入DDR的数据进行合理复位，防止占用DDR的吞吐量---
reg video_0_rstn;
reg video_1_rstn;
reg video_2_rstn;
reg video_3_rstn;

always @(posedge O_axi_clk) begin
	if (fdma_wareq_full == 1'b0 && fdma_rareq_full == 1'b0) begin
		if (~full_rstn_dly2) begin
			video_0_rstn <= 1'b0;
			video_1_rstn <= 1'b0;
			video_2_rstn <= 1'b0;
			video_3_rstn <= 1'b0;
		end else begin
			case (state_ddr_clk)
				VIDEO_0:begin
					video_0_rstn <= 1'b1;
					video_1_rstn <= 1'b0;
					video_2_rstn <= 1'b0;
					video_3_rstn <= 1'b0;
				end 
				VIDEO_1:begin
					video_0_rstn <= 1'b0;
					video_1_rstn <= 1'b1;
					video_2_rstn <= 1'b0;
					video_3_rstn <= 1'b0;
				end 
				VIDEO_2:begin
					video_0_rstn <= 1'b0;
					video_1_rstn <= 1'b0;
					video_2_rstn <= 1'b1;
					video_3_rstn <= 1'b0;
				end 
				VIDEO_3:begin
					video_0_rstn <= 1'b0;
					video_1_rstn <= 1'b0;
					video_2_rstn <= 1'b0;
					video_3_rstn <= 1'b1;
				end 
				default: begin
					video_0_rstn <= 1'b0;
					video_1_rstn <= 1'b0;
					video_2_rstn <= 1'b0;
					video_3_rstn <= 1'b0;
				end
			endcase
		end
	end 
end



wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr_0;   //FDMA写通道地址
wire                             fdma_wareq_0;   //synthesis keep
wire [15: 0]                     fdma_wsize_0;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy_0;   //synthesis keep
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata_0;   //FDMA写数据
wire                            fdma_wvalid_0; //synthesis keep

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr_1;   //FDMA写通道地址
wire                             fdma_wareq_1;   //synthesis keep
wire [15: 0]                     fdma_wsize_1;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy_1;   //synthesis keep	
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata_1;   //FDMA写数据
wire                            fdma_wvalid_1;  //synthesis keep


wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr_2;   //FDMA写通道地址
wire                             fdma_wareq_2;  //synthesis keep
wire [15: 0]                     fdma_wsize_2;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy_2;   //synthesis keep	
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata_2;   //FDMA写数据
wire                            fdma_wvalid_2;  //synthesis keep

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr_3;   //FDMA写通道地址
wire                             fdma_wareq_3;  //synthesis keep
wire [15: 0]                     fdma_wsize_3;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy_3;   //synthesis keep	
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata_3;   //FDMA写数据
wire                            fdma_wvalid_3;  //synthesis keep





wire                            O_vtc0_de;
wire [31:0]                     I_rd_ddr_data_0;





wire [7:0] wbuf_sync_0,rbuf_sync_0;//用于切换帧缓存
wire [7:0] wbuf_sync_1,rbuf_sync_1;//用于切换帧缓存
wire [7:0] wbuf_sync_2,rbuf_sync_2;//用于切换帧缓存
wire [7:0] wbuf_sync_3,rbuf_sync_3;//用于切换帧缓存

//----对输入进来的数据打一拍

reg 		I0_vtc_vs_dly;
reg 		I0_vtc_data_valid_dly;
reg [31:0]	I0_vtc_data_dly;

always @(posedge I0_clk)begin
	I0_vtc_vs_dly 		  <= I0_vtc_vs;
	I0_vtc_data_valid_dly <= I0_vtc_data_valid;
	I0_vtc_data_dly       <= I0_vtc_data;
end

reg 		I1_vtc_vs_dly;
reg 		I1_vtc_data_valid_dly;
reg [31:0]	I1_vtc_data_dly;

always @(posedge I1_clk)begin
	I1_vtc_vs_dly 		  <= I1_vtc_vs;
	I1_vtc_data_valid_dly <= I1_vtc_data_valid;
	I1_vtc_data_dly       <= I1_vtc_data;
end

reg 		I2_vtc_vs_dly;
reg 		I2_vtc_data_valid_dly;
reg [31:0]	I2_vtc_data_dly;

always @(posedge I2_clk)begin
	I2_vtc_vs_dly 		  <= I2_vtc_vs;
	I2_vtc_data_valid_dly <= I2_vtc_data_valid;
	I2_vtc_data_dly       <= I2_vtc_data;
end

reg 		I3_vtc_vs_dly;
reg 		I3_vtc_data_valid_dly;
reg [31:0]	I3_vtc_data_dly;

always @(posedge I3_clk)begin
	I3_vtc_vs_dly 		  <= I3_vtc_vs;
	I3_vtc_data_valid_dly <= I3_vtc_data_valid;
	I3_vtc_data_dly       <= I3_vtc_data;
end


	
wire [15:0] 	O_I0_vtc_data_dly;

wr_width_convert u0_wr_width_convert(
	.I_wr_data       	( I0_vtc_data_dly        ),
	.O_wr_data       	( O_I0_vtc_data_dly       )
);


//--------第一路视频写入DDR-------------
uidbuf_only_w# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.W_BUFDEPTH(2048),//写FIFO 的实际深度为W_BUFDEPTH*2 
.W_DATAWIDTH(16),
.W_BASEADDR(1843200),   //占用的地址空间大小为1280*720*2=1,843,200，目前地址使用到3,686,400
.W_DSIZEBITS(25),
.W_XSIZE(1280), 
.W_XSTRIDE(1280),
.W_YSIZE(720),
.W_XDIV(1),
.W_BUFSIZE(3)

)
uidbuf_u0
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(video_0_rstn ),

.I_W_FS(I0_vtc_vs_dly),
.I_W_clk(I0_clk),
.I_W_wren(I0_vtc_data_valid_dly),
.I_W_data(O_I0_vtc_data_dly), 
.O_W_sync_cnt(wbuf_sync_0),
.I_W_buf(wbuf_sync_0),
.O_W_full(),
       
.O_fdma_waddr(  fdma_waddr_0)  ,
.O_fdma_wareq(  fdma_wareq_0)  ,
.O_fdma_wsize(  fdma_wsize_0)  ,                                     
.I_fdma_wbusy(  fdma_wbusy_0)  ,			
.O_fdma_wdata(  fdma_wdata_0)  ,
.I_fdma_wvalid(fdma_wvalid_0)  
 ); 



wire [15:0] 	O_I1_vtc_data_dly;

wr_width_convert u1_wr_width_convert(
	.I_wr_data       	( I1_vtc_data_dly        ),
	.O_wr_data       	( O_I1_vtc_data_dly       )
);


//--------第二路视频写DDR-------------
uidbuf_only_w# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.W_BUFDEPTH(2048),//写FIFO 的实际深度为W_BUFDEPTH*2 
.W_DATAWIDTH(16),
.W_BASEADDR(3686400),  //占用的地址空间大小为1280*720*2=1,843,200，目前地址使用到5,529,600
.W_DSIZEBITS(25),
.W_XSIZE(1280), 
.W_XSTRIDE(1280),
.W_YSIZE(720), 
.W_XDIV(1),
.W_BUFSIZE(3)
)
uidbuf_u1
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(video_1_rstn),

.I_W_FS(I1_vtc_vs_dly),
.I_W_clk(I1_clk),
.I_W_wren(I1_vtc_data_valid_dly),
.I_W_data(O_I1_vtc_data_dly), 
.O_W_sync_cnt(wbuf_sync_1),
.I_W_buf(wbuf_sync_1),
.O_W_full(),


.O_fdma_waddr(  fdma_waddr_1)  ,
.O_fdma_wareq(  fdma_wareq_1)  ,
.O_fdma_wsize(  fdma_wsize_1)  ,                                     
.I_fdma_wbusy(  fdma_wbusy_1)  ,			
.O_fdma_wdata(  fdma_wdata_1)  ,
.I_fdma_wvalid(fdma_wvalid_1)  
 ); 




wire [15:0] 	O_I2_vtc_data_dly;

wr_width_convert u2_wr_width_convert(
	.I_wr_data       	( I2_vtc_data_dly        ),
	.O_wr_data       	( O_I2_vtc_data_dly       )
);



//--------第三路视频写DDR-------------
uidbuf_only_w# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.W_BUFDEPTH(2048),//写FIFO 的实际深度为W_BUFDEPTH*2 
.W_DATAWIDTH(16),
.W_BASEADDR(5529600),   //占用的地址空间大小为1280*720*2=1,843,200，目前地址使用到7,372,800
.W_DSIZEBITS(25),
.W_XSIZE(1280), 
.W_XSTRIDE(1280),
.W_YSIZE(720), 
.W_XDIV(1),
.W_BUFSIZE(3)
)
uidbuf_u2
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(video_2_rstn),
.I_W_FS(I2_vtc_vs_dly),
.I_W_clk(I2_clk),
.I_W_wren(I2_vtc_data_valid_dly),
.I_W_data(O_I2_vtc_data_dly), 
.O_W_sync_cnt(wbuf_sync_2),
.I_W_buf(wbuf_sync_2),
.O_W_full(),

       
.O_fdma_waddr(  fdma_waddr_2)  ,
.O_fdma_wareq(  fdma_wareq_2)  ,
.O_fdma_wsize(  fdma_wsize_2)  ,                                     
.I_fdma_wbusy(  fdma_wbusy_2)  ,			
.O_fdma_wdata(  fdma_wdata_2)  ,
.I_fdma_wvalid(fdma_wvalid_2)  
 ); 






wire [15:0] 	O_I3_vtc_data_dly;

wr_width_convert u3_wr_width_convert(
	.I_wr_data       	( I3_vtc_data_dly        ),
	.O_wr_data       	( O_I3_vtc_data_dly        )
);




//--------第四路视频写DDR-------------

uidbuf_only_w# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.W_BUFDEPTH(2048),
.W_DATAWIDTH(16),
.W_BASEADDR(7372800),  //占用的地址空间大小为1280*720*2=1,843,200，目前地址使用到9,216,000
.W_DSIZEBITS(25),
.W_XSIZE(1280), 
.W_XSTRIDE(1280),
.W_YSIZE(720), 
.W_XDIV(1),
.W_BUFSIZE(3)

)
uidbuf_u3
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(video_3_rstn),
.I_W_FS(I3_vtc_vs_dly),
.I_W_clk(I3_clk),
.I_W_wren(I3_vtc_data_valid_dly),
.I_W_data(O_I3_vtc_data_dly), 
.O_W_sync_cnt(wbuf_sync_3),
.I_W_buf(wbuf_sync_3),
.O_W_full(),
       
.O_fdma_waddr(  fdma_waddr_3)  ,
.O_fdma_wareq(  fdma_wareq_3)  ,
.O_fdma_wsize(  fdma_wsize_3)  ,                                     
.I_fdma_wbusy(  fdma_wbusy_3)  ,			
.O_fdma_wdata(  fdma_wdata_3)  ,
.I_fdma_wvalid(fdma_wvalid_3)  
 ); 


wire vtc_de_valid;

wire [15:0]I_rd_data_0;
wire [31:0]vtc_data;

rd_width_convert u0_rd_width_convert(
	.O_rd_data       	( vtc_data        ),
	.I_rd_data       	( I_rd_data_0        )
);


uidbuf_r_baseaddr_switch# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.R_BUFDEPTH(2048), 
.R_DATAWIDTH(16),
.R_DSIZEBITS(25),
.R_XSIZE(1280),
.R_XSTRIDE(1280),
.R_YSIZE(720), 
.R_XDIV(1),
.R_BUFSIZE(3)
)
uidbuf_u4
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(full_rstn ),
.I_state_ddr_clk(state_ddr_clk ),

.I_R_FS(O_vtc_vs),
.I_R_clk(clk_75m),
.I_R_rden(vtc_de_valid),
.O_R_data(I_rd_data_0),
.O_R_sync_cnt(),
.I_R_buf(rbuf_sync_0),
.O_R_empty(),
       
.O_fdma_raddr(  fdma_raddr_full)  ,
.O_fdma_rareq(  fdma_rareq_full)  ,
.O_fdma_rsize(  fdma_rsize_full)  ,                                     
.I_fdma_rbusy(  fdma_rbusy_full)  ,			
.I_fdma_rdata(  fdma_rdata_full)	 ,
.I_fdma_rvalid(fdma_rvalid_full)
 ); 


//帧缓存信号选择
reg [7:0] wbuf_sync;

always @(posedge O_axi_clk or negedge pll_locked) begin
	if (~pll_locked) begin
		wbuf_sync <= wbuf_sync_0;
	end else begin
		case (state_ddr_clk)
			VIDEO_0:begin
				wbuf_sync <= wbuf_sync_0;
			end
			VIDEO_1:begin
				wbuf_sync <= wbuf_sync_1;
			end
			VIDEO_2:begin
				wbuf_sync <= wbuf_sync_2;
			end
			VIDEO_3:begin
				wbuf_sync <= wbuf_sync_3;
			end
			default: begin
				wbuf_sync <= wbuf_sync_0;
			end
		endcase
	end
end


//设置3帧缓存，读延迟写1帧
uisetvbuf#(
.BUF_DELAY(1),
.BUF_LENTH(3)
)
uisetvbuf_u0
(
.I_bufn(wbuf_sync),
.O_bufn(rbuf_sync_0)
);   








uidbufw_interconnect #(
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
)
 u_uidbufw_interconnect(
	.ui_clk        	( O_axi_clk         ),
	.ui_rstn       	( pll_locked),
	.fdma_waddr_1  	(  fdma_waddr_0   ),
	.fdma_wareq_1  	(  fdma_wareq_0   ),
	.fdma_wsize_1  	(  fdma_wsize_0   ),
	.fdma_wbusy_1  	(  fdma_wbusy_0   ),
	.fdma_wdata_1  	(  fdma_wdata_0   ),
	.fdma_wvalid_1 	( fdma_wvalid_0  ),
	.fdma_waddr_2  	(  fdma_waddr_1   ),
	.fdma_wareq_2  	(  fdma_wareq_1   ),
	.fdma_wsize_2  	(  fdma_wsize_1   ),
	.fdma_wbusy_2  	(  fdma_wbusy_1   ),
	.fdma_wdata_2  	(  fdma_wdata_1   ),
	.fdma_wvalid_2 	( fdma_wvalid_1  ),
	.fdma_waddr_3  	(  fdma_waddr_2   ),
	.fdma_wareq_3  	(  fdma_wareq_2   ),
	.fdma_wsize_3  	(  fdma_wsize_2   ),
	.fdma_wbusy_3  	(  fdma_wbusy_2   ),
	.fdma_wdata_3  	(  fdma_wdata_2   ),
	.fdma_wvalid_3 	( fdma_wvalid_2  ),
	.fdma_waddr_4  	(  fdma_waddr_3   ),
	.fdma_wareq_4  	(  fdma_wareq_3   ),
	.fdma_wsize_4  	(  fdma_wsize_3   ),
	.fdma_wbusy_4  	(  fdma_wbusy_3   ),
	.fdma_wdata_4  	(  fdma_wdata_3   ),
	.fdma_wvalid_4 	( fdma_wvalid_3  ),
	.fdma_waddr    	(  fdma_waddr_full  ),
	.fdma_wareq    	(  fdma_wareq_full  ),
	.fdma_wsize    	(  fdma_wsize_full  ),
	.fdma_wbusy    	(  fdma_wbusy_full  ),
	.fdma_wdata    	(  fdma_wdata_full  ),
	.fdma_wvalid   	( fdma_wvalid_full    )
);





uivtc#(
	.H_ActiveSize  	( 1280            ),
	.H_FrameSize   	( 1280+110+40+220 ),
	.H_SyncStart   	( 1280+110         ),
	.H_SyncEnd     	( 1280+110+40      ),
	.V_ActiveSize  	( 720             ),
	.V_FrameSize   	( 720+5+5+20      ),
	.V_SyncStart   	( 720+5           ),
	.V_SyncEnd     	( 720+5+5         )
)
 u_uivtc
(
	.I_vtc_rstn    	    ( S_pll_lock          	),
	.I_vtc_clk     	    ( clk_75m           	),
	.O_vtc_vs      	    ( O_vtc_vs      		),
	.O_vtc_de_valid     ( vtc_de_valid     )
);


always @(posedge clk_75m) begin
	O_vtc_de_valid <= vtc_de_valid;
	O_vtc_data	   <= vtc_data;
end


endmodule