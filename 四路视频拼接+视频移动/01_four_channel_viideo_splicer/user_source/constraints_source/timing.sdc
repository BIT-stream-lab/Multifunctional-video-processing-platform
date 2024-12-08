create_clock -name {sys_clk_25m} -period 40.000 -waveform {0.000 20.000} [get_ports {I_sys_clk}]
derive_pll_clocks