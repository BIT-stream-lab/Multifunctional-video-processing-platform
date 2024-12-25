/*
 * @Author: bit_stream 
 * @Date: 2024-12-07 16:30:48 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-12 19:43:07
 */
 

module uidbufw_interconnect #(
parameter  integer                   AXI_DATA_WIDTH = 128,//AXI总线数据位宽
parameter  integer                   AXI_ADDR_WIDTH = 32 //AXI总线地址位宽
)
(
    input   wire                                  ui_clk,
    input   wire                                  ui_rstn,


    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_1,
    input   wire                                    fdma_wareq_1,
    input   wire        [15  :0]                    fdma_wsize_1,                                     
    output  reg                                     fdma_wbusy_1,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_1,
    output  reg                                     fdma_wvalid_1, //wvalid 要立刻输出 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_2,
    input   wire                                    fdma_wareq_2,
    input   wire        [15  :0]                    fdma_wsize_2,                                     
    output  reg                                     fdma_wbusy_2,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_2,
    output  reg                                     fdma_wvalid_2, //wvalid 要立刻输出 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_3,
    input   wire                                    fdma_wareq_3,
    input   wire        [15  :0]                    fdma_wsize_3,                                     
    output  reg                                     fdma_wbusy_3,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_3,
    output  reg                                     fdma_wvalid_3, //wvalid 要立刻输出 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_waddr_4,
    input   wire                                    fdma_wareq_4,
    input   wire        [15  :0]                    fdma_wsize_4,                                     
    output  reg                                     fdma_wbusy_4,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_wdata_4,
    output  reg                                     fdma_wvalid_4, //wvalid 要立刻输出 

    output  reg          [AXI_ADDR_WIDTH-1'b1: 0]   fdma_waddr,
    output  reg                                     fdma_wareq,
    output  reg          [15  :0]                   fdma_wsize,                                     
    input   wire                                    fdma_wbusy,
    output  reg          [AXI_DATA_WIDTH-1'b1:0]    fdma_wdata, //wdata要立刻输出
    input   wire                                    fdma_wvalid

);
    localparam IDLE = 0;
    localparam  W_1 = 1;
    localparam  W_2 = 2;
    localparam  W_3 = 3;
    localparam  W_4 = 4;
  

    wire fdma_wbusy_fall;
    reg fdma_wbusy_dly;
    always @(posedge ui_clk or negedge ui_rstn)begin
        if (ui_rstn == 1'b0) begin
           fdma_wbusy_dly <= 1'b0;
        end else begin
           fdma_wbusy_dly <= fdma_wbusy;
        end
    end

    assign  fdma_wbusy_fall = (~fdma_wbusy)&(fdma_wbusy_dly) ;



    reg [2:0]state;

    always@(posedge ui_clk or negedge ui_rstn)begin
        if (ui_rstn == 1'b0) begin
            state<=IDLE;
        end else begin
            case (state)
                IDLE:begin
                    if (fdma_wareq_1) begin
                        state<=W_1;
                    end else if (fdma_wareq_2) begin
                        state<=W_2;
                    end else if (fdma_wareq_3) begin
                        state<=W_3;
                    end else if (fdma_wareq_4) begin
                        state<=W_4;
                    end else begin
                        state<=state;
                    end
                end 
                W_1:begin
                    if (fdma_wbusy_fall) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                W_2:begin
                    if (fdma_wbusy_fall) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                W_3:begin
                    if (fdma_wbusy_fall) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                W_4:begin
                    if (fdma_wbusy_fall) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                default: state<=IDLE;
            endcase
        end
    end



    always @(posedge ui_clk) begin
        case (state)
            IDLE:begin
                fdma_waddr   <= 'd0;
                fdma_wareq   <= 'b0;
                fdma_wsize   <= 'd0;
                fdma_wbusy_1 <= 'b0;
                fdma_wbusy_2 <= 'b0;
                fdma_wbusy_3 <= 'b0;
                fdma_wbusy_4 <= 'b0;
            end 
            W_1:begin
                fdma_waddr   <= fdma_waddr_1;
                fdma_wareq   <= fdma_wareq_1;
                fdma_wsize   <= fdma_wsize_1;
                fdma_wbusy_1 <= fdma_wbusy;
                fdma_wbusy_2 <= 'b0;
                fdma_wbusy_3 <= 'b0;
                fdma_wbusy_4 <= 'b0;
            end
            W_2:begin
                fdma_waddr   <= fdma_waddr_2;
                fdma_wareq   <= fdma_wareq_2;
                fdma_wsize   <= fdma_wsize_2;
                fdma_wbusy_1 <= 'b0;
                fdma_wbusy_2 <= fdma_wbusy;
                fdma_wbusy_3 <= 'b0;
                fdma_wbusy_4 <= 'b0;
            end
            W_3:begin
                fdma_waddr   <= fdma_waddr_3;
                fdma_wareq   <= fdma_wareq_3;
                fdma_wsize   <= fdma_wsize_3;
                fdma_wbusy_1 <= 'b0;
                fdma_wbusy_2 <= 'b0;
                fdma_wbusy_3 <= fdma_wbusy;
                fdma_wbusy_4 <= 'b0;
            end
            W_4:begin
                fdma_waddr   <= fdma_waddr_4;
                fdma_wareq   <= fdma_wareq_4;
                fdma_wsize   <= fdma_wsize_4;
                fdma_wbusy_1 <= 'b0;
                fdma_wbusy_2 <= 'b0;
                fdma_wbusy_3 <= 'b0;
                fdma_wbusy_4 <= fdma_wbusy;
            end
            default: begin
                fdma_waddr   <= 'd0;
                fdma_wareq   <= 'b0;
                fdma_wsize   <= 'd0;
                fdma_wbusy_1 <= 'b0;
                fdma_wbusy_2 <= 'b0;
                fdma_wbusy_3 <= 'b0;
                fdma_wbusy_4 <= 'b0;
            end
        endcase
    end


    //fdma_wdata fdma_wvalid_1要立刻输出，不能延迟一个时钟周期，因为对于FDMA而言，当fdma_wvalid有效时，fdma_wdata也要有效
    always@(*)begin
        case (state)
            IDLE:begin
              fdma_wdata    <= 'd0;
              fdma_wvalid_1 <= 'b0;
              fdma_wvalid_2 <= 'b0;
              fdma_wvalid_3 <= 'b0;
              fdma_wvalid_4 <= 'b0;
            end 
            W_1:begin
              fdma_wdata    <= fdma_wdata_1;
              fdma_wvalid_1 <= fdma_wvalid;
              fdma_wvalid_2 <= 'b0;
              fdma_wvalid_3 <= 'b0;
              fdma_wvalid_4 <= 'b0;
            end
            W_2:begin
              fdma_wdata    <= fdma_wdata_2;
              fdma_wvalid_1 <= 'b0;
              fdma_wvalid_2 <= fdma_wvalid;
              fdma_wvalid_3 <= 'b0;
              fdma_wvalid_4 <= 'b0;
            end
            W_3:begin
              fdma_wdata    <= fdma_wdata_3;
              fdma_wvalid_1 <= 'b0;
              fdma_wvalid_2 <= 'b0;
              fdma_wvalid_3 <= fdma_wvalid;
              fdma_wvalid_4 <= 'b0;
            end
            W_4:begin
              fdma_wdata    <= fdma_wdata_4;
              fdma_wvalid_1 <= 'b0;
              fdma_wvalid_2 <= 'b0;
              fdma_wvalid_3 <= 'b0;
              fdma_wvalid_4 <= fdma_wvalid;
            end
            default: begin
              fdma_wdata    <= 'd0;
              fdma_wvalid_1 <= 'b0;
              fdma_wvalid_2 <= 'b0;
              fdma_wvalid_3 <= 'b0;
              fdma_wvalid_4 <= 'b0;
            end
        endcase
    end





endmodule //uidbuf_interconnect

