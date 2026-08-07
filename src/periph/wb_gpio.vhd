library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_gpio is
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

    gpio_i : in std_logic_vector(31 downto 0);
    gpio_o : out std_logic_vector(31 downto 0);
    gpio_t : out std_logic_vector(31 downto 0)
  );
end entity wb_gpio;

architecture rtl of wb_gpio is

begin

  PROC_REG : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        gpio_t <= (others => '0');
        gpio_o <= (others => '0');
        s_dout <= (others => '0');
        s_ack  <= '0';
      else
        s_dout <= (others => '0');
        s_ack  <= '0';

        if s_cyc = '1' and s_stb = '1' and s_ack = '0' then
          s_ack <= '1';

          if s_we = '1' then
            case (s_adr(3 downto 2)) is
              when "00" =>
                gpio_t <= s_din;
              when "11" =>
                gpio_o <= s_din;
              when others =>
                null;
            end case;
          else
            case (s_adr(3 downto 2)) is
              when "00" =>
                s_dout <= gpio_t;
              when "10" =>
                s_dout <= gpio_i;
              when "11" =>
                s_dout <= gpio_o;
              when others =>
                null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;