library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cpu_pkg.all;

entity bcond is
  port (
    rs1 : in std_logic_vector(31 downto 0);
    rs2 : in std_logic_vector(31 downto 0);
    sel : in std_logic_vector(2 downto 0);

    cond : out std_logic
  );
end entity bcond;

architecture rtl of bcond is

  signal eq_c, lt_c, ltu_c : std_logic;

begin

  eq_c <= '1' when (rs1 = rs2) else
    '0';
  lt_c <= '1' when (signed(rs1) < signed(rs2)) else
    '0';
  ltu_c <= '1' when (unsigned(rs1) < unsigned(rs2)) else
    '0';

  PROC_COMB : process (all)
  begin
    case (sel) is
      when BEQ    => cond    <= eq_c;
      when BNE    => cond    <= not(eq_c);
      when BLT    => cond    <= lt_c;
      when BGE    => cond    <= not(lt_c);
      when BLTU   => cond   <= ltu_c;
      when BGEU   => cond   <= not(ltu_c);
      when others => cond <= 'X';
    end case;
  end process;

end architecture;