library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stream_fifo is
  generic (
    G_DW : natural := 8;
    G_AW : natural := 4
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_valid : in std_logic;
    s_ready : out std_logic;
    s_data  : in std_logic_vector(G_DW - 1 downto 0);

    m_valid : out std_logic;
    m_ready : in std_logic;
    m_data  : out std_logic_vector(G_DW - 1 downto 0)
  );
end entity stream_fifo;

architecture rtl of stream_fifo is

  type t_mem is array (natural range <>) of std_logic_vector(G_DW - 1 downto 0);
  signal mem : t_mem(0 to (2 ** G_AW - 1));

  attribute ramstyle        : string;
  attribute ramstyle of mem : signal is "no_rw_check";

  signal wptr : unsigned(G_AW downto 0);
  signal rptr : unsigned(G_AW downto 0);

  signal ptr_eq : std_logic;
  signal full   : std_logic;
  signal empty  : std_logic;

  signal m_valid_int : std_logic;
  signal m_ready_int : std_logic;
  signal m_data_int  : std_logic_vector(G_DW - 1 downto 0);

begin

  s_ready     <= not(full);
  m_valid_int <= not(empty);

  ptr_eq <= '1' when (wptr(G_AW - 1 downto 0) = rptr(G_AW - 1 downto 0)) else
    '0';
  empty <= '1' when (ptr_eq = '1') and (wptr(G_AW) = rptr(G_AW)) else
    '0';
  full <= '1' when (ptr_eq = '1') and (wptr(G_AW) /= rptr(G_AW)) else
    '0';

  PROC_W : process (clk)
  begin
    if rising_edge(clk) then
      if s_valid = '1' and s_ready = '1' then
        wptr                                     <= wptr + 1;
        mem(to_integer(wptr(G_AW - 1 downto 0))) <= s_data;
      end if;
    end if;
  end process;

  PROC_R : process (clk)
  begin
    if rising_edge(clk) then
      if m_ready_int = '1' then
        if m_valid_int = '1' then
          rptr <= rptr + 1;
        end if;
        m_valid <= m_valid_int;
        m_data  <= mem(to_integer(rptr(G_AW - 1 downto 0)));
      end if;
    end if;
  end process;

  m_ready_int <= m_ready or not(m_valid);

end architecture;