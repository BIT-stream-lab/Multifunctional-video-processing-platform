create_clock -name {sys_clk_25m} -period 40.000 -waveform {0.000 20.000} [get_ports {I_sys_clk}]
derive_clocks
set_clock_groups -asynchronous -group [get_clocks {sys_clk_25m}] -group [get_clocks {u_pll/pll_inst.clkc[0]}] -group [get_clocks {u_uifdma_axi_ddr/u_ddr_phy/dfi_clk}] -group [get_clocks {u_pll/pll_inst.clkc[1]}]
