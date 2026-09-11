library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.wb_pkg.all;

entity wb_Nx1 is
  generic (
    N  : natural;
    AW : natural;
    DW : natural
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_cyc  : in std_logic_vector(N - 1 downto 0);
    s_stb  : in std_logic_vector(N - 1 downto 0);
    s_adr  : in t_slv_arr(N - 1 downto 0)(AW - 1 downto 0);
    s_we   : in std_logic_vector(N - 1 downto 0);
    s_sel  : in t_slv_arr(N - 1 downto 0)(DW/8 - 1 downto 0);
    s_din  : in t_slv_arr(N - 1 downto 0)(DW - 1 downto 0);
    s_dout : out t_slv_arr(N - 1 downto 0)(DW - 1 downto 0);
    s_ack  : out std_logic_vector(N - 1 downto 0);

    m_cyc  : out std_logic;
    m_stb  : out std_logic;
    m_adr  : out std_logic_vector(AW - 1 downto 0);
    m_we   : out std_logic;
    m_sel  : out std_logic_vector(DW/8 - 1 downto 0);
    m_dout : out std_logic_vector(DW - 1 downto 0);
    m_din  : in std_logic_vector(DW - 1 downto 0);
    m_ack  : in std_logic
  );
end entity wb_Nx1;

architecture rtl of wb_Nx1 is

  type t_state is (
    S_idle,
    S_active
  );
  signal state : t_state := S_idle;

  signal pri_valid : std_logic;
  signal pri_index : natural range 0 to N - 1;
  signal grant     : natural range 0 to N - 1 := 0;

begin

  PROC_COMB_PRI : process (all)
  begin
    pri_valid <= '0';
    pri_index <= 0;
    for I in N - 1 downto 0 loop
      if s_cyc(I) = '1' then
        pri_valid <= '1';
        pri_index <= I;
      end if;
    end loop;
  end process;

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        grant <= 0;
        state <= S_idle;
      else
        case (state) is
          when S_idle =>
            if pri_valid = '1' then
              grant <= pri_index;
              state <= S_active;
            end if;
          when S_active =>
            if s_cyc(grant) = '0' or m_ack = '1' then
              if pri_valid = '1' then
                grant <= pri_index;
              else
                state <= S_idle;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  PROC_COMB_MUX : process (all)
  begin
    s_ack <= (others => '0');
    case (state) is
      when S_idle =>
        m_cyc <= '0';
        m_stb <= '0';
      when S_active =>
        m_cyc        <= s_cyc(grant);
        m_stb        <= s_stb(grant);
        s_ack(grant) <= m_ack;
    end case;

    m_adr  <= s_adr(grant);
    m_we   <= s_we(grant);
    m_sel  <= s_sel(grant);
    m_dout <= s_din(grant);
    for I in 0 to N - 1 loop
      s_dout(I) <= m_din;
    end loop;
  end process;

end architecture;