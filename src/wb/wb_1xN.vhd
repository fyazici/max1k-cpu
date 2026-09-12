library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.wb_pkg.all;

entity wb_1xN is
  generic (
    N        : natural;
    AW       : natural;
    DW       : natural;
    BASEADDR : t_slv_arr;
    HIGHADDR : t_slv_arr
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_cyc  : in std_logic;
    s_stb  : in std_logic;
    s_adr  : in std_logic_vector(AW - 1 downto 0);
    s_we   : in std_logic;
    s_sel  : in std_logic_vector(DW/8 - 1 downto 0);
    s_din  : in std_logic_vector(DW - 1 downto 0);
    s_dout : out std_logic_vector(DW - 1 downto 0);
    s_ack  : out std_logic;

    m_cyc  : out std_logic_vector(N - 1 downto 0);
    m_stb  : out std_logic_vector(N - 1 downto 0);
    m_adr  : out t_slv_arr(N - 1 downto 0)(AW - 1 downto 0);
    m_we   : out std_logic_vector(N - 1 downto 0);
    m_sel  : out t_slv_arr(N - 1 downto 0)(DW/8 - 1 downto 0);
    m_dout : out t_slv_arr(N - 1 downto 0)(DW - 1 downto 0);
    m_din  : in t_slv_arr(N - 1 downto 0)(DW - 1 downto 0);
    m_ack  : in std_logic_vector(N - 1 downto 0)
  );
end entity wb_1xN;

architecture rtl of wb_1xN is

  signal sel : natural range 0 to N - 1;

begin

  PROC_SEL : process (all)
    variable base_cond, high_cond : boolean;
  begin
    sel <= 0; -- default if not matched
    for I in N - 1 downto 0 loop
      base_cond := unsigned(s_adr) >= unsigned(BASEADDR(I));
      high_cond := unsigned(s_adr) <= unsigned(HIGHADDR(I));
      if base_cond and high_cond then
        sel <= I;
      end if;
    end loop;
  end process;

  PROC_COMB : process (all)
  begin
    m_cyc      <= (others => '0');
    m_stb      <= (others => '0');
    m_cyc(sel) <= s_cyc;
    m_stb(sel) <= s_stb;

    for I in 0 to N - 1 loop
      m_adr(I)  <= s_adr;
      m_we(I)   <= s_we;
      m_sel(I)  <= s_sel;
      m_dout(I) <= s_din;
    end loop;

    s_ack  <= m_ack(sel);
    s_dout <= m_din(sel);
  end process;

end architecture;