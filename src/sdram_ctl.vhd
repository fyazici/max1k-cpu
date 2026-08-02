library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity sdram_ctl is
  generic (
    G_BURST_LEN : natural := 1
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    cyc  : in std_logic;
    stb  : in std_logic;
    ack  : out std_logic;
    adr  : in std_logic_vector(31 downto 0);
    we   : in std_logic;
    din  : in std_logic_vector(G_BURST_LEN * 16 - 1 downto 0);
    sel  : in std_logic_vector(G_BURST_LEN * 2 - 1 downto 0);
    dout : out std_logic_vector(G_BURST_LEN * 16 - 1 downto 0);

    SDRAM_A   : out std_logic_vector(11 downto 0);
    SDRAM_BA  : out std_logic_vector(1 downto 0);
    SDRAM_CLK : out std_logic;
    SDRAM_CKE : out std_logic;
    SDRAM_CAS : out std_logic;
    SDRAM_CS  : out std_logic;
    SDRAM_RAS : out std_logic;
    SDRAM_WE  : out std_logic;
    SDRAM_DQM : out std_logic_vector(1 downto 0) := (others => '1');
    SDRAM_DQ  : inout std_logic_vector(15 downto 0)
  );
end entity sdram_ctl;

architecture rtl of sdram_ctl is

  type t_state is (
    S_init, S_init_1, S_init_2, S_init_3,
    S_idle,
    S_active,
    S_write, S_write_burst,
    S_read,
    S_read_1, S_read_1_burst,
    S_precharge
  );

  signal state : t_state := S_init;

  constant CMD_LOADMODE    : std_logic_vector(2 downto 0) := "000";
  constant CMD_REFRESH     : std_logic_vector(2 downto 0) := "001";
  constant CMD_PRECHARGE   : std_logic_vector(2 downto 0) := "010";
  constant CMD_ACTIVE      : std_logic_vector(2 downto 0) := "011";
  constant CMD_WRITE       : std_logic_vector(2 downto 0) := "100";
  constant CMD_READ        : std_logic_vector(2 downto 0) := "101";
  constant CMD_NOP         : std_logic_vector(2 downto 0) := "111";
  constant CMD_AUTOREFRESH : std_logic_vector(2 downto 0) := "001";

  signal SDRAM_CMD : std_logic_vector(2 downto 0) := CMD_NOP;

  signal ctr_tmr : natural := 0;
  signal ctr_aux : natural := 0;

  constant t_RP  : natural := 3; -- >15 ns
  constant t_RSC : natural := 1;
  constant t_RC  : natural := 10; -- >60 ns
  constant t_RCD : natural := 3; -- >15 ns
  constant t_WR  : natural := 2 + 1; -- BL=1 => tRAS>42
  constant t_CAS : natural := 2; -- mode reg
  constant t_REF : natural := 64000000/4096/13; -- 64ms/4096/??ns

  signal ctr_ref : natural := t_REF;

  signal adr_int : std_logic_vector(21 downto 0);

begin

  assert (G_BURST_LEN = 1) or (G_BURST_LEN = 2) or (G_BURST_LEN = 4) or (G_BURST_LEN = 8) report "unsupported burst length " & integer'image(G_BURST_LEN) severity error;

  SDRAM_CS  <= '0';
  SDRAM_CKE <= '1';
  SDRAM_CLK <= clk;

  (SDRAM_RAS, SDRAM_CAS, SDRAM_WE) <= SDRAM_CMD;

  G_BL1 : if G_BURST_LEN = 1 generate
    adr_int <= adr(22 downto 1);
  end generate;
  G_BL2 : if G_BURST_LEN = 2 generate
    adr_int <= adr(22 downto 2) & "0";
  end generate;
  G_BL4 : if G_BURST_LEN = 4 generate
    adr_int <= adr(22 downto 3) & "00";
  end generate;
  G_BL8 : if G_BURST_LEN = 8 generate
    adr_int <= adr(22 downto 4) & "000";
  end generate;

  PROC_FSM : process (clk)
  begin
    if rising_edge(clk) then
      -- default
      SDRAM_CMD <= CMD_NOP;
      SDRAM_BA  <= (others => '0');
      SDRAM_A   <= (others => '0');
      --SDRAM_DQM <= (others => '1');
      SDRAM_DQ <= (others => 'Z');

      ack <= '0';

      if reset = '1' then
        state   <= S_init;
        ctr_tmr <= 0;
        ctr_ref <= t_REF;
      else
        if ctr_ref > 0 then
          ctr_ref <= ctr_ref - 1;
        end if;

        if ctr_tmr > 0 then
          ctr_tmr <= ctr_tmr - 1;
        else
          SDRAM_DQM <= (others => '1');
          case (state) is
              -- Init Sequence --
            when S_init =>
              SDRAM_CMD   <= CMD_PRECHARGE;
              SDRAM_A(10) <= '1'; -- all banks
              ctr_tmr     <= t_RP;
              state       <= S_init_1;
            when S_init_1 =>
              SDRAM_CMD <= CMD_LOADMODE;
              SDRAM_BA  <= (others => '0');
              case (G_BURST_LEN) is
                when 1      => SDRAM_A <= "000000100000"; -- BRBW, CL2, SEQ, BL1
                when 2      => SDRAM_A <= "000000100001"; -- BRBW, CL2, SEQ, BL2
                when 4      => SDRAM_A <= "000000100010"; -- BRBW, CL2, SEQ, BL4
                when 8      => SDRAM_A <= "000000100011"; -- BRBW, CL2, SEQ, BL8
                when others => null;
              end case;
              ctr_tmr <= t_RSC;
              state   <= S_init_2;
            when S_init_2 =>
              SDRAM_CMD <= CMD_AUTOREFRESH;
              ctr_tmr   <= t_RC;
              ctr_aux   <= 1;
              state     <= S_init_3;
            when S_init_3 =>
              SDRAM_CMD <= CMD_AUTOREFRESH;
              ctr_tmr   <= t_RC;
              if ctr_aux < 8 then
                ctr_aux <= ctr_aux + 1;
              else
                state <= S_idle;
              end if;
              -- Operation --
            when S_idle =>
              if ctr_ref > 0 then
                if cyc = '1' and stb = '1' then
                  SDRAM_CMD <= CMD_ACTIVE;
                  SDRAM_BA  <= adr_int(21 downto 20);
                  SDRAM_A   <= adr_int(19 downto 8);
                  ctr_tmr   <= t_RCD;
                  if we = '1' then
                    state <= S_write;
                  else
                    state <= S_read;
                  end if;
                end if;
              else
                SDRAM_CMD <= CMD_AUTOREFRESH;
                ctr_ref   <= t_REF;
                ctr_tmr   <= t_RC;
              end if;

            when S_write =>
              SDRAM_CMD           <= CMD_WRITE;
              SDRAM_A(10)         <= '0'; -- no AP
              SDRAM_A(7 downto 0) <= adr_int(7 downto 0);
              SDRAM_DQ            <= din(15 downto 0);
              SDRAM_DQM           <= not(sel(1 downto 0));
              if G_BURST_LEN = 1 then
                ack     <= '1';
                ctr_tmr <= t_WR;
                state   <= S_precharge;
              else
                ctr_tmr <= 0;
                ctr_aux <= 1;
                state   <= S_write_burst;
              end if;

            when S_write_burst =>
              ctr_aux   <= ctr_aux + 1;
              SDRAM_DQ  <= din(ctr_aux * 16 + 15 downto ctr_aux * 16);
              SDRAM_DQM <= not(sel(ctr_aux * 2 + 1 downto ctr_aux * 2));
              ctr_tmr   <= 0;
              if ctr_aux = (G_BURST_LEN - 1) then
                ack     <= '1';
                ctr_tmr <= t_WR;
                state   <= S_precharge;
              end if;

            when S_read =>
              SDRAM_CMD           <= CMD_READ;
              SDRAM_A(10)         <= '0'; -- no AP
              SDRAM_A(7 downto 0) <= adr_int(7 downto 0);
              SDRAM_DQM           <= "00";
              ctr_tmr             <= t_CAS;
              state               <= S_read_1;

            when S_read_1 =>
              SDRAM_DQM         <= "00";
              dout(15 downto 0) <= SDRAM_DQ;
              if G_BURST_LEN = 1 then
                ack   <= '1';
                state <= S_precharge;
              else
                ctr_tmr <= 0;
                ctr_aux <= 1;
                state   <= S_read_1_burst;
              end if;

            when S_read_1_burst =>
              ctr_aux                                     <= ctr_aux + 1;
              SDRAM_DQM                                   <= "00";
              dout(ctr_aux * 16 + 15 downto ctr_aux * 16) <= SDRAM_DQ;
              ctr_tmr                                     <= 0;
              if ctr_aux = (G_BURST_LEN - 1) then
                ack   <= '1';
                state <= S_precharge;
              end if;

            when S_precharge =>
              SDRAM_CMD   <= CMD_PRECHARGE;
              SDRAM_A(10) <= '1'; -- all banks
              ctr_tmr     <= t_RP;
              state       <= S_idle;

            when others =>
              null;
          end case;
        end if;
      end if;
    end if;
  end process;

end architecture;