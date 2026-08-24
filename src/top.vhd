library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
  port (
    CLK12M     : in std_logic;
    LED        : inout std_logic_vector(7 downto 0);
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
      locked : out std_logic
    );
  end component;

  signal clk       : std_logic;
  signal locked    : std_logic;
  signal reset     : std_logic := '1';
  signal reset_ctr : natural   := 1000;

  -- instruction memory intf
  signal wb_ibus_adr : std_logic_vector(31 downto 0);
  signal wb_ibus_din : std_logic_vector(31 downto 0);
  signal wb_ibus_stb : std_logic;
  signal wb_ibus_cyc : std_logic;
  signal wb_ibus_ack : std_logic;

  -- data memory intf
  signal wb_dbus_adr  : std_logic_vector(31 downto 0);
  signal wb_dbus_din  : std_logic_vector(31 downto 0);
  signal wb_dbus_dout : std_logic_vector(31 downto 0);
  signal wb_dbus_we   : std_logic;
  signal wb_dbus_sel  : std_logic_vector(3 downto 0);
  signal wb_dbus_stb  : std_logic;
  signal wb_dbus_cyc  : std_logic;
  signal wb_dbus_ack  : std_logic;

  -- memory intf
  signal wb_mem_adr  : std_logic_vector(31 downto 0);
  signal wb_mem_din  : std_logic_vector(31 downto 0);
  signal wb_mem_dout : std_logic_vector(31 downto 0);
  signal wb_mem_we   : std_logic;
  signal wb_mem_sel  : std_logic_vector(3 downto 0);
  signal wb_mem_stb  : std_logic;
  signal wb_mem_cyc  : std_logic;
  signal wb_mem_ack  : std_logic;

  -- periph intf
  signal wb_periph_adr  : std_logic_vector(31 downto 0);
  signal wb_periph_din  : std_logic_vector(31 downto 0);
  signal wb_periph_dout : std_logic_vector(31 downto 0);
  signal wb_periph_we   : std_logic;
  signal wb_periph_sel  : std_logic_vector(3 downto 0);
  signal wb_periph_stb  : std_logic;
  signal wb_periph_cyc  : std_logic;
  signal wb_periph_ack  : std_logic;

  -- periph intf regslice
  signal wb_periph_adr_r  : std_logic_vector(31 downto 0);
  signal wb_periph_din_r  : std_logic_vector(31 downto 0);
  signal wb_periph_dout_r : std_logic_vector(31 downto 0);
  signal wb_periph_we_r   : std_logic;
  signal wb_periph_sel_r  : std_logic_vector(3 downto 0);
  signal wb_periph_stb_r  : std_logic;
  signal wb_periph_cyc_r  : std_logic;
  signal wb_periph_ack_r  : std_logic;

  -- gpio intf
  signal wb_gpio0_adr  : std_logic_vector(31 downto 0);
  signal wb_gpio0_din  : std_logic_vector(31 downto 0);
  signal wb_gpio0_dout : std_logic_vector(31 downto 0);
  signal wb_gpio0_we   : std_logic;
  signal wb_gpio0_sel  : std_logic_vector(3 downto 0);
  signal wb_gpio0_stb  : std_logic;
  signal wb_gpio0_cyc  : std_logic;
  signal wb_gpio0_ack  : std_logic;

  -- uart intf
  signal wb_uart0_adr  : std_logic_vector(31 downto 0);
  signal wb_uart0_din  : std_logic_vector(31 downto 0);
  signal wb_uart0_dout : std_logic_vector(31 downto 0);
  signal wb_uart0_we   : std_logic;
  signal wb_uart0_sel  : std_logic_vector(3 downto 0);
  signal wb_uart0_stb  : std_logic;
  signal wb_uart0_cyc  : std_logic;
  signal wb_uart0_ack  : std_logic;

  -- gpio
  signal gpio0_i : std_logic_vector(31 downto 0) := (others => '0');
  signal gpio0_o : std_logic_vector(31 downto 0);
  signal gpio0_t : std_logic_vector(31 downto 0);

begin

  GEN_GPIO0 : for I in 0 to 7 generate
    led(I) <= gpio0_o(I) when (gpio0_t(I) = '0') else
    'Z';
    gpio0_i(I) <= led(I);
  end generate;

  U_PLL1 : pll1
  port map
  (
    inclk0 => CLK12M,
    c0     => clk,
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
      i_adr => wb_ibus_adr,
      i_din => wb_ibus_din,
      i_stb => wb_ibus_stb,
      i_cyc => wb_ibus_cyc,
      i_ack => wb_ibus_ack,

      -- data memory intf
      d_adr  => wb_dbus_adr,
      d_din  => wb_dbus_din,
      d_dout => wb_dbus_dout,
      d_we   => wb_dbus_we,
      d_sel  => wb_dbus_sel,
      d_stb  => wb_dbus_stb,
      d_cyc  => wb_dbus_cyc,
      d_ack  => wb_dbus_ack
    );

  U_WBMUX : entity work.wb_mux_2to2
    port map
    (
      clk   => clk,
      reset => reset,

      -- 0x0000_0000 4G
      s0_cyc  => wb_ibus_cyc,
      s0_stb  => wb_ibus_stb,
      s0_adr  => wb_ibus_adr,
      s0_we   => '0',
      s0_sel => (others => '0'),
      s0_din => (others => '0'),
      s0_dout => wb_ibus_din,
      s0_ack  => wb_ibus_ack,

      -- 0x0000_0000 4G
      s1_cyc  => wb_dbus_cyc,
      s1_stb  => wb_dbus_stb,
      s1_adr  => wb_dbus_adr,
      s1_we   => wb_dbus_we,
      s1_sel  => wb_dbus_sel,
      s1_din  => wb_dbus_dout,
      s1_dout => wb_dbus_din,
      s1_ack  => wb_dbus_ack,

      -- 0x0000_0000 2G
      m0_cyc  => wb_mem_cyc,
      m0_stb  => wb_mem_stb,
      m0_adr  => wb_mem_adr,
      m0_we   => wb_mem_we,
      m0_sel  => wb_mem_sel,
      m0_dout => wb_mem_dout,
      m0_din  => wb_mem_din,
      m0_ack  => wb_mem_ack,

      -- 0x8000_0000 2G
      m1_cyc  => wb_periph_cyc,
      m1_stb  => wb_periph_stb,
      m1_adr  => wb_periph_adr,
      m1_we   => wb_periph_we,
      m1_sel  => wb_periph_sel,
      m1_dout => wb_periph_dout,
      m1_din  => wb_periph_din,
      m1_ack  => wb_periph_ack
    );

  U_MEM : entity work.wb_mem
    generic map
    (
      G_AW        => 13,
      G_INIT_FILE => "D:\\Files\\max1k\\max1k-cpu\\tb\\sw\\main.mif"
    )
    port map
    (
      clk    => clk,
      s_adr  => wb_mem_adr,
      s_din  => wb_mem_dout,
      s_dout => wb_mem_din,
      s_we   => wb_mem_we,
      s_sel  => wb_mem_sel,
      s_stb  => wb_mem_stb,
      s_cyc  => wb_mem_cyc,
      s_ack  => wb_mem_ack
    );

  U_WBRS_PERIPH : entity work.wb_regslice
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_periph_cyc,
      s_stb  => wb_periph_stb,
      s_adr  => wb_periph_adr,
      s_we   => wb_periph_we,
      s_sel  => wb_periph_sel,
      s_din  => wb_periph_dout,
      s_dout => wb_periph_din,
      s_ack  => wb_periph_ack,

      m_cyc  => wb_periph_cyc_r,
      m_stb  => wb_periph_stb_r,
      m_adr  => wb_periph_adr_r,
      m_we   => wb_periph_we_r,
      m_sel  => wb_periph_sel_r,
      m_dout => wb_periph_dout_r,
      m_din  => wb_periph_din_r,
      m_ack  => wb_periph_ack_r
    );

  U_WBMUX_PERIPH : entity work.wb_mux_1to2
    port map
    (
      clk   => clk,
      reset => reset,

      sel => wb_periph_adr_r(30),

      -- 0x8000_0000 2G
      s_cyc  => wb_periph_cyc_r,
      s_stb  => wb_periph_stb_r,
      s_adr  => wb_periph_adr_r,
      s_we   => wb_periph_we_r,
      s_sel  => wb_periph_sel_r,
      s_din  => wb_periph_dout_r,
      s_dout => wb_periph_din_r,
      s_ack  => wb_periph_ack_r,

      -- 0x8000_0000 1G
      m0_cyc  => wb_gpio0_cyc,
      m0_stb  => wb_gpio0_stb,
      m0_adr  => wb_gpio0_adr,
      m0_we   => wb_gpio0_we,
      m0_sel  => wb_gpio0_sel,
      m0_dout => wb_gpio0_dout,
      m0_din  => wb_gpio0_din,
      m0_ack  => wb_gpio0_ack,

      -- 0xC000_0000 1G
      m1_cyc  => wb_uart0_cyc,
      m1_stb  => wb_uart0_stb,
      m1_adr  => wb_uart0_adr,
      m1_we   => wb_uart0_we,
      m1_sel  => wb_uart0_sel,
      m1_dout => wb_uart0_dout,
      m1_din  => wb_uart0_din,
      m1_ack  => wb_uart0_ack
    );

  U_GPIO0 : entity work.wb_gpio
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_gpio0_cyc,
      s_stb  => wb_gpio0_stb,
      s_adr  => wb_gpio0_adr,
      s_we   => wb_gpio0_we,
      s_sel  => wb_gpio0_sel,
      s_din  => wb_gpio0_dout,
      s_dout => wb_gpio0_din,
      s_ack  => wb_gpio0_ack,

      gpio_i => gpio0_i,
      gpio_o => gpio0_o,
      gpio_t => gpio0_t
    );

  U_UART0 : entity work.wb_uart
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_uart0_cyc,
      s_stb  => wb_uart0_stb,
      s_adr  => wb_uart0_adr,
      s_we   => wb_uart0_we,
      s_sel  => wb_uart0_sel,
      s_din  => wb_uart0_dout,
      s_dout => wb_uart0_din,
      s_ack  => wb_uart0_ack,

      uart_rx => FT2232H_TX,
      uart_tx => FT2232H_RX
    );

end architecture;