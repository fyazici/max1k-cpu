library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cpu_pkg.all;

entity immext is
  port (
    instr : in std_logic_vector(31 downto 0);
    sel   : in std_logic_vector(2 downto 0);

    imm : out std_logic_vector(31 downto 0)
  );
end entity immext;

architecture rtl of immext is
  signal imm_i, imm_s, imm_b, imm_u, imm_j : std_logic_vector(31 downto 0);
begin

  imm_i <= std_logic_vector(resize(signed(instr(31 downto 20)), 32));
  imm_s <= std_logic_vector(resize(signed(instr(31 downto 25) & instr(11 downto 7)), 32));
  imm_b <= std_logic_vector(resize(signed(instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & "0"), 32));
  imm_u <= instr(31 downto 12) & x"000";
  imm_j <= std_logic_vector(resize(signed(instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & "0"), 32));

  PROC_COMB : process (all)
  begin
    case (sel) is
      when ISEL_I => imm <= imm_i;
      when ISEL_S => imm <= imm_s;
      when ISEL_B => imm <= imm_b;
      when ISEL_U => imm <= imm_u;
      when ISEL_J => imm <= imm_j;
      when others => imm <= (others => 'X');
    end case;
  end process;

end architecture;