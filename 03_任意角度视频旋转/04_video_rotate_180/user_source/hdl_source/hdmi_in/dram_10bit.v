module dram_10bit #(
    parameter DEVICE = "EG"   //"EF2","EF3","EF4","SF1","EG","PH1A","PH1P","DR1"
    )(
    input wire       I_rst,

    input wire       I_wr_clk,
    input wire       I_wr_en,
    input wire[9:0]  I_wr_data,

    input wire       I_rd_clk,
    output reg[9:0]  O_rd_data
);


    reg[3:0]   S_wr_addr = 'd0;  
    reg[3:0]   S_rd_addr = 'd6;  
    wire[10:0] S_rd_data;        


    always @(posedge I_wr_clk or posedge I_rst) begin
        if(I_rst)
            S_wr_addr <= 'd0;
        else
            if(I_wr_en)
                S_wr_addr <= S_wr_addr + 1'b1;
            else
                S_wr_addr <= S_wr_addr;
    end


    always @(posedge I_rd_clk or posedge I_rst) begin
        if(I_rst)
            S_rd_addr <= 'd6;
        else
            S_rd_addr <= S_rd_addr + 1'b1;
    end


    always @(posedge I_rd_clk) begin
        O_rd_data <= S_rd_data;
    end


    generate
        if(DEVICE == "EF2")
            begin
                EF2_LOGIC_DRAM #(
                    .INIT_FILE    ( "NONE" ),
                    .DATA_WIDTH_W ( 10     ),
                    .ADDR_WIDTH_W ( 4      ),
                    .DATA_DEPTH_W ( 16     ),
                    .DATA_WIDTH_R ( 10     ),
                    .ADDR_WIDTH_R ( 4      ),
                    .DATA_DEPTH_R ( 16     )
                )dram(
                    .di    ( I_wr_data ),
                    .waddr ( S_wr_addr ),
                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .do    ( S_rd_data ),
                    .raddr ( S_rd_addr )
                );
            end
        else if(DEVICE == "EF3")
            begin
                EF3_LOGIC_DRAM #(
                    .INIT_FILE    ( "NONE" ),
                    .DATA_WIDTH_W ( 10     ),
                    .ADDR_WIDTH_W ( 4      ),
                    .DATA_DEPTH_W ( 16     ),
                    .DATA_WIDTH_R ( 10     ),
                    .ADDR_WIDTH_R ( 4      ),
                    .DATA_DEPTH_R ( 16     )
                )dram(
                    .di    ( I_wr_data ),
                    .waddr ( S_wr_addr ),
                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .do    ( S_rd_data ),
                    .raddr ( S_rd_addr )
                );
            end
		else if(DEVICE == "EF4")
            begin
                EF4_LOGIC_DRAM #(
                    .INIT_FILE    ( "NONE" ),
                    .DATA_WIDTH_W ( 10     ),
                    .ADDR_WIDTH_W ( 4      ),
                    .DATA_DEPTH_W ( 16     ),
                    .DATA_WIDTH_R ( 10     ),
                    .ADDR_WIDTH_R ( 4      ),
                    .DATA_DEPTH_R ( 16     )
                )dram(
                    .di    ( I_wr_data ),
                    .waddr ( S_wr_addr ),
                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .dout  ( S_rd_data ),
                    .raddr ( S_rd_addr )
                );
            end
        else if(DEVICE == "SF1")
            begin
                SF1_LOGIC_DRAM #(
                    .INIT_FILE    ( "NONE" ),
                    .DATA_WIDTH_W ( 10     ),
                    .ADDR_WIDTH_W ( 4      ),
                    .DATA_DEPTH_W ( 16     ),
                    .DATA_WIDTH_R ( 10     ),
                    .ADDR_WIDTH_R ( 4      ),
                    .DATA_DEPTH_R ( 16     )
                )dram(
                    .di    ( I_wr_data ),
                    .waddr ( S_wr_addr ),
                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .dout  ( S_rd_data ),
                    .raddr ( S_rd_addr )
                );
            end
        else if(DEVICE == "EG")
            begin
                EG_LOGIC_DRAM #(
                    .INIT_FILE    ( "NONE" ),
                    .DATA_WIDTH_W ( 10     ),
                    .ADDR_WIDTH_W ( 4      ),
                    .DATA_DEPTH_W ( 16     ),
                    .DATA_WIDTH_R ( 10     ),
                    .ADDR_WIDTH_R ( 4      ),
                    .DATA_DEPTH_R ( 16     )
                )dram(
                    .di    ( I_wr_data ),
                    .waddr ( S_wr_addr ),
                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .do    ( S_rd_data ),
                    .raddr ( S_rd_addr )
                );
            end
        else if(DEVICE == "PH1A")
            begin
                PH1_LOGIC_DRAM#(
                    .DATA_WIDTH_W( 10        ),
                    .DATA_WIDTH_R( 10        ),
                    .ADDR_WIDTH_W( 4         ),
                    .ADDR_WIDTH_R( 4         ),
                    .DATA_DEPTH_W( 16        ),
                    .DATA_DEPTH_R( 16        ),
                    .INIT_FILE   ( "NONE"    ),
                    .FILL_ALL    ( "NONE"    ),  // "NONE" or some binary string like "0101", not wider than the wider port
                    .READREG     ( "DISABLE" ),  //DEFAULT := "DISABLE"
                    .RESETMODE   ( "SYNC"    )   // ASYNC := "SYNC"
                ) u_PH1_LOGIC_DRAM(
                    .rrst  ( 1'b0      ),

                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .waddr ( S_wr_addr ),
                    .di    ( I_wr_data ),

                    .rclk  ( I_wr_clk  ),
                    .rce   ( 1'b1      ),
                    .raddr ( S_rd_addr ),
                    .rdoq  (           ),
                    .rdo   ( S_rd_data )
                );
            end
        else if(DEVICE == "PH1P")
            begin
                PH1P_LOGIC_DRAM#(
                    .DATA_WIDTH_W( 10        ),
                    .DATA_WIDTH_R( 10        ),
                    .ADDR_WIDTH_W( 4         ),
                    .ADDR_WIDTH_R( 4         ),
                    .DATA_DEPTH_W( 16        ),
                    .DATA_DEPTH_R( 16        ),
                    .INIT_FILE   ( "NONE"    ),
                    .FILL_ALL    ( "NONE"    ),  // "NONE" or some binary string like "0101", not wider than the wider port
                    .READREG     ( "DISABLE" ),  //DEFAULT := "DISABLE"
                    .RESETMODE   ( "SYNC"    )   // ASYNC := "SYNC"
                ) u_PH1_LOGIC_DRAM(
                    .rrst  ( 1'b0      ),

                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .waddr ( S_wr_addr ),
                    .di    ( I_wr_data ),

                    .rclk  ( I_wr_clk  ),
                    .rce   ( 1'b1      ),
                    .raddr ( S_rd_addr ),
                    .rdoq  (           ),
                    .rdo   ( S_rd_data )
                );
            end
        else if(DEVICE == "DR1")
            begin
                DR1_LOGIC_DRAM#(
                    .DATA_WIDTH_W( 10        ),
                    .DATA_WIDTH_R( 10        ),
                    .ADDR_WIDTH_W( 4         ),
                    .ADDR_WIDTH_R( 4         ),
                    .DATA_DEPTH_W( 16        ),
                    .DATA_DEPTH_R( 16        ),
                    .INIT_FILE   ( "NONE"    ),
                    .FILL_ALL    ( "NONE"    ),  // "NONE" or some binary string like "0101", not wider than the wider port
                    .READREG     ( "DISABLE" ),  //DEFAULT := "DISABLE"
                    .RESETMODE   ( "SYNC"    )   // ASYNC := "SYNC"
                ) u_PH1_LOGIC_DRAM(
                    .rrst  ( 1'b0      ),

                    .wclk  ( I_wr_clk  ),
                    .we    ( I_wr_en   ),
                    .waddr ( S_wr_addr ),
                    .di    ( I_wr_data ),

                    .rclk  ( I_wr_clk  ),
                    .rce   ( 1'b1      ),
                    .raddr ( S_rd_addr ),
                    .rdoq  (           ),
                    .rdo   ( S_rd_data )
                );
            end
    endgenerate


endmodule