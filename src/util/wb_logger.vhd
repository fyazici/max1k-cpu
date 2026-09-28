library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity wb_logger is
  generic (
    G_ID       : string;
    G_FILENAME : string
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_cyc  : in std_logic;
    s_stb  : in std_logic;
    s_adr  : in std_logic_vector(31 downto 0);
    s_we   : in std_logic;
    s_sel  : in std_logic_vector(3 downto 0);
    s_din  : in std_logic_vector(31 downto 0);
    s_dout : in std_logic_vector(31 downto 0);
    s_ack  : in std_logic
  );
end entity wb_logger;

architecture rtl of wb_logger is

begin

  process
    file f     : text open write_mode is G_FILENAME;
    variable l : line;
  begin
    loop
      wait until rising_edge(clk);
      if s_cyc = '1' and s_stb = '1' and s_ack = '1' then
        if s_we = '1' then
          write(l, G_ID & ",W,A=" & to_hstring(s_adr) & ",D=" & to_hstring(s_din) & ",S=" & to_hstring(s_sel));
        else
          write(l, G_ID & ",R,A=" & to_hstring(s_adr) & ",D=" & to_hstring(s_dout));
        end if;
        writeline(f, l);
      end if;
    end loop;
  end process;

end architecture;