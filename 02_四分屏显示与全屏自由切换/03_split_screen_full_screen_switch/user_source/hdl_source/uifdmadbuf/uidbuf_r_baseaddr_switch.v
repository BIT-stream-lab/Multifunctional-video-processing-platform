/*
 * @Author: bit_stream 
 * @Date: 2024-12-24 16:28:16 
 * @Last Modified by:   bit_stream 
 * @Last Modified time: 2024-12-24 16:28:16 
 */

`timescale 1ns / 1ns

module uidbuf_r_baseaddr_switch#(
parameter  integer                   VIDEO_ENABLE   = 1,//ʹ����Ƶ֧֡�ֹ���

parameter  integer                   AXI_DATA_WIDTH = 128,//AXI��������λ��
parameter  integer                   AXI_ADDR_WIDTH = 32, //AXI���ߵ�ַλ��

parameter  integer                   R_BUFDEPTH     = 2048, //��ͨ��AXI����FIFO�����С
parameter  integer                   R_DATAWIDTH    = 32, //��ͨ��AXI��������λ���С
parameter  integer                   R_DSIZEBITS    = 24, //��ͨ�����û������ݵ�������ַ��С������FDMA DBUF ����֡������ʼ��ַ
parameter  integer                   R_XSIZE        = 1920, //��ͨ������X��������ݴ�С��������ÿ��FDMA ��������ݳ���
parameter  integer                   R_XSTRIDE      = 1920, //��ͨ������X�����Strideֵ����Ҫ����ͼ�λ���Ӧ��
parameter  integer                   R_YSIZE        = 1080, //��ͨ������Y����ֵ�������˽����˶��ٴ�XSIZE����
parameter  integer                   R_XDIV         = 2, //��ͨ����X�������ݲ��ΪXDIV�δ��䣬����FIFO��ʹ��
parameter  integer                   R_BUFSIZE      = 3 //��ͨ������֡�����С��Ŀǰ���֧��128֡�������޸Ĳ���֧�ָ�������
)
(
input wire                                  I_ui_clk, //��FDMA AXI����ʱ��һ��
input wire                                  I_ui_rstn, //��FDMA AXI��λһ��
input wire    [2    :0]                     I_state_ddr_clk, 

//----------fdma signals read-------  
input  wire                                 I_R_clk, //�û������ݽӿ�ʱ��
input  wire                                 I_R_FS, //�û������ݽӿ�ͬ���źţ����ڷ���Ƶ֡һ������1
input  wire                                 I_R_rden, //�û�������ʹ��
output wire    [R_DATAWIDTH-1'b1 : 0]       O_R_data, //�û�������
output reg     [7   :0]                     O_R_sync_cnt =0, //��ͨ��BUF֡ͬ�����
input  wire    [7   :0]                     I_R_buf, //дͨ��BUF֡ͬ������
output wire                                 O_R_empty,

output wire    [AXI_ADDR_WIDTH-1'b1: 0]     O_fdma_raddr, // FDMA��ͨ����ַ
output wire                                 O_fdma_rareq, // FDMA��ͨ������
output wire    [15: 0]                      O_fdma_rsize, // FDMA��ͨ��һ��FDMA�Ĵ����С                                     
input  wire                                 I_fdma_rbusy, // FDMA����BUSY״̬��AXI�������ڶ�����     
input  wire    [AXI_DATA_WIDTH-1'b1:0]      I_fdma_rdata, // FDMA������
input  wire                                 I_fdma_rvalid, // FDMA ����Ч
output wire                                 O_fdma_rready, // FDMA��׼���ã��û����Զ�����
output reg     [7  :0]                      O_fmda_rbuf =0, // FDMA�Ķ�֡��������
output wire                                 O_fdma_rirq // FDMAһ�ζ���ɵ����ݴ�����ɺ󣬲����ж�
);    

// ����Log2
function integer clog2;
  input integer value;
  begin 
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
    end 
  endfunction


wire   R_FS;

//FDMA��д״̬����״ֵ̬��һ��4��״ֵ̬���� 
localparam S_IDLE  =  2'd0;  
localparam S_RST   =  2'd1;  
localparam S_DATA1 =  2'd2;   
localparam S_DATA2 =  2'd3; 

reg [AXI_ADDR_WIDTH-1'b1: 0]R_BASEADDR;

localparam VIDEO_0_BASEADDR = 1843200;
localparam VIDEO_1_BASEADDR = 3686400;
localparam VIDEO_2_BASEADDR = 5529600;
localparam VIDEO_3_BASEADDR = 7372800;

//����I_state_ddr_clk�����е�ַ���л�

//��ʱ�л�����һ֡��Ƶ���������л�����֤ÿһ֡�����������

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


localparam RYBUF_SIZE           = (R_BUFSIZE - 1'b1); //��ͨ����Ҫ��ɶ��ٴ�XSIZE����
localparam RY_BURST_TIMES       = (R_YSIZE*R_XDIV); //��ͨ����Ҫ��ɵ�FDMA burst ����������XDIV���ڰ�XSIZE�ֽ��δ���
localparam FDMA_RX_BURST        = (R_XSIZE*R_DATAWIDTH/AXI_DATA_WIDTH)/R_XDIV; //FDMA BURST һ�εĴ�С
localparam RX_BURST_ADDR_INC    = (R_XSIZE*(R_DATAWIDTH/8))/R_XDIV; //FDMAÿ��burst֮��ĵ�ַ����
localparam RX_LAST_ADDR_INC     = (R_XSTRIDE-R_XSIZE)*(R_DATAWIDTH/8) + RX_BURST_ADDR_INC; //����strideֵ����������һ�ε�ַ

localparam RFIFO_DEPTH = R_BUFDEPTH*R_DATAWIDTH/AXI_DATA_WIDTH;//R_BUFDEPTH/(AXI_DATA_WIDTH/R_DATAWIDTH);
localparam R_WR_DATA_COUNT_WIDTH = clog2(RFIFO_DEPTH); //��ͨ��FIFO ���벿�����
localparam R_RD_DATA_COUNT_WIDTH = clog2(R_BUFDEPTH); //дͨ��FIFO����������

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

assign O_fdma_raddr = R_BASEADDR + {O_fmda_rbufn,R_addr};//����FPGA�߼����˷��Ƚϸ��ӣ����ͨ�����ø�λ��ַʵ�ֻ�������

reg [1:0] R_MS_r =0;
always @(posedge I_ui_clk) R_MS_r <= R_MS;

//ÿ��FDMA DBUF ���һ֡���ݴ���󣬲����жϣ�����жϳ���60�����ڵ�uiclk,������ӳٱ����㹻ZYNQ IP��ʶ������ж�
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

//֡ͬ����������Ƶ��Ч
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

//��ͨ��״̬��������4��״ֵ̬����
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
      case(R_MS) //֡ͬ�������ڷ���Ƶ����һ�㳣��Ϊ1
        S_IDLE:begin
          R_addr <= 0;
          R_bcnt <= 0;
          rrst_cnt <= 0;
          rdiv_cnt <=0;
          if(R_FS) begin
            R_MS <= S_RST;
            if(O_R_sync_cnt < RYBUF_SIZE) //���֡ͬ��������������Ҫ�ö�ͨ����֡ͬ����ʱ��ʹ��
                O_R_sync_cnt <= O_R_sync_cnt + 1'b1; 
            else 
                O_R_sync_cnt <= 0;  
          end
       end
       S_RST:begin//֡ͬ�������ڷ���Ƶ����ֱ������,������Ƶ���ݣ���ͬ��ÿһ֡�����Ҹ�λ����FIFO
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
        S_DATA2:begin //д��Ч����
            if(I_fdma_rbusy == 1'b0)begin
                if(R_bcnt == RY_BURST_TIMES - 1'b1) //�ж��Ƿ������
                    R_MS <= S_IDLE;
                else begin
                    if(rdiv_cnt < R_XDIV - 1'b1)begin//�����XSIZE���˷ִδ��䣬һ��XSIZEҲ��ҪXDIV��FDMA��ɴ���
                        R_addr <= R_addr +  RX_BURST_ADDR_INC;  //�����ַ����
                        rdiv_cnt <= rdiv_cnt + 1'b1;
                     end
                    else begin
                        R_addr <= R_addr + RX_LAST_ADDR_INC; //�������һ�ε�ַ���������һ�ε�ַ����stride ����
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

//��ͨ��������FIFO��������ԭ�����xpm_fifo_async fifo����FIFO�洢�ռ����㹻���࣬����һ��FDMA��burst���ɷ�������
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
          if(I_fdma_rbusy == 1'b0 && R_REQ  && R_MS == S_DATA1)begin//���д��ɺ���ִ�ж�
            O_fdma_rareq_r  <= 1'b1;  
            WR_S            <= 2'd2;
         end
        end     
        2:begin
            if(I_fdma_rbusy == 1'b1) begin //�ȴ������
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

