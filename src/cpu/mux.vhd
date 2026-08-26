library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mux2 is
  generic (
    G_DW : natural := 32
  );
  port (
    sel : in std_logic_vector(0 downto 0);
    d0  : in std_logic_vector(G_DW - 1 downto 0);
    d1  : in std_logic_vector(G_DW - 1 downto 0);
    q   : out std_logic_vector(G_DW - 1 downto 0)
  );
end entity mux2;

architecture rtl of mux2 is
begin
  PROC_COMB : process (all)
  begin
    case (sel) is
      when "0" =>
        q <= d0;
      when "1" =>
        q <= d1;
      when others =>
        null;
    end case;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mux4 is
  generic (
    G_DW : natural := 32
  );
  port (
    sel : in std_logic_vector(1 downto 0);
    d0  : in std_logic_vector(G_DW - 1 downto 0);
    d1  : in std_logic_vector(G_DW - 1 downto 0);
    d2  : in std_logic_vector(G_DW - 1 downto 0);
    d3  : in std_logic_vector(G_DW - 1 downto 0);
    q   : out std_logic_vector(G_DW - 1 downto 0)
  );
end entity mux4;

architecture rtl of mux4 is
begin
  PROC_COMB : process (all)
  begin
    case (sel) is
      when "00" =>
        q <= d0;
      when "01" =>
        q <= d1;
      when "10" =>
        q <= d2;
      when "11" =>
        q <= d3;
      when others =>
        null;
    end case;
  end process;
end architecture;