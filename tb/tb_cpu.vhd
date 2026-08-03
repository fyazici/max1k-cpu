library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_cpu is
end entity tb_cpu;

architecture rtl of tb_cpu is
  signal CLK12M : std_logic := '0';
  signal LED    : std_logic_vector(7 downto 0);
begin

  CLK12M <= not(CLK12M) after 41.667 ns;

  uut : entity work.top
    port map
    (
      CLK12M     => CLK12M,
      LED        => LED,
      USER_BTN   => '0',
      SDRAM_A    => open,
      SDRAM_BA   => open,
      SDRAM_CLK  => open,
      SDRAM_CKE  => open,
      SDRAM_CAS  => open,
      SDRAM_CS   => open,
      SDRAM_RAS  => open,
      SDRAM_WE   => open,
      SDRAM_DQM  => open,
      SDRAM_DQ   => open,
      FT2232H_RX => open,
      FT2232H_TX => '1'
    );

end architecture;