/*
 * @Author: bit_stream 
 * @Date: 2025-01-15 14:25:52 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2025-01-15 18:26:13
 */

module video_rotate_180_process#(
    parameter AXI_DATA_WIDTH = 256,
    parameter AXI_ADDR_WIDTH = 29
)
(

	//ddr ip signal
    input   wire            O_axi_clk   ,
    input   wire            pll_locked  ,

    //uart ctrl signal
    
    //pll signal
	input	wire        clk_75m,
	input	wire        S_pll_lock,//pll ok
    //hdmi in siganl


	input	wire 			I_vtc_clk		,
	input	wire 			I_vtc_vs		,
	input	wire 			I_vtc_data_valid,
	input	wire [31:0]		I_vtc_data	,	



	 //fdma signal
	output	wire [AXI_ADDR_WIDTH-1:  0]       fdma_waddr_rotate_180 , 
	output	wire                              fdma_wareq_rotate_180 , 
	output	wire [15: 0]                      fdma_wsize_rotate_180 , 
	input	wire                              fdma_wbusy_rotate_180,
	output	wire [AXI_DATA_WIDTH-1 : 0]       fdma_wdata_rotate_180 , 
	input	wire                             fdma_wvalid_rotate_180,

	
	output	wire [AXI_ADDR_WIDTH-1:  0]        fdma_raddr_rotate_180,  
    output	wire                               fdma_rareq_rotate_180,  
    output	wire [15: 0]                       fdma_rsize_rotate_180,                                
    input	wire                               fdma_rbusy_rotate_180, 			
    input	wire [AXI_DATA_WIDTH-1 : 0]        fdma_rdata_rotate_180, 
    input	wire                              fdma_rvalid_rotate_180, 

    //hdmi out siganl
	output	wire 			O_vtc_vs		,
	output	wire 			O_vtc_de_valid,
	output	wire [31:0]		O_vtc_data		
);


wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr_0;   //FDMA写通道地址
wire                             fdma_wareq_0;   //synthesis keep
wire [15: 0]                     fdma_wsize_0;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy_0;   //synthesis keep
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata_0;   //FDMA写数据
wire                            fdma_wvalid_0; //synthesis keep

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr_0;   //FDMA读通道地址
wire                             fdma_rareq_0;  //synthesis keep
wire [15: 0]                     fdma_rsize_0;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy_0;   //synthesis keep	
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata_0;   //FDMA读数据
wire                            fdma_rvalid_0;  //synthesis keep

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr_1;   //FDMA读通道地址
wire                             fdma_rareq_1;   //synthesis keep
wire [15: 0]                     fdma_rsize_1;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy_1;   //synthesis keep 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata_1;   //FDMA读数据
wire                            fdma_rvalid_1;  //synthesis keep



//----对输入进来的数据打一拍

reg 		I_vtc_vs_dly;
reg 		I_vtc_data_valid_dly;
reg [31:0]	I_vtc_data_dly;

always @(posedge I_vtc_clk)begin
	I_vtc_vs_dly 		  <= I_vtc_vs;
	I_vtc_data_valid_dly <= I_vtc_data_valid;
	I_vtc_data_dly       <= I_vtc_data;
end


wire       	vs_data_sample_0; 
wire       	de_data_sample_0; 
wire  [31:0]wr_data_sample_0; 

//把视频从1280*720 缩放至 640*360

down_samping_2x2 #(
	.H_SIZE 	( 1280  ),
	.V_SIZE 	( 720  )
)
u0_down_samping_2x2
(
	.I_clk    	( I_vtc_clk     ),
	.I_rst_n  	( S_pll_lock  ),
	.I_rgb_vs 	( I_vtc_vs_dly  ),
	.I_rgb_de 	( I_vtc_data_valid_dly  ),
	.I_rgb_data  ( I_vtc_data_dly ),
	.O_rgb_vs 	( vs_data_sample_0  ),
	.O_rgb_de 	( de_data_sample_0  ),
	.O_rgb_data ( wr_data_sample_0  )
);


wire [7:0] wbuf_sync_0,rbuf_sync_0;//用于切换帧缓存
wire [7:0] wbuf_sync_1,rbuf_sync_1;//用于切换帧缓存

wire                            O_vtc0_de;
wire                            O_vtc1_de;
wire [31:0]                     I_rd_ddr_data_0;
wire [31:0]                     I_rd_ddr_data_1;



//把待旋转的视频存储进ddr，存储进ddr的数据一路用于显示，一路用于旋转，在显示器上
//同时显示旋转之前的视频和旋转之后的视频


// outports wire

wire [15:0] 	O_wr_data_sample_0;

wr_width_convert u0_wr_width_convert(
	.I_wr_data       	( wr_data_sample_0        ),
	.O_wr_data       	( O_wr_data_sample_0        )
);

wire [15:0]I_rd_data_0;

rd_width_convert u0_rd_width_convert(
	.O_rd_data       	( I_rd_ddr_data_0        ),
	.I_rd_data       	( I_rd_data_0        )
);


uidbuf# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.W_BUFDEPTH(1024),
.W_DATAWIDTH(16),
.W_BASEADDR(0),   //占用的地址空间大小为640*360*2=460,800
.W_DSIZEBITS(25),
.W_XSIZE(640), 
.W_XSTRIDE(640),
.W_YSIZE(360),
.W_XDIV(1),
.W_BUFSIZE(3),

.R_BUFDEPTH(1024), 
.R_DATAWIDTH(16),
.R_BASEADDR(0),
.R_DSIZEBITS(25),
.R_XSIZE(640),
.R_XSTRIDE(640),
.R_YSIZE(360), 
.R_XDIV(1),
.R_BUFSIZE(3)
)
uidbuf_u0
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(pll_locked ),

.I_W_FS(vs_data_sample_0),
.I_W_clk(I_vtc_clk),
.I_W_wren(de_data_sample_0),
.I_W_data(O_wr_data_sample_0), 
.O_W_sync_cnt(wbuf_sync_0),
.I_W_buf(wbuf_sync_0),
.O_W_full(),

.I_R_FS(O_vtc_vs),
.I_R_clk(clk_75m),
.I_R_rden(O_vtc0_de),
.O_R_data(I_rd_data_0),
.O_R_sync_cnt(),
.I_R_buf(rbuf_sync_0),
.O_R_empty(),
       
.O_fdma_waddr(  fdma_waddr_rotate_180)  ,
.O_fdma_wareq(  fdma_wareq_rotate_180)  ,
.O_fdma_wsize(  fdma_wsize_rotate_180)  ,                                     
.I_fdma_wbusy(  fdma_wbusy_rotate_180)  ,			
.O_fdma_wdata(  fdma_wdata_rotate_180)  ,
.I_fdma_wvalid(fdma_wvalid_rotate_180)  ,
.O_fdma_raddr(  fdma_raddr_0)  ,
.O_fdma_rareq(  fdma_rareq_0)  ,
.O_fdma_rsize(  fdma_rsize_0)  ,                                     
.I_fdma_rbusy(  fdma_rbusy_0)  ,			
.I_fdma_rdata(  fdma_rdata_0)  ,
.I_fdma_rvalid(fdma_rvalid_0)
 ); 

//设置3帧缓存，读延迟写1帧
uisetvbuf#(
.BUF_DELAY(1),
.BUF_LENTH(3)
)
uisetvbuf_u0
(
.I_bufn(wbuf_sync_0),
.O_bufn(rbuf_sync_0)
);   



wire [15:0]I_rd_data_1;

rd_width_convert u1_rd_width_convert(
	.O_rd_data       	( I_rd_ddr_data_1        ),
	.I_rd_data       	( I_rd_data_1        )
);


wire O_vtc_hs;

uidbuf_only_r_rotate_180# (
.VIDEO_ENABLE(1'b1),  
.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),


.R_BUFDEPTH(1024), 
.R_DATAWIDTH(16),
.R_BASEADDR(0),
.R_DSIZEBITS(25),
.R_XSIZE(640), 
.R_XSTRIDE(640),
.R_YSIZE(360),  
.R_XDIV(1),
.R_BUFSIZE(3)
)
uidbuf_u1
(
.I_ui_clk(O_axi_clk),
.I_ui_rstn(pll_locked),
.I_R_FS(O_vtc_vs),
.I_R_clk(clk_75m),
.I_R_fifo_rd_en(O_vtc0_de),
.I_R_ram_rd_en (O_vtc1_de),
.I_R_href      (O_vtc_hs),
.O_R_data(I_rd_data_1),
.O_R_sync_cnt(),
.I_R_buf(rbuf_sync_0),
.O_R_empty(),
       

.O_fdma_raddr(  fdma_raddr_1)  ,
.O_fdma_rareq(  fdma_rareq_1)  ,
.O_fdma_rsize(  fdma_rsize_1)  ,                                     
.I_fdma_rbusy(  fdma_rbusy_1)  ,			
.I_fdma_rdata(  fdma_rdata_1),
.I_fdma_rvalid(fdma_rvalid_1)
 ); 




uidbufr_interconnect #(
	.AXI_DATA_WIDTH 	( AXI_DATA_WIDTH  ),
	.AXI_ADDR_WIDTH 	( AXI_ADDR_WIDTH   ))
u_uidbufr_interconnect(
	.ui_clk        	(  O_axi_clk      ),
	.ui_rstn       	(  pll_locked     ),
	.fdma_raddr_1  	(  fdma_raddr_0   ),
	.fdma_rareq_1  	(  fdma_rareq_0   ),
	.fdma_rsize_1  	(  fdma_rsize_0   ),
	.fdma_rbusy_1  	(  fdma_rbusy_0   ),
	.fdma_rdata_1  	(  fdma_rdata_0   ),
	.fdma_rvalid_1 	( fdma_rvalid_0   ),
	.fdma_raddr_2  	(  fdma_raddr_1   ),
	.fdma_rareq_2  	(  fdma_rareq_1   ),
	.fdma_rsize_2  	(  fdma_rsize_1   ),
	.fdma_rbusy_2  	(  fdma_rbusy_1   ),
	.fdma_rdata_2  	(  fdma_rdata_1   ),
	.fdma_rvalid_2 	( fdma_rvalid_1  ),
	.fdma_raddr    	(  fdma_raddr_rotate_180     ),
	.fdma_rareq    	(  fdma_rareq_rotate_180     ),
	.fdma_rsize    	(  fdma_rsize_rotate_180     ),
	.fdma_rbusy    	(  fdma_rbusy_rotate_180     ),
	.fdma_rdata    	(  fdma_rdata_rotate_180     ),
	.fdma_rvalid   	( fdma_rvalid_rotate_180     )
);


uivtc_video_rotate_180#(
	.H_ActiveSize  	( 1280            ),
	.H_FrameSize   	( 1280+110+40+220 ),
	.H_SyncStart   	( 1280+110         ),
	.H_SyncEnd     	( 1280+110+40      ),
	.V_ActiveSize  	( 720             ),
	.V_FrameSize   	( 720+5+5+20      ),
	.V_SyncStart   	( 720+5           ),
	.V_SyncEnd     	( 720+5+5         ),    
	.H2_ActiveSize  ( 640             ), 
	.V2_ActiveSize  ( 360             ),
	.VTC0_X         ( 0               ), //旋转之前的视频 初始位置
	.VTC0_Y         ( 180               ), 
	.VTC1_X         ( 640             ), //旋转之后的视频 初始位置
	.VTC1_Y         ( 180               )
)
 u_uivtc_video_rotate_180
(
	.I_vtc_rstn    	    ( S_pll_lock          	),
	.I_vtc_clk     	    ( clk_75m           	),
	.O_vtc_vs      	    ( O_vtc_vs      		),
	.O_vtc_hs      	    ( O_vtc_hs      		),
	.O_vtc_data_valid   ( O_vtc_de_valid     	),//输出至显示器的视频像素有效信号
	.O_vtc_data         ( O_vtc_data			),//输出至显示器的视频像素数据
	.O_vtc0_de     	    ( O_vtc0_de      		),//旋转之前的视频像素数据读取使能
	.I_rd_ddr_data_0    ( I_rd_ddr_data_0		),//旋转之前的视频像素数据
	.O_vtc1_de_ahead    ( O_vtc1_de      		),//旋转之后的视频像素数据读取使能,提前一个时钟周期
	.I_rd_ddr_data_1    ( I_rd_ddr_data_1		)//旋转之后的视频像素数据
);




endmodule