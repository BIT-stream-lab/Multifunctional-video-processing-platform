


module lane_lvds_1_10 #(
    parameter DEVICE = "EG" //"EF2","EF3","EF4","SF1","EG","PH1A","PH1P","DR1"
    )(
    input wire      I_parallel_clk,
    input wire      I_parallel_2p5x_clk,
    input wire      I_parallel_5x_clk,

    input wire      I_rst,

    input wire      I_lvds_serial_in,

    output reg[9:0] O_data
);


    wire[3:0] S_iddrx2_data;      
    reg[3:0]  S_iddrx2_data_1d;   
    reg[3:0]  S_iddrx2_data_2d;   
    reg[2:0]  S_cnt = 3'd0;       
    wire      S_10bit_data_en;    
    reg[9:0]  S_10bit_data;       
    reg       S_10bit_data_en_1d; 
    wire[9:0] S_dram_rd_data;


    generate
        if(DEVICE == "EF2")
            begin
                EF2_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
        else if(DEVICE == "EF3")
            begin
                EF3_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
		else if(DEVICE == "EF4")
            begin
                EF4_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
        else if(DEVICE == "SF1")
            begin
                SF1_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
        else if(DEVICE == "EG")
            begin
                EG_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
        else if(DEVICE == "PH1A")
            begin
                PH1_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
        else if(DEVICE == "PH1P")
            begin
                PH1P_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
        else if(DEVICE == "DR1")
            begin
                DR1_LOGIC_IDDRx2 u_iddrx2(
                    .pclk ( I_parallel_2p5x_clk ), 
                    .sclk ( I_parallel_5x_clk   ), 
                    .rst  ( 1'b0                ),
                
                    .d    ( I_lvds_serial_in    ), 

                    .q3   ( S_iddrx2_data[0]    ), 
                    .q2   ( S_iddrx2_data[1]    ), 
                    .q1   ( S_iddrx2_data[2]    ), 
                    .q0   ( S_iddrx2_data[3]    )
                );
            end
	endgenerate


    always @(posedge I_parallel_2p5x_clk) begin
        S_iddrx2_data_1d <= S_iddrx2_data;
        S_iddrx2_data_2d <= S_iddrx2_data_1d;
    end


    always @(posedge I_parallel_2p5x_clk) begin
        if(S_cnt >= 'd4)
            S_cnt <= 'd0;
        else
            S_cnt <= S_cnt + 'd1;
    end


    assign S_10bit_data_en = (S_cnt == 3'd0) || (S_cnt == 3'd2) ? 1'b1 : 1'b0;


    always @(posedge I_parallel_2p5x_clk) begin
        if(S_10bit_data_en)
            begin
                S_10bit_data <= S_cnt == 'd0 ? {S_iddrx2_data_2d[3:0],S_iddrx2_data_1d[3:0],S_iddrx2_data[3:2]} : 
                                S_cnt == 'd2 ? {S_iddrx2_data_2d[1:0],S_iddrx2_data_1d[3:0],S_iddrx2_data[3:0]} : 'd0;
            end
        else
            S_10bit_data <= 'd0;
    end

    always @(posedge I_parallel_2p5x_clk) begin
        S_10bit_data_en_1d <= S_10bit_data_en;
    end


    dram_10bit#(
        .DEVICE    ( DEVICE )
    )u_dram_10bit(
        .I_rst     ( I_rst               ),

        .I_wr_clk  ( I_parallel_2p5x_clk ),
        .I_wr_en   ( S_10bit_data_en_1d  ),
        .I_wr_data ( S_10bit_data        ),

        .I_rd_clk  ( I_parallel_clk      ),
        .O_rd_data ( S_dram_rd_data      )
    );

    always @(posedge I_parallel_clk) begin
        O_data <= S_dram_rd_data;
    end


    
endmodule