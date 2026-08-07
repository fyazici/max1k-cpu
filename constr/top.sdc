#create input clock which is 12MHz
create_clock -name CLK12M -period 83.333 [get_ports {CLK12M}]
create_clock -name SDRAM_CLK -period 10.416 [get_ports {SDRAM_CLK}]

#derive PLL clocks
derive_pll_clocks

#derive clock uncertainty
derive_clock_uncertainty

#set false path
set_false_path -from [get_ports {USER_BTN}]
set_false_path -from [get_ports {LED*}]
set_false_path -to [get_ports {LED*}]
set_false_path -from [get_ports {FT2232H_TX}]
set_false_path -to [get_ports {FT2232H_RX}]
