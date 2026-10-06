library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity wb_cache is
  generic (
    G_NUM_WORDS : natural := 256;
    G_RAMSTYLE  : string  := "auto"
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    s_csr_cyc  : in std_logic;
    s_csr_stb  : in std_logic;
    s_csr_adr  : in std_logic_vector(31 downto 0);
    s_csr_we   : in std_logic;
    s_csr_sel  : in std_logic_vector(3 downto 0);
    s_csr_din  : in std_logic_vector(31 downto 0);
    s_csr_dout : out std_logic_vector(31 downto 0);
    s_csr_ack  : out std_logic;

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
end entity wb_cache;

architecture rtl of wb_cache is

  constant C_ADR_W : natural := integer(ceil(log2(real(G_NUM_WORDS))));
  constant C_TAG_W : natural := 32 - C_ADR_W - 2;

  signal vld_mem : std_logic_vector(G_NUM_WORDS - 1 downto 0) := (others => '0');

  signal mem_adr : std_logic_vector(C_ADR_W - 1 downto 0);
  signal mem_we  : std_logic := '0';

  signal data_sel  : std_logic_vector(3 downto 0);
  signal data_din  : std_logic_vector(31 downto 0);
  signal data_dout : std_logic_vector(31 downto 0);

  signal tag_din  : std_logic_vector(C_TAG_W - 1 downto 0);
  signal tag_dout : std_logic_vector(C_TAG_W - 1 downto 0);

  signal vld_din  : std_logic;
  signal vld_dout : std_logic;

  signal vtag_din  : std_logic_vector(C_TAG_W downto 0);
  signal vtag_dout : std_logic_vector(C_TAG_W downto 0);

  signal is_cacheable : std_logic;
  signal is_hit       : std_logic;

  type t_state is (S_idle, S_write, S_write_ack, S_check, S_read);
  signal state : t_state := S_idle;

  -- csr
  signal cache_mask       : std_logic_vector(31 downto 0) := (others => '0');
  signal cache_invalidate : std_logic                     := '0';
  signal hit_ctr          : unsigned(31 downto 0)         := (others => '0');
  signal miss_ctr         : unsigned(31 downto 0)         := (others => '0');

begin

  assert (2 ** C_ADR_W = G_NUM_WORDS) report "num words must be a power of two" severity error;

  PROC_CSR : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        cache_mask       <= (others => '0');
        cache_invalidate <= '0';
        hit_ctr          <= (others => '0');
        miss_ctr         <= (others => '0');
        s_csr_ack        <= '0';
      else
        s_csr_ack        <= '0';
        cache_invalidate <= '0';

        if state = S_check then
          if is_hit = '1' then
            hit_ctr <= hit_ctr + 1;
          else
            miss_ctr <= miss_ctr + 1;
          end if;
        end if;

        if s_csr_cyc = '1' and s_csr_stb = '1' and s_csr_ack = '0' then
          s_csr_ack <= '1';
          if s_csr_we = '1' then
            case (s_csr_adr(3 downto 2)) is
              when "00" => cache_mask       <= s_csr_din;
              when "01" => cache_invalidate <= s_csr_din(0);
              when "10" => hit_ctr          <= (others => '0');
              when "11" => miss_ctr         <= (others => '0');

              when others => null;
            end case;
          else
            case (s_csr_adr(3 downto 2)) is
              when "00" => s_csr_dout <= cache_mask;
              when "01" => s_csr_dout <= (others => '0');
              when "10" => s_csr_dout <= std_logic_vector(hit_ctr);
              when "11" => s_csr_dout <= std_logic_vector(miss_ctr);

              when others => null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

  mem_adr <= s_adr(C_ADR_W + 2 - 1 downto 2);

  PROC_SEQ : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        mem_we <= '0';
        s_ack  <= '0';
        m_cyc  <= '0';
        m_stb  <= '0';
        state  <= S_idle;
      else
        mem_we <= '0';
        s_ack  <= '0';

        tag_din <= s_adr(31 downto C_ADR_W + 2);

        case (state) is
          when S_idle =>
            -- prepare to access the downstream bus  
            m_adr  <= s_adr;
            m_we   <= s_we;
            m_sel  <= s_sel;
            m_dout <= s_din;

            if s_cyc = '1' and s_stb = '1' and s_ack = '0' then
              if s_we = '1' then
                -- write through
                m_cyc <= '1';
                m_stb <= '1';
                state <= S_write;
              else
                state <= S_check;
              end if;
            end if;

          when S_write =>
            s_ack <= '1';

            if is_hit = '1' then
              mem_we   <= '1';
              data_sel <= s_sel;
              data_din <= s_din;
              vld_din  <= '1';
            end if;

            if m_ack = '1' then
              m_cyc <= '0';
              m_stb <= '0';
              state <= S_idle;
            else
              state <= S_write_ack;
            end if;

          when S_write_ack =>
            if m_ack = '1' then
              m_cyc <= '0';
              m_stb <= '0';
              state <= S_idle;
            end if;

          when S_check =>
            if is_hit = '1' then
              s_dout <= data_dout;
              s_ack  <= '1';
              state  <= S_idle;
            else
              -- miss: read and allocate
              m_cyc <= '1';
              m_stb <= '1';
              state <= S_read;
            end if;

          when S_read =>
            if m_ack = '1' then
              m_cyc  <= '0';
              m_stb  <= '0';
              s_dout <= m_din;
              s_ack  <= '1';

              mem_we   <= is_cacheable;
              data_sel <= (others => '1');
              data_din <= m_din;
              vld_din  <= '1';
              state    <= S_idle;
            end if;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  is_cacheable <= cache_mask(to_integer(unsigned(s_adr(31 downto 27))));

  is_hit <= '1' when (is_cacheable = '1' and vld_dout = '1' and tag_dout = tag_din) else
    '0';

  U_TAG_MEM : altsyncram
  generic map(
    clock_enable_input_a          => "BYPASS",
    clock_enable_output_a         => "BYPASS",
    intended_device_family        => "MAX 10",
    lpm_hint                      => "ENABLE_RUNTIME_MOD=NO",
    lpm_type                      => "altsyncram",
    numwords_a                    => G_NUM_WORDS,
    operation_mode                => "SINGLE_PORT",
    outdata_aclr_a                => "NONE",
    outdata_reg_a                 => "UNREGISTERED",
    power_up_uninitialized        => "FALSE",
    read_during_write_mode_port_a => "DONT_CARE",
    widthad_a                     => C_ADR_W,
    width_a                       => C_TAG_W + 1,
    width_byteena_a               => 1
  )
  port map
  (
    address_a => mem_adr,
    clock0    => clk,
    data_a    => vtag_din,
    wren_a    => mem_we,
    q_a       => vtag_dout
  );

  vtag_din(C_TAG_W - 1 downto 0) <= tag_din;
  vtag_din(C_TAG_W)              <= vld_din;
  
  tag_dout <= vtag_dout(C_TAG_W - 1 downto 0);
  vld_dout <= vtag_dout(C_TAG_W);

  U_DATA_MEM : altsyncram
  generic map(
    byte_size                     => 8,
    clock_enable_input_a          => "BYPASS",
    clock_enable_output_a         => "BYPASS",
    intended_device_family        => "MAX 10",
    lpm_hint                      => "ENABLE_RUNTIME_MOD=NO",
    lpm_type                      => "altsyncram",
    numwords_a                    => G_NUM_WORDS,
    operation_mode                => "SINGLE_PORT",
    outdata_aclr_a                => "NONE",
    outdata_reg_a                 => "UNREGISTERED",
    power_up_uninitialized        => "FALSE",
    read_during_write_mode_port_a => "DONT_CARE",
    widthad_a                     => C_ADR_W,
    width_a                       => 32,
    width_byteena_a               => 4
  )
  port map
  (
    address_a => mem_adr,
    byteena_a => data_sel,
    clock0    => clk,
    data_a    => data_din,
    wren_a    => mem_we,
    q_a       => data_dout
  );

end architecture;