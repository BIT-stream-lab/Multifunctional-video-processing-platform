/*
 * @Author: bit_stream 
 * @Date: 2024-12-24 16:28:16 
 * @Last Modified by:   bit_stream 
 * @Last Modified time: 2024-12-24 16:28:16 
 */

`timescale 1ns / 1ns

module uidbuf_r_baseaddr_switch#(
parameter  integer                   VIDEO_ENABLE   = 1,//使能视频帧支持功能

parameter  integer                   AXI_DATA_WIDTH = 128,//AXI总线数据位宽
parameter  integer                   AXI_ADDR_WIDTH = 32, //AXI总线地址位宽

parameter  integer                   R_BUFDEPTH     = 2048, //读通道AXI设置FIFO缓存大小
parameter  integer                   R_DATAWIDTH    = 32, //读通道AXI设置数据位宽大小
parameter  integer                   R_DSIZEBITS    = 24, //读通道设置缓存数据的增量地址大小，用于FDMA DBUF 计算帧缓存起始地址
parameter  integer                   R_XSIZE        = 1920, //读通道设置X方向的数据大小，代表了每次FDMA 传输的数据长度
parameter  integer                   R_XSTRIDE      = 1920, //读通道设置X方向的Stride值，主要用于图形缓存应用
parameter  integer                   R_YSIZE        = 1080, //读通道设置Y方向值，代表了进行了多少次XSIZE传输
parameter  integer                   R_XDIV         = 2, //读通道对X方向数据拆分为XDIV次传输，减少FIFO的使用
parameter  integer                   R_BUFSIZE      = 3 //读通道设置帧缓存大小，目前最大支持128帧，可以修改参数支持更缓存数
)
(
input wire                                  I_ui_clk, //和FDMA AXI总线时钟一致
input wire                                  I_ui_rstn, //和FDMA AXI复位一致
input wire    [2    :0]                     I_state_ddr_clk, 

//----------fdma signals read-------  
input  wire                                 I_R_clk, //用户读数据接口时钟
input  wire                                 I_R_FS, //用户读数据接口同步信号，对于非视频帧一般设置1
input  wire                                 I_R_rden, //用户读数据使能
output wire    [R_DATAWIDTH-1'b1 : 0]       O_R_data, //用户读数据
output reg     [7   :0]                     O_R_sync_cnt =0, //读通道BUF帧同步输出
input  wire    [7   :0]                     I_R_buf, //写通道BUF帧同步输入
output wire                                 O_R_empty,

output wire    [AXI_ADDR_WIDTH-1'b1: 0]     O_fdma_raddr, // FDMA读通道地址
output wire                                 O_fdma_rareq, // FDMA读通道请求
output wire    [15: 0]                      O_fdma_rsize, // FDMA读通道一次FDMA的传输大小                                     
input  wire                                 I_fdma_rbusy, // FDMA处于BUSY状态，AXI总线正在读操作     
input  wire    [AXI_DATA_WIDTH-1'b1:0]      I_fdma_rdata, // FDMA读数据
input  wire                                 I_fdma_rvalid, // FDMA 读有效
output wire                                 O_fdma_rready, // FDMA读准备好，用户可以读数据
output reg     [7  :0]                      O_fmda_rbuf =0, // FDMA的读帧缓存号输出
output wire                                 O_fdma_rirq // FDMA一次读完成的数据传输完成后，产生中断
);    

// 计算Log2
function integer clog2;
  input integer value;
  begin 
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
    end 
  endfunction


wire   R_FS;

//FDMA读写状态机的状态值，一般4个状态值即可 
localparam S_IDLE  =  2'd0;  
localparam S_RST   =  2'd1;  
localparam S_DATA1 =  2'd2;   
localparam S_DATA2 =  2'd3; 

reg [AXI_ADDR_WIDTH-1'b1: 0]R_BASEADDR;

localparam VIDEO_0_BASEADDR = 1843200;
localparam VIDEO_1_BASEADDR = 3686400;
localparam VIDEO_2_BASEADDR = 5529600;
localparam VIDEO_3_BASEADDR = 7372800;

//根据I_state_ddr_clk来进行地址的切换

//何时切换？在一帧视频读完后进行切换，保证每一帧画面的完整性

localparam VIDEO_0  = 3'd0;
localparam VIDEO_1  = 3'd1;
localparam VIDEO_2  = 3'd2;
localparam VIDEO_3  = 3'd3;

always @(posedge I_ui_clk or negedge I_ui_rstn) begin
    if (~I_ui_rstn) begin
        R_BASEADDR <= VIDEO_0_BASEADDR;
    end else if (R_FS) begin
        case (I_state_ddr_clk)
            VIDEO_0:begin
                R_BASEADDR <= VIDEO_0_BASEADDR;
            end 
            VIDEO_1:begin
                R_BASEADDR <= VIDEO_1_BASEADDR;
            end 
            VIDEO_2:begin
                R_BASEADDR <= VIDEO_2_BASEADDR;
            end 
            VIDEO_3:begin
                R_BASEADDR <= VIDEO_3_BASEADDR;
            end 
            default: begin
                R_BASEADDR <= VIDEO_0_BASEADDR;
            end
        endcase
    end
end


localparam RYBUF_SIZE           = (R_BUFSIZE - 1'b1); //读通道需要完成多少次XSIZE操作
localparam RY_BURST_TIMES       = (R_YSIZE*R_XDIV); //读通道需要完成的FDMA burst 操作次数，XDIV用于把XSIZE分解多次传输
localparam FDMA_RX_BURST        = (R_XSIZE*R_DATAWIDTH/AXI_DATA_WIDTH)/R_XDIV; //FDMA BURST 一次的大小
localparam RX_BURST_ADDR_INC    = (R_XSIZE*(R_DATAWIDTH/8))/R_XDIV; //FDMA每次burst之后的地址增加
localparam RX_LAST_ADDR_INC     = (R_XSTRIDE-R_XSIZE)*(R_DATAWIDTH/8) + RX_BURST_ADDR_INC; //根据stride值计算出来最后一次地址

localparam RFIFO_DEPTH = R_BUFDEPTH*R_DATAWIDTH/AXI_DATA_WIDTH;//R_BUFDEPTH/(AXI_DATA_WIDTH/R_DATAWIDTH);
localparam R_WR_DATA_COUNT_WIDTH = clog2(RFIFO_DEPTH); //读通道FIFO 输入部分深度
localparam R_RD_DATA_COUNT_WIDTH = clog2(R_BUFDEPTH); //写通道FIFO输出部分深度

assign                                  O_fdma_rready = 1'b1;
reg                                     O_fdma_rareq_r= 1'b0;
reg                                     R_FIFO_Rst=0; 
reg [1 :0]                              R_MS=0; 
reg [R_DSIZEBITS-1'b1:0]                R_addr=0; 
reg [15:0]                              R_bcnt=0; 
wire[R_WR_DATA_COUNT_WIDTH-1'b1 :0]     R_wcnt;
reg                                     R_REQ=0; 
reg [5 :0]                              rirq_dly_cnt =0;
reg [3 :0]                              rdiv_cnt =0;
reg [7 :0]                              rrst_cnt =0;
reg [7 :0]                              O_fmda_rbufn;
assign O_fdma_rsize = FDMA_RX_BURST;
assign O_fdma_rirq = (rirq_dly_cnt>0);

assign O_fdma_raddr = R_BASEADDR + {O_fmda_rbufn,R_addr};//由于FPGA逻辑做乘法比较复杂，因此通过设置高位地址实现缓存设置

reg [1:0] R_MS_r =0;
always @(posedge I_ui_clk) R_MS_r <= R_MS;

//每次FDMA DBUF 完成一帧数据传输后，产生中断，这个中断持续60个周期的uiclk,这里的延迟必须足够ZYNQ IP核识别到这个中断
always @(posedge I_ui_clk) begin
    if(I_ui_rstn == 1'b0)begin
        rirq_dly_cnt <= 6'd0;
        O_fmda_rbuf <=0;
    end
    else if((R_MS_r == S_DATA2) && (R_MS == S_IDLE))begin
        rirq_dly_cnt <= 60;
        O_fmda_rbuf <= O_fmda_rbufn;
    end
    else if(rirq_dly_cnt >0)
        rirq_dly_cnt <= rirq_dly_cnt - 1'b1;
end

//帧同步，对于视频有效
fs_cap #
(
.VIDEO_ENABLE(VIDEO_ENABLE)
)
fs_cap_R0
(
  .I_clk(I_ui_clk),
  .I_rstn(I_ui_rstn),
  .I_vs(I_R_FS),
  .O_fs_cap(R_FS)
);

assign O_fdma_rareq = O_fdma_rareq_r;

//读通道状态机，采用4个状态值描述
 always @(posedge I_ui_clk) begin
   if(!I_ui_rstn)begin
        R_MS          <= S_IDLE;
        R_FIFO_Rst   <= 0;
        R_addr       <= 0;
        O_R_sync_cnt <= 0;
        R_bcnt       <= 0;
        rrst_cnt     <= 0;
        rdiv_cnt      <= 0;
        O_fmda_rbufn    <= 0;
       // O_fdma_rareq_r  <= 1'd0;
    end   
    else begin
      case(R_MS) //帧同步，对于非视频数据一般常量为1
        S_IDLE:begin
          R_addr <= 0;
          R_bcnt <= 0;
          rrst_cnt <= 0;
          rdiv_cnt <=0;
          if(R_FS) begin
            R_MS <= S_RST;
            if(O_R_sync_cnt < RYBUF_SIZE) //输出帧同步计数器，当需要用读通道做帧同步的时候使用
                O_R_sync_cnt <= O_R_sync_cnt + 1'b1; 
            else 
                O_R_sync_cnt <= 0;  
          end
       end
       S_RST:begin//帧同步，对于非视频数据直接跳过,对于视频数据，会同步每一帧，并且复位数据FIFO
           O_fmda_rbufn <= I_R_buf;
           rrst_cnt <= rrst_cnt + 1'b1;
           if((VIDEO_ENABLE == 1) && (rrst_cnt < 40))
                R_FIFO_Rst <= 1;
           else if((VIDEO_ENABLE == 1) && (rrst_cnt < 100))
                R_FIFO_Rst <= 0;
           else if(O_fdma_rirq == 1'b0) begin
                R_MS <= S_DATA1;
           end
       end
       S_DATA1:begin 
        // if(I_fdma_rbusy == 1'b0 && R_REQ)begin
         //   O_fdma_rareq_r  <= 1'b1;  
        // end
         if(I_fdma_rbusy == 1'b1) begin
        //    O_fdma_rareq_r  <= 1'b0;
            R_MS    <= S_DATA2;
         end         
        end
        S_DATA2:begin //写有效数据
            if(I_fdma_rbusy == 1'b0)begin
                if(R_bcnt == RY_BURST_TIMES - 1'b1) //判断是否传输完毕
                    R_MS <= S_IDLE;
                else begin
                    if(rdiv_cnt < R_XDIV - 1'b1)begin//如果对XSIZE做了分次传输，一个XSIZE也需要XDIV次FDMA完成传输
                        R_addr <= R_addr +  RX_BURST_ADDR_INC;  //计算地址增量
                        rdiv_cnt <= rdiv_cnt + 1'b1;
                     end
                    else begin
                        R_addr <= R_addr + RX_LAST_ADDR_INC; //计算最后一次地址增量，最后一次地址根据stride 计算
                        rdiv_cnt <= 0;
                    end
                    R_bcnt <= R_bcnt + 1'b1;
                    R_MS    <= S_DATA1;
                end 
            end
         end
         default:R_MS <= S_IDLE;
      endcase
   end
end 

//读通道的数据FIFO，采用了原语调用xpm_fifo_async fifo，当FIFO存储空间有足够空余，满足一次FDMA的burst即可发出请求
always@(posedge I_ui_clk)      
     R_REQ  <= (R_wcnt < FDMA_RX_BURST - 1);


rfifo #( 
.DATA_WIDTH_W(AXI_DATA_WIDTH), 
.DATA_WIDTH_R(R_DATAWIDTH), 
.ADDR_WIDTH_W(R_WR_DATA_COUNT_WIDTH), 
.ADDR_WIDTH_R(R_RD_DATA_COUNT_WIDTH), 
.AL_FULL_NUM(RFIFO_DEPTH-2), 
.AL_EMPTY_NUM(2), 
.SHOW_AHEAD_EN(1'b1) , 
.OUTREG_EN ("NOREG")
) 
u_rfifo(
.rst((I_ui_rstn == 1'b0) || (R_FIFO_Rst == 1'b1)), //asynchronous port,active hight
.clkw(I_ui_clk),  //write clock
.clkr(I_R_clk),  //read clock
.we(I_fdma_rvalid),  //write enable,active hight
.di(I_fdma_rdata),  //write data
.re(I_R_rden),  //read enable,active hight
.dout(O_R_data),  //read data
//.valid(),  //read data valid flag
//.full_flag(),  //fifo full flag
.empty_flag(O_R_empty),  //fifo empty flag
//.afull(),  //fifo almost full flag
//.aempty(),  //fifo almost empty flag
.wrusedw(R_wcnt) //stored data number in fifo
//.rdusedw(W_rcnt) //available data number for read      
) ;

reg [1:0]WR_S;

always @(posedge I_ui_clk) begin
    if(!I_ui_rstn)begin
        WR_S            <= 2'd0;
        O_fdma_rareq_r  <= 1'd0;
    end
    else begin
        case(WR_S)
        0:begin
          if(I_fdma_rbusy == 1'b0 && R_REQ  && R_MS == S_DATA1)begin//如果写完成后再执行读
            O_fdma_rareq_r  <= 1'b1;  
            WR_S            <= 2'd2;
         end
        end     
        2:begin
            if(I_fdma_rbusy == 1'b1) begin //等待读完成
                O_fdma_rareq_r  <= 1'b0;
                WR_S    <= 3;
            end            
        end
        3:begin
            if(I_fdma_rbusy==0)
                WR_S    <= 0;
        end
        default: WR_S <= 0;
        endcase
    end
end  

endmodule

