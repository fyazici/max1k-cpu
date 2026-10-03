library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_flash is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_wb_cyc  : in std_logic;
    s_wb_stb  : in std_logic;
    s_wb_adr  : in std_logic_vector(31 downto 0);
    s_wb_we   : in std_logic;
    s_wb_sel  : in std_logic_vector(3 downto 0);
    s_wb_din  : in std_logic_vector(31 downto 0);
    s_wb_dout : out std_logic_vector(31 downto 0);
    s_wb_ack  : out std_logic;

    spi_cyc  : out std_logic := '0';
    spi_stb  : out std_logic := '0';
    spi_din  : out std_logic_vector(7 downto 0);
    spi_dout : in std_logic_vector(7 downto 0);
    spi_ack  : in std_logic
  );
end entity wb_flash;

architecture rtl of wb_flash is

  type t_state is (
    S_idle,
    S_cmd,
    S_adr_0, S_adr_1, S_adr_2,
    S_data_0, S_data_1, S_data_2, S_data_3,
    S_ack
  );
  signal state : t_state := S_idle;

begin

  PROC_SEQ : process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        s_wb_ack <= '0';
        spi_cyc  <= '0';
        spi_stb  <= '0';
      else
        s_wb_ack <= '0';

        case (state) is
          when S_idle =>
            if s_wb_cyc = '1' and s_wb_stb = '1' then
              spi_cyc <= '1';
              spi_stb <= '1';
              spi_din <= x"03"; -- read
              state   <= S_cmd;
            end if;
          when S_cmd =>
            if spi_ack = '1' then
              spi_din <= s_wb_adr(23 downto 16);
              state   <= S_adr_0;
            end if;
          when S_adr_0 =>
            if spi_ack = '1' then
              spi_din <= s_wb_adr(15 downto 8);
              state   <= S_adr_1;
            end if;
          when S_adr_1 =>
            if spi_ack = '1' then
              spi_din <= s_wb_adr(7 downto 0);
              state   <= S_adr_2;
            end if;
          when S_adr_2 =>
            if spi_ack = '1' then
              spi_din <= (others => '0');
              state   <= S_data_0;
            end if;
          when S_data_0 =>
            if spi_ack = '1' then
              s_wb_dout(7 downto 0) <= spi_dout;
              state                 <= S_data_1;
            end if;
          when S_data_1 =>
            if spi_ack = '1' then
              s_wb_dout(15 downto 8) <= spi_dout;
              state                  <= S_data_2;
            end if;
          when S_data_2 =>
            if spi_ack = '1' then
              s_wb_dout(23 downto 16) <= spi_dout;
              state                   <= S_data_3;
            end if;
          when S_data_3 =>
            if spi_ack = '1' then
              spi_cyc                 <= '0';
              spi_stb                 <= '0';
              s_wb_dout(31 downto 24) <= spi_dout;
              s_wb_ack                <= '1';
              state                   <= S_ack;
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