

-- Infra design for ipbus module
--
-- This version is for Nexys A7 100T eval board, using ethernet interface
--
-- You must edit this file to set the IP and MAC addresses
--
-- Brenton T, 24/11/01
--
---------------------------------------------------------------------------------


-- Nexys A7 100T_rmii_infra
--
-- All board-specific stuff goes here
--
-- Brenton T, November 2024

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ipbus.all;

entity NexysA7100T_rmii_infra is
    generic (
        CLK_AUX_FREQ : real := 20.0;     -- Default: 40 MHz clock - LHC but I have chosen 20 here
        DHCP_not_RARP : std_logic := '0' -- Default use RARP not DHCP for now...
        );
    port(
        sysclk       : in  std_logic;   -- 100MHz board crystal clock
        clk_ipb_o    : out std_logic;   -- IPbus clock
        rst_ipb_o    : out std_logic;

        clk_100_o    : out std_logic;
	    rst_100_o    : out std_logic;

	    clk_50_o     : out std_logic;
	    rst_50_o     : out std_logic;
        
        clk_aux_o    : out std_logic;   -- 40MHz generated clock but I chose 20MHz for this design
        rst_aux_o    : out std_logic;

        nuke         : in  std_logic;   -- The signal of doom
        soft_rst     : in  std_logic;   -- The signal of lesser doom
        leds         : out std_logic_vector(1 downto 0);   -- status LEDs


        rmii_tx   : out std_logic_vector(1 downto 0);
        rmii_tx_en   : out std_logic;

        rmii_ref_clk : out  std_logic;  ----50MHz 45 degree phase shifted

        rmii_crsdv   : in  std_logic;
        rmii_rstN    : out  std_logic;

        rmii_rxd_err  : in  std_logic;
        rmii_rxd      : in  std_logic_vector(1 downto 0);
        phy_rst	      : out std_logic;
       


        mac_addr     : in  std_logic_vector(47 downto 0);  -- MAC address
        ip_addr      : in  std_logic_vector(31 downto 0);  -- IP address
        ipam_select  : in  std_logic;      -- enable RARP or DHCP
        ipb_in       : in  ipb_rbus;    -- ipbus
        ipb_out      : out ipb_wbus
        );
	
	 

end NexysA7100T_rmii_infra ;

architecture rtl of NexysA7100T_rmii_infra is

    signal clk25_fr, clk100, clk200, clk_ipb, clk_ipb_i, clk_50, locked, rst100, rst_ipb, rst50, rst_ipb_ctrl, rst_eth, rst_aux, onehz, pkt,clk_aux : std_logic;
    signal mac_tx_data, mac_rx_data                                                                                  : std_logic_vector(7 downto 0);
    signal mac_tx_valid, mac_tx_last, mac_tx_error, mac_tx_ready, mac_rx_valid, mac_rx_last, mac_rx_error            : std_logic;
    signal led_p                                                                                                     : std_logic_vector(0 downto 0);

begin

--      DCM clock generation for internal bus, ethernet

    clocks : entity work.clocks_7s_extphy_se
        generic map(
            CLK_AUX_FREQ => CLK_AUX_FREQ
            )
        port map(
            sysclk        => sysclk,
     
            clko_100      => clk100,
	        clko_50       => clk_50,
            clko_200      => clk200,
            clko_ipb      => clk_ipb_i,
	        clko_aux      => clk_aux,
            locked        => locked,
            nuke          => nuke,
            soft_rst      => soft_rst,
            rsto_100      => rst100,
	        rsto_50       => rst50,
            rsto_ipb      => rst_ipb,
	        rsto_aux      => rst_aux,
            rsto_ipb_ctrl => rst_ipb_ctrl,
            onehz         => onehz
            );

    clk_ipb   <= clk_ipb_i;  -- Best to align delta delays on all clocks for simulation
    clk_ipb_o <= clk_ipb_i;
    clk_aux_o <= clk_aux;
    rst_aux_o <= rst_aux;
    rst_ipb_o <= rst_ipb;
    clk_100_o  <= clk100;
    clk_50_o   <= clk_50;
    rst_100_o  <= rst100;
    rst_50_o   <= rst50;
    rmii_rstN  <= not rst50;
 
    
    stretch : entity work.led_stretcher
        generic map(
            WIDTH => 1
            )
        port map(
            clk  => clk100,
            d(0) => pkt,
            q    => led_p
            );

    leds <= (led_p(0), locked and onehz);

-- Ethernet MAC core and PHY interface

    eth : entity work.top_rmii
        port map(
            clk50        => clk_50,
	        clk100       => clk100,
            rst100       => rst100,

            PHY_TXD   => rmii_tx,
            PHY_TXEN  => rmii_tx_en,

            PHY_RXD      => rmii_rxd,
            PHY_CRS_DV   => rmii_crsdv,
            PHY_RXER     => rmii_rxd_err,
	        PHY_RST	     => phy_rst,
            tx_data      => mac_tx_data,
            tx_valid     => mac_tx_valid,
            tx_last      => mac_tx_last,
            tx_error     => mac_tx_error,
            tx_ready     => mac_tx_ready,
            rx_data      => mac_rx_data,
            rx_valid     => mac_rx_valid,
            rx_last      => mac_rx_last,
            rx_error     => mac_rx_error
            );

-- ipbus control logic

    ipbus : entity work.ipbus_ctrl
        generic map(
            DHCP_RARP => DHCP_not_RARP
        )
        port map(
            mac_clk      => clk100,
            rst_macclk   => rst100,
            ipb_clk      => clk_ipb,
            rst_ipb      => rst_ipb_ctrl,
            mac_rx_data  => mac_rx_data,
            mac_rx_valid => mac_rx_valid,
            mac_rx_last  => mac_rx_last,
            mac_rx_error => mac_rx_error,
            mac_tx_data  => mac_tx_data,
            mac_tx_valid => mac_tx_valid,
            mac_tx_last  => mac_tx_last,
            mac_tx_error => mac_tx_error,
            mac_tx_ready => mac_tx_ready,
            ipb_out      => ipb_out,
            ipb_in       => ipb_in,
            mac_addr     => mac_addr,
            ip_addr      => ip_addr,
            ipam_select  => ipam_select,
            pkt          => pkt
            );

end rtl;

