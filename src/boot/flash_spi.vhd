library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity flash_spi is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    cyc  : in std_logic;
    stb  : in std_logic;
    din  : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0);
    ack  : out std_logic;

    FLASH_CLK  : out std_logic;
    FLASH_CS   : out std_logic;
    FLASH_HOLD : out std_logic;
    FLASH_WP   : out std_logic;
    FLASH_DI   : out std_logic;
    FLASH_DO   : in std_logic
  );
end entity flash_spi;

architecture rtl of flash_spi is

  type t_state is (
    S_idle,
    S_low,
    S_high,
    S_ack
  );

  signal sr : std_logic_vector(7 downto 0);

  signal state  : t_state := S_idle;
  signal bitctr : natural;

begin

  FLASH_HOLD <= '1';
  FLASH_WP   <= '1';
  FLASH_CS   <= not(cyc);
  FLASH_CLK  <= '0' when (state = S_low) else
    '1';

  ack <= '1' when (state = S_ack) else
    '0';

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S_idle;
      else
        case (state) is
          when S_idle =>
            if cyc = '1' and stb = '1' then
              sr     <= din;
              bitctr <= 8;
              state  <= S_high;
            end if;

          when S_low =>
            sr    <= sr(6 downto 0) & FLASH_DO;
            state <= S_high;

          when S_high =>
            FLASH_DI <= sr(7);
            bitctr   <= bitctr - 1;
            if bitctr > 0 then
              state <= S_low;
            else
              dout  <= sr;
              state <= S_ack;
            end if;

          when S_ack =>
            state <= S_idle;

          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

end architecture;