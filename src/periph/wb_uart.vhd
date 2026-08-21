library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_uart is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_cyc  : in std_logic;
    s_stb  : in std_logic;
    s_adr  : in std_logic_vector(31 downto 0);
    s_we   : in std_logic;
    s_sel  : in std_logic_vector(3 downto 0);
    s_din  : in std_logic_vector(31 downto 0);
    s_dout : out std_logic_vector(31 downto 0);
    s_ack  : out std_logic;

    uart_rx : in std_logic;
    uart_tx : out std_logic
  );
end entity wb_uart;

architecture rtl of wb_uart is

  signal baud_div : std_logic_vector(15 downto 0);

  signal rx_valid : std_logic;
  signal rx_ready : std_logic := '0';
  signal rx_data  : std_logic_vector(7 downto 0);

  signal rx_valid_f : std_logic;
  signal rx_ready_f : std_logic := '0';
  signal rx_data_f  : std_logic_vector(7 downto 0);

  signal tx_valid : std_logic := '0';
  signal tx_ready : std_logic;
  signal tx_data  : std_logic_vector(7 downto 0);

  signal tx_valid_f : std_logic := '0';
  signal tx_ready_f : std_logic;
  signal tx_data_f  : std_logic_vector(7 downto 0);

begin

  PROC_REG : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        s_dout     <= (others => '0');
        s_ack      <= '0';
        tx_valid_f <= '0';
        rx_ready_f <= '0';
      else
        s_dout <= (others => '0');
        s_ack  <= '0';

        tx_valid_f <= '0';
        rx_ready_f <= '0';

        if s_cyc = '1' and s_stb = '1' and s_ack = '0' then
          s_ack <= '1';

          if s_we = '1' then
            case (s_adr(3 downto 2)) is
              when "00" =>
                baud_div <= s_din(15 downto 0);
              when "10" =>
                tx_valid_f <= '1';
                tx_data_f  <= s_din(7 downto 0);
              when others =>
                null;
            end case;
          else
            case (s_adr(3 downto 2)) is
              when "00" =>
                s_dout <= x"0000" & baud_div;
              when "01" =>
                s_dout <= x"0000000" & "00" & rx_valid_f & tx_ready_f;
              when "11" =>
                rx_ready_f <= '1';
                s_dout     <= x"000000" & rx_data_f;
              when others =>
                null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------- 

  U_RX : entity work.uart_rx
    port map
    (
      clk   => clk,
      reset => reset,

      baud_div => baud_div,

      rx => uart_rx,

      dout_valid => rx_valid,
      dout_ready => rx_ready,
      dout_data  => rx_data
    );

  U_RX_FIFO : entity work.stream_fifo
    generic map(
      G_DW       => 8,
      G_AW       => 3,
      G_RAMSTYLE => "logic"
    )
    port map
    (
      clk   => clk,
      reset => reset,

      s_valid => rx_valid,
      s_ready => rx_ready,
      s_data  => rx_data,

      m_valid => rx_valid_f,
      m_ready => rx_ready_f,
      m_data  => rx_data_f
    );

  --------------------------------------- 

  U_TX_FIFO : entity work.stream_fifo
    generic map(
      G_DW       => 8,
      G_AW       => 3,
      G_RAMSTYLE => "logic"
    )
    port map
    (
      clk   => clk,
      reset => reset,

      s_valid => tx_valid_f,
      s_ready => tx_ready_f,
      s_data  => tx_data_f,

      m_valid => tx_valid,
      m_ready => tx_ready,
      m_data  => tx_data
    );

  U_TX : entity work.uart_tx
    port map
    (
      clk   => clk,
      reset => reset,

      baud_div => baud_div,

      din_valid => tx_valid,
      din_ready => tx_ready,
      din_data  => tx_data,

      tx => uart_tx
    );

end architecture;