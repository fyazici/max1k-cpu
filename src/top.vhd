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
    FLASH_CLK  : out std_logic;
    FLASH_CS   : out std_logic;
    FLASH_HOLD : out std_logic;
    FLASH_WP   : out std_logic;
    FLASH_DI   : out std_logic;
    FLASH_DO   : in std_logic;
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

  -- boot controller intf
  signal cpu_reset    : std_logic;
  signal wb_boot_adr  : std_logic_vector(31 downto 0);
  signal wb_boot_din  : std_logic_vector(31 downto 0);
  signal wb_boot_dout : std_logic_vector(31 downto 0);
  signal wb_boot_we   : std_logic;
  signal wb_boot_sel  : std_logic_vector(3 downto 0);
  signal wb_boot_stb  : std_logic;
  signal wb_boot_cyc  : std_logic;
  signal wb_boot_ack  : std_logic;

  -- instruction memory intf
  signal wb_ibus_adr  : std_logic_vector(31 downto 0);
  signal wb_ibus_din  : std_logic_vector(31 downto 0);
  signal wb_ibus_dout : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_ibus_we   : std_logic                     := '0';
  signal wb_ibus_sel  : std_logic_vector(3 downto 0)  := (others => '0');
  signal wb_ibus_stb  : std_logic;
  signal wb_ibus_cyc  : std_logic;
  signal wb_ibus_ack  : std_logic;

  -- data memory intf
  signal wb_dbus_adr  : std_logic_vector(31 downto 0);
  signal wb_dbus_din  : std_logic_vector(31 downto 0);
  signal wb_dbus_dout : std_logic_vector(31 downto 0);
  signal wb_dbus_we   : std_logic;
  signal wb_dbus_sel  : std_logic_vector(3 downto 0);
  signal wb_dbus_stb  : std_logic;
  signal wb_dbus_cyc  : std_logic;
  signal wb_dbus_ack  : std_logic;

  signal wb_dbus_adr_r  : std_logic_vector(31 downto 0);
  signal wb_dbus_din_r  : std_logic_vector(31 downto 0);
  signal wb_dbus_dout_r : std_logic_vector(31 downto 0);
  signal wb_dbus_we_r   : std_logic;
  signal wb_dbus_sel_r  : std_logic_vector(3 downto 0);
  signal wb_dbus_stb_r  : std_logic;
  signal wb_dbus_cyc_r  : std_logic;
  signal wb_dbus_ack_r  : std_logic;

  signal wb_d2m_adr  : std_logic_vector(31 downto 0);
  signal wb_d2m_din  : std_logic_vector(31 downto 0);
  signal wb_d2m_dout : std_logic_vector(31 downto 0);
  signal wb_d2m_we   : std_logic;
  signal wb_d2m_sel  : std_logic_vector(3 downto 0);
  signal wb_d2m_stb  : std_logic;
  signal wb_d2m_cyc  : std_logic;
  signal wb_d2m_ack  : std_logic;

  signal wb_d2p_adr  : std_logic_vector(31 downto 0);
  signal wb_d2p_din  : std_logic_vector(31 downto 0);
  signal wb_d2p_dout : std_logic_vector(31 downto 0);
  signal wb_d2p_we   : std_logic;
  signal wb_d2p_sel  : std_logic_vector(3 downto 0);
  signal wb_d2p_stb  : std_logic;
  signal wb_d2p_cyc  : std_logic;
  signal wb_d2p_ack  : std_logic;

  -- memory intf
  signal wb_mem_adr  : std_logic_vector(31 downto 0);
  signal wb_mem_din  : std_logic_vector(31 downto 0);
  signal wb_mem_dout : std_logic_vector(31 downto 0);
  signal wb_mem_we   : std_logic;
  signal wb_mem_sel  : std_logic_vector(3 downto 0);
  signal wb_mem_stb  : std_logic;
  signal wb_mem_cyc  : std_logic;
  signal wb_mem_ack  : std_logic;

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

  -- GEN_GPIO0 : for I in 0 to 7 generate
  --   led(I) <= gpio0_o(I) when (gpio0_t(I) = '0') else
  --   'Z';
  --   gpio0_i(I) <= led(I);
  -- end generate;

  led(7)          <= reset;
  led(6)          <= cpu_reset;
  led(5)          <= wb_boot_cyc;
  led(4)          <= wb_boot_stb;
  led(3)          <= wb_boot_ack;
  led(2 downto 0) <= wb_boot_adr(4 downto 2);

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

  U_BOOT_CTL : entity work.boot_ctl
    generic map(
      FLASH_BASEADDR => x"000000",
      SDRAM_BASEADDR => x"00000000",
      SDRAM_HIGHADDR => x"007FFFFF" -- 8 MB
    )
    port map
    (
      clk   => clk,
      reset => reset,

      cpu_reset => cpu_reset,

      m_cyc  => wb_boot_cyc,
      m_stb  => wb_boot_stb,
      m_adr  => wb_boot_adr,
      m_we   => wb_boot_we,
      m_sel  => wb_boot_sel,
      m_dout => wb_boot_dout,
      m_din  => wb_boot_din,
      m_ack  => wb_boot_ack,

      FLASH_CLK  => FLASH_CLK,
      FLASH_CS   => FLASH_CS,
      FLASH_HOLD => FLASH_HOLD,
      FLASH_WP   => FLASH_WP,
      FLASH_DI   => FLASH_DI,
      FLASH_DO   => FLASH_DO
    );

  U_CPU : entity work.cpu
    generic map(G_RESET_VEC => x"00000000")
    port map
    (
      clk   => clk,
      reset => cpu_reset,

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

  U_WBRS_D2P : entity work.wb_regslice
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_dbus_cyc,
      s_stb  => wb_dbus_stb,
      s_adr  => wb_dbus_adr,
      s_we   => wb_dbus_we,
      s_sel  => wb_dbus_sel,
      s_din  => wb_dbus_dout,
      s_dout => wb_dbus_din,
      s_ack  => wb_dbus_ack,

      m_cyc  => wb_dbus_cyc_r,
      m_stb  => wb_dbus_stb_r,
      m_adr  => wb_dbus_adr_r,
      m_we   => wb_dbus_we_r,
      m_sel  => wb_dbus_sel_r,
      m_dout => wb_dbus_dout_r,
      m_din  => wb_dbus_din_r,
      m_ack  => wb_dbus_ack_r
    );

  U_WBMUX_DBUS : entity work.wb_1xN
    generic map(
      N  => 2,
      AW => 32,
      DW => 32,
      BASEADDR => (0 => x"00000000", 1 => x"80000000"),
      HIGHADDR => (0 => x"7FFFFFFF", 1 => x"FFFFFFFF")
    )
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_dbus_cyc_r,
      s_stb  => wb_dbus_stb_r,
      s_adr  => wb_dbus_adr_r,
      s_we   => wb_dbus_we_r,
      s_sel  => wb_dbus_sel_r,
      s_din  => wb_dbus_dout_r,
      s_dout => wb_dbus_din_r,
      s_ack  => wb_dbus_ack_r,

      m_cyc(0)  => wb_d2m_cyc,
      m_cyc(1)  => wb_d2p_cyc,
      m_stb(0)  => wb_d2m_stb,
      m_stb(1)  => wb_d2p_stb,
      m_adr(0)  => wb_d2m_adr,
      m_adr(1)  => wb_d2p_adr,
      m_we(0)   => wb_d2m_we,
      m_we(1)   => wb_d2p_we,
      m_sel(0)  => wb_d2m_sel,
      m_sel(1)  => wb_d2p_sel,
      m_dout(0) => wb_d2m_dout,
      m_dout(1) => wb_d2p_dout,
      m_din(0)  => wb_d2m_din,
      m_din(1)  => wb_d2p_din,
      m_ack(0)  => wb_d2m_ack,
      m_ack(1)  => wb_d2p_ack
    );

  U_WBMUX_MEM : entity work.wb_Nx1
    generic map(N => 3, AW => 32, DW => 32)
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc(0)  => wb_ibus_cyc,
      s_cyc(1)  => wb_d2m_cyc,
      s_cyc(2)  => wb_boot_cyc,
      s_stb(0)  => wb_ibus_stb,
      s_stb(1)  => wb_d2m_stb,
      s_stb(2)  => wb_boot_stb,
      s_adr(0)  => wb_ibus_adr,
      s_adr(1)  => wb_d2m_adr,
      s_adr(2)  => wb_boot_adr,
      s_we(0)   => wb_ibus_we,
      s_we(1)   => wb_d2m_we,
      s_we(2)   => wb_boot_we,
      s_sel(0)  => wb_ibus_sel,
      s_sel(1)  => wb_d2m_sel,
      s_sel(2)  => wb_boot_sel,
      s_din(0)  => wb_ibus_dout,
      s_din(1)  => wb_d2m_dout,
      s_din(2)  => wb_boot_dout,
      s_dout(0) => wb_ibus_din,
      s_dout(1) => wb_d2m_din,
      s_dout(2) => wb_boot_din,
      s_ack(0)  => wb_ibus_ack,
      s_ack(1)  => wb_d2m_ack,
      s_ack(2)  => wb_boot_ack,

      m_cyc  => wb_mem_cyc,
      m_stb  => wb_mem_stb,
      m_adr  => wb_mem_adr,
      m_we   => wb_mem_we,
      m_sel  => wb_mem_sel,
      m_dout => wb_mem_dout,
      m_din  => wb_mem_din,
      m_ack  => wb_mem_ack
    );

  U_MEM : entity work.sdram_ctl
    generic map(G_BURST_LEN => 2)
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_mem_cyc,
      s_stb  => wb_mem_stb,
      s_adr  => wb_mem_adr,
      s_we   => wb_mem_we,
      s_sel  => wb_mem_sel,
      s_din  => wb_mem_dout,
      s_dout => wb_mem_din,
      s_ack  => wb_mem_ack,

      SDRAM_A   => SDRAM_A,
      SDRAM_BA  => SDRAM_BA,
      SDRAM_CLK => SDRAM_CLK,
      SDRAM_CKE => SDRAM_CKE,
      SDRAM_CAS => SDRAM_CAS,
      SDRAM_CS  => SDRAM_CS,
      SDRAM_RAS => SDRAM_RAS,
      SDRAM_WE  => SDRAM_WE,
      SDRAM_DQM => SDRAM_DQM,
      SDRAM_DQ  => SDRAM_DQ
    );

  -- U_MEM : entity work.wb_mem
  --   generic map
  --   (
  --     G_AW        => 13,
  --     G_INIT_FILE => "D:\\Files\\max1k\\max1k-cpu\\tb\\sw\\main.mif"
  --   )
  --   port map
  --   (
  --     clk    => clk,
  --     s_adr  => wb_mem_adr,
  --     s_din  => wb_mem_dout,
  --     s_dout => wb_mem_din,
  --     s_we   => wb_mem_we,
  --     s_sel  => wb_mem_sel,
  --     s_stb  => wb_mem_stb,
  --     s_cyc  => wb_mem_cyc,
  --     s_ack  => wb_mem_ack
  --   );

  U_WBMUX_PERIPH : entity work.wb_1xN
    generic map(
      N  => 2,
      AW => 32,
      DW => 32,
      BASEADDR => (0 => x"A0000000", 1 => x"A0010000"),
      HIGHADDR => (0 => x"A000FFFF", 1 => x"A001FFFF")
    )
    port map
    (
      clk   => clk,
      reset => reset,

      s_cyc  => wb_d2p_cyc,
      s_stb  => wb_d2p_stb,
      s_adr  => wb_d2p_adr,
      s_we   => wb_d2p_we,
      s_sel  => wb_d2p_sel,
      s_din  => wb_d2p_dout,
      s_dout => wb_d2p_din,
      s_ack  => wb_d2p_ack,

      m_cyc(0)  => wb_gpio0_cyc,
      m_cyc(1)  => wb_uart0_cyc,
      m_stb(0)  => wb_gpio0_stb,
      m_stb(1)  => wb_uart0_stb,
      m_adr(0)  => wb_gpio0_adr,
      m_adr(1)  => wb_uart0_adr,
      m_we(0)   => wb_gpio0_we,
      m_we(1)   => wb_uart0_we,
      m_sel(0)  => wb_gpio0_sel,
      m_sel(1)  => wb_uart0_sel,
      m_dout(0) => wb_gpio0_dout,
      m_dout(1) => wb_uart0_dout,
      m_din(0)  => wb_gpio0_din,
      m_din(1)  => wb_uart0_din,
      m_ack(0)  => wb_gpio0_ack,
      m_ack(1)  => wb_uart0_ack
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