create_clock -name {sys_clk_25m} -period 40.000 -waveform {0.000 20.000} [get_ports {I_sys_clk}]
create_clock -name {hdmi_rx_ck_lane_p} -period 13.468 -waveform {0.000 6.734} [get_ports {I_hdmi_rx_clk_p}]

derive_pll_clocks
set_clock_groups -asynchronous -group [get_clocks {sys_clk_25m}] -group [get_clocks {u_pll/pll_inst.clkc[0]}]  -group [get_clocks {u_pll/pll_inst.clkc[1]}] -group [get_clocks {hdmi_rx_ck_lane_p}] -group [get_clocks {u_hdmi_pll/pll_inst.clkc[3]}] -group [get_clocks {u_hdmi_pll/pll_inst.clkc[2]}]
