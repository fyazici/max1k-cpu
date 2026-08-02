library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
  port (
    CLK12M     : in std_logic;
    LED        : out std_logic_vector(7 downto 0);
    USER_BTN   : in std_logic;
    SDRAM_A    : out std_logic_vector(11 downto 0);
    SDRAM_BA   : out std_logic_vector(1 downto 0);
    SDRAM_CLK  : out std_logic;
    SDRAM_CKE  : out std_logic;
    SDRAM_CAS  : out std_logic;
    SDRAM_CS   : out std_logic;
    SDRAM_RAS  : out std_logic;
    SDRAM_WE   : out std_logic;
    SDRAM_DQM  : out std_logic_vector(1 downto 0);
    SDRAM_DQ   : inout std_logic_vector(15 downto 0);
    FT2232H_RX : out std_logic;
    FT2232H_TX : in std_logic
  );
end entity top;

architecture rtl of top is

  component pll1
    port (
      inclk0 : in std_logic := '0';
      c0     : out std_logic;
      c1     : out std_logic;
      locked : out std_logic
    );
  end component;

  signal clk       : std_logic;
  signal locked    : std_logic;
  signal reset     : std_logic := '1';
  signal reset_ctr : natural   := 1000;

  -- instruction memory intf
  signal i_adr : std_logic_vector(31 downto 0);
  signal i_din : std_logic_vector(31 downto 0);
  signal i_stb : std_logic;
  signal i_cyc : std_logic;
  signal i_ack : std_logic;

  -- data memory intf
  signal d_adr  : std_logic_vector(31 downto 0);
  signal d_din  : std_logic_vector(31 downto 0);
  signal d_dout : std_logic_vector(31 downto 0);
  signal d_we   : std_logic;
  signal d_sel  : std_logic_vector(3 downto 0);
  signal d_stb  : std_logic;
  signal d_cyc  : std_logic;
  signal d_ack  : std_logic;

  -- memory intf
  signal m_adr  : std_logic_vector(31 downto 0);
  signal m_din  : std_logic_vector(31 downto 0);
  signal m_dout : std_logic_vector(31 downto 0);
  signal m_we   : std_logic;
  signal m_sel  : std_logic_vector(3 downto 0);
  signal m_stb  : std_logic;
  signal m_cyc  : std_logic;
  signal m_ack  : std_logic;

begin

  led <= d_dout(7 downto 0);

  U_PLL1 : pll1
  port map
  (
    inclk0 => CLK12M,
    c0     => clk,
    c1     => open,
    locked => locked
  );

  PROC_RST : process (clk)
  begin
    if rising_edge(clk) then
      if locked = '1' then
        if reset_ctr > 0 then
          reset_ctr <= reset_ctr - 1;
        else
          reset <= '0';
        end if;
      else
        reset     <= '1';
        reset_ctr <= 1000;
      end if;
    end if;
  end process;

  uut : entity work.cpu
    generic map(G_RESET_VEC => x"00000000")
    port map
    (
      clk   => clk,
      reset => reset,

      -- instruction memory intf
      i_adr => i_adr,
      i_din => i_din,
      i_stb => i_stb,
      i_cyc => i_cyc,
      i_ack => i_ack,

      -- data memory intf
      d_adr  => d_adr,
      d_din  => d_din,
      d_dout => d_dout,
      d_we   => d_we,
      d_sel  => d_sel,
      d_stb  => d_stb,
      d_cyc  => d_cyc,
      d_ack  => d_ack
    );

  u_wbmux : entity work.wb_mux_2to1
    port map
    (
      clk   => clk,
      reset => reset,

      s0_cyc  => i_cyc,
      s0_stb  => i_stb,
      s0_adr  => i_adr,
      s0_we   => '0',
      s0_sel => (others => '0'),
      s0_din => (others => '0'),
      s0_dout => i_din,
      s0_ack  => i_ack,

      s1_cyc  => d_cyc,
      s1_stb  => d_stb,
      s1_adr  => d_adr,
      s1_we   => d_we,
      s1_sel  => d_sel,
      s1_din  => d_dout,
      s1_dout => d_din,
      s1_ack  => d_ack,

      m_cyc  => m_cyc,
      m_stb  => m_stb,
      m_adr  => m_adr,
      m_we   => m_we,
      m_sel  => m_sel,
      m_dout => m_dout,
      m_din  => m_din,
      m_ack  => m_ack
    );

  mem : entity work.mem
    generic map(G_INIT_FILE => "D:\\Files\\max1k\\max1k-cpu\\tb\\sw\\main.hex")
    port map
    (
      clk  => clk,
      adr  => m_adr,
      din  => m_dout,
      dout => m_din,
      we   => m_we,
      sel  => m_sel,
      stb  => m_stb,
      cyc  => m_cyc,
      ack  => m_ack
    );

end architecture;