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
  signal alu_adr   : std_logic_vector(31 downto 0);

  signal rd_src : std_logic_vector(1 downto 0);

  signal lsu_ldout   : std_logic_vector(31 downto 0);
  signal lsu_size    : std_logic_vector(1 downto 0);
  signal lsu_signext : std_logic;
  signal ldout_latch : std_logic_vector(31 downto 0);

  signal imm_sel  : std_logic_vector(2 downto 0);
  signal imm_dout : std_logic_vector(31 downto 0);

  signal mem_mask, wb_mask : std_logic;

  signal b_ovr  : std_logic;
  signal b_cond : std_logic;

  type t_state is (
    S_fetch,
    S_decode,
    S_execute,
    S_memory,
    S_writeback
  );
  signal state : t_state := S_fetch;

  -- CSRs
  signal mcycle    : std_logic_vector(31 downto 0) := (others => '0');
  signal mcycleh   : std_logic_vector(31 downto 0) := (others => '0');
  signal minstret  : std_logic_vector(31 downto 0) := (others => '0');
  signal minstreth : std_logic_vector(31 downto 0) := (others => '0');

  signal minstret_ce : std_logic;

  signal csr_src  : std_logic_vector(1 downto 0);
  signal csr_dout : std_logic_vector(31 downto 0);

begin

  pc_plus_4 <= std_logic_vector(unsigned(pc) + 4);

  U_PCMUX : entity work.mux2
    generic map(G_DW => 32)
    port map
    (
      sel => pc_src and ((b_ovr or b_cond) & ""),
      d0  => pc_plus_4, --PCSRC_PCp4
      d1  => alu_z, -- PCSRC_ALU
      q   => pc_din
    );

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
      wb_mask     => wb_mask,
      csr_src     => csr_src
    );

  U_IMMEXT : entity work.immext
    port map
    (
      instr => instr,
      sel   => imm_sel,
      imm   => imm_dout
    );

  U_RDMUX : entity work.mux4
    generic map(G_DW => 32)
    port map
    (
      sel => rd_src,
      d0  => alu_z, -- RDSRC_ALU
      d1  => pc_plus_4, -- RDSRC_PCp4
      d2  => ldout_latch, -- RDSRC_MEM
      d3  => csr_dout,
      q   => rd_din
    );

  rd_we <= '1' when (state = S_writeback) else
    '0';
  U_REGFILE : entity work.regfile
    generic map(
      G_USE_BRAM => TRUE
    )
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

  U_ALU_XMUX : entity work.mux2
    generic map(G_DW => 32)
    port map
    (
      sel => alu_xsrc,
      d0  => rs1_dout, -- XSRC_RS1
      d1  => pc, -- XSRC_PC
      q   => alu_x
    );

  U_ALU_YMUX : entity work.mux2
    generic map(G_DW => 32)
    port map
    (
      sel => alu_ysrc,
      d0  => rs2_dout, -- YSRC_R
      d1  => imm_dout, -- YSRC_I
      q   => alu_y
    );

  U_ALU_SHMUX : entity work.mux2
    generic map(G_DW => 5)
    port map
    (
      sel => alu_shsrc,
      d0  => instr(24 downto 20), -- SHSRC_I
      d1  => rs2_dout(4 downto 0), -- SHSRC_R
      q   => alu_shamt
    );

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

  alu_adr <= std_logic_vector(signed(rs1_dout) + signed(imm_dout));

  U_LSU : entity work.lsu
    port map
    (
      offset  => alu_adr(1 downto 0),
      size    => lsu_size,
      signext => lsu_signext,

      ldin  => d_din,
      ldout => lsu_ldout,
      sdin  => rs2_dout,
      sdout => d_dout,
      sstrb => d_sel
    );

  U_MCYCLE_CTR : entity work.counter64
    port map
    (
      clk   => clk,
      reset => reset,
      ce    => '1',
      ql    => mcycle,
      qh    => mcycleh
    );

  U_MINSTRET_CTR : entity work.counter64
    port map
    (
      clk   => clk,
      reset => reset,
      ce    => minstret_ce,
      ql    => minstret,
      qh    => minstreth
    );

  minstret_ce <= '1' when (state = S_writeback) else
    '0';

  U_CSR_MUX : entity work.mux4
    generic map(G_DW => 32)
    port map
    (
      sel => csr_src,
      d0  => mcycle,
      d1  => mcycleh,
      d2  => minstret,
      d3  => minstreth,
      q   => csr_dout
    );

  i_cyc <= '1' when (state = S_fetch) else
    '0';
  i_stb <= i_cyc;
  i_adr <= pc;

  d_cyc <= mem_mask when (state = S_memory) else
    '0';
  d_stb <= d_cyc;
  d_adr <= alu_adr(31 downto 2) & "00";

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
      else
        case (state) is
          when S_fetch =>
            if i_ack = '1' then
              instr <= i_din;
              state <= S_decode;
            end if;

          when S_decode =>
            state <= S_execute;

          when S_execute =>
            state <= S_memory;

          when S_memory =>
            if mem_mask = '0' or d_ack = '1' then
              ldout_latch <= lsu_ldout;
              state       <= S_writeback;
            end if;

          when S_writeback =>
            pc    <= pc_din;
            state <= S_fetch;
        end case;
      end if;
    end if;
  end process;

end architecture;