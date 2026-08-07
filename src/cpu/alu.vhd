library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cpu_pkg.all;

entity alu is
  port (
    clk   : in std_logic;
    op    : in std_logic_vector(3 downto 0);
    shamt : in std_logic_vector(4 downto 0);
    x     : in std_logic_vector(31 downto 0);
    y     : in std_logic_vector(31 downto 0);
    z     : out std_logic_vector(31 downto 0)
  );
end entity alu;

architecture rtl of alu is

begin

  PROC_COMB : process (op, x, y, shamt)
  begin
    z <= (others => 'X');
    case (op) is
      when ALUOP_ADD =>
        z <= std_logic_vector(signed(x) + signed(y));
      when ALUOP_SUB =>
        z <= std_logic_vector(signed(x) - signed(y));
      when ALUOP_SLL =>
        z <= std_logic_vector(shift_left(unsigned(x), to_integer(unsigned(shamt))));
      when ALUOP_SLT =>
        if signed(x) < signed(y) then
          z(0) <= '1';
        end if;
      when ALUOP_SLTU =>
        if unsigned(x) < unsigned(y) then
          z(0) <= '1';
        end if;
      when ALUOP_XOR =>
        z <= x xor y;
      when ALUOP_SRL =>
        z <= std_logic_vector(shift_right(unsigned(x), to_integer(unsigned(y(4 downto 0)))));
      when ALUOP_SRA =>
        z <= std_logic_vector(shift_right(signed(x), to_integer(unsigned(y(4 downto 0)))));
      when ALUOP_OR =>
        z <= x or y;
      when ALUOP_AND =>
        z <= x and y;
      when others =>
        null;
    end case;
  end process;

end architecture;