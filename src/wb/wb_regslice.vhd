library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_regslice is
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

    m_cyc  : out std_logic;
    m_stb  : out std_logic;
    m_adr  : out std_logic_vector(31 downto 0);
    m_we   : out std_logic;
    m_sel  : out std_logic_vector(3 downto 0);
    m_dout : out std_logic_vector(31 downto 0);
    m_din  : in std_logic_vector(31 downto 0);
    m_ack  : in std_logic
  );
end entity wb_regslice;

architecture rtl of wb_regslice is

  type t_state is (
    S_idle,
    S_busy
  );
  signal state : t_state := S_idle;
begin

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        m_cyc <= '0';
        m_stb <= '0';
        s_ack <= '0';
        state <= S_idle;
      else
        s_ack <= '0';
        case (state) is
          when S_idle =>
            if s_cyc = '1' and s_stb = '1' and s_ack = '0' then
              m_cyc  <= '1';
              m_stb  <= '1';
              m_we   <= s_we;
              m_sel  <= s_sel;
              m_adr  <= s_adr;
              m_dout <= s_din;
              state  <= S_busy;
            end if;
          when S_busy =>
            if m_ack = '1' then
              m_cyc  <= '0';
              m_stb  <= '0';
              s_dout <= m_din;
              s_ack  <= '1';
              state  <= S_idle;
            end if;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

end architecture;