library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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

  type t_mem is array (natural range <>) of std_logic_vector;
  signal data_mem0 : t_mem(G_NUM_WORDS - 1 downto 0)(7 downto 0);
  signal data_mem1 : t_mem(G_NUM_WORDS - 1 downto 0)(7 downto 0);
  signal data_mem2 : t_mem(G_NUM_WORDS - 1 downto 0)(7 downto 0);
  signal data_mem3 : t_mem(G_NUM_WORDS - 1 downto 0)(7 downto 0);
  signal tag_mem   : t_mem(G_NUM_WORDS - 1 downto 0)(C_TAG_W - 1 downto 0);
  signal vld_mem   : std_logic_vector(G_NUM_WORDS - 1 downto 0);

  attribute ramstyle              : string;
  attribute ramstyle of data_mem0 : signal is G_RAMSTYLE & ", no_rw_check";
  attribute ramstyle of data_mem1 : signal is G_RAMSTYLE & ", no_rw_check";
  attribute ramstyle of data_mem2 : signal is G_RAMSTYLE & ", no_rw_check";
  attribute ramstyle of data_mem3 : signal is G_RAMSTYLE & ", no_rw_check";
  attribute ramstyle of tag_mem   : signal is G_RAMSTYLE & ", no_rw_check";
  attribute ramstyle of vld_mem   : signal is "no_rw_check";

  signal mem_adr : std_logic_vector(C_ADR_W - 1 downto 0);
  signal mem_we  : std_logic := '0';

  signal data_sel  : std_logic_vector(3 downto 0);
  signal data_din  : std_logic_vector(31 downto 0);
  signal data_dout : std_logic_vector(31 downto 0);

  signal tag_din  : std_logic_vector(C_TAG_W - 1 downto 0);
  signal tag_dout : std_logic_vector(C_TAG_W - 1 downto 0);

  signal vld_din  : std_logic;
  signal vld_dout : std_logic;

  signal is_cacheable : std_logic;
  signal is_hit       : std_logic;

  type t_state is (S_idle, S_write, S_check, S_read);
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
            if s_cyc = '1' and s_stb = '1' and s_ack = '0' then
              if s_we = '1' then
                -- write through
                mem_we   <= is_cacheable;
                data_sel <= s_sel;
                data_din <= s_din;
                vld_din  <= '1';

                m_cyc <= '1';
                m_stb <= '1';
                state <= S_write;
              else
                state <= S_check;
              end if;
            end if;

          when S_write =>
            if m_ack = '1' then
              m_cyc <= '0';
              m_stb <= '0';
              s_ack <= '1';
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

  m_adr  <= s_adr;
  m_we   <= s_we;
  m_sel  <= s_sel;
  m_dout <= s_din;

  PROC_VLD_MEM : process (clk)
    variable v_adr : natural range 0 to G_NUM_WORDS - 1 := 0;
  begin
    if rising_edge(clk) then
      -- must reset only valid mem
      if reset = '1' or cache_invalidate = '1' then
        vld_mem <= (others => '0');
      end if;

      v_adr := to_integer(unsigned(mem_adr));
      if mem_we = '1' then
        vld_mem(v_adr) <= vld_din;
      end if;
      vld_dout <= vld_mem(v_adr);
    end if;
  end process;

  PROC_TAG_MEM : process (clk)
    variable v_adr : natural range 0 to G_NUM_WORDS - 1 := 0;
  begin
    if rising_edge(clk) then
      v_adr := to_integer(unsigned(mem_adr));
      if mem_we = '1' then
        tag_mem(v_adr) <= tag_din;
      end if;
      tag_dout <= tag_mem(v_adr);
    end if;
  end process;

  PROC_DATA_MEM : process (clk)
    variable v_adr : natural range 0 to G_NUM_WORDS - 1 := 0;
  begin
    if rising_edge(clk) then
      v_adr := to_integer(unsigned(mem_adr));
      if mem_we = '1' and data_sel(0) = '1' then
        data_mem0(v_adr) <= data_din(7 downto 0);
      end if;
      if mem_we = '1' and data_sel(1) = '1' then
        data_mem1(v_adr) <= data_din(15 downto 8);
      end if;
      if mem_we = '1' and data_sel(2) = '1' then
        data_mem2(v_adr) <= data_din(23 downto 16);
      end if;
      if mem_we = '1' and data_sel(3) = '1' then
        data_mem3(v_adr) <= data_din(31 downto 24);
      end if;
      data_dout <= data_mem3(v_adr) & data_mem2(v_adr) & data_mem1(v_adr) & data_mem0(v_adr);
    end if;
  end process;

end architecture;