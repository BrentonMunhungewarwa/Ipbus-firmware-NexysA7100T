library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library unisim;
use unisim.VComponents.all;
use work.emac_hostbus_decl.all;

entity top_rmii is
    Port (
        PHY_TXD     : out std_logic_vector(1 downto 0);
        PHY_TXEN    : out std_logic;
        PHY_RXD     : in  std_logic_vector(1 downto 0);
        PHY_RXER    : in  std_logic;
        PHY_RST	    : out std_logic;
        
        PHY_CRS_DV  : in  std_logic;

	clk50	    : in std_logic;
	clk100	    : in std_logic;
	rst100	    : in std_logic;

	

	tx_data: in std_logic_vector(7 downto 0);
	tx_valid: in std_logic;
	tx_last: in std_logic;
	tx_error: in std_logic:= '0';
	tx_ready: out std_logic;
	rx_data: out std_logic_vector(7 downto 0);
	rx_valid: out std_logic;
	rx_last: out std_logic;
	rx_error: out std_logic:= '0';
	hostbus_in: in emac_hostbus_in := ('0', "00", "0000000000", X"00000000", '0', '0', '0');
	hostbus_out: out emac_hostbus_out
	
    );
end entity;

architecture Behavioral of top_rmii is

    -- Local parameters
    constant TIMER_LIMIT : integer := 5000000;

    -- Signals
    signal clk_100      : std_logic;
    signal clk_50       : std_logic;
    signal reset100    : std_logic;
    signal timer       : integer range 0 to TIMER_LIMIT-1 := 0;
    signal led_register: std_logic_vector(7 downto 0) := (others => '0');

    -- Ethernet interface signals
    signal crc_bad           : std_logic;
    signal crc_good          : std_logic;
    signal eth_m_axis_tdata  : std_logic_vector(7 downto 0);
    signal eth_m_axis_tvalid : std_logic;
    signal eth_m_axis_tlast  : std_logic;
    signal eth_m_axis_tready : std_logic := '1';
    signal eth_s_axis_tdata  : std_logic_vector(7 downto 0);
    signal eth_s_axis_tvalid : std_logic;
    signal eth_s_axis_tlast  : std_logic;
    signal eth_s_axis_tready : std_logic;

begin

-- There was once the instantiation of a clock wizard here

    -- Timer process
    timer_process: process(clk100)
    begin
        if rising_edge(clk100) then
            if timer < TIMER_LIMIT then
                timer <= timer + 1;
            else
                timer <= 0;
            end if;
        end if;
    end process;

    -- Instantiate the RMII Ethernet module (SystemVerilog module)
    rmii_ethernet_inst: entity work.rmii_ethernet
        port map (
            PHY_CLK           => clk50,
            PHY_TXD           => PHY_TXD,
            PHY_TXEN          => PHY_TXEN,
            PHY_RXD           => PHY_RXD,
            PHY_RXER          => PHY_RXER,
            PHY_RST           => PHY_RST,
            PHY_CRS_DV        => PHY_CRS_DV,
            ETH_RX_AXIS_CLK   => clk100,
            ETH_RX_AXIS_RESET => rst100,
            ETH_RX_AXIS_TDATA => eth_m_axis_tdata,
            ETH_RX_AXIS_TVALID => eth_m_axis_tvalid,
            ETH_RX_AXIS_TLAST  => eth_m_axis_tlast,
            ETH_RX_AXIS_TREADY => eth_m_axis_tready,
            ETH_TX_AXIS_CLK   => clk100,
            ETH_TX_AXIS_RESET => rst100,
            ETH_TX_AXIS_TDATA => tx_data,
            ETH_TX_AXIS_TVALID => tx_valid,
            ETH_TX_AXIS_TLAST  => tx_last,
            ETH_TX_AXIS_TREADY => tx_ready,
            CRC_BAD            => crc_bad,
            CRC_GOOD           => crc_good
        );

	
	rx_data   <= eth_m_axis_tdata ;
	rx_valid  <= eth_m_axis_tvalid;
	rx_last   <= eth_m_axis_tlast ;

	hostbus_out.hostrddata <= (others => '0');
	hostbus_out.hostmiimrdy <= '0';

end Behavioral;

