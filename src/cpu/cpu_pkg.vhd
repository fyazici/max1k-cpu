library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package cpu_pkg is
  constant RS1_ZERO : std_logic_vector(4 downto 0) := "00000";

  constant PCSRC_PCp4 : std_logic_vector(0 downto 0) := "0";
  constant PCSRC_ALU  : std_logic_vector(0 downto 0) := "1";

  constant BEQ  : std_logic_vector(2 downto 0) := "000";
  constant BNE  : std_logic_vector(2 downto 0) := "001";
  constant BLT  : std_logic_vector(2 downto 0) := "100";
  constant BGE  : std_logic_vector(2 downto 0) := "101";
  constant BLTU : std_logic_vector(2 downto 0) := "110";
  constant BGEU : std_logic_vector(2 downto 0) := "111";

  constant XSRC_RS1 : std_logic_vector(0 downto 0) := "0";
  constant XSRC_PC  : std_logic_vector(0 downto 0) := "1";

  constant YSRC_R : std_logic_vector(0 downto 0) := "0";
  constant YSRC_I : std_logic_vector(0 downto 0) := "1";

  constant SHSRC_I : std_logic_vector(0 downto 0) := "0";
  constant SHSRC_R : std_logic_vector(0 downto 0) := "1";

  constant ISEL_I : std_logic_vector(2 downto 0) := "000"; -- I-type
  constant ISEL_S : std_logic_vector(2 downto 0) := "001"; -- S-type
  constant ISEL_B : std_logic_vector(2 downto 0) := "010"; -- B-type
  constant ISEL_U : std_logic_vector(2 downto 0) := "011"; -- U-type
  constant ISEL_J : std_logic_vector(2 downto 0) := "100"; -- J-type

  constant RDSRC_ALU  : std_logic_vector(1 downto 0) := "00";
  constant RDSRC_PCp4 : std_logic_vector(1 downto 0) := "01";
  constant RDSRC_MEM  : std_logic_vector(1 downto 0) := "10";
  constant RDSRC_CSR  : std_logic_vector(1 downto 0) := "11";

  constant CSRSRC_MCYCLE    : std_logic_vector(1 downto 0) := "00";
  constant CSRSRC_MCYCLEH   : std_logic_vector(1 downto 0) := "01";
  constant CSRSRC_MINSTRET  : std_logic_vector(1 downto 0) := "10";
  constant CSRSRC_MINSTRETH : std_logic_vector(1 downto 0) := "11";

  constant LSU_BYTE : std_logic_vector(1 downto 0) := "00";
  constant LSU_HALF : std_logic_vector(1 downto 0) := "01";
  constant LSU_WORD : std_logic_vector(1 downto 0) := "10";

  constant ALUOP_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant ALUOP_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant ALUOP_SLL  : std_logic_vector(3 downto 0) := "0010";
  constant ALUOP_SLT  : std_logic_vector(3 downto 0) := "0100";
  constant ALUOP_SLTU : std_logic_vector(3 downto 0) := "0110";
  constant ALUOP_XOR  : std_logic_vector(3 downto 0) := "1000";
  constant ALUOP_SRL  : std_logic_vector(3 downto 0) := "1010";
  constant ALUOP_SRA  : std_logic_vector(3 downto 0) := "1011";
  constant ALUOP_OR   : std_logic_vector(3 downto 0) := "1100";
  constant ALUOP_AND  : std_logic_vector(3 downto 0) := "1110";
end package;