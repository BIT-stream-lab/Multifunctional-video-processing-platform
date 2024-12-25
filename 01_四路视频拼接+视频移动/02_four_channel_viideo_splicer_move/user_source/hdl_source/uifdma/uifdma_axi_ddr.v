`timescale 1ps/1ps
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

/*************uifdma_axi_ddr(DDR controller)*************
--版本号1.0
--以下是米联客设计的uifdma_axi_ddr(DDR controller)DDR控制器
--1.代码简洁，代码结构清晰，逻辑设计严谨
--2.使用方便，基于AXI总线接口设计的，DDR控制器，用户接口采用米联客的FDMA时序接口，只需要给出需要burst的设计长度，以及burst请求，就可以自动完成DDR数据的读写burst
--3.参数灵活设置，支持AXI1.0 AXI3.0 AXI4.0协议，支持AXI burst长度设置，而用户端的FDMA接口只要给出总的数据长度，无需关注每次AXI的burst长度
*********************************************************************/
//`define DRAM_BYTE_NUM 8    // 1 = x8, 2 = x16,4 = x32,8=x64
//`define DRAM_SIZE    "4G"     // AP106,AP102=2G ,AP104=4G    1G , 2G , 4G = 256x16bit, 8G    ,ONE DDR particle capacity

//`define XLNX_NATIVE
//`define ALC_NATIVE  
`define MC_AXI  
 
//`define AXI_ATG  
//`define ATG   
//`define DFI
  
module uifdma_axi_ddr#(
parameter DRAM_TYPE       = "DDR3"  ,            //"DDR4" "DDR3"
parameter ECC             = "OFF",
parameter DRAM_BYTE_NUM   =  4,
parameter APP_ADDR_WIDTH  =  27,                 // 512Mx16bit = 29 ,256Mx16bit = 28 , 128Mx16bit = 27, 64Mx16bit = 26,
parameter AXI_ID_WIDTH    =  4,                                                                                   
parameter APP_DATA_WIDTH  = (ECC == "ON")? (DRAM_BYTE_NUM-1)*8*8 : DRAM_BYTE_NUM*8*8,
parameter APP_MASK_WIDTH  = (ECC == "ON")? (DRAM_BYTE_NUM-1)*8   : DRAM_BYTE_NUM*8,
parameter AXI_ADDR_WIDTH  = APP_ADDR_WIDTH+3,
parameter AXI_DATA_WIDTH  = APP_DATA_WIDTH,
parameter DQ_WIDTH        = DRAM_BYTE_NUM * 8,
parameter DQS_WIDTH       = DRAM_BYTE_NUM,
parameter DM_WIDTH        = DRAM_BYTE_NUM,
parameter ADDR_WIDTH      = 14,                  // 512Mx16bit = 16 ,256Mx16bit = 15  ,128Mx16bit = 14 ,64Mx16bit = 13
parameter ROW_WIDTH       = 14,                  // 512Mx16bit = 16 ,256Mx16bit = 15  ,128Mx16bit = 14 ,64Mx16bit = 13
parameter COL_WIDTH       = 10,                  //
parameter BA_WIDTH        = 3,                   //
parameter BG_WIDTH        = 1,                   //
parameter ODT_WIDTH       = 1,                   // PP phy 2, single phy 1
parameter CKE_WIDTH       = 1,                   // PP phy 2, single phy 1
parameter CS_WIDTH        = 1,                   // PP phy 2, single phy 1
parameter M_AXI_MAX_BURST_LEN   =    256

)
(
input                                     I_ddr_clk   , 
input                                     I_sys_rstn  ,
output                                    O_ddr_pll_locked , //synthesis keep   
// DDR3 signals                                                                                             
output    [ADDR_WIDTH-1:0]                ddr_addr    , 
output    [  BA_WIDTH-1:0]                ddr_ba      ,
output    [ CKE_WIDTH-1:0]                ddr_cke     ,
output    [ ODT_WIDTH-1:0]                ddr_odt     ,
output    [  CS_WIDTH-1:0]                ddr_cs_n    ,
output                                    ddr_ras_n   ,
output                                    ddr_cas_n   ,
output                                    ddr_we_n    ,
output                                    ddr_ck_p    ,
output                                    ddr_ck_n    ,
output                                    ddr_reset_n ,
inout     [  DM_WIDTH-1:0]                ddr_dm  ,
inout     [  DQ_WIDTH-1:0]                ddr_dq      ,
inout     [ DQS_WIDTH-1:0]                ddr_dqs_n   ,
inout     [ DQS_WIDTH-1:0]                ddr_dqs_p   , 


output                                    O_axi_clk      ,//synthesis keep 
input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_waddr   ,//synthesis keep//FDMA写通道地址
input                                     I_fdma_wareq   ,//synthesis keep//FDMA写通道请求
input     [15 : 0]                        I_fdma_wsize   ,//synthesis keep//FDMA写通道一次FDMA的传输大小                                            
output                                    O_fdma_wbusy   ,//synthesis keep//FDMA处于BUSY状态，AXI总线正在写操作  
				
input     [AXI_DATA_WIDTH-1 :0]           I_fdma_wdata	 ,//synthesis keep/FDMA写数据
output                                    O_fdma_wvalid  ,//synthesis keep//FDMA 写有效
input	                                  I_fdma_wready	 ,//synthesis keep//FDMA写准备好，用户可以写数据

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output                                    O_fdma_rbusy   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 
				
output   [AXI_DATA_WIDTH-1 :0]            O_fdma_rdata	 ,//synthesis keep// FDMA读数据
output                                    O_fdma_rvalid  ,//synthesis keep// FDMA 读有效
input	                                  I_fdma_rready   //synthesis keep// FDMA读准备好，用户可以读数据

);                                        

//-------- User Clock --------//
wire                           pll_locked ;
wire                           ddr_init_cal_done  ;
wire                           dfi_clk;
wire    [  3:0]                dfi_reset_n ;
wire    [  CKE_WIDTH*4-1:0]    dfi_cke;
wire    [  ODT_WIDTH*4-1:0]    dfi_odt;
wire    [  CS_WIDTH *4-1:0]    dfi_cs_n;
wire    [  3:0]                dfi_ras_n;
wire    [  3:0]                dfi_cas_n;
wire    [  3:0]                dfi_act_n;
wire    [  3:0]                dfi_we_n;
wire    [  BA_WIDTH*4-1 :0]    dfi_bank;
wire    [  BG_WIDTH*4-1 :0]    dfi_bg;
wire    [  ADDR_WIDTH*4-1:0]   dfi_address;
wire    [  DQS_WIDTH*4-1:0]    dfi_wrdata_en;
wire    [  DQ_WIDTH*8-1:0]     dfi_wrdata;
wire    [  DM_WIDTH*8-1:0]     dfi_wrdata_mask;
wire    [  DQS_WIDTH*4-1:0]    dfi_rddata_en;
wire    [  DQS_WIDTH*4-1:0]    dfi_rddata_valid;
wire    [  DQ_WIDTH*8-1:0]     dfi_rddata;
wire    [  DM_WIDTH*8-1:0]     dfi_rddata_dbi_n;

assign O_axi_clk        =  dfi_clk;
assign O_ddr_pll_locked =  pll_locked;

//例化APP接口转AXI接口

// AXI Write Addr
wire [AXI_ADDR_WIDTH-1:0]      axi_awaddr  ;
wire                           axi_awvalid ;
wire                           axi_awready ;
wire   [AXI_ID_WIDTH-1:0]      axi_awid    ;
wire                [7:0]      axi_awlen   ; 
wire                [2:0]      axi_awsize  ; 
wire                [1:0]      axi_awburst ; 
wire                [0:0]      axi_awlock  ; 
wire                [3:0]      axi_awcache ; 
wire                [2:0]      axi_awprot  ; 
wire                [3:0]      axi_awqos   ;
// AXI Write Data              
wire [APP_DATA_WIDTH-1:0]      axi_wdata   ;
wire [APP_MASK_WIDTH-1:0]      axi_wstrb   ;
wire                           axi_wvalid  ;
wire                           axi_wlast   ;
wire                           axi_wready  ;
// Write Response Port         
wire   [AXI_ID_WIDTH-1:0]      axi_bid     ;    
wire                [1:0]      axi_bresp   ;    
wire                           axi_bvalid  ;    
wire                           axi_bready  ;    
                               
// AXI Read Addr               
wire [AXI_ADDR_WIDTH-1:0]      axi_araddr  ;
wire                           axi_arvalid ;
wire                           axi_arready ;
wire [  AXI_ID_WIDTH-1:0]      axi_arid    ;
wire                [7:0]      axi_arlen   ;
wire                [2:0]      axi_arsize  ;
wire                [1:0]      axi_arburst ;
wire                [0:0]      axi_arlock  ;
wire                [3:0]      axi_arcache ;
wire                [2:0]      axi_arprot  ;
wire                [3:0]      axi_arqos   ;
// AXI Read Data               
wire [APP_DATA_WIDTH-1:0]      axi_rdata   ;
wire                           axi_rlast   ;
wire                           axi_rvalid  ;
wire                           axi_rready  ;
wire   [AXI_ID_WIDTH-1:0]      axi_rid     ;
wire                [1:0]      axi_rresp   ;


  
//例化DDR IP
//===== DDR3 PHY INS =====//
ddr_ip u_ddr_phy (
`ifndef DFI
        .sys_clk                    ( I_ddr_clk          ),
        .sys_rst_n                  ( I_sys_rstn        ),
`else
        .sys_clk_p                  ( I_ddr_clk          ),
        .sys_rstn                   ( I_sys_rstn        ),
`endif
        .dfi_clk                    ( dfi_clk          ), 
        .pll_locked                 ( pll_locked       ),
//        .user_clk0                  (                  ),
         //DDR bus signals                             
        .ddr_addr                   ( ddr_addr         ),
        .ddr_ba                     ( ddr_ba           ),
        //.ddr_bg                     ( ddr_bg           ),
        .ddr_ck_n                   ( ddr_ck_n         ),
        .ddr_ck_p                   ( ddr_ck_p         ),
        .ddr_ras_n                  ( ddr_ras_n        ),
        .ddr_cas_n                  ( ddr_cas_n        ),
        .ddr_we_n                   ( ddr_we_n         ),  
        //.ddr_act_n                  ( ddr_act_n        ),
        .ddr_cke                    ( ddr_cke          ),
        .ddr_cs_n                   ( ddr_cs_n         ),
        .ddr_dm                     ( ddr_dm ),        
        .ddr_odt                    ( ddr_odt          ),
        .ddr_reset_n                ( ddr_reset_n      ),
        .ddr_dq                     ( ddr_dq           ),
        .ddr_dqs_n                  ( ddr_dqs_n        ),
        .ddr_dqs_p                  ( ddr_dqs_p        ),  
        .ddr_init_cal_done          ( ddr_init_cal_done    ),

`ifdef DFI
         // DFI bus signals, between hard 
         // controller and users or top-level systems  
        .dfi_reset_n                ( dfi_reset_n      ),
        .dfi_cke                    ( dfi_cke          ),
        .dfi_odt                    ( dfi_odt          ),
        .dfi_cs_n                   ( dfi_cs_n         ),
        .dfi_ras_n                  ( dfi_ras_n        ),
        .dfi_cas_n                  ( dfi_cas_n        ),
        .dfi_we_n                   ( dfi_we_n         ),
        //.dfi_act_n                  ( dfi_act_n        ),
        .dfi_bank                   ( dfi_bank         ),
        //.dfi_bg                     ( dfi_bg           ),
        .dfi_address                ( dfi_address      ),
        .dfi_wrdata_en              ( dfi_wrdata_en    ),
        .dfi_wrdata                 ( dfi_wrdata       ),
        .dfi_wrdata_mask            ( dfi_wrdata_mask  ), 
        .dfi_rddata_en              ( dfi_rddata_en    ),
        .dfi_rddata_valid           ( dfi_rddata_valid ),
        .dfi_rddata                 ( dfi_rddata       ),
        .dfi_rddata_dbi_n           ( dfi_rddata_dbi_n ), 
        .dfi_ctrlupd_req            ( 2'b00            ),
        .dfi_ctrlupd_ack            (                  ),
        .dfi_phyupd_req             (                  ),
        .dfi_phyupd_ack             ( 2'h0             ),
        .dfi_phyupd_type            (                  )

`elsif MC_AXI  
 // Write Addr Ports                            
        .axi_awaddr                 ( axi_awaddr       ),
        .axi_awvalid                ( axi_awvalid      ),
        .axi_awready                ( axi_awready      ),
                                          
        .axi_awid                   ( axi_awid         ),
        .axi_awlen                  ( axi_awlen        ),
        .axi_awsize                 ( axi_awsize       ),
        .axi_awburst                ( axi_awburst      ),
        .axi_awlock                 ( axi_awlock       ),
        .axi_awcache                ( axi_awcache      ),
        .axi_awprot                 ( axi_awprot       ),
        .axi_awqos                  ( axi_awqos        ),
                                                
        // Write Data Port                             
        .axi_wdata                  ( axi_wdata        ),
        .axi_wstrb                  ( axi_wstrb        ),
        .axi_wvalid                 ( axi_wvalid       ),
        .axi_wlast                  ( axi_wlast        ),
        .axi_wready                 ( axi_wready       ),
        // Write Response Port                         
        .axi_bid                    ( axi_bid          ),
        .axi_bresp                  ( axi_bresp        ),
        .axi_bvalid                 ( axi_bvalid       ),
        .axi_bready                 ( axi_bready       ),
        // Read Address Ports                          
        .axi_araddr                 ( axi_araddr       ),
        .axi_arvalid                ( axi_arvalid      ),
        .axi_arready                ( axi_arready      ),
                                          
        .axi_arid                   ( axi_arid         ),
        .axi_arlen                  ( axi_arlen        ),
        .axi_arsize                 ( axi_arsize       ),
        .axi_arburst                ( axi_arburst      ),
        .axi_arlock                 ( axi_arlock       ),
        .axi_arcache                ( axi_arcache      ),
        .axi_arprot                 ( axi_arprot       ),
        .axi_arqos                  ( axi_arqos        ),
                                                 
        // Read Data Ports                                                         
        .axi_rid                    ( axi_rid          ),
        .axi_rresp                  ( axi_rresp        ),                                       
        .axi_rdata                  ( axi_rdata        ),
        .axi_rlast                  ( axi_rlast        ),
        .axi_rvalid                 ( axi_rvalid       ),
        .axi_rready                 ( axi_rready       )
  `else
        // Native
        .paxi_awaddr        ( axi_awaddr       ),
        .paxi_awvalid       ( axi_awvalid      ),
        .paxi_awready       ( axi_awready      ),
        
        .paxi_wdata         ( axi_wdata        ),
        .paxi_wstrb         ( axi_wstrb        ),
        .paxi_wvalid        ( axi_wvalid       ),
        .paxi_wlast         ( axi_wlast        ),
        .paxi_wready        ( axi_wready       ),
        
         // Write Response Port
        .paxi_bid           ( axi_bid          ),
        .paxi_bresp         ( axi_bresp        ),
        .paxi_bvalid        ( axi_bvalid       ),
        .paxi_bready        ( axi_bready       ),
         // Read Address Ports
        .paxi_araddr        ( axi_araddr       ),
        .paxi_arvalid       ( axi_arvalid      ),
        .paxi_arready       ( axi_arready      ),
        
         // Read Data Ports
        .paxi_rdata         ( axi_rdata        ),
        .paxi_rlast         ( axi_rlast        ),
        .paxi_rvalid        ( axi_rvalid       ),
        .paxi_rready        ( axi_rready       )

`endif 
);



//例化米联客uiFDMA AXI 控制器 IP
uiFDMA#
(
.M_AXI_B2B_SET(1),
.M_AXI_ID_WIDTH(AXI_ID_WIDTH)           ,//ID位宽
.M_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)		,//内存地址位宽
.M_AXI_DATA_WIDTH(AXI_DATA_WIDTH)		,//AXI总线的数据位宽
.M_AXI_MAX_BURST_LEN (M_AXI_MAX_BURST_LEN)                //AXI总线的burst 大小，对于AXI4，支持任意长度，对于AXI3以下最大16
)
uiFDMA_inst
(
.I_fdma_waddr(I_fdma_waddr)          ,//FDMA写通道地址
.I_fdma_wareq(I_fdma_wareq)          ,//FDMA写通道请求
.I_fdma_wsize(I_fdma_wsize)          ,//FDMA写通道一次FDMA的传输大小                                            
.O_fdma_wbusy(O_fdma_wbusy)          ,//FDMA处于BUSY状态，AXI总线正在写操作  
				
.I_fdma_wdata(I_fdma_wdata)		   ,//FDMA写数据
.O_fdma_wvalid(O_fdma_wvalid)        ,//FDMA 写有效
.I_fdma_wready(1'b1)		       ,//FDMA写准备好，用户可以写数据

.I_fdma_raddr(I_fdma_raddr)          ,// FDMA读通道地址
.I_fdma_rareq(I_fdma_rareq)          ,// FDMA读通道请求
.I_fdma_rsize(I_fdma_rsize)          ,// FDMA读通道一次FDMA的传输大小                                      
.O_fdma_rbusy(O_fdma_rbusy)          ,// FDMA处于BUSY状态，AXI总线正在读操作 
				
.O_fdma_rdata(O_fdma_rdata)		   ,// FDMA读数据
.O_fdma_rvalid(O_fdma_rvalid)        ,// FDMA 读有效
.I_fdma_rready(1'b1)		       ,// FDMA读准备好，用户可以读数据

//以下为AXI总线信号		
.M_AXI_ACLK                             (dfi_clk),
.M_AXI_ARESETN                          (pll_locked),
// Master Interface Write Address Ports
.M_AXI_AWID                             (axi_awid),
.M_AXI_AWADDR                           (axi_awaddr),
.M_AXI_AWLEN                            (axi_awlen),
.M_AXI_AWSIZE                           (axi_awsize),
.M_AXI_AWBURST                          (axi_awburst),
.M_AXI_AWLOCK                           (),
.M_AXI_AWCACHE                          (axi_awcache),
.M_AXI_AWPROT                           (axi_awprot),
.M_AXI_AWQOS                            (),
.M_AXI_AWVALID                          (axi_awvalid),
.M_AXI_AWREADY                          (axi_awready),
// Master Interface Write Data Ports
.M_AXI_WDATA                            (axi_wdata),
.M_AXI_WSTRB                            (axi_wstrb),
.M_AXI_WLAST                            (axi_wlast),
.M_AXI_WVALID                           (axi_wvalid),
.M_AXI_WREADY                           (axi_wready),
// Master Interface Write Response Ports
.M_AXI_BID                              (axi_bid),
.M_AXI_BRESP                            (axi_bresp),
.M_AXI_BVALID                           (axi_bvalid),
.M_AXI_BREADY                           (axi_bready),
// Master Interface Read Address Ports
.M_AXI_ARID                             (axi_arid),
.M_AXI_ARADDR                           (axi_araddr),
.M_AXI_ARLEN                            (axi_arlen),
.M_AXI_ARSIZE                           (axi_arsize),
.M_AXI_ARBURST                          (axi_arburst),
.M_AXI_ARLOCK                           (),
.M_AXI_ARCACHE                          (axi_arcache),
.M_AXI_ARPROT                           (),
.M_AXI_ARQOS                            (),
.M_AXI_ARVALID                          (axi_arvalid),
.M_AXI_ARREADY                          (axi_arready),
// Master Interface Read Data Ports
.M_AXI_RID                              (axi_rid),
.M_AXI_RDATA                            (axi_rdata),
.M_AXI_RRESP                            (axi_rresp),
.M_AXI_RLAST                            (axi_rlast),
.M_AXI_RVALID                           (axi_rvalid),
.M_AXI_RREADY                           (axi_rready)		
);

 
endmodule

