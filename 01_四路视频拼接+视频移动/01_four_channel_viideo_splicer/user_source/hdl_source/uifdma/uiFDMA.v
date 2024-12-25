
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
*Revision: 3.3
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

/*********uiFDMA(AXI-FAST DMA Controller)基于AXI总线的自定义内存控制器***********
--1.代码简洁，占用极少逻辑资源，代码结构清晰，逻辑设计严谨，读写对称
--2.fdma控制信号，简化了AXI总线的控制，根据I_fdma_wsize和I_fdma_rsize可以自动完成AXI总线的控制，完成数据的搬运
--3版本号说明
--1.0 初次发布
--2.0 修改型号定义，解决1.0版本中，last信号必须连续前一个valid的bug
--3.0 修改,AXI-burst最大burst 256
--3.1 修改可以设置AXI burst长度
--3.2 解决3.1版本中，当总的burst长度是奇数的时候出现错误，修改端口命名规则，设置I代表了输入信号，O代表了输出信号
--3.3 读通道增加背靠背burst机制
*********************************************************************/
`timescale 1ns / 1ns

module uiFDMA#
(
parameter  integer         M_AXI_B2B_SET			= 2		    , //读通道背靠背多次连续burst
parameter  integer         M_AXI_ID_WIDTH			= 16		, //ID,demo中没用到
parameter  integer         M_AXI_ID			        = 0		    , //ID,demo中没用到
parameter  integer         M_AXI_ADDR_WIDTH			= 32		, //内存地址位宽
parameter  integer         M_AXI_DATA_WIDTH			= 64		, //AXI总线的数据位宽
parameter  integer		   M_AXI_MAX_BURST_LEN      = 16          //AXI总线的burst 大小，对于AXI4，支持任意长度，对于AXI3以下最大16
)
(
input   wire [M_AXI_ADDR_WIDTH-1 : 0]      I_fdma_waddr          ,//FDMA写通道地址
input                                      I_fdma_wareq          ,//FDMA写通道请求
input   wire [15 : 0]                      I_fdma_wsize          ,//FDMA写通道一次FDMA的传输大小                                            
output                                     O_fdma_wbusy          ,//FDMA处于BUSY状态，AXI总线正在写操作  
				
input   wire [M_AXI_DATA_WIDTH-1 :0]       I_fdma_wdata		     ,//FDMA写数据
output  wire                               O_fdma_wvalid         ,//FDMA 写有效
input	wire                               I_fdma_wready		 ,//FDMA写准备好，用户可以写数据

input   wire [M_AXI_ADDR_WIDTH-1 : 0]      I_fdma_raddr          ,// FDMA读通道地址
input                                      I_fdma_rareq          ,// FDMA读通道请求
input   wire [15 : 0]                      I_fdma_rsize          ,// FDMA读通道一次FDMA的传输大小                                      
output                                     O_fdma_rbusy          ,// FDMA处于BUSY状态，AXI总线正在读操作 
				
output  wire [M_AXI_DATA_WIDTH-1 :0]       O_fdma_rdata		     ,// FDMA读数据
output  wire                               O_fdma_rvalid         ,// FDMA 读有效
input	wire                               I_fdma_rready		 ,// FDMA读准备好，用户可以读数据

//以下为AXI总线信号		
input 	wire  								M_AXI_ACLK			,
input 	wire  								M_AXI_ARESETN		,
output 	wire [M_AXI_ID_WIDTH-1 : 0]		    M_AXI_AWID			,
output 	wire [M_AXI_ADDR_WIDTH-1 : 0] 	    M_AXI_AWADDR		,
output 	wire [7 : 0]						M_AXI_AWLEN			,
output 	wire [2 : 0] 						M_AXI_AWSIZE		,
output 	wire [1 : 0] 						M_AXI_AWBURST		,
output 	wire  								M_AXI_AWLOCK		,
output 	wire [3 : 0] 						M_AXI_AWCACHE		,
output 	wire [2 : 0] 						M_AXI_AWPROT		,  
output 	wire [3 : 0] 						M_AXI_AWQOS			,
output 	wire  								M_AXI_AWVALID		,
input	wire  								M_AXI_AWREADY		,
output  wire [M_AXI_ID_WIDTH-1 : 0] 		M_AXI_WID			,
output  wire [M_AXI_DATA_WIDTH-1 : 0] 	    M_AXI_WDATA			,
output  wire [M_AXI_DATA_WIDTH/8-1 : 0] 	M_AXI_WSTRB			,
output  wire  								M_AXI_WLAST			, 			
output  wire  								M_AXI_WVALID		,
input   wire  								M_AXI_WREADY		,
input   wire [M_AXI_ID_WIDTH-1 : 0] 		M_AXI_BID			,
input   wire [1 : 0] 						M_AXI_BRESP			,
input   wire  								M_AXI_BVALID		,
output  wire  								M_AXI_BREADY		, 
output  wire [M_AXI_ID_WIDTH-1 : 0] 		M_AXI_ARID			,	 

output  wire [M_AXI_ADDR_WIDTH-1 : 0] 	    M_AXI_ARADDR		,	 	
output  wire [7 : 0] 						M_AXI_ARLEN			,	 
output  wire [2 : 0] 						M_AXI_ARSIZE		,	 
output  wire [1 : 0] 						M_AXI_ARBURST		,	 
output  wire  								M_AXI_ARLOCK		,	 
output  wire [3 : 0] 						M_AXI_ARCACHE		,	 
output  wire [2 : 0] 						M_AXI_ARPROT		,	 
output  wire [3 : 0] 						M_AXI_ARQOS			,	 	   
output  wire  								M_AXI_ARVALID		,	 
input   wire  								M_AXI_ARREADY		,	 
input   wire [M_AXI_ID_WIDTH-1 : 0] 		M_AXI_RID			,	 
input   wire [M_AXI_DATA_WIDTH-1 : 0] 	    M_AXI_RDATA			,	 
input   wire [1 : 0] 						M_AXI_RRESP			,	 
input   wire  								M_AXI_RLAST			,	 
input   wire  								M_AXI_RVALID		,    
output  wire  								M_AXI_RREADY				
	);

//计算数据位宽
function integer clogb2 (input integer bit_depth);              
begin                                                        
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
	        bit_depth = bit_depth >> 1;                               
end                                                           
endfunction 


localparam AXI_BYTES =  M_AXI_DATA_WIDTH/8;
localparam [3:0] MAX_BURST_LEN_SIZE = clogb2(M_AXI_MAX_BURST_LEN)  -1;         
                                                    
//fdma axi write----------------------------------------------
reg     [M_AXI_ADDR_WIDTH-1 : 0]        axi_awaddr  =0;     //AXI4 写地址
reg                                     axi_awvalid = 1'b0; //AXI4 写地有效
wire    [M_AXI_DATA_WIDTH-1 : 0]        axi_wdata   ;       //AXI4 写数据
wire                                    axi_wlast   ;       //AXI4 写LAST信号
reg                                     axi_wvalid  = 1'b0; //AXI4 写数据有效
wire                                    w_next= (M_AXI_WVALID & M_AXI_WREADY);//当valid ready信号都有效，代表AXI4数据传输有效
reg   [8 :0]                            wburst_len  = 1  ;  //写传输的axi burst长度，代码会自动计算每次axi传输的burst 长度
reg   [8 :0]                            wburst_cnt  = 0  ;  //每次axi bust的计数器
reg   [15:0]                            wfdma_cnt   = 0  ;  //fdma的写数据计数器
reg                                     axi_wstart_locked  =0;  //axi 传输进行中，lock住，用于时序控制
wire  [15:0] axi_wburst_size   =        wburst_len * AXI_BYTES; //axi 传输的地址长度计算

assign M_AXI_AWID       = M_AXI_ID;         //写地址ID，用来标志一组写信号, M_AXI_ID是通过参数接口定义
assign M_AXI_AWADDR     = axi_awaddr;
assign M_AXI_AWLEN      = wburst_len - 1;   //AXI4 burst的长度
assign M_AXI_AWSIZE     = clogb2(AXI_BYTES-1);
assign M_AXI_AWBURST    = 2'b01;            //AXI4的busr类型INCR模式，地址递增
assign M_AXI_AWLOCK     = 1'b0;
assign M_AXI_AWCACHE    = 4'b0000;          //不使用cache,不使用buffer
assign M_AXI_AWPROT     = 3'h0;
assign M_AXI_AWQOS      = 4'h0;
assign M_AXI_AWVALID         = axi_awvalid;
assign M_AXI_WDATA      = axi_wdata;
assign M_AXI_WSTRB      = {(AXI_BYTES){1'b1}};//设置所有的WSTRB为1代表传输的所有数据有效
assign M_AXI_WLAST      = axi_wlast;
assign M_AXI_WVALID     = axi_wvalid & I_fdma_wready;//写数据有效，这里必须设置I_fdma_wready有效
assign M_AXI_BREADY     = 1'b1;
//----------------------------------------------------------------------------  
//AXI4 FULL Write
assign  axi_wdata        = I_fdma_wdata;
assign  O_fdma_wvalid      = w_next;
reg     fdma_wstart_locked = 1'b0;
wire    fdma_wend;
wire    fdma_wstart;
assign   O_fdma_wbusy = fdma_wstart_locked ;
//在整个写过程中fdma_wstart_locked将保持有效，直到本次FDMA写结束
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0 || fdma_wend == 1'b1 )
        fdma_wstart_locked <= 1'b0;
    else if(fdma_wstart)
        fdma_wstart_locked <= 1'b1;                                
//产生fdma_wstart信号，整个信号保持1个  M_AXI_ACLK时钟周期
assign fdma_wstart = (fdma_wstart_locked == 1'b0 && I_fdma_wareq == 1'b1);    
        
//AXI4 write burst lenth busrt addr ------------------------------
//当fdma_wstart信号有效，代表一次新的FDMA传输，首先把地址本次fdma的burst地址寄存到axi_awaddr作为第一次axi burst的地址。如果fdma的数据长度大于256，那么当axi_wlast有效的时候，自动计算下次axi的burst地址
always @(posedge M_AXI_ACLK)
    if(fdma_wstart)    
        axi_awaddr <= I_fdma_waddr;
    else if(axi_wlast == 1'b1)
        axi_awaddr <= axi_awaddr + axi_wburst_size ;                    
//AXI4 write cycle -----------------------------------------------
//axi_wstart_locked_r1, axi_wstart_locked_r2信号是用于时序同步
reg axi_wstart_locked_r1 = 1'b0, axi_wstart_locked_r2 = 1'b0;
always @(posedge M_AXI_ACLK)begin
    axi_wstart_locked_r1 <= axi_wstart_locked;
    axi_wstart_locked_r2 <= axi_wstart_locked_r1;
end
// axi_wstart_locked的作用代表一次axi写burst操作正在进行中。
always @(posedge M_AXI_ACLK)
    if((fdma_wstart_locked == 1'b1) &&  axi_wstart_locked == 1'b0)
        axi_wstart_locked <= 1'b1; 
    else if(axi_wlast == 1'b1 || fdma_wstart == 1'b1)
        axi_wstart_locked <= 1'b0;
        
//AXI4 addr valid and write addr----------------------------------- 
always @(posedge M_AXI_ACLK)
     if((axi_wstart_locked_r1 == 1'b1) &&  axi_wstart_locked_r2 == 1'b0)
         axi_awvalid <= 1'b1;
     else if((axi_wstart_locked == 1'b1 && M_AXI_AWREADY == 1'b1)|| axi_wstart_locked == 1'b0)
         axi_awvalid <= 1'b0;       
//AXI4 write data---------------------------------------------------        
always @(posedge M_AXI_ACLK)
    if((axi_wstart_locked_r1 == 1'b1) &&  axi_wstart_locked_r2 == 1'b0)
        axi_wvalid <= 1'b1;
    else if(axi_wlast == 1'b1 || axi_wstart_locked == 1'b0)
        axi_wvalid <= 1'b0;//   
//AXI4 write data burst len counter----------------------------------
always @(posedge M_AXI_ACLK)
    if(axi_wstart_locked == 1'b0)
        wburst_cnt <= 'd0;
    else if(w_next)
        wburst_cnt <= wburst_cnt + 1'b1;    
            
assign axi_wlast = (w_next == 1'b1) && (wburst_cnt == M_AXI_AWLEN);
//fdma write data burst len counter----------------------------------
reg wburst_len_req = 1'b0;
reg [15:0] fdma_wleft_cnt =16'd0;

// wburst_len_req信号是自动管理每次axi需要burst的长度
always @(posedge M_AXI_ACLK)
        wburst_len_req <= fdma_wstart|axi_wlast;

// fdma_wleft_cnt用于记录一次FDMA剩余需要传输的数据数量  
always @(posedge M_AXI_ACLK)
    if( fdma_wstart )begin
        wfdma_cnt <= 1'd0;
        fdma_wleft_cnt <= I_fdma_wsize;
    end
    else if(w_next)begin
        wfdma_cnt <= wfdma_cnt + 1'b1;  
        fdma_wleft_cnt <= (I_fdma_wsize - 1'b1) - wfdma_cnt;
    end
//当最后一个数据的时候，产生fdma_wend信号代表本次fdma传输结束
assign  fdma_wend = w_next && (fdma_wleft_cnt == 1 );
//一次axi最大传输的长度是256因此当大于256，自动拆分多次传输
always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        wburst_len <= 1;
    end
    else if(wburst_len_req)begin
        if(fdma_wleft_cnt[15:MAX_BURST_LEN_SIZE] >0)  
            wburst_len <= M_AXI_MAX_BURST_LEN;
        else 
            wburst_len <= fdma_wleft_cnt[MAX_BURST_LEN_SIZE-1:0];
    end
    else wburst_len <= wburst_len;
end


//fdma axi read----------------------------------------------
reg     [M_AXI_ADDR_WIDTH-1 : 0]    axi_araddr =0   ;  //synthesis keep  
reg                               axi_arvalid  =1'b0; //synthesis keep  
wire                              axi_rlast   ; //synthesis keep  
wire                              axi_rready  = 1'b1;//synthesis keep  
wire                              r_next      = (M_AXI_RVALID && M_AXI_RREADY);//synthesis keep  
reg   [8 :0]                      rburst_len  = 1  ;//synthesis keep  
reg   [8 :0]                      rburst_cnt  = 0  ; //synthesis keep  
reg   [15:0]                      rfdma_cnt   = 0  ; //synthesis keep    
wire  [15:0] axi_rburst_size   =  rburst_len * AXI_BYTES; //synthesis keep  

assign M_AXI_ARID       = M_AXI_ID; 
assign M_AXI_ARADDR     = axi_araddr;
assign M_AXI_ARLEN      = rburst_len - 1; 
assign M_AXI_ARSIZE     = clogb2((AXI_BYTES)-1);
assign M_AXI_ARBURST    = 2'b01;
assign M_AXI_ARLOCK     = 1'b0; 
assign M_AXI_ARCACHE    = 4'b0000;
assign M_AXI_ARPROT     = 3'b010;
assign M_AXI_ARQOS      = 4'h0;
assign M_AXI_ARVALID    = axi_arvalid;
assign M_AXI_RREADY     = axi_rready&&I_fdma_rready; 
assign O_fdma_rdata     = M_AXI_RDATA;    
assign O_fdma_rvalid    = r_next;    

//AXI4 FULL Read-----------------------------------------   

reg     fdma_rstart_locked = 1'b0; //synthesis keep  
wire    fdma_rend; //synthesis keep  
wire    fdma_rstart; //synthesis keep  
assign   O_fdma_rbusy = fdma_rstart_locked ;//synthesis keep  

always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0 || fdma_rend == 1'b1)
        fdma_rstart_locked <= 1'b0;
    else if(fdma_rstart)
        fdma_rstart_locked <= 1'b1;                                

assign fdma_rstart = (fdma_rstart_locked == 1'b0 && I_fdma_rareq == 1'b1);    
//AXI4 read burst lenth busrt addr ------------------------------

always @(posedge M_AXI_ACLK)
    if(fdma_rstart == 1'b1)    
        axi_araddr <= I_fdma_raddr;
    else if(axi_arvalid & M_AXI_ARREADY ) 
        axi_araddr <= axi_araddr + axi_rburst_size ;  

reg fdma_rstart_r = 1'b0;
always @(posedge M_AXI_ACLK)
        fdma_rstart_r <= fdma_rstart;

reg [3 :0] rb2b;//synthesis keep  
reg [15:0] fdma_rleft_cnt;//synthesis keep  
wire rb2b_last;//synthesis keep  


//控制读地址多次Burst
reg [3:0]rb2b_last_cnt;//synthesis keep  
always @(posedge M_AXI_ACLK)
    if(fdma_rstart)
        rb2b_last_cnt <= 0;
    else if((rb2b_last_cnt < M_AXI_B2B_SET) & axi_rlast)
         rb2b_last_cnt <= rb2b_last_cnt + 1'b1;
    else if(rb2b_last_cnt == M_AXI_B2B_SET )
        rb2b_last_cnt <= 0;

assign rb2b_last = (rb2b_last_cnt == M_AXI_B2B_SET -1'b1) & axi_rlast;
//实现背靠背连续多次地址burst或者单次地址burst
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(M_AXI_ARESETN == 0)begin
        axi_arvalid     <= 1'b0;
        rburst_len      <= 1;
        rb2b            <= 0;
        fdma_rleft_cnt  <= 0;
    end
    else begin
    	if(fdma_rstart)begin
        	axi_arvalid     <= 1'b0;
        	rburst_len      <= 1;
        	fdma_rleft_cnt  <= I_fdma_rsize;
        	rb2b            <= 0;
    	end
    	else if(M_AXI_B2B_SET == 1)begin // 只进行单次burst，把单次burs和多次Burst区分，可以优化1个时钟的效率
        	if(M_AXI_ARREADY & axi_arvalid ) // 只进行单次地址burst
            	axi_arvalid <= 1'b0;
        	else if(fdma_rstart_r | (~fdma_rend&axi_rlast))begin //第一次burst 和每次last后burst
            	if(fdma_rleft_cnt[15:MAX_BURST_LEN_SIZE] > 0)begin
                	axi_arvalid     <= 1'b1;
                	rburst_len      <= M_AXI_MAX_BURST_LEN; //最大burst长度
                	fdma_rleft_cnt  <= fdma_rleft_cnt - M_AXI_MAX_BURST_LEN;//剩余burst长度
            	end
            	else if(fdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0] >0 )begin// 最后一次的burst
                	axi_arvalid     <= 1'b1;
                	rburst_len      <= fdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0]; 
                	fdma_rleft_cnt  <= 0; 
            	end
            	else if(fdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0] ==0 )begin// 没有数据需要burst
                	axi_arvalid     <= 1'b0;
            	end 
        	end
    	end
    	else begin
        	if(rb2b_last )begin//支持2次以上的back 2 banck 传输
            	axi_arvalid   <= 1'b0;
            	rb2b          <= 0;
        	end
        	else if((rb2b != M_AXI_B2B_SET) & M_AXI_ARREADY)begin //当rb2b != M_AXI_B2B_SET就进行多少地址的burst
            	if(fdma_rleft_cnt[15:MAX_BURST_LEN_SIZE] > 0)begin//以最大burst长度burst
                	axi_arvalid     <= 1'b1;
                	rb2b            <= rb2b + 1'b1;
                	rburst_len      <= M_AXI_MAX_BURST_LEN; //以最大burst长度burst 
                	fdma_rleft_cnt  <= fdma_rleft_cnt - M_AXI_MAX_BURST_LEN;//剩余burst长度
            	end
            	else if(fdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0] >0 )begin// 最后一次的burst
                	axi_arvalid     <= 1'b1;
                	rb2b            <= rb2b + 1'b1;
                	rburst_len      <= fdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0]; 
                	fdma_rleft_cnt  <= 0;
            	end
            	else if(fdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0] == 0 )begin//没有数据需要burst
                	axi_arvalid     <= 1'b0;
                	rb2b            <= M_AXI_B2B_SET;
            	end    
        	end
        	else if(rb2b == M_AXI_B2B_SET) begin//多次burst结束
            	axi_arvalid <= 1'b0;
        	end
    	end
    end
end

//以下部分为读数据通道的burst控制

reg rburst_len_req = 1'b0;//synthesis keep  
reg [8:0] rburst_len_d =0;//synthesis keep  
reg [15:0] fdma_rleft_cnt_d;//synthesis keep  

always @(posedge M_AXI_ACLK)
        rburst_len_req <= fdma_rstart|axi_rlast;

always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        rburst_len_d <= 1;
    end
    else if(rburst_len_req)begin
        if(fdma_rleft_cnt_d[15:MAX_BURST_LEN_SIZE] >0)  
            rburst_len_d <= M_AXI_MAX_BURST_LEN;
        else 
            rburst_len_d <= fdma_rleft_cnt_d[MAX_BURST_LEN_SIZE-1:0];
    end
    else rburst_len_d <= rburst_len_d;
end

always @(posedge M_AXI_ACLK)
    if(fdma_rstart )begin
    	fdma_rleft_cnt_d <= I_fdma_rsize;
        rfdma_cnt <= 1'd0;
    end
    else if(r_next)begin
    	fdma_rleft_cnt_d <= (I_fdma_rsize - 1'b1) - rfdma_cnt;
        rfdma_cnt <= rfdma_cnt + 1'b1;  
    end
    
//AXI4 read data burst len counter----------------------------------
always @(posedge M_AXI_ACLK)
    if(axi_rlast == 1'b1 |fdma_rstart )
        rburst_cnt <= 0;
    else if(r_next)
        rburst_cnt <= rburst_cnt + 1'b1;            
assign axi_rlast = (r_next == 1'b1) && (rburst_cnt == rburst_len_d-1);
        


assign  fdma_rend = r_next && (rfdma_cnt == I_fdma_rsize-1 );


endmodule


