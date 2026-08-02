library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_mux_2to1 is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s0_cyc  : in std_logic;
    s0_stb  : in std_logic;
    s0_adr  : in std_logic_vector(31 downto 0);
    s0_we   : in std_logic;
    s0_sel  : in std_logic_vector(3 downto 0);
    s0_din  : in std_logic_vector(31 downto 0);
    s0_dout : out std_logic_vector(31 downto 0);
    s0_ack  : out std_logic;

    s1_cyc  : in std_logic;
    s1_stb  : in std_logic;
    s1_adr  : in std_logic_vector(31 downto 0);
    s1_we   : in std_logic;
    s1_sel  : in std_logic_vector(3 downto 0);
    s1_din  : in std_logic_vector(31 downto 0);
    s1_dout : out std_logic_vector(31 downto 0);
    s1_ack  : out std_logic;

    m_cyc  : out std_logic;
    m_stb  : out std_logic;
    m_adr  : out std_logic_vector(31 downto 0);
    m_we   : out std_logic;
    m_sel  : out std_logic_vector(3 downto 0);
    m_dout : out std_logic_vector(31 downto 0);
    m_din  : in std_logic_vector(31 downto 0);
    m_ack  : in std_logic
  );
end entity wb_mux_2to1;

architecture rtl of wb_mux_2to1 is

  signal sel    : std_logic := '0';
  signal toggle : std_logic := '0';

begin

  PROC_COMB : process (all)
    variable req : std_logic_vector(1 downto 0);
  begin
    req := s1_cyc & s0_cyc;
    case (req) is
      when "00" =>
        sel <= '0';
      when "01" =>
        sel <= '0';
      when "10" =>
        sel <= '1';
      when "11" =>
        sel <= toggle; -- round robin
      when others =>
        null;
    end case;

    if sel = '0' then
      m_cyc  <= s0_cyc;
      m_stb  <= s0_stb;
      m_adr  <= s0_adr;
      m_we   <= s0_we;
      m_sel  <= s0_sel;
      m_dout <= s0_din;
    else
      m_cyc  <= s1_cyc;
      m_stb  <= s1_stb;
      m_adr  <= s1_adr;
      m_we   <= s1_we;
      m_sel  <= s1_sel;
      m_dout <= s1_din;
    end if;

    s0_dout <= m_din;
    s1_dout <= m_din;

    s0_ack <= not(sel) and m_ack;
    s1_ack <= sel and m_ack;

  end process;

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if sel = '0' and m_ack = '1' then
        toggle <= '1';
      end if;
      if sel = '1' and m_ack = '1' then
        toggle <= '0';
      end if;
    end if;
  end process;

end architecture;