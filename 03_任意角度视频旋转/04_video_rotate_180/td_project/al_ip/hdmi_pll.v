/************************************************************\
 **     Copyright (c) 2012-2023 Anlogic Inc.
 **  All Right Reserved.\
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	C:/HIT/personal_learn/FPGA_compete/prj/cascade/second_card_rotate/user_source/ip_source/hdmi_pll.v
 ** Date	:	2024 11 17
 ** TD version	:	5.6.88061
\************************************************************/

///////////////////////////////////////////////////////////////////////////////
//	Input frequency:               75.000000MHz
//	Clock multiplication factor: 1
//	Clock division factor:       1
//	Clock information:
//		Clock name	| Frequency 	| Phase shift
//		C0        	| 75.000000 MHZ	| 0.0000  DEG  
//		C1        	| 187.500000MHZ	| 0.0000  DEG  
//		C2        	| 375.000000MHZ	| 90.0000 DEG  
//		C3        	| 75.000000 MHZ	| 0.0000  DEG  
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 fs

module hdmi_pll (
  refclk,
  reset,
  lock,
  clk0_out,
  clk1_out,
  clk2_out,
  clk3_out 
);

  input refclk;
  input reset;
  output lock;
  output clk0_out;
  output clk1_out;
  output clk2_out;
  output clk3_out;

  wire clk0_buf;

  PH1_LOGIC_BUFG bufg_feedback (
    .i(clk0_buf),
    .o(clk0_out) 
  );

  PH1_PHY_PLL #(
    .DYN_PHASE_PATH_SEL("DISABLE"),
    .DYN_FPHASE_EN("DISABLE"),
    .MPHASE_ENABLE("ENABLE"),
    .FIN("75.000000"),
    .FEEDBK_MODE("NORMAL"),
    .FBKCLK("CLKC0_EXT"),
    .PLL_FEED_TYPE("EXTERNAL"),
    .PLL_USR_RST("ENABLE"),
    .GMC_GAIN(2),
    .ICP_CUR(12),
    .LPF_CAP(2),
    .LPF_RES(2),
    .REFCLK_DIV(1),
    .FBCLK_DIV(1),
    .CLKC0_ENABLE("ENABLE"),
    .CLKC0_DIV(15),
    .CLKC0_CPHASE(14),
    .CLKC0_FPHASE(0),
    .CLKC0_FPHASE_RSTSEL(0),
    .CLKC0_DUTY_INT(8),
    .CLKC0_DUTY50("ENABLE"),
    .CLKC1_ENABLE("ENABLE"),
    .CLKC1_DIV(6),
    .CLKC1_CPHASE(5),
    .CLKC1_FPHASE(0),
    .CLKC1_FPHASE_RSTSEL(0),
    .CLKC1_DUTY_INT(3),
    .CLKC1_DUTY50("ENABLE"),
    .CLKC2_ENABLE("ENABLE"),
    .CLKC2_DIV(3),
    .CLKC2_CPHASE(2),
    .CLKC2_FPHASE(6),
    .CLKC2_FPHASE_RSTSEL(1),
    .CLKC2_DUTY_INT(2),
    .CLKC2_DUTY50("ENABLE"),
    .CLKC3_ENABLE("ENABLE"),
    .CLKC3_DIV(15),
    .CLKC3_CPHASE(14),
    .CLKC3_FPHASE(0),
    .CLKC3_FPHASE_RSTSEL(0),
    .CLKC3_DUTY_INT(8),
    .CLKC3_DUTY50("ENABLE"),
    .INTPI(1),
    .HIGH_SPEED_EN("DISABLE"),
    .SSC_ENABLE("DISABLE"),
    .SSC_MODE("CENTER"),
    .SSC_AMP(0.0000),
    .SSC_FREQ_DIV(0),
    .SSC_RNGE(0),
    .FRAC_ENABLE("DISABLE"),
    .DITHER_ENABLE("DISABLE"),
    .SDM_FRAC(0) 
  ) pll_inst (
    .refclk(refclk),
    .pllreset(reset),
    .lock(lock),
    .pllpd(1'b0),
    .refclk_rst(1'b0),
    .wakeup(1'b0),
    .psclk(1'b0),
    .psdown(1'b0),
    .psstep(1'b0),
    .psclksel(3'b000),
    .psdone(open),
    .cps_step(2'b00),
    .drp_clk(1'b0),
    .drp_rstn(1'b1),
    .drp_sel(1'b0),
    .drp_rd(1'b0),
    .drp_wr(1'b0),
    .drp_addr(8'b00000000),
    .drp_wdata(8'b00000000),
    .drp_err(open),
    .drp_rdy(open),
    .drp_rdata({open, open, open, open, open, open, open, open}),
    .fbclk(clk0_out),
    .clkc({open, open, open, open, clk3_out, clk2_out, clk1_out, clk0_buf}),
    .clkcb({open, open, open, open, open, open, open, open}),
    .clkc_en({8'b00001111}),
    .clkc_rst(2'b00),
    .ext_freq_mod_clk(1'b0),
    .ext_freq_mod_en(1'b0),
    .ext_freq_mod_val(17'b00000000000000000),
    .ssc_en(1'b0) 
  );

endmodule

