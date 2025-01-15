

module hdmi_rx_phy_wrapper#(
        parameter DEVICE = "PH1A"  //"EF2","EF3","EF4","SF1","EG","PH1A","PH1P","DR1"
    )(
    input wire       I_parallel_clk,
    input wire       I_parallel_2p5x_clk,    
    input wire       I_parallel_5x_clk,  
    input wire       I_rst,
  
    input wire       I_hdmi_rx_ch0_p,
    input wire       I_hdmi_rx_ch1_p,
    input wire       I_hdmi_rx_ch2_p,

    output wire[9:0] O_ch0_raw_data,
    output wire[9:0] O_ch1_raw_data,
    output wire[9:0] O_ch2_raw_data
);

    lane_lvds_1_10 #(
        .DEVICE ( DEVICE )
    )u0_lane_lvds_1_10(
        .I_parallel_clk      ( I_parallel_clk      ),
        .I_parallel_2p5x_clk ( I_parallel_2p5x_clk ),
        .I_parallel_5x_clk   ( I_parallel_5x_clk   ),

        .I_rst               ( I_rst               ),

        .I_lvds_serial_in    ( I_hdmi_rx_ch0_p     ),

        .O_data              ( O_ch0_raw_data      )
    );


    lane_lvds_1_10  #(
        .DEVICE ( DEVICE )
    )u1_lane_lvds_1_10(
        .I_parallel_clk      ( I_parallel_clk      ),
        .I_parallel_2p5x_clk ( I_parallel_2p5x_clk ),
        .I_parallel_5x_clk   ( I_parallel_5x_clk   ),

        .I_rst               ( I_rst               ),

        .I_lvds_serial_in    ( I_hdmi_rx_ch1_p     ),

        .O_data              ( O_ch1_raw_data      )
    );

    lane_lvds_1_10  #(
        .DEVICE ( DEVICE )
    )u2_lane_lvds_1_10(
        .I_parallel_clk      ( I_parallel_clk      ),
        .I_parallel_2p5x_clk ( I_parallel_2p5x_clk ),
        .I_parallel_5x_clk   ( I_parallel_5x_clk   ),

        .I_rst               ( I_rst               ),

        .I_lvds_serial_in    ( I_hdmi_rx_ch2_p     ),

        .O_data              ( O_ch2_raw_data      )
    );
endmodule