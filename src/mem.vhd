library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity mem is
  generic (
    G_INIT_FILE : string := "UNUSED"
  );
  port (
    clk : in std_logic;

    adr  : in std_logic_vector(31 downto 0);
    din  : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(31 downto 0);
    we   : in std_logic;
    sel  : in std_logic_vector(3 downto 0);
    stb  : in std_logic;
    cyc  : in std_logic;
    ack  : out std_logic
  );
end entity mem;

architecture rtl of mem is
  signal ack_r1 : std_logic := '0';
begin

  altsyncram_component : altsyncram
  generic map(
    byte_size                     => 8,
    clock_enable_input_a          => "BYPASS",
    clock_enable_output_a         => "BYPASS",
    init_file                     => G_INIT_FILE,
    intended_device_family        => "MAX 10",
    lpm_hint                      => "ENABLE_RUNTIME_MOD=NO",
    lpm_type                      => "altsyncram",
    numwords_a                    => 4096,
    operation_mode                => "SINGLE_PORT",
    outdata_aclr_a                => "NONE",
    outdata_reg_a                 => "CLOCK0",
    power_up_uninitialized        => "FALSE",
    read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
    widthad_a                     => 12,
    width_a                       => 32,
    width_byteena_a               => 4
  )
  port map
  (
    address_a => adr(13 downto 2),
    byteena_a => sel,
    clock0    => clk,
    data_a    => din,
    wren_a    => cyc and stb and we,
    q_a       => dout
  );

  PROC_ACK : process (clk)
  begin
    if rising_edge(clk) then
      ack_r1 <= cyc and stb;
      ack    <= ack_r1 and not(ack);
    end if;
  end process;

end rtl;