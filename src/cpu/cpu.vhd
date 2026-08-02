library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cpu_pkg.all;

entity cpu is
  generic (
    G_RESET_VEC : std_logic_vector(31 downto 0) := (others => '0')
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    -- instruction memory intf
    i_adr : out std_logic_vector(31 downto 0);
    i_din : in std_logic_vector(31 downto 0);
    i_stb : out std_logic;
    i_cyc : out std_logic;
    i_ack : in std_logic;

    -- data memory intf
    d_adr  : out std_logic_vector(31 downto 0);
    d_din  : in std_logic_vector(31 downto 0);
    d_dout : out std_logic_vector(31 downto 0);
    d_we   : out std_logic;
    d_sel  : out std_logic_vector(3 downto 0);
    d_stb  : out std_logic;
    d_cyc  : out std_logic;
    d_ack  : in std_logic
  );
end entity cpu;

architecture rtl of cpu is

  signal pc        : std_logic_vector(31 downto 0) := (others => 'X');
  signal pc_plus_4 : std_logic_vector(31 downto 0);
  signal pc_din    : std_logic_vector(31 downto 0);
  signal pc_src    : std_logic_vector(0 downto 0);

  signal instr : std_logic_vector(31 downto 0);

  signal rd_sel   : std_logic_vector(4 downto 0);
  signal rd_din   : std_logic_vector(31 downto 0);
  signal rd_we    : std_logic;
  signal rs1_sel  : std_logic_vector(4 downto 0);
  signal rs1_dout : std_logic_vector(31 downto 0);
  signal rs2_sel  : std_logic_vector(4 downto 0);
  signal rs2_dout : std_logic_vector(31 downto 0);

  signal alu_op    : std_logic_vector(3 downto 0);
  signal alu_xsrc  : std_logic_vector(0 downto 0);
  signal alu_x     : std_logic_vector(31 downto 0);
  signal alu_ysrc  : std_logic_vector(0 downto 0);
  signal alu_y     : std_logic_vector(31 downto 0);
  signal alu_shsrc : std_logic_vector(0 downto 0);
  signal alu_shamt : std_logic_vector(4 downto 0);
  signal alu_z     : std_logic_vector(31 downto 0);

  signal rd_src : std_logic_vector(1 downto 0);

  signal lsu_ldout   : std_logic_vector(31 downto 0);
  signal lsu_size    : std_logic_vector(1 downto 0);
  signal lsu_signext : std_logic;

  signal imm_sel  : std_logic_vector(2 downto 0);
  signal imm_dout : std_logic_vector(31 downto 0);

  signal mem_mask, wb_mask : std_logic;

  signal b_ovr  : std_logic;
  signal b_cond : std_logic;

  type t_state is (
    S_fetch, S_fetch_1,
    S_decode,
    S_execute,
    S_memory, S_memory_1,
    S_writeback
  );
  signal state : t_state := S_fetch;

begin

  PROC_PC_MUX : process (pc, pc_src, pc_plus_4, b_ovr, b_cond, alu_z)
  begin
    pc_din    <= (others => 'X');
    pc_plus_4 <= std_logic_vector(unsigned(pc) + 4);
    case (pc_src) is
      when PCSRC_PCp4 =>
        pc_din <= pc_plus_4;
      when PCSRC_ALU =>
        if b_ovr = '1' or b_cond = '1' then
          pc_din <= alu_z;
        else
          pc_din <= pc_plus_4;
        end if;
      when others =>
        null;
    end case;
  end process;

  U_DECODE : entity work.decode
    port map
    (
      clk         => clk,
      instr       => instr,
      pc_src      => pc_src,
      b_ovr       => b_ovr,
      rd_sel      => rd_sel,
      rs1_sel     => rs1_sel,
      rs2_sel     => rs2_sel,
      imm_sel     => imm_sel,
      alu_op      => alu_op,
      alu_xsrc    => alu_xsrc,
      alu_ysrc    => alu_ysrc,
      alu_shsrc   => alu_shsrc,
      rd_src      => rd_src,
      lsu_size    => lsu_size,
      lsu_signext => lsu_signext,
      mem_mask    => mem_mask,
      mem_we      => d_we,
      wb_mask     => wb_mask
    );

  U_IMMEXT : entity work.immext
    port map
    (
      instr => instr,
      sel   => imm_sel,
      imm   => imm_dout
    );

  PROC_RDMUX : process (rd_src, alu_z, pc_plus_4, lsu_ldout)
  begin
    rd_din <= (others => 'X');
    case (rd_src) is
      when RDSRC_ALU =>
        rd_din <= alu_z;
      when RDSRC_PCp4 =>
        rd_din <= pc_plus_4;
      when RDSRC_MEM =>
        rd_din <= lsu_ldout;
      when others =>
        null;
    end case;
  end process;

  rd_we <= '1' when (state = S_writeback) else
    '0';
  U_REGFILE : entity work.regfile
    port map
    (
      clk   => clk,
      reset => reset,

      rd_sel   => rd_sel,
      rd_din   => rd_din,
      rd_we    => rd_we and wb_mask,
      rs1_sel  => rs1_sel,
      rs1_dout => rs1_dout,
      rs2_sel  => rs2_sel,
      rs2_dout => rs2_dout
    );

  U_BCOND : entity work.bcond
    port map
    (
      clk  => clk,
      rs1  => rs1_dout,
      rs2  => rs2_dout,
      sel  => instr(14 downto 12),
      cond => b_cond
    );

  PROC_ALU_XMUX : process (alu_xsrc, rs1_dout, pc)
  begin
    alu_x <= (others => 'X');
    case (alu_xsrc) is
      when XSRC_RS1 =>
        alu_x <= rs1_dout;
      when XSRC_PC =>
        alu_x <= pc;
      when others =>
        null;
    end case;
  end process;

  PROC_ALU_YMUX : process (alu_ysrc, rs2_dout, imm_dout)
  begin
    alu_y <= (others => 'X');
    case (alu_ysrc) is
      when YSRC_R => -- R-type
        alu_y <= rs2_dout;
      when YSRC_I => -- I-type
        alu_y <= imm_dout;
      when others =>
        null;
    end case;
  end process;

  PROC_ALU_SHMUX : process (alu_shsrc, instr, rs2_dout)
  begin
    alu_shamt <= (others => 'X');
    case (alu_shsrc) is
      when SHSRC_I => -- I-type
        alu_shamt <= instr(24 downto 20);
      when SHSRC_R => -- R-type
        alu_shamt <= rs2_dout(4 downto 0);
      when others =>
        null;
    end case;
  end process;

  U_ALU : entity work.alu
    port map
    (
      clk   => clk,
      op    => alu_op,
      shamt => alu_shamt,
      x     => alu_x,
      y     => alu_y,
      z     => alu_z
    );

  U_LSU : entity work.lsu
    port map
    (
      clk     => clk,
      offset  => alu_z(1 downto 0),
      size    => lsu_size,
      signext => lsu_signext,

      ldin  => d_din,
      ldout => lsu_ldout,
      sdin  => rs2_dout,
      sdout => d_dout,
      sstrb => d_sel
    );

  i_adr <= pc;
  d_adr <= alu_z(31 downto 2) & "00";

  -- DOCs:
  -- https://docs.riscv.org/reference/isa/unpriv/rv32.html
  -- https://vivonomicon.com/2020/06/13/lets-write-a-minimal-risc-v-cpu-in-nmigen/
  -- https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#jal
  PROC_CU : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pc    <= G_RESET_VEC;
        state <= S_fetch;
        i_stb <= '0';
        i_cyc <= '0';
        d_stb <= '0';
        d_cyc <= '0';
      else
        case (state) is
          when S_fetch =>
            i_cyc <= '1';
            i_stb <= '1';
            state <= S_fetch_1;

          when S_fetch_1 =>
            if i_ack = '1' then
              instr <= i_din;
              i_cyc <= '0';
              i_stb <= '0';
              state <= S_decode;
            end if;

          when S_decode =>
            state <= S_execute;

          when S_execute =>
            state <= S_memory;

          when S_memory =>
            if mem_mask = '1' then
              d_cyc <= '1';
              d_stb <= '1';
              state <= S_memory_1;
            else
              state <= S_writeback;
            end if;

          when S_memory_1 =>
            if d_ack = '1' then
              d_cyc <= '0';
              d_stb <= '0';
              state <= S_writeback;
            end if;

          when S_writeback =>
            pc    <= pc_din;
            state <= S_fetch;
        end case;
      end if;
    end if;
  end process;

end architecture;