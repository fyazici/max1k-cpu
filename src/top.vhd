library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
  generic (
    G_SIM_MODE : boolean := FALSE
  );
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
      c1     : out std_logic;
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

  signal wb_icache_adr  : std_logic_vector(31 downto 0);
  signal wb_icache_din  : std_logic_vector(31 downto 0);
  signal wb_icache_dout : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_icache_we   : std_logic                     := '0';
  signal wb_icache_sel  : std_logic_vector(3 downto 0)  := (others => '0');
  signal wb_icache_stb  : std_logic;
  signal wb_icache_cyc  : std_logic;
  signal wb_icache_ack  : std_logic;

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

  signal wb_dcache_adr  : std_logic_vector(31 downto 0);
  signal wb_dcache_din  : std_logic_vector(31 downto 0);
  signal wb_dcache_dout : std_logic_vector(31 downto 0);
  signal wb_dcache_we   : std_logic;
  signal wb_dcache_sel  : std_logic_vector(3 downto 0);
  signal wb_dcache_stb  : std_logic;
  signal wb_dcache_cyc  : std_logic;
  signal wb_dcache_ack  : std_logic;

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

  -- icache csr intf
  signal wb_icache_csr_adr  : std_logic_vector(31 downto 0);
  signal wb_icache_csr_din  : std_logic_vector(31 downto 0);
  signal wb_icache_csr_dout : std_logic_vector(31 downto 0);
  signal wb_icache_csr_we   : std_logic;
  signal wb_icache_csr_sel  : std_logic_vector(3 downto 0);
  signal wb_icache_csr_stb  : std_logic;
  signal wb_icache_csr_cyc  : std_logic;
  signal wb_icache_csr_ack  : std_logic;

  -- dcache csr intf
  signal wb_dcache_csr_adr  : std_logic_vector(31 downto 0);
  signal wb_dcache_csr_din  : std_logic_vector(31 downto 0);
  signal wb_dcache_csr_dout : std_logic_vector(31 downto 0);
  signal wb_dcache_csr_we   : std_logic;
  signal wb_dcache_csr_sel  : std_logic_vector(3 downto 0);
  signal wb_dcache_csr_stb  : std_logic;
  signal wb_dcache_csr_cyc  : std_logic;
  signal wb_dcache_csr_ack  : std_logic;

  -- flash
  signal flash_spi_cyc  : std_logic;
  signal flash_spi_stb  : std_logic;
  signal flash_spi_din  : std_logic_vector(7 downto 0);
  signal flash_spi_dout : std_logic_vector(7 downto 0);
  signal flash_spi_ack  : std_logic;

  signal wb_flash_cyc  : std_logic;
  signal wb_flash_stb  : std_logic;
  signal wb_flash_adr  : std_logic_vector(31 downto 0);
  signal wb_flash_we   : std_logic;
  signal wb_flash_sel  : std_logic_vector(3 downto 0);
  signal wb_flash_din  : std_logic_vector(31 downto 0);
  signal wb_flash_dout : std_logic_vector(31 downto 0);
  signal wb_flash_ack  : std_logic;

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

  -- led(7)          <= reset;
  -- led(6)          <= cpu_reset;
  -- led(5)          <= wb_boot_cyc;
  -- led(4)          <= wb_boot_stb;
  -- led(3)          <= wb_boot_ack;
  -- led(2 downto 0) <= wb_boot_adr(4 downto 2);

  U_PLL1 : pll1
  port map
  (
    inclk0 => CLK12M,
    c0     => clk,
    c1     => SDRAM_CLK,
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

  U_WBRS_DBUS : entity work.wb_regslice
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

  U_ICACHE : entity work.wb_cache
    generic map(G_NUM_WORDS => 256, G_RAMSTYLE => "m9k")
    port map
    (
      clk   => clk,
      reset => reset,

      s_csr_cyc  => wb_icache_csr_cyc,
      s_csr_stb  => wb_icache_csr_stb,
      s_csr_adr  => wb_icache_csr_adr,
      s_csr_we   => wb_icache_csr_we,
      s_csr_sel  => wb_icache_csr_sel,
      s_csr_din  => wb_icache_csr_dout,
      s_csr_dout => wb_icache_csr_din,
      s_csr_ack  => wb_icache_csr_ack,

      s_cyc  => wb_ibus_cyc,
      s_stb  => wb_ibus_stb,
      s_adr  => wb_ibus_adr,
      s_we   => wb_ibus_we,
      s_sel  => wb_ibus_sel,
      s_din  => wb_ibus_dout,
      s_dout => wb_ibus_din,
      s_ack  => wb_ibus_ack,

      m_cyc  => wb_icache_cyc,
      m_stb  => wb_icache_stb,
      m_adr  => wb_icache_adr,
      m_we   => wb_icache_we,
      m_sel  => wb_icache_sel,
      m_dout => wb_icache_dout,
      m_din  => wb_icache_din,
      m_ack  => wb_icache_ack
    );

  U_DCACHE : entity work.wb_cache
    generic map(G_NUM_WORDS => 256, G_RAMSTYLE => "m9k")
    port map
    (
      clk   => clk,
      reset => reset,

      s_csr_cyc  => wb_dcache_csr_cyc,
      s_csr_stb  => wb_dcache_csr_stb,
      s_csr_adr  => wb_dcache_csr_adr,
      s_csr_we   => wb_dcache_csr_we,
      s_csr_sel  => wb_dcache_csr_sel,
      s_csr_din  => wb_dcache_csr_dout,
      s_csr_dout => wb_dcache_csr_din,
      s_csr_ack  => wb_dcache_csr_ack,

      s_cyc  => wb_dbus_cyc_r,
      s_stb  => wb_dbus_stb_r,
      s_adr  => wb_dbus_adr_r,
      s_we   => wb_dbus_we_r,
      s_sel  => wb_dbus_sel_r,
      s_din  => wb_dbus_dout_r,
      s_dout => wb_dbus_din_r,
      s_ack  => wb_dbus_ack_r,

      m_cyc  => wb_dcache_cyc,
      m_stb  => wb_dcache_stb,
      m_adr  => wb_dcache_adr,
      m_we   => wb_dcache_we,
      m_sel  => wb_dcache_sel,
      m_dout => wb_dcache_dout,
      m_din  => wb_dcache_din,
      m_ack  => wb_dcache_ack
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

      s_cyc  => wb_dcache_cyc,
      s_stb  => wb_dcache_stb,
      s_adr  => wb_dcache_adr,
      s_we   => wb_dcache_we,
      s_sel  => wb_dcache_sel,
      s_din  => wb_dcache_dout,
      s_dout => wb_dcache_din,
      s_ack  => wb_dcache_ack,

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

      s_cyc(0)  => wb_icache_cyc,
      s_cyc(1)  => wb_d2m_cyc,
      s_cyc(2)  => wb_boot_cyc,
      s_stb(0)  => wb_icache_stb,
      s_stb(1)  => wb_d2m_stb,
      s_stb(2)  => wb_boot_stb,
      s_adr(0)  => wb_icache_adr,
      s_adr(1)  => wb_d2m_adr,
      s_adr(2)  => wb_boot_adr,
      s_we(0)   => wb_icache_we,
      s_we(1)   => wb_d2m_we,
      s_we(2)   => wb_boot_we,
      s_sel(0)  => wb_icache_sel,
      s_sel(1)  => wb_d2m_sel,
      s_sel(2)  => wb_boot_sel,
      s_din(0)  => wb_icache_dout,
      s_din(1)  => wb_d2m_dout,
      s_din(2)  => wb_boot_dout,
      s_dout(0) => wb_icache_din,
      s_dout(1) => wb_d2m_din,
      s_dout(2) => wb_boot_din,
      s_ack(0)  => wb_icache_ack,
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

  GEN_SDRAM : if G_SIM_MODE = FALSE generate
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

        spi_cyc_ext  => flash_spi_cyc,
        spi_stb_ext  => flash_spi_stb,
        spi_din_ext  => flash_spi_din,
        spi_dout_ext => flash_spi_dout,
        spi_ack_ext  => flash_spi_ack,

        FLASH_CLK  => FLASH_CLK,
        FLASH_CS   => FLASH_CS,
        FLASH_HOLD => FLASH_HOLD,
        FLASH_WP   => FLASH_WP,
        FLASH_DI   => FLASH_DI,
        FLASH_DO   => FLASH_DO
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
        SDRAM_CLK => open,
        SDRAM_CKE => SDRAM_CKE,
        SDRAM_CAS => SDRAM_CAS,
        SDRAM_CS  => SDRAM_CS,
        SDRAM_RAS => SDRAM_RAS,
        SDRAM_WE  => SDRAM_WE,
        SDRAM_DQM => SDRAM_DQM,
        SDRAM_DQ  => SDRAM_DQ
      );

    U_WB_FLASH : entity work.wb_flash
      port map
      (
        clk   => clk,
        reset => reset,

        s_wb_cyc  => wb_flash_cyc,
        s_wb_stb  => wb_flash_stb,
        s_wb_adr  => wb_flash_adr,
        s_wb_we   => wb_flash_we,
        s_wb_sel  => wb_flash_sel,
        s_wb_din  => wb_flash_dout,
        s_wb_dout => wb_flash_din,
        s_wb_ack  => wb_flash_ack,

        spi_cyc  => flash_spi_cyc,
        spi_stb  => flash_spi_stb,
        spi_din  => flash_spi_din,
        spi_dout => flash_spi_dout,
        spi_ack  => flash_spi_ack
      );
  end generate;

  GEN_BRAM : if G_SIM_MODE = TRUE generate
    cpu_reset    <= reset;
    wb_boot_cyc  <= '0';
    wb_boot_stb  <= '0';
    wb_boot_adr  <= (others => '0');
    wb_boot_we   <= '0';
    wb_boot_sel  <= (others => '0');
    wb_boot_dout <= (others => '0');

    U_MEM : entity work.wb_mem
      generic map
      (
        G_AW        => 21,
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
  end generate;

  U_WBMUX_PERIPH : entity work.wb_1xN
    generic map(
      N  => 5,
      AW => 32,
      DW => 32,
      BASEADDR => (0 => x"80000000", 1 => x"A0000000", 2 => x"A0010000", 3 => x"FFF00000", 4 => x"FFF10000"),
      HIGHADDR => (0 => x"807FFFFF", 1 => x"A000FFFF", 2 => x"A001FFFF", 3 => x"FFF0FFFF", 4 => x"FFF1FFFF")
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

      m_cyc(0) => wb_flash_cyc,
      m_cyc(1) => wb_gpio0_cyc,
      m_cyc(2) => wb_uart0_cyc,
      m_cyc(3) => wb_icache_csr_cyc,
      m_cyc(4) => wb_dcache_csr_cyc,

      m_stb(0) => wb_flash_stb,
      m_stb(1) => wb_gpio0_stb,
      m_stb(2) => wb_uart0_stb,
      m_stb(3) => wb_icache_csr_stb,
      m_stb(4) => wb_dcache_csr_stb,

      m_adr(0) => wb_flash_adr,
      m_adr(1) => wb_gpio0_adr,
      m_adr(2) => wb_uart0_adr,
      m_adr(3) => wb_icache_csr_adr,
      m_adr(4) => wb_dcache_csr_adr,

      m_we(0) => wb_flash_we,
      m_we(1) => wb_gpio0_we,
      m_we(2) => wb_uart0_we,
      m_we(3) => wb_icache_csr_we,
      m_we(4) => wb_dcache_csr_we,

      m_sel(0) => wb_flash_sel,
      m_sel(1) => wb_gpio0_sel,
      m_sel(2) => wb_uart0_sel,
      m_sel(3) => wb_icache_csr_sel,
      m_sel(4) => wb_dcache_csr_sel,

      m_dout(0) => wb_flash_dout,
      m_dout(1) => wb_gpio0_dout,
      m_dout(2) => wb_uart0_dout,
      m_dout(3) => wb_icache_csr_dout,
      m_dout(4) => wb_dcache_csr_dout,

      m_din(0) => wb_flash_din,
      m_din(1) => wb_gpio0_din,
      m_din(2) => wb_uart0_din,
      m_din(3) => wb_icache_csr_din,
      m_din(4) => wb_dcache_csr_din,

      m_ack(0) => wb_flash_ack,
      m_ack(1) => wb_gpio0_ack,
      m_ack(2) => wb_uart0_ack,
      m_ack(3) => wb_icache_csr_ack,
      m_ack(4) => wb_dcache_csr_ack
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
    generic map(G_FIFO_DEPTH => 256)
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