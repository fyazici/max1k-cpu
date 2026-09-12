#create input clock which is 12MHz
create_clock -name CLK12M -period 83.333 [get_ports {CLK12M}]

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


# FLASH
set pll_clk {U_PLL1|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -name FLASH_CLK -source [get_pins $pll_clk] -divide_by 2 [get_ports {FLASH_CLK}]

set_multicycle_path  -setup -start -to [get_ports {FLASH_DI}] 2
set_multicycle_path  -hold  -start -to [get_ports {FLASH_DI}] 1

set_multicycle_path  -setup -start -to [get_ports {FLASH_CS}] 3
set_multicycle_path  -hold  -start -to [get_ports {FLASH_CS}] 2

set_output_delay -clock FLASH_CLK -max 5.000 [get_ports {FLASH_CS}]
set_output_delay -clock FLASH_CLK -min -5.000 [get_ports {FLASH_CS}]

set_output_delay -clock FLASH_CLK -max 2.000 [get_ports {FLASH_DI}]
set_output_delay -clock FLASH_CLK -min -3.000 [get_ports {FLASH_DI}]

set_input_delay -clock FLASH_CLK -max 6.000 [get_ports {FLASH_DO}]
set_input_delay -clock FLASH_CLK -min 2.000 [get_ports {FLASH_DO}]

# SDRAM
set SDRAM_CLK {U_PLL1|altpll_component|auto_generated|pll1|clk[0]}

set_output_delay -clock $SDRAM_CLK -max  1.500 [get_ports {SDRAM_A* SDRAM_BA* SDRAM_CAS SDRAM_RAS SDRAM_WE SDRAM_DQM* SDRAM_DQ*}]
set_output_delay -clock $SDRAM_CLK -min -1.000 [get_ports {SDRAM_A* SDRAM_BA* SDRAM_CAS SDRAM_RAS SDRAM_WE SDRAM_DQM* SDRAM_DQ*}]

set_input_delay -clock $SDRAM_CLK -max 6.000 [get_ports {SDRAM_DQ*}]
set_input_delay -clock $SDRAM_CLK -min 3.000 [get_ports {SDRAM_DQ*}]

