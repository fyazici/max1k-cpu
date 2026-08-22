library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity counter64 is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    ce    : in std_logic;
    ql    : out std_logic_vector(31 downto 0);
    qh    : out std_logic_vector(31 downto 0)
  );
end entity counter64;

architecture rtl of counter64 is

  signal ctr_l : unsigned(31 downto 0) := (others => '0');
  signal ctr_h : unsigned(31 downto 0) := (others => '0');

begin

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        ctr_l <= (others => '0');
        ctr_h <= (others => '0');
      else
        if ce = '1' then
          ctr_l <= ctr_l + 1;
          -- pipelined lookahead carry into high word
          if ctr_l = x"FFFFFFFE" then
            ctr_h <= ctr_h + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  ql <= std_logic_vector(ctr_l);
  qh <= std_logic_vector(ctr_h);

end architecture;