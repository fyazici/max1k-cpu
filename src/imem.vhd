library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity imem is
  generic (
    G_INIT_FILE : string := "UNUSED"
  );
  port (
    clk : in std_logic;

    adr  : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(31 downto 0);
    stb  : in std_logic;
    cyc  : in std_logic;
    ack  : out std_logic
  );
end entity imem;

architecture rtl of imem is

begin

  U_MEM : altsyncram
  generic map(
    address_aclr_a         => "NONE",
    clock_enable_input_a   => "BYPASS",
    clock_enable_output_a  => "BYPASS",
    init_file              => G_INIT_FILE,
    intended_device_family => "MAX 10",
    lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
    lpm_type               => "altsyncram",
    numwords_a             => 4096,
    operation_mode         => "ROM",
    outdata_aclr_a         => "NONE",
    outdata_reg_a          => "CLOCK0",
    widthad_a              => 12,
    width_a                => 32,
    width_byteena_a        => 1,
    -- for ihex proper loading
    widthad_b        => 14,
    width_b          => 8,
    init_file_layout => "PORT_B"
  )
  port map
  (
    address_a => adr(13 downto 2),
    clock0    => clk,
    q_a       => dout
  );

  PROC_ACK : process (clk)
  begin
    if rising_edge(clk) then
      -- 1 cycle latency?
      ack <= cyc and stb and not(ack);
    end if;
  end process;

end rtl;