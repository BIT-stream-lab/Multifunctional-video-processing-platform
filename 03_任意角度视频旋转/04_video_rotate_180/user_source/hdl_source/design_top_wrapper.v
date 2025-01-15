/*
 * @Author: bit_stream 
 * @Date: 2025-01-13 19:56:29 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2025-01-15 15:10:23
 */

`define DRAM_BYTE_NUM    2
`define APP_ADDR_WIDTH   27   // 512Mx16bit = 29 ,256Mx16bit = 28 , 128Mx16bit = 27, 64Mx16bit = 26,

module design_top_wrapper(
    //ddr io
    output wire   [13:0]                          ddr_addr    , // 256M x 16bit
    output wire   [ 2:0]                          ddr_ba      ,
    output wire   [ 0:0]                          ddr_cke     ,
    output wire   [ 0:0]                          ddr_odt     ,
    output wire   [ 0:0]                          ddr_cs_n    ,
    output wire                                   ddr_ras_n   ,
    output wire                                   ddr_cas_n   ,
    output wire                                   ddr_we_n    ,
    output wire   [ 0:0]                          ddr_ck_p    ,
    output wire   [ 0:0]                          ddr_ck_n    ,
    output wire                                   ddr_reset_n ,
    inout  wire   [`DRAM_BYTE_NUM     - 1 : 0]    ddr_dm      ,
    inout  wire   [`DRAM_BYTE_NUM * 8 - 1 : 0]    ddr_dq      ,
    inout  wire   [`DRAM_BYTE_NUM     - 1 : 0]    ddr_dqs_p   ,
    inout  wire   [`DRAM_BYTE_NUM     - 1 : 0]    ddr_dqs_n   ,

    input wire  I_sys_clk,
    input wire  I_rst_n,

	//hdmi input io
	input wire  I_hdmi_rx_clk_p,
    input wire  I_hdmi_rx_ch0_p,
    input wire  I_hdmi_rx_ch1_p,
    input wire  I_hdmi_rx_ch2_p,


    input wire  I_hdmi_rx_ddc_scl, 
    inout wire  IO_hdmi_rx_ddc_sda,
	output wire O_hdmi_rx_hpd,

    output wire O_hdmi_tx_ddc_scl, 
    inout wire  IO_hdmi_tx_ddc_sda,


	//uart io
	input  wire                     I_uart_rxd  ,
	output wire                     O_uart_txd  ,

    //hdmi tmds channel signal
    output wire   [2:0]   O_hdmi_tx_p,
    output wire           O_hdmi_clk_p

);


wire                             O_axi_clk;
wire                             pll_locked;


localparam  AXI_ADDR_WIDTH = `APP_ADDR_WIDTH + 2;
localparam  AXI_DATA_WIDTH = `DRAM_BYTE_NUM*8*8;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr;   //FDMA写通道地址
wire                             fdma_wareq;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata;   //FDMA写数据
wire                            fdma_wvalid;  //FDMA 写有效


wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr;   //FDMA读通道地址
wire                             fdma_rareq;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata;   //FDMA读数据
wire                            fdma_rvalid;  //FDMA 读有效


reg[31:0]   S_rst_cnt = 'd0;
wire        S_rst_rel;            

always @(posedge I_sys_clk or negedge I_rst_n) begin
	if(!I_rst_n)
    	S_rst_cnt <= 'd0;
    else
      	begin
    		if(S_rst_cnt >= 'd100000)
        		S_rst_cnt <= S_rst_cnt;
    		else
        		S_rst_cnt <= S_rst_cnt + 'd1;
      	end
end

assign S_rst_rel = S_rst_cnt >= 'd100000 ? 1'b1 : 1'b0;



wire        S_pll_lock;
wire        clk_75m;
wire        clk_375m;


pll u_pll(
.refclk    ( I_sys_clk           ),
.reset     ( ~S_rst_rel          ),
.clk0_out  ( clk_75m             ),
.clk1_out  ( clk_375m            ),
.lock      ( S_pll_lock          )
);


//----------HDMI input module----------------

	wire        S_parallel_clk;      //synthesis keep; 
    wire        S_parallel_2p5x_clk;
    wire        S_parallel_5x_clk;

    wire        S_pll_lock_hdmi_rx;         


    hdmi_pll u_hdmi_pll(
        .refclk          ( I_hdmi_rx_clk_p     ),
  
        .reset           ( ~S_rst_rel          ),

        .clk1_out        ( S_parallel_2p5x_clk ),
		.clk2_out        ( S_parallel_5x_clk   ),
 		.clk3_out        ( S_parallel_clk      )  ,     
        .lock            ( S_pll_lock_hdmi_rx          )
    );


    reg[31:0]   S_hpd_cnt = 'd0;

    always @(posedge I_sys_clk or negedge I_rst_n) begin
		if(!I_rst_n)
        	S_hpd_cnt <= 'd0;
      	else
          	begin
        		if(S_hpd_cnt >= 'd100000)
            		S_hpd_cnt <= S_hpd_cnt;
        		else
            		S_hpd_cnt <= S_hpd_cnt + 'd1;
          	end
    end

    assign O_hdmi_rx_hpd = S_hpd_cnt >= 'd100000 ? 1'b1 : 1'b0;
    


    wire[9:0]   S_rx_ch0_raw_data;   //synthesis keep; 
    wire[9:0]   S_rx_ch1_raw_data;   //synthesis keep;  
    wire[9:0]   S_rx_ch2_raw_data;   //synthesis keep; 

	hdmi_rx_phy_wrapper #(
        .DEVICE ( "PH1A" )
    )u_hdmi_rx_phy_wrapper(
        .I_parallel_clk      ( S_parallel_clk      ),
        .I_parallel_2p5x_clk ( S_parallel_2p5x_clk ),
        .I_parallel_5x_clk   ( S_parallel_5x_clk   ),
        .I_rst               ( ~S_pll_lock_hdmi_rx            ),

        .I_hdmi_rx_ch0_p     ( I_hdmi_rx_ch0_p     ),
        .I_hdmi_rx_ch1_p     ( I_hdmi_rx_ch1_p     ),
        .I_hdmi_rx_ch2_p     ( I_hdmi_rx_ch2_p     ),

        .O_ch0_raw_data      ( S_rx_ch0_raw_data   ),
        .O_ch1_raw_data      ( S_rx_ch1_raw_data   ),
        .O_ch2_raw_data      ( S_rx_ch2_raw_data   )
    );


 	wire        S_rx_native_vsync;   
    wire        S_rx_native_hsync;   
    wire        S_rx_native_de;      
    wire[23:0]  S_rx_native_data;    

    hdmi_1_4b_receiver_core_wrapper #(
        .DEVICE         ( "PH1A"         ), //"EF2","EF3","EF4","SF1","EG","PH1A","PH1P","DR1","PH2A"
        .EDID_INIT_FILE ( "edid_1280720.mif" )
    )u_hdmi_1_4b_receiver_core_wrapper(
        .I_pixel_clk        ( S_parallel_clk         ),
        .I_ddc_clk          ( I_sys_clk              ),
        .I_rst              ( ~I_rst_n               ),
   
        .I_ch0_tmds_data    ( S_rx_ch0_raw_data      ),
        .I_ch1_tmds_data    ( S_rx_ch1_raw_data      ),
        .I_ch2_tmds_data    ( S_rx_ch2_raw_data      ),
   
        .I_ddc_scl          ( I_hdmi_rx_ddc_scl      ),
        .IO_ddc_sda         ( IO_hdmi_rx_ddc_sda     ),
  
        .O_hdmi_hpd         (                        ),
                
        .I_apb_clk          ( 1'b0                   ),
        .I_apb_paddr        ( 12'd0                  ),
        .I_apb_psel         ( 1'b0                   ),
        .I_apb_penable      ( 1'b0                   ),
        .I_apb_pwrite       ( 1'b0                   ),
        .I_apb_pwdata       ( 32'd0                  ),
  
        .O_native_vsync     ( S_rx_native_vsync      ),
        .O_native_hsync     ( S_rx_native_hsync      ),
        .O_native_de        ( S_rx_native_de         ),
        .O_native_data      ( S_rx_native_data       )
    );



//视频旋转模块

wire                      	O_vtc_vs;
wire                      	O_vtc_de_valid;
wire [31:0]               	O_vtc_data;


video_rotate_180_process #(
	.AXI_DATA_WIDTH 	( AXI_DATA_WIDTH  ),
	.AXI_ADDR_WIDTH 	( AXI_ADDR_WIDTH   ))
u_video_rotate_180_process(
	.O_axi_clk         	( O_axi_clk          ),
	.pll_locked        	( pll_locked         ),
	.clk_75m           	( clk_75m            ),
	.S_pll_lock        	( S_pll_lock         ),
    //hdmi in
	.I_vtc_clk          ( S_parallel_clk         ),
	.I_vtc_vs         	( S_rx_native_vsync            ),
	.I_vtc_data_valid 	( S_rx_native_de    ),
	.I_vtc_data       	( {8'd0,S_rx_native_data}   ),
    //fdma signal
	.fdma_waddr_rotate_180  	( fdma_waddr   ),
	.fdma_wareq_rotate_180  	( fdma_wareq   ),
	.fdma_wsize_rotate_180  	( fdma_wsize   ),
	.fdma_wbusy_rotate_180  	( fdma_wbusy   ),
	.fdma_wdata_rotate_180  	( fdma_wdata   ),
	.fdma_wvalid_rotate_180 	( fdma_wvalid  ),
	.fdma_raddr_rotate_180  	( fdma_raddr   ),
	.fdma_rareq_rotate_180  	( fdma_rareq   ),
	.fdma_rsize_rotate_180  	( fdma_rsize   ),
	.fdma_rbusy_rotate_180  	( fdma_rbusy   ),
	.fdma_rdata_rotate_180  	( fdma_rdata   ),
	.fdma_rvalid_rotate_180 	( fdma_rvalid  ),
    //hdmi out
	.O_vtc_vs          	( O_vtc_vs          ),
	.O_vtc_de_valid    	( O_vtc_de_valid    ),
	.O_vtc_data        	( O_vtc_data         )
);


 //例化APP接口转AXI接口
 uifdma_axi_ddr#
 (
 .DRAM_BYTE_NUM   (`DRAM_BYTE_NUM)     ,
 .APP_ADDR_WIDTH  (`APP_ADDR_WIDTH)    ,                 
 .AXI_ADDR_WIDTH  ( AXI_ADDR_WIDTH)    ,                                     
 .AXI_DATA_WIDTH  (`DRAM_BYTE_NUM*8*8) ,
 .APP_DATA_WIDTH  (`DRAM_BYTE_NUM*8*8) ,
 .APP_MASK_WIDTH  (`DRAM_BYTE_NUM * 8)  
 )
 u_uifdma_axi_ddr
 (
 .I_ddr_clk                       ( I_sys_clk    ),
 .I_sys_rstn                      ( S_pll_lock  ),
 .O_ddr_pll_locked                ( pll_locked ),

 // DDR signals
 .ddr_reset_n                     ( ddr_reset_n  ),
 .ddr_addr                        ( ddr_addr     ),
 .ddr_ba                          ( ddr_ba       ),
 .ddr_ck_p                        ( ddr_ck_p     ),
 .ddr_ck_n                        ( ddr_ck_n     ),
 .ddr_cke                         ( ddr_cke      ),
 .ddr_cs_n                        ( ddr_cs_n     ),
 .ddr_ras_n                       ( ddr_ras_n    ),
 .ddr_cas_n                       ( ddr_cas_n    ),
 .ddr_we_n                        ( ddr_we_n     ),
 .ddr_odt                         ( ddr_odt      ),
 .ddr_dqs_p                       ( ddr_dqs_p    ),
 .ddr_dqs_n                       ( ddr_dqs_n    ),
 .ddr_dq                          ( ddr_dq       ),
 .ddr_dm                          ( ddr_dm       ),


 .O_axi_clk                       (O_axi_clk     ),

 .I_fdma_waddr                    (fdma_waddr)    ,// FDMA写通道地址
 .I_fdma_wareq                    (fdma_wareq)    ,// FDMA写通道请求
 .I_fdma_wsize                    (fdma_wsize)    ,// FDMA写通道一次FDMA的传输大小                                            
 .O_fdma_wbusy                    (fdma_wbusy)    ,// FDMA处于BUSY状态，AXI总线正在写操作  
				
 .I_fdma_wdata                    (fdma_wdata)    ,// FDMA写数据
 .O_fdma_wvalid                   (fdma_wvalid)   ,// FDMA 写有效
 .I_fdma_wready                   (1'b1)		     ,// FDMA写准备好，用户可以写数据

 .I_fdma_raddr                    (fdma_raddr)    ,// FDMA读通道地址
 .I_fdma_rareq                    (fdma_rareq)    ,// FDMA读通道请求
 .I_fdma_rsize                    (fdma_rsize)    ,// FDMA读通道一次FDMA的传输大小                                      
 .O_fdma_rbusy                    (fdma_rbusy)    ,// FDMA处于BUSY状态，AXI总线正在读操作 
				
 .O_fdma_rdata                    (fdma_rdata)    ,// FDMA读数据
 .O_fdma_rvalid                   (fdma_rvalid)   ,// FDMA 读有效
 .I_fdma_rready                   (1'b1)		     // FDMA读准备好，用户可以读数据
 );




//hdmi 输出IP
hdmi_tx#(
 //HDMI视频参数设置       
.H_ActiveSize  	( 1280            ),
.H_FrameSize   	( 1280+110+40+220 ),
.H_SyncStart   	( 1280+110         ),
.H_SyncEnd     	( 1280+110+40      ),
.V_ActiveSize  	( 720             ),
.V_FrameSize   	( 720+5+5+20      ),
.V_SyncStart   	( 720+5           ),
.V_SyncEnd     	( 720+5+5         ),       
     
.VIDEO_VIC          ( 16       ),
.VIDEO_TPG          ( "Disable"),//设置disable，用户数据驱动HDMI接口，否则设置eable产生内部测试图形
.VIDEO_FORMAT       ( "RGB444" )//设置输入数据格式为RGB格式
)u_hdmi_tx
(
.I_pixel_clk        ( clk_75m           ),//像素时钟
.I_serial_clk       ( clk_375m           ),//串行发送时钟
.I_rst              ( ~S_pll_lock            ),//异步复位信号，高电平有效

.I_video_rgb_enable (1'b1               ),//是否使能RGB输入接口，设置1使能，否则采用stream video时序接口  
.I_video_in_vs      ( O_vtc_vs            ),//RGB 输入VS 帧同步
.I_video_in_de      ( O_vtc_de_valid    ),//RGB 输入de有效
.I_video_in_data    ( O_vtc_data[23:0]	 ), //视频输入数据   

.O_hdmi_clk_p       ( O_hdmi_clk_p     ),//HDMI时钟通道
.O_hdmi_tx_p        ( O_hdmi_tx_p      )//HDMI数据通道
);








endmodule