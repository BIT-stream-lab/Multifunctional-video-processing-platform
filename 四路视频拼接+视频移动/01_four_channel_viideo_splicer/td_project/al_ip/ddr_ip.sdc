# Reference
#create_clock -name ddr_ref_clk -period 10 -waveform {0 5} [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk}]
derive_pll_clocks

# PLL0
rename_clock -name ref_clk -source [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk}] -master_clock {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk} [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.clkc[0]}]
rename_clock -name ctl_clk -source [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk}] -master_clock {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk} [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.clkc[1]}]
rename_clock -name ddr_clk -source [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk}] -master_clock {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk} [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.clkc[2]}]
rename_clock -name mcu_clk -source [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk}] -master_clock {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.refclk} [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.clkc[3]}]

# PLL1
rename_clock -name usr_clk -source [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll0/pll_inst.clkc[0]}] -master_clock [get_clocks {ref_clk}] [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll1/pll_inst.clkc[0]}]

# 1st stage BUFG
create_generated_clock -name fbk_clk -source [get_pins {u_ph1_logic_standard_phy/u_clk/u_pll1/pll_inst.clkc[0]}] -master_clock [get_clocks {usr_clk}] -divide_by 1 [get_nets {u_ph1_logic_standard_phy/u_clk/hctrl_clk_int}]
# 2st stage BUFG
create_generated_clock -name dfi_clk -source [get_nets {u_ph1_logic_standard_phy/u_clk/hctrl_clk_int}]           -master_clock [get_clocks {fbk_clk}] -divide_by 1 [get_nets {u_ph1_logic_standard_phy/u_clk/hctrl_clk_bufg}]

set_clock_groups -asynchronous -group [get_clocks mcu_clk]

###################################################################################################
# Exception Constraint for Bus Matrix
set_false_path -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_phy_loopback_en[*]}]

set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_chain_en}]     -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_en}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_div[*]}]       -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_div[*]}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_wrlvl_sel[*]}] -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_wrlvl_sel[*]}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_wdata_sel[*]}] -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_wdq_sel[*]}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_testmode_en}]      -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_testmode_en}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.loopback_clk_sel[*]}]    -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_loopback_clk_sel[*]}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.loopback_clknum_sel[*]}] -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_loopback_clknum_sel[*]}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.loopback_mode}]          -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_loopback_mode}] 2
set_multicycle_path -setup -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.dqs_pupd_en}]            -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_dqs_pupd_en}] 2

set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_chain_en}]     -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_en}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_div[*]}]       -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_div[*]}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_wrlvl_sel[*]}] -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_wrlvl_sel[*]}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_osc_wdata_sel[*]}] -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_osc_wdq_sel[*]}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.delay_testmode_en}]      -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_delay_testmode_en}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.loopback_clk_sel[*]}]    -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_loopback_clk_sel[*]}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.loopback_clknum_sel[*]}] -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_loopback_clknum_sel[*]}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.loopback_mode}]          -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_loopback_mode}] 1
set_multicycle_path -hold  -end -from [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_hard_controller_*.dqs_pupd_en}]            -to [get_pins {u_ph1_logic_standard_phy/u_ddrphy_standard/u_ddrphy/ddr_phy_4lanes_*$ph1_ddr_4lanes.*_dqs_pupd_en}] 1

###################################################################################################
# sclk for each sector
create_generated_clock -name sclk0 -source [get_nets {u_ph1_logic_standard_phy/u_clk/hctrl_clk_bufg}] -master_clock [get_clocks {dfi_clk}] -divide_by 1 [get_pins {u_ph1_logic_standard_phy/u_clk/gen_bank31_hctrl_clk$u_bank31_hctrl_clk.clkout}]
create_generated_clock -name sclk1 -source [get_nets {u_ph1_logic_standard_phy/u_clk/hctrl_clk_bufg}] -master_clock [get_clocks {dfi_clk}] -divide_by 1 [get_pins {u_ph1_logic_standard_phy/u_clk/gen_bank32_hctrl_clk$u_bank32_hctrl_clk.clkout}]

