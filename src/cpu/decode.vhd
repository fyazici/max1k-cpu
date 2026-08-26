library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cpu_pkg.all;

entity decode is
  port (
    instr : in std_logic_vector(31 downto 0);

    pc_src      : out std_logic_vector(0 downto 0);
    b_ovr       : out std_logic;
    rd_sel      : out std_logic_vector(4 downto 0);
    rs1_sel     : out std_logic_vector(4 downto 0);
    rs2_sel     : out std_logic_vector(4 downto 0);
    imm_sel     : out std_logic_vector(2 downto 0);
    alu_op      : out std_logic_vector(3 downto 0);
    alu_xsrc    : out std_logic_vector(0 downto 0);
    alu_ysrc    : out std_logic_vector(0 downto 0);
    alu_shsrc   : out std_logic_vector(0 downto 0);
    rd_src      : out std_logic_vector(1 downto 0);
    lsu_size    : out std_logic_vector(1 downto 0);
    lsu_signext : out std_logic;
    mem_mask    : out std_logic;
    mem_we      : out std_logic;
    wb_mask     : out std_logic;
    csr_src     : out std_logic_vector(1 downto 0)
  );
end entity decode;

architecture rtl of decode is

begin

  PROC_DEC : process (all)
  begin
    pc_src      <= PCSRC_PCp4;
    b_ovr       <= '0';
    rd_sel      <= instr(11 downto 7);
    rs1_sel     <= instr(19 downto 15);
    rs2_sel     <= instr(24 downto 20);
    imm_sel     <= ISEL_U;
    alu_op      <= instr(14 downto 12) & "0";
    alu_xsrc    <= XSRC_RS1;
    alu_ysrc    <= YSRC_I;
    alu_shsrc   <= SHSRC_I;
    rd_src      <= RDSRC_ALU;
    lsu_size    <= instr(13 downto 12);
    lsu_signext <= not(instr(14));
    mem_mask    <= '0';
    mem_we      <= '0';
    wb_mask     <= '0';
    csr_src     <= instr(21) & instr(27); -- FIXME: handle invalid cases

    case (instr(6 downto 2)) is
      when "01101"        => -- LUI
        rs1_sel  <= (others => '0');
        alu_xsrc <= XSRC_RS1;
        imm_sel  <= ISEL_U;
        alu_ysrc <= YSRC_I;
        alu_op   <= ALUOP_ADD;
        wb_mask  <= '1';

      when "00101" => -- AUIPC
        alu_xsrc <= XSRC_PC;
        imm_sel  <= ISEL_U;
        alu_ysrc <= YSRC_I;
        alu_op   <= ALUOP_ADD;
        rd_src   <= RDSRC_ALU;
        wb_mask  <= '1';

      when "11011" => -- JAL
        pc_src   <= PCSRC_ALU;
        b_ovr    <= '1';
        alu_xsrc <= XSRC_PC;
        imm_sel  <= ISEL_J;
        alu_ysrc <= YSRC_I;
        alu_op   <= ALUOP_ADD;
        rd_src   <= RDSRC_PCp4;
        wb_mask  <= '1';

      when "11001" => -- JALR
        pc_src   <= PCSRC_ALU;
        b_ovr    <= '1';
        alu_xsrc <= XSRC_RS1;
        imm_sel  <= ISEL_I;
        alu_ysrc <= YSRC_I;
        alu_op   <= ALUOP_ADD;
        rd_src   <= RDSRC_PCp4;
        wb_mask  <= '1';

      when "11000" => -- Bxx
        pc_src   <= PCSRC_ALU;
        b_ovr    <= '0';
        imm_sel  <= ISEL_B;
        alu_op   <= ALUOP_ADD;
        alu_xsrc <= XSRC_PC;
        alu_ysrc <= YSRC_I;

      when "00000" => -- Lxx
        alu_xsrc <= XSRC_RS1;
        imm_sel  <= ISEL_I;
        alu_ysrc <= YSRC_I;
        alu_op   <= ALUOP_ADD;
        rd_src   <= RDSRC_MEM;
        mem_mask <= '1';
        wb_mask  <= '1';

      when "01000" => -- Sxx
        alu_xsrc <= XSRC_RS1;
        imm_sel  <= ISEL_S;
        alu_ysrc <= YSRC_I;
        alu_op   <= ALUOP_ADD;
        mem_mask <= '1';
        mem_we   <= '1';

      when "00100" => -- ALU-I
        imm_sel <= ISEL_I;
        if instr(14 downto 12) = "101" then -- SRA?
          alu_op <= instr(14 downto 12) & instr(30);
        else
          alu_op <= instr(14 downto 12) & "0";
        end if;
        alu_xsrc  <= XSRC_RS1;
        alu_ysrc  <= YSRC_I;
        alu_shsrc <= SHSRC_I;
        rd_src    <= RDSRC_ALU;
        wb_mask   <= '1';

      when "01100" => -- ALU-R
        if instr(14 downto 12) = "000" then -- SUB?
          alu_op <= instr(14 downto 12) & instr(30);
        else
          alu_op <= instr(14 downto 12) & "0";
        end if;
        alu_xsrc  <= XSRC_RS1;
        alu_ysrc  <= YSRC_R;
        alu_shsrc <= SHSRC_R;
        rd_src    <= RDSRC_ALU;
        wb_mask   <= '1';

      when "11100" => -- SYSTEM
        -- FIXME: cover all cases
        rd_src  <= RDSRC_CSR;
        wb_mask <= '1';

      when others => -- NOP
        null;
    end case;
  end process;

end architecture;