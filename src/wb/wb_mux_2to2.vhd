library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_mux_2to2 is
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
end entity wb_mux_2to2;

architecture rtl of wb_mux_2to2 is

  signal i_cyc  : std_logic;
  signal i_stb  : std_logic;
  signal i_adr  : std_logic_vector(31 downto 0);
  signal i_we   : std_logic;
  signal i_sel  : std_logic_vector(3 downto 0);
  signal i_dout : std_logic_vector(31 downto 0);
  signal i_din  : std_logic_vector(31 downto 0);
  signal i_ack  : std_logic;

  signal e_cyc  : std_logic;
  signal e_stb  : std_logic;
  signal e_adr  : std_logic_vector(31 downto 0);
  signal e_we   : std_logic;
  signal e_sel  : std_logic_vector(3 downto 0);
  signal e_dout : std_logic_vector(31 downto 0);
  signal e_din  : std_logic_vector(31 downto 0);
  signal e_ack  : std_logic;

begin

  U_INGRESS : entity work.wb_mux_2to1
    port map
    (
      clk   => clk,
      reset => reset,

      s0_cyc  => s0_cyc,
      s0_stb  => s0_stb,
      s0_adr  => s0_adr,
      s0_we   => s0_we,
      s0_sel  => s0_sel,
      s0_din  => s0_din,
      s0_dout => s0_dout,
      s0_ack  => s0_ack,

      s1_cyc  => s1_cyc,
      s1_stb  => s1_stb,
      s1_adr  => s1_adr,
      s1_we   => s1_we,
      s1_sel  => s1_sel,
      s1_din  => s1_din,
      s1_dout => s1_dout,
      s1_ack  => s1_ack,

      m_cyc  => i_cyc,
      m_stb  => i_stb,
      m_adr  => i_adr,
      m_we   => i_we,
      m_sel  => i_sel,
      m_dout => i_dout,
      m_din  => i_din,
      m_ack  => i_ack
    );

  U_REGSLICE : entity work.wb_regslice
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => i_cyc,
      s_stb  => i_stb,
      s_adr  => i_adr,
      s_we   => i_we,
      s_sel  => i_sel,
      s_din  => i_dout,
      s_dout => i_din,
      s_ack  => i_ack,

      m_cyc  => e_cyc,
      m_stb  => e_stb,
      m_adr  => e_adr,
      m_we   => e_we,
      m_sel  => e_sel,
      m_dout => e_dout,
      m_din  => e_din,
      m_ack  => e_ack
    );

  U_EGRESS : entity work.wb_mux_1to2
    port map
    (
      clk   => clk,
      reset => reset,

      sel => e_adr(31),

      s_cyc  => e_cyc,
      s_stb  => e_stb,
      s_adr  => e_adr,
      s_we   => e_we,
      s_sel  => e_sel,
      s_din  => e_dout,
      s_dout => e_din,
      s_ack  => e_ack,

      m0_cyc  => m0_cyc,
      m0_stb  => m0_stb,
      m0_adr  => m0_adr,
      m0_we   => m0_we,
      m0_sel  => m0_sel,
      m0_dout => m0_dout,
      m0_din  => m0_din,
      m0_ack  => m0_ack,

      m1_cyc  => m1_cyc,
      m1_stb  => m1_stb,
      m1_adr  => m1_adr,
      m1_we   => m1_we,
      m1_sel  => m1_sel,
      m1_dout => m1_dout,
      m1_din  => m1_din,
      m1_ack  => m1_ack
    );

end architecture;