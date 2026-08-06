library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_rx is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    baud_div : in std_logic_vector(15 downto 0);

    rx : in std_logic;

    dout_valid : out std_logic;
    dout_ready : in std_logic;
    dout_data  : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of uart_rx is
  signal dout_valid_r : std_logic;

  signal rx_prev   : std_logic;
  signal bit_timer : unsigned(15 downto 0);
  signal bit_idx   : natural range 0 to 7;

  type state_t is (S_IDLE, S_START, S_SAMPLE, S_STOP, S_END);
  signal state : state_t;
begin

  PROC_UART_RX : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        bit_timer    <= (others => '0');
        bit_idx      <= 0;
        dout_data    <= (others => '0');
        dout_valid_r <= '0';
        rx_prev      <= '1';
      else
        rx_prev <= rx;
        case (state) is
          when S_IDLE =>
            dout_valid_r <= '0';
            if (rx = '0' and rx_prev = '1') then
              bit_timer <= unsigned("0" & baud_div(15 downto 1));
              state     <= S_START;
            end if;
          when S_START =>
            if (rx = '0') then
              if (bit_timer = 0) then
                bit_timer <= unsigned(baud_div);
                bit_idx   <= 7;
                dout_data <= (others => '0');
                state     <= S_SAMPLE;
              else
                bit_timer <= bit_timer - 1;
              end if;
            else
              state <= S_IDLE;
            end if;
          when S_SAMPLE =>
            if (bit_timer = 0) then
              dout_data(7 - bit_idx) <= rx;
              if (bit_idx = 0) then
                state <= S_STOP;
              else
                bit_idx <= bit_idx - 1;
              end if;
              bit_timer <= unsigned(baud_div);
            else
              bit_timer <= bit_timer - 1;
            end if;
          when S_STOP =>
            if (bit_timer = 0) then
              if (rx = '1') then
                dout_valid_r <= '1';
              end if;
              state <= S_END;
            else
              bit_timer <= bit_timer - 1;
            end if;
          when S_END =>
            if (dout_valid_r = '1' and dout_ready = '1') then
              dout_valid_r <= '0';
              state        <= S_IDLE;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  dout_valid <= dout_valid_r;

end architecture;
