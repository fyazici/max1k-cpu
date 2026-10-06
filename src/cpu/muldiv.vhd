library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity divremu is
  generic (
    DW : natural := 32
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;
    start : in std_logic;
    n     : in std_logic_vector(DW - 1 downto 0);
    d     : in std_logic_vector(DW - 1 downto 0);
    done  : out std_logic;
    q     : out std_logic_vector(DW - 1 downto 0);
    r     : out std_logic_vector(DW - 1 downto 0)
  );
end entity divremu;

architecture rtl of divremu is
  type t_state is (S_idle, S_loop, S_rem, S_done);
  signal state : t_state := S_idle;

  signal ctr : natural range 0 to DW - 1;
  signal ar  : signed(DW downto 0);
  signal mr  : signed(DW downto 0);
  signal qr  : std_logic_vector(DW - 1 downto 0);
begin
  PROC_SEQ : process (clk)
    variable ar_next : signed(DW downto 0);
    variable qr_next : std_logic_vector(DW - 1 downto 0);
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S_idle;
      else
        done <= '0';
        case (state) is
          when S_idle =>
            if start = '1' and done = '0' then
              ar    <= (others => '0');
              mr    <= signed("0" & d);
              qr    <= n;
              ctr   <= DW - 1;
              state <= S_loop;
            end if;
          when S_loop =>
            ar_next := ar(ar'high - 1 downto 0) & qr(qr'high);
            qr_next := qr(qr'high - 1 downto 0) & "0";
            if ar >= 0 then
              ar_next := ar_next - mr;
            else
              ar_next := ar_next + mr;
            end if;
            if ar_next >= 0 then
              qr_next(0) := '1';
            else
              qr_next(0) := '0';
            end if;
            ar <= ar_next;
            qr <= qr_next;
            if ctr > 0 then
              ctr <= ctr - 1;
            else
              state <= S_rem;
            end if;
          when S_rem =>
            if ar < 0 then
              ar <= ar + mr;
            end if;
            state <= S_done;
          when S_done =>
            q     <= std_logic_vector(qr);
            r     <= std_logic_vector(ar(DW - 1 downto 0));
            done  <= '1';
            state <= S_idle;
        end case;
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity divrems is
  generic (
    DW : natural := 32
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;
    start : in std_logic;
    n     : in std_logic_vector(DW - 1 downto 0);
    d     : in std_logic_vector(DW - 1 downto 0);
    done  : out std_logic;
    q     : out std_logic_vector(DW - 1 downto 0);
    r     : out std_logic_vector(DW - 1 downto 0)
  );
end entity divrems;

architecture rtl of divrems is
  signal n_sign : std_logic;
  signal d_sign : std_logic;
  signal n_abs  : std_logic_vector(DW - 1 downto 0);
  signal d_abs  : std_logic_vector(DW - 1 downto 0);
  signal q_abs  : std_logic_vector(DW - 1 downto 0);
  signal r_abs  : std_logic_vector(DW - 1 downto 0);
begin
  PROC_COMB : process (all)
  begin
    n_sign <= n(n'high);
    d_sign <= d(d'high);
    if n_sign = '1' then
      n_abs <= std_logic_vector(-signed(n));
    else
      n_abs <= n;
    end if;
    if d_sign = '1' then
      d_abs <= std_logic_vector(-signed(d));
    else
      d_abs <= d;
    end if;
    if n_sign /= d_sign then
      q <= std_logic_vector(resize(-signed("0" & q_abs), DW));
    else
      q <= q_abs;
    end if;
    if n_sign = '1' then
      r <= std_logic_vector(resize(-signed("0" & r_abs), DW));
    else
      r <= r_abs;
    end if;
  end process;

  U_DIVREMU : entity work.divremu
    generic map(DW => DW)
    port map
    (
      clk   => clk,
      reset => reset,
      start => start,
      n     => n_abs,
      d     => d_abs,
      done  => done,
      q     => q_abs,
      r     => r_abs
    );
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library lpm;
use lpm.all;

use work.cpu_pkg.all;

entity muldiv is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    valid : in std_logic;
    stall : out std_logic;

    op : in std_logic_vector(2 downto 0);
    x  : in std_logic_vector(31 downto 0);
    y  : in std_logic_vector(31 downto 0);
    z  : out std_logic_vector(31 downto 0)
  );
end entity muldiv;

architecture rtl of muldiv is

  component lpm_mult
    generic (
      lpm_hint           : string;
      lpm_pipeline       : natural;
      lpm_representation : string;
      lpm_type           : string;
      lpm_widtha         : natural;
      lpm_widthb         : natural;
      lpm_widthp         : natural
    );
    port (
      clock  : in std_logic;
      dataa  : in std_logic_vector (32 downto 0);
      datab  : in std_logic_vector (32 downto 0);
      result : out std_logic_vector (65 downto 0)
    );
  end component;

  constant C_MUL_LATENCY : natural                          := 2;
  signal ctr             : natural range 0 to C_MUL_LATENCY := 0;

  signal div_start : std_logic;
  signal div_done  : std_logic;
  signal done      : std_logic := '0';

  type t_state is (S_idle, S_reg, S_mul, S_div);
  signal state : t_state := S_idle;

  signal op_a  : std_logic_vector(32 downto 0) := (others => '0');
  signal op_b  : std_logic_vector(32 downto 0) := (others => '0');
  signal mul_z : std_logic_vector(65 downto 0) := (others => '0');
  signal div_q : std_logic_vector(32 downto 0) := (others => '0');
  signal div_r : std_logic_vector(32 downto 0) := (others => '0');

begin

  stall <= valid and not(done);

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        div_start <= '0';
        done      <= '0';
        state     <= S_idle;
      else
        div_start <= '0';
        done      <= '0';
        case (state) is
          when S_idle =>
            if valid = '1' and done = '0' then
              -- x and y come 1 cycle later
              state <= S_reg;
            end if;
          when S_reg =>
            case (op) is
              when MULDIVOP_MUL =>
                op_a  <= x(x'high) & x;
                op_b  <= y(y'high) & y;
                ctr   <= C_MUL_LATENCY;
                state <= S_mul;
              when MULDIVOP_MULH =>
                op_a  <= x(x'high) & x;
                op_b  <= y(y'high) & y;
                ctr   <= C_MUL_LATENCY;
                state <= S_mul;
              when MULDIVOP_MULHSU =>
                op_a  <= x(x'high) & x;
                op_b  <= '0' & y;
                ctr   <= C_MUL_LATENCY;
                state <= S_mul;
              when MULDIVOP_MULHU =>
                op_a  <= '0' & x;
                op_b  <= '0' & y;
                ctr   <= C_MUL_LATENCY;
                state <= S_mul;
              when MULDIVOP_DIV =>
                op_a      <= x(x'high) & x;
                op_b      <= y(y'high) & y;
                div_start <= '1';
                state     <= S_div;
              when MULDIVOP_DIVU =>
                op_a      <= '0' & x;
                op_b      <= '0' & y;
                div_start <= '1';
                state     <= S_div;
              when MULDIVOP_REM =>
                op_a      <= x(x'high) & x;
                op_b      <= y(y'high) & y;
                div_start <= '1';
                state     <= S_div;
              when MULDIVOP_REMU =>
                op_a      <= '0' & x;
                op_b      <= '0' & y;
                div_start <= '1';
                state     <= S_div;
              when others =>
                state <= S_idle;
            end case;
          when S_mul =>
            if ctr > 0 then
              ctr <= ctr - 1;
            else
              case (op) is
                when MULDIVOP_MUL =>
                  z <= mul_z(31 downto 0);
                when MULDIVOP_MULH =>
                  z <= mul_z(63 downto 32);
                when MULDIVOP_MULHSU =>
                  z <= mul_z(63 downto 32);
                when MULDIVOP_MULHU =>
                  z <= mul_z(63 downto 32);
                when others  =>
                  z <= (others => 'X');
              end case;
              done  <= '1';
              state <= S_idle;
            end if;
          when S_div =>
            if div_done = '1' then
              case (op) is
                when MULDIVOP_DIV =>
                  z <= div_q(31 downto 0);
                when MULDIVOP_DIVU =>
                  z <= div_q(31 downto 0);
                when MULDIVOP_REM =>
                  z <= div_r(31 downto 0);
                when MULDIVOP_REMU =>
                  z <= div_r(31 downto 0);
                when others  =>
                  z <= (others => 'X');
              end case;
              done  <= '1';
              state <= S_idle;
            end if;
        end case;
      end if;
    end if;
  end process;

  U_MUL : LPM_MULT
  generic map(
    lpm_hint           => "MAXIMIZE_SPEED=5",
    lpm_pipeline       => C_MUL_LATENCY,
    lpm_representation => "SIGNED",
    lpm_type           => "LPM_MULT",
    lpm_widtha         => 33,
    lpm_widthb         => 33,
    lpm_widthp         => 66
  )
  port map
  (
    clock  => clk,
    dataa  => op_a,
    datab  => op_b,
    result => mul_z
  );

  U_DIV : entity work.divrems
    generic map(DW => 33)
    port map
    (
      clk   => clk,
      reset => reset,
      start => div_start,
      n     => op_a,
      d     => op_b,
      done  => div_done,
      q     => div_q,
      r     => div_r
    );

end architecture;