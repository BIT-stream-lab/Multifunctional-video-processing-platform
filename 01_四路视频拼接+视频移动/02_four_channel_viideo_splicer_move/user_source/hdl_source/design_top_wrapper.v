/*
 * @Author: bit_stream 
 * @Date: 2024-12-12 17:06:06 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-12 19:08:16
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


//--------产生四路测试数据-------------

wire vtc_vs;
wire vtc_hs;
wire vtc_de;


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
	.O_vtc_vs      	    ( vtc_vs      			),
	.O_vtc_hs			( vtc_hs			    ),
	.O_vtc_de_valid     ( vtc_de     		    )
);



wire vs_0;
wire hs_0;
wire data_valid_0;
wire [23:0]data_0;

uitpg_0 uitpg_inst_0	
(
.I_tpg_clk(clk_75m),   //系统时钟
.I_tpg_rstn(S_pll_lock), //系统复位
.I_tpg_vs(vtc_vs),   //图像的vs信号
.I_tpg_hs(vtc_hs),   //图像的hs信号 
.I_tpg_de(vtc_de),   //de数据有效信号
.O_tpg_vs(vs_0),//和vtc_vs信号一样
.O_tpg_hs(hs_0),//和vtc_hs信号一样
.O_tpg_de(data_valid_0),//和vtc_de信号一样		
.O_tpg_data(data_0)//测试图像数据输出			
);

wire vs_1;
wire hs_1;
wire data_valid_1;
wire [23:0]data_1;

uitpg_1 uitpg_inst_1	
(
.I_tpg_clk(clk_75m),   //系统时钟
.I_tpg_rstn(S_pll_lock), //系统复位
.I_tpg_vs(vtc_vs),   //图像的vs信号
.I_tpg_hs(vtc_hs),   //图像的hs信号 
.I_tpg_de(vtc_de),   //de数据有效信号
.O_tpg_vs(vs_1),//和vtc_vs信号一样
.O_tpg_hs(hs_1),//和vtc_hs信号一样
.O_tpg_de(data_valid_1),//和vtc_de信号一样		
.O_tpg_data(data_1)//测试图像数据输出			
);

wire vs_2;
wire hs_2;
wire data_valid_2;
wire [23:0]data_2;

uitpg_2 uitpg_inst_2	
(
.I_tpg_clk(clk_75m),   //系统时钟
.I_tpg_rstn(S_pll_lock), //系统复位
.I_tpg_vs(vtc_vs),   //图像的vs信号
.I_tpg_hs(vtc_hs),   //图像的hs信号 
.I_tpg_de(vtc_de),   //de数据有效信号
.O_tpg_vs(vs_2),//和vtc_vs信号一样
.O_tpg_hs(hs_2),//和vtc_hs信号一样
.O_tpg_de(data_valid_2),//和vtc_de信号一样		
.O_tpg_data(data_2)//测试图像数据输出			
);



wire vs_3;
wire hs_3;
wire data_valid_3;
wire [23:0]data_3;



uitpg_3 uitpg_inst_3	
(
.I_tpg_clk(clk_75m),   //系统时钟
.I_tpg_rstn(S_pll_lock), //系统复位
.I_tpg_vs(vtc_vs),   //图像的vs信号
.I_tpg_hs(vtc_hs),   //图像的hs信号 
.I_tpg_de(vtc_de),   //de数据有效信号
.O_tpg_vs(vs_3),//和vtc_vs信号一样
.O_tpg_hs(hs_3),//和vtc_hs信号一样
.O_tpg_de(data_valid_3),//和vtc_de信号一样		
.O_tpg_data(data_3)//测试图像数据输出			
);


wire       	video_move_en;



//------------------uart_trans inst--------------

uart_trans u_uart_trans(			   
	.I_sysclk          				   ( I_sys_clk           		  ),
	.I_uart_rx         				   ( I_uart_rxd          		  ),
	.O_uart_tx         				   ( O_uart_txd          		  ),
	.O_video_move_en     	       	   ( video_move_en                )
);




//四路视频拼接模块

wire                      	O_vtc_vs;
wire                      	O_vtc_de_valid;
wire [31:0]               	O_vtc_data;

four_channel_viideo_splicer_move #(
	.AXI_DATA_WIDTH 	( AXI_DATA_WIDTH  ),
	.AXI_ADDR_WIDTH 	( AXI_ADDR_WIDTH   ))
u_four_channel_viideo_splicer_move(
	.O_axi_clk         	( O_axi_clk          ),
	.pll_locked        	( pll_locked         ),
	.I_video_move_en	( video_move_en 			 ),
	.clk_75m           	( clk_75m            ),
	.S_pll_lock        	( S_pll_lock         ),
    //第一路数据
	.I0_clk            	( clk_75m         ),
	.I0_vtc_vs         	( vs_0            ),
	.I0_vtc_data_valid 	( data_valid_0    ),
	.I0_vtc_data       	( {8'd0,data_0}   ),
    //第二路数据
	.I1_clk            	( clk_75m         ),
	.I1_vtc_vs         	( vs_1            ),
	.I1_vtc_data_valid 	( data_valid_1    ),
	.I1_vtc_data       	( {8'd0,data_1}   ),
    //第三路数据
	.I2_clk            	( clk_75m         ),
	.I2_vtc_vs         	( vs_2            ),
	.I2_vtc_data_valid 	( data_valid_2    ),
	.I2_vtc_data       	( {8'd0,data_2}   ),
    //第四路数据
	.I3_clk            	( clk_75m         ),
	.I3_vtc_vs         	( vs_3            ),
	.I3_vtc_data_valid 	( data_valid_3    ),
	.I3_vtc_data       	( {8'd0,data_3}   ),
    //fdma signal
	.fdma_waddr_split  	( fdma_waddr   ),
	.fdma_wareq_split  	( fdma_wareq   ),
	.fdma_wsize_split  	( fdma_wsize   ),
	.fdma_wbusy_split  	( fdma_wbusy   ),
	.fdma_wdata_split  	( fdma_wdata   ),
	.fdma_wvalid_split 	( fdma_wvalid  ),
	.fdma_raddr_split  	( fdma_raddr   ),
	.fdma_rareq_split  	( fdma_rareq   ),
	.fdma_rsize_split  	( fdma_rsize   ),
	.fdma_rbusy_split  	( fdma_rbusy   ),
	.fdma_rdata_split  	( fdma_rdata   ),
	.fdma_rvalid_split 	( fdma_rvalid  ),
    //hdmi out
	.O_vtc_vs          	( O_vtc_vs           ),
	.O_vtc_de_valid    	( O_vtc_de_valid     ),
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