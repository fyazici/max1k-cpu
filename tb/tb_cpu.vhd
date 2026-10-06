library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_cpu is
end entity tb_cpu;

architecture rtl of tb_cpu is
  signal CLK12M : std_logic := '0';
  signal LED    : std_logic_vector(7 downto 0);
begin

  CLK12M <= not(CLK12M) after 41.667 ns;

  uut : entity work.top
    generic map(G_SIM_MODE => TRUE)
    port map
    (
      CLK12M     => CLK12M,
      LED        => LED,
      USER_BTN   => '0',
      SDRAM_A    => open,
      SDRAM_BA   => open,
      SDRAM_CLK  => open,
      SDRAM_CKE  => open,
      SDRAM_CAS  => open,
      SDRAM_CS   => open,
      SDRAM_RAS  => open,
      SDRAM_WE   => open,
      SDRAM_DQM  => open,
      SDRAM_DQ   => open,
      FLASH_CLK  => open,
      FLASH_CS   => open,
      FLASH_HOLD => open,
      FLASH_WP   => open,
      FLASH_DI   => open,
      FLASH_DO   => '0',
      FT2232H_RX => open,
      FT2232H_TX => '1'
    );

  process
    variable v_ctr : natural := 0;
  begin
    --<< signal .tb_cpu.uut.U_DCACHE.cache_mask : std_logic_vector(31 downto 0) >> <= force x"00000000";
    loop
      report "tic toc";
      wait for 100 us;
    end loop;
  end process;

  U_WBLOG_DBUS : entity work.wb_logger
    generic map(
      G_ID       => "DBUS",
      G_FILENAME => "dbus.csv"
    )
    port map
    (
      clk   => << signal .tb_cpu.uut.clk   : std_logic >>,
      reset => << signal .tb_cpu.uut.clk : std_logic >>,

      s_cyc  => << signal .tb_cpu.uut.wb_dbus_cyc  : std_logic >>,
      s_stb  => << signal .tb_cpu.uut.wb_dbus_stb  : std_logic >>,
      s_adr  => << signal .tb_cpu.uut.wb_dbus_adr  : std_logic_vector(31 downto 0) >>,
      s_we   => << signal .tb_cpu.uut.wb_dbus_we    : std_logic >>,
      s_sel  => << signal .tb_cpu.uut.wb_dbus_sel  : std_logic_vector(3 downto 0) >>,
      s_din  => << signal .tb_cpu.uut.wb_dbus_dout : std_logic_vector(31 downto 0) >>,
      s_dout => << signal .tb_cpu.uut.wb_dbus_din : std_logic_vector(31 downto 0) >>,
      s_ack  => << signal .tb_cpu.uut.wb_dbus_ack  : std_logic >>
    );

  U_WBLOG_IBUS : entity work.wb_logger
    generic map(
      G_ID       => "IBUS",
      G_FILENAME => "ibus.csv"
    )
    port map
    (
      clk   => << signal .tb_cpu.uut.clk   : std_logic >>,
      reset => << signal .tb_cpu.uut.clk : std_logic >>,

      s_cyc  => << signal .tb_cpu.uut.wb_ibus_cyc  : std_logic >>,
      s_stb  => << signal .tb_cpu.uut.wb_ibus_stb  : std_logic >>,
      s_adr  => << signal .tb_cpu.uut.wb_ibus_adr  : std_logic_vector(31 downto 0) >>,
      s_we   => << signal .tb_cpu.uut.wb_ibus_we    : std_logic >>,
      s_sel  => << signal .tb_cpu.uut.wb_ibus_sel  : std_logic_vector(3 downto 0) >>,
      s_din  => << signal .tb_cpu.uut.wb_ibus_dout : std_logic_vector(31 downto 0) >>,
      s_dout => << signal .tb_cpu.uut.wb_ibus_din : std_logic_vector(31 downto 0) >>,
      s_ack  => << signal .tb_cpu.uut.wb_ibus_ack  : std_logic >>
    );

end architecture;