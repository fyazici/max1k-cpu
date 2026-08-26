library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cpu_pkg.all;

entity lsu is
  port (
    offset  : in std_logic_vector(1 downto 0);
    size    : in std_logic_vector(1 downto 0);
    signext : in std_logic;

    ldin  : in std_logic_vector(31 downto 0);
    ldout : out std_logic_vector(31 downto 0);
    sdin  : in std_logic_vector(31 downto 0);
    sdout : out std_logic_vector(31 downto 0);
    sstrb : out std_logic_vector(3 downto 0)
  );
end entity lsu;

architecture rtl of lsu is
begin

  PROC_COMB : process (all)
  begin
    ldout <= (others => 'X');
    sdout <= (others => 'X');
    sstrb <= (others => 'X');

    case (size) is
      when LSU_BYTE =>
        if offset = "00" then
          ldout(7 downto 0)  <= ldin(7 downto 0);
          ldout(31 downto 8) <= (others => (signext and ldin(7)));
          sstrb              <= "0001";
        elsif offset = "01" then
          ldout(7 downto 0)  <= ldin(15 downto 8);
          ldout(31 downto 8) <= (others => (signext and ldin(15)));
          sstrb              <= "0010";
        elsif offset = "10" then
          ldout(7 downto 0)  <= ldin(23 downto 16);
          ldout(31 downto 8) <= (others => (signext and ldin(23)));
          sstrb              <= "0100";
        else
          ldout(7 downto 0)  <= ldin(31 downto 24);
          ldout(31 downto 8) <= (others => (signext and ldin(31)));
          sstrb              <= "1000";
        end if;
        sdout <= sdin(7 downto 0) & sdin(7 downto 0) & sdin(7 downto 0) & sdin(7 downto 0);
      when LSU_HALF =>
        if offset = "00" then
          ldout(15 downto 0)  <= ldin(15 downto 0);
          ldout(31 downto 16) <= (others => (signext and ldin(15)));
          sstrb               <= "0011";
        elsif offset = "10" then
          ldout(15 downto 0)  <= ldin(31 downto 16);
          ldout(31 downto 16) <= (others => (signext and ldin(31)));
          sstrb               <= "1100";
        end if;
        sdout <= sdin(15 downto 0) & sdin(15 downto 0);
      when LSU_WORD =>
        ldout <= ldin;
        sdout <= sdin;
        sstrb <= "1111";
      when others =>
        null;
    end case;
  end process;

end architecture;