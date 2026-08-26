library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity regfile is
  generic (
    G_USE_BRAM : boolean := FALSE
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    rd_sel : in std_logic_vector(4 downto 0);
    rd_din : in std_logic_vector(31 downto 0);
    rd_we  : in std_logic;

    rs1_sel  : in std_logic_vector(4 downto 0);
    rs1_dout : out std_logic_vector(31 downto 0);

    rs2_sel  : in std_logic_vector(4 downto 0);
    rs2_dout : out std_logic_vector(31 downto 0)
  );
end entity regfile;

architecture rtl of regfile is

begin

  G_NO_BRAM : if G_USE_BRAM = FALSE generate
    B_NO_BRAM : block
      type t_regs is array (31 downto 0) of std_logic_vector(31 downto 0);
      signal regs : t_regs := (others => (others => '0'));
    begin

      PROC_SEQ : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            regs <= (others => (others => '0'));
          else
            if rd_we = '1' then
              regs(to_integer(unsigned(rd_sel))) <= rd_din;
            end if;

            -- x0 is always 0
            regs(0) <= (others => '0');
          end if;
        end if;
      end process;

      rs1_dout <= regs(to_integer(unsigned(rs1_sel)));
      rs2_dout <= regs(to_integer(unsigned(rs2_sel)));
    end block;
  end generate;

  G_YES_BRAM : if G_USE_BRAM = TRUE generate
    B_YES_BRAM : block
      type t_regs is array (31 downto 0) of std_logic_vector(31 downto 0);
      signal mem0 : t_regs := (others => (others => '0'));
      signal mem1 : t_regs := (others => (others => '0'));

      attribute ramstyle         : string;
      attribute ramstyle of mem0 : signal is "no_rw_check";
      attribute ramstyle of mem1 : signal is "no_rw_check";

      signal rd_we_int : std_logic;
    begin

      -- prevent write to x0
      rd_we_int <= rd_we when (unsigned(rd_sel) /= 0) else
        '0';

      PROC_SEQ : process (clk)
      begin
        if rising_edge(clk) then
          if rd_we_int = '1' then
            mem0(to_integer(unsigned(rd_sel))) <= rd_din;
            mem1(to_integer(unsigned(rd_sel))) <= rd_din;
          end if;
        end if;
      end process;

      rs1_dout <= mem0(to_integer(unsigned(rs1_sel)));
      rs2_dout <= mem1(to_integer(unsigned(rs2_sel)));

    end block;
  end generate;

end architecture;