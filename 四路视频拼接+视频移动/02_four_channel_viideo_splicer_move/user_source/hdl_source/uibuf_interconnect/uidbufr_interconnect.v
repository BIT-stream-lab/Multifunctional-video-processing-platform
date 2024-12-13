/*
 * @Author: bit_stream 
 * @Date: 2024-12-12 19:25:03 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-12 19:41:32
 */

module uidbufr_interconnect #(
parameter  integer                   AXI_DATA_WIDTH = 128,//AXI总线数据位宽
parameter  integer                   AXI_ADDR_WIDTH = 32 //AXI总线地址位宽
)
(
    input   wire                                  ui_clk,
    input   wire                                  ui_rstn,


    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_raddr_1,
    input   wire                                    fdma_rareq_1,
    input   wire        [15  :0]                    fdma_rsize_1,                                     
    output  reg                                     fdma_rbusy_1,
    output  reg         [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata_1,
    output  reg                                     fdma_rvalid_1, 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_raddr_2,
    input   wire                                    fdma_rareq_2,
    input   wire        [15  :0]                    fdma_rsize_2,                                     
    output  reg                                     fdma_rbusy_2,
    output  reg         [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata_2,
    output  reg                                     fdma_rvalid_2, 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_raddr_3,
    input   wire                                    fdma_rareq_3,
    input   wire        [15  :0]                    fdma_rsize_3,                                     
    output  reg                                     fdma_rbusy_3,
    output  reg         [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata_3,
    output  reg                                     fdma_rvalid_3, 

    input   wire        [AXI_ADDR_WIDTH-1'b1: 0]    fdma_raddr_4,
    input   wire                                    fdma_rareq_4,
    input   wire        [15  :0]                    fdma_rsize_4,                                     
    output  reg                                     fdma_rbusy_4,
    output  reg         [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata_4,
    output  reg                                     fdma_rvalid_4, 

    output  reg         [AXI_ADDR_WIDTH-1'b1: 0]    fdma_raddr,
    output  reg                                     fdma_rareq,
    output  reg         [15  :0]                    fdma_rsize,                                     
    input   wire                                    fdma_rbusy,
    input   wire        [AXI_DATA_WIDTH-1'b1:0]     fdma_rdata,
    input   wire                                    fdma_rvalid
);

    parameter IDLE=0;
    parameter R_1=1;
    parameter R_2=2;
    parameter R_3=3;
    parameter R_4=4;



    reg [2:0]state;//synthesis keep
    always@(posedge ui_clk or negedge ui_rstn)begin
        if (ui_rstn==1'b0) begin
            state<=IDLE;
        end else begin
            case (state)
                IDLE:begin
                    if (fdma_rareq_1) begin
                        state<=R_1;
                    end else if (fdma_rareq_2) begin
                        state<=R_2;
                    end else if (fdma_rareq_3) begin
                        state<=R_3;
                    end else if (fdma_rareq_4) begin
                        state<=R_4;
                    end else begin
                        state<=state;
                    end
                end 
                R_1:begin
                    if (~fdma_rbusy) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                R_2:begin
                    if (~fdma_rbusy) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                R_3:begin
                    if (~fdma_rbusy) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                R_4:begin
                    if (~fdma_rbusy) begin
                        state<=IDLE;
                    end else begin
                        state<=state;
                    end
                end
                default: state<=IDLE;
            endcase
        end
    end


    always@(posedge ui_clk)begin
        case (state)
            IDLE:begin
                fdma_raddr    <= 'd0;
                fdma_rareq    <= 'b0;
                fdma_rsize    <= 'd0;

                fdma_rbusy_1  <= 'b0;
                fdma_rvalid_1 <= 'b0;
                fdma_rdata_1  <= 'd0;

                fdma_rbusy_2  <= 'b0;
                fdma_rvalid_2 <= 'b0;
                fdma_rdata_2  <= 'd0;

                fdma_rbusy_3  <= 'b0;
                fdma_rvalid_3 <= 'b0;
                fdma_rdata_3  <= 'd0;

                fdma_rbusy_4  <= 'b0;
                fdma_rvalid_4 <= 'b0;
                fdma_rdata_4  <= 'd0;
            end 
            R_1:begin
                fdma_raddr    <= fdma_raddr_1;
                fdma_rareq    <= fdma_rareq_1;
                fdma_rsize    <= fdma_rsize_1;

                fdma_rbusy_1  <= fdma_rbusy ;
                fdma_rvalid_1 <= fdma_rvalid;
                fdma_rdata_1  <= fdma_rdata ;

                fdma_rbusy_2  <= 'b0;
                fdma_rvalid_2 <= 'b0;
                fdma_rdata_2  <= 'd0;

                fdma_rbusy_3  <= 'b0;
                fdma_rvalid_3 <= 'b0;
                fdma_rdata_3  <= 'd0;
                
                fdma_rbusy_4  <= 'b0;
                fdma_rvalid_4 <= 'b0;
                fdma_rdata_4  <= 'd0;
            end
            R_2:begin
                fdma_raddr    <= fdma_raddr_2;
                fdma_rareq    <= fdma_rareq_2;
                fdma_rsize    <= fdma_rsize_2;

                fdma_rbusy_1  <= 'b0;
                fdma_rvalid_1 <= 'b0;
                fdma_rdata_1  <= 'd0;

                fdma_rbusy_2  <= fdma_rbusy ;
                fdma_rvalid_2 <= fdma_rvalid;
                fdma_rdata_2  <= fdma_rdata ;

                fdma_rbusy_3  <= 'b0;
                fdma_rvalid_3 <= 'b0;
                fdma_rdata_3  <= 'd0;
                
                fdma_rbusy_4  <= 'b0;
                fdma_rvalid_4 <= 'b0;
                fdma_rdata_4  <= 'd0;
            end
            R_3:begin
                fdma_raddr    <= fdma_raddr_3;
                fdma_rareq    <= fdma_rareq_3;
                fdma_rsize    <= fdma_rsize_3;

                fdma_rbusy_1  <= 'b0;
                fdma_rvalid_1 <= 'b0;
                fdma_rdata_1  <= 'd0;

                fdma_rbusy_2  <= 'b0;
                fdma_rvalid_2 <= 'b0;
                fdma_rdata_2  <= 'd0;

                fdma_rbusy_3  <= fdma_rbusy ;
                fdma_rvalid_3 <= fdma_rvalid;
                fdma_rdata_3  <= fdma_rdata ;
                
                fdma_rbusy_4  <= 'b0;
                fdma_rvalid_4 <= 'b0;
                fdma_rdata_4  <= 'd0;
            end
            R_4:begin
                fdma_raddr    <= fdma_raddr_4;
                fdma_rareq    <= fdma_rareq_4;
                fdma_rsize    <= fdma_rsize_4;

                fdma_rbusy_1  <= 'b0;
                fdma_rvalid_1 <= 'b0;
                fdma_rdata_1  <= 'd0;

                fdma_rbusy_2  <= 'b0;
                fdma_rvalid_2 <= 'b0;
                fdma_rdata_2  <= 'd0;

                fdma_rbusy_3  <= 'b0;
                fdma_rvalid_3 <= 'b0;
                fdma_rdata_3  <= 'd0;
                
                fdma_rbusy_4  <= fdma_rbusy ;
                fdma_rvalid_4 <= fdma_rvalid;
                fdma_rdata_4  <= fdma_rdata ;
            end
            
            default: begin
                fdma_raddr    <= 'd0;
                fdma_rareq    <= 'b0;
                fdma_rsize    <= 'd0;

                fdma_rbusy_1  <= 'b0;
                fdma_rvalid_1 <= 'b0;
                fdma_rdata_1  <= 'd0;

                fdma_rbusy_2  <= 'b0;
                fdma_rvalid_2 <= 'b0;
                fdma_rdata_2  <= 'd0;

                fdma_rbusy_3  <= 'b0;
                fdma_rvalid_3 <= 'b0;
                fdma_rdata_3  <= 'd0;

                fdma_rbusy_4  <= 'b0;
                fdma_rvalid_4 <= 'b0;
                fdma_rdata_4  <= 'd0;
            end
        endcase
    end
    
endmodule //uidbufr_interconnect
