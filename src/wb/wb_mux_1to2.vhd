library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_mux_1to2 is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    sel : in std_logic;

    s_cyc  : in std_logic;
    s_stb  : in std_logic;
    s_adr  : in std_logic_vector(31 downto 0);
    s_we   : in std_logic;
    s_sel  : in std_logic_vector(3 downto 0);
    s_din  : in std_logic_vector(31 downto 0);
    s_dout : out std_logic_vector(31 downto 0);
    s_ack  : out std_logic;

    m0_cyc  : out std_logic;
    m0_stb  : out std_logic;
    m0_adr  : out std_logic_vector(31 downto 0);
    m0_we   : out std_logic;
    m0_sel  : out std_logic_vector(3 downto 0);
    m0_dout : out std_logic_vector(31 downto 0);
    m0_din  : in std_logic_vector(31 downto 0);
    m0_ack  : in std_logic;

    m1_cyc  : out std_logic;
    m1_stb  : out std_logic;
    m1_adr  : out std_logic_vector(31 downto 0);
    m1_we   : out std_logic;
    m1_sel  : out std_logic_vector(3 downto 0);
    m1_dout : out std_logic_vector(31 downto 0);
    m1_din  : in std_logic_vector(31 downto 0);
    m1_ack  : in std_logic
  );
end entity wb_mux_1to2;

architecture rtl of wb_mux_1to2 is

begin

  m0_adr  <= s_adr;
  m0_we   <= s_we;
  m0_sel  <= s_sel;
  m0_dout <= s_din;

  m1_adr  <= s_adr;
  m1_we   <= s_we;
  m1_sel  <= s_sel;
  m1_dout <= s_din;

  m0_cyc <= not(sel) and s_cyc;
  m0_stb <= not(sel) and s_stb;

  m1_cyc <= sel and s_cyc;
  m1_stb <= sel and s_stb;

  PROC_COMB : process (sel, m0_ack, m0_din, m1_ack, m1_din)
  begin
    if sel = '0' then
      s_ack  <= m0_ack;
      s_dout <= m0_din;
    else
      s_ack  <= m1_ack;
      s_dout <= m1_din;
    end if;
  end process;

end architecture;