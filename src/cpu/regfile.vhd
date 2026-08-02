library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity regfile is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    rd_sel : in std_logic_vector(4 downto 0);
    rd_din : in std_logic_vector(31 downto 0);
    rd_we  : in std_logic;

    rs1_sel  : in std_logic_vector(4 downto 0);
    rs1_dout : out std_logic_vector(31 downto 0);

    rs2_sel  : in std_logic_vector(4 downto 0);
    rs2_dout : out std_logic_vector(31 downto 0)
  );
end entity regfile;

architecture rtl of regfile is

  type t_regs is array (31 downto 0) of std_logic_vector(31 downto 0);
  signal regs : t_regs := (others => (others => '0'));

begin

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        regs <= (others => (others => '0'));
      else
        if rd_we = '1' then
          regs(to_integer(unsigned(rd_sel))) <= rd_din;
        end if;

        rs1_dout <= regs(to_integer(unsigned(rs1_sel)));
        rs2_dout <= regs(to_integer(unsigned(rs2_sel)));

        -- x0 is always 0
        regs(0) <= (others => '0');
      end if;
    end if;
  end process;

end architecture;