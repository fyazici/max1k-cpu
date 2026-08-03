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
  signal m0_adr  : std_logic_vector(31 downto 0);
  signal m0_din  : std_logic_vector(31 downto 0);
  signal m0_dout : std_logic_vector(31 downto 0);
  signal m0_we   : std_logic;
  signal m0_sel  : std_logic_vector(3 downto 0);
  signal m0_stb  : std_logic;
  signal m0_cyc  : std_logic;
  signal m0_ack  : std_logic;

  -- gpio intf
  signal m1_adr  : std_logic_vector(31 downto 0);
  signal m1_din  : std_logic_vector(31 downto 0);
  signal m1_dout : std_logic_vector(31 downto 0);
  signal m1_we   : std_logic;
  signal m1_sel  : std_logic_vector(3 downto 0);
  signal m1_stb  : std_logic;
  signal m1_cyc  : std_logic;
  signal m1_ack  : std_logic;

  signal io_i : std_logic_vector(31 downto 0);
  signal io_o : std_logic_vector(31 downto 0);
  signal io_t : std_logic_vector(31 downto 0);
begin

  led <= io_o(7 downto 0);

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

  U_CPU : entity work.cpu
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

  U_WBMUX : entity work.wb_mux_2to2
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

  U_MEM : entity work.wb_mem
    generic map(G_INIT_FILE => "D:\\Files\\max1k\\max1k-cpu\\tb\\sw\\main.mif")
    port map
    (
      clk    => clk,
      s_adr  => m0_adr,
      s_din  => m0_dout,
      s_dout => m0_din,
      s_we   => m0_we,
      s_sel  => m0_sel,
      s_stb  => m0_stb,
      s_cyc  => m0_cyc,
      s_ack  => m0_ack
    );

  U_GPIO : entity work.wb_gpio
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => m1_cyc,
      s_stb  => m1_stb,
      s_adr  => m1_adr,
      s_we   => m1_we,
      s_sel  => m1_sel,
      s_din  => m1_dout,
      s_dout => m1_din,
      s_ack  => m1_ack,

      io_i => io_i,
      io_o => io_o,
      io_t => io_t
    );

end architecture;