library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity regce is
  generic (
    G_DW : natural := 32
  );
  port (
    clk  : in std_logic;
    ce   : in std_logic;
    sclr : in std_logic;
    d    : in std_logic_vector(G_DW - 1 downto 0);
    q    : out std_logic_vector(G_DW - 1 downto 0)
  );
end entity regce;

architecture rtl of regce is

begin

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if ce = '1' then
        if sclr = '1' then
          q <= (others => '0');
        else
          q <= d;
        end if;
      end if;
    end if;
  end process;

end architecture;