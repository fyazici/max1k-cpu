library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity boot_ctl is
  generic (
    FLASH_BASEADDR : std_logic_vector(23 downto 0);
    SDRAM_BASEADDR : std_logic_vector(31 downto 0);
    SDRAM_HIGHADDR : std_logic_vector(31 downto 0)
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    cpu_reset : out std_logic;

    m_cyc  : out std_logic;
    m_stb  : out std_logic;
    m_adr  : out std_logic_vector(31 downto 0);
    m_we   : out std_logic;
    m_sel  : out std_logic_vector(3 downto 0);
    m_dout : out std_logic_vector(31 downto 0);
    m_din  : in std_logic_vector(31 downto 0);
    m_ack  : in std_logic;

    FLASH_CLK  : out std_logic;
    FLASH_CS   : out std_logic;
    FLASH_HOLD : out std_logic;
    FLASH_WP   : out std_logic;
    FLASH_DI   : out std_logic;
    FLASH_DO   : in std_logic
  );
end entity boot_ctl;

architecture rtl of boot_ctl is

  type t_state is (
    S_init,
    S_cmd, S_adr_0, S_adr_1, S_adr_2,
    S_read_0, S_read_1, S_read_2, S_read_3,
    S_write,
    S_done
  );
  signal state : t_state := S_init;

  signal spi_cyc  : std_logic                    := '0';
  signal spi_stb  : std_logic                    := '0';
  signal spi_din  : std_logic_vector(7 downto 0) := (others => '0');
  signal spi_dout : std_logic_vector(7 downto 0);
  signal spi_ack  : std_logic;

  signal rd_buf : std_logic_vector(31 downto 0);

  signal sdram_adr : unsigned(31 downto 0) := (others => '0');

begin

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        cpu_reset <= '1';
        m_cyc     <= '0';
        m_stb     <= '0';
        spi_cyc   <= '0';
        spi_stb   <= '0';
        spi_din   <= (others => '0');
        sdram_adr <= unsigned(SDRAM_BASEADDR);
        state     <= S_init;
      else
        case (state) is
            -- start continuous flash read
          when S_init =>
            spi_cyc   <= '1';
            spi_stb   <= '1';
            spi_din   <= x"03"; -- read
            sdram_adr <= unsigned(SDRAM_BASEADDR);
            state     <= S_cmd;
          when S_cmd =>
            if spi_ack = '1' then
              spi_din <= FLASH_BASEADDR(23 downto 16);
              state   <= S_adr_0;
            end if;
          when S_adr_0 =>
            if spi_ack = '1' then
              spi_din <= FLASH_BASEADDR(15 downto 8);
              state   <= S_adr_1;
            end if;
          when S_adr_1 =>
            if spi_ack = '1' then
              spi_din <= FLASH_BASEADDR(7 downto 0);
              state   <= S_adr_2;
            end if;
          when S_adr_2 =>
            if spi_ack = '1' then
              spi_din <= (others => '0');
              state   <= S_read_0;
            end if;

            -- flash read / memory write loop
          when S_read_0 =>
            if spi_ack = '1' then
              rd_buf(7 downto 0) <= spi_dout;
              state              <= S_read_1;
            end if;
          when S_read_1 =>
            if spi_ack = '1' then
              rd_buf(15 downto 8) <= spi_dout;
              state               <= S_read_2;
            end if;
          when S_read_2 =>
            if spi_ack = '1' then
              rd_buf(23 downto 16) <= spi_dout;
              state                <= S_read_3;
            end if;
          when S_read_3 =>
            if spi_ack = '1' then
              spi_stb              <= '0';
              rd_buf(31 downto 24) <= spi_dout;

              m_cyc <= '1';
              m_stb <= '1';
              state <= S_write;
            end if;
          when S_write =>
            if m_ack = '1' then
              sdram_adr <= sdram_adr + 4;
              m_cyc     <= '0';
              m_stb     <= '0';

              if sdram_adr <= unsigned(SDRAM_HIGHADDR) then
                spi_stb      <= '1';
                state        <= S_read_0;
              else
                spi_cyc <= '0';
                state   <= S_done;
              end if;
            end if;
          when S_done =>
            cpu_reset <= '0';
        end case;
      end if;
    end if;
  end process;

  m_adr  <= std_logic_vector(sdram_adr);
  m_we   <= '1';
  m_sel  <= x"F";
  m_dout <= rd_buf;

  U_FLASH_SPI : entity work.flash_spi
    port map
    (
      clk   => clk,
      reset => reset,

      cyc  => spi_cyc,
      stb  => spi_stb,
      din  => spi_din,
      dout => spi_dout,
      ack  => spi_ack,

      FLASH_CLK  => FLASH_CLK,
      FLASH_CS   => FLASH_CS,
      FLASH_HOLD => FLASH_HOLD,
      FLASH_WP   => FLASH_WP,
      FLASH_DI   => FLASH_DI,
      FLASH_DO   => FLASH_DO
    );

end architecture;