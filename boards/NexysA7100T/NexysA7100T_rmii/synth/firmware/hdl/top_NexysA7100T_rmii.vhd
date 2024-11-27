-- Top-level design for ipbus module
--
-- This version is for Nexys A7 100T eval board, using ethernet interface
--
-- You must edit this file to set the IP and MAC addresses
--
-- Brenton T, 24/11/01

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ipbus.all;

entity top is generic (
	ENABLE_DHCP  : std_logic := '0'; -- Default is build with support for RARP rather than DHCP
	USE_IPAM     : std_logic := '0'; -- Default is no, use static IP address as specified by ip_addr below
	MAC_ADDRESS  : std_logic_vector(47 downto 0) := X"00183E04B0FE" -- Careful here, arbitrary addresses do not always work
	);
	port (
    sysclk       : in  std_logic; --Input Board Clock
    leds         : out std_logic_vector(3 downto 0);  -- status LEDs
    dip_sw       : in  std_logic_vector(3 downto 0);  -- switches


    rmii_tx      : out std_logic_vector(1 downto 0);
    rmii_tx_en   : out std_logic;
    rmii_ref_clk : out  std_logic;  --50MHz 
    rmii_crsdv   : in  std_logic;
    rmii_rstN    : out  std_logic;
    rmii_rxd_err : in  std_logic;
    rmii_rxd     : in std_logic_vector(1 downto 0);
    
    phy_rst      : out std_logic
    );

end top;

architecture rtl of top is

    signal clk_ipb, rst_ipb, clk_aux, rst_aux, nuke, soft_rst, phy_rst_e, userled : std_logic;
    signal mac_addr                                                               : std_logic_vector(47 downto 0);
    signal ip_addr                                                                : std_logic_vector(31 downto 0);
    signal ipb_out                                                                : ipb_wbus;
    signal ipb_in                                                                 : ipb_rbus;

begin

-- Infrastructure

    infra : entity work.NexysA7100T_rmii_infra
		generic map(
			DHCP_not_RARP => ENABLE_DHCP
		)
        port map(
            sysclk       => sysclk,
           
            clk_ipb_o    => clk_ipb,
            rst_ipb_o    => rst_ipb,
            rst_100_o    => phy_rst_e,
            clk_aux_o    => clk_aux,
            rst_aux_o    => rst_aux,
            nuke         => nuke,
            soft_rst     => soft_rst,
            leds         => leds(1 downto 0),
           
            rmii_tx      => rmii_tx,
            rmii_tx_en   => rmii_tx_en,
           
            rmii_rxd     => rmii_rxd,
            rmii_rxd_err => rmii_rxd_err, 
	        phy_rst      => phy_rst,
            clk_50_o     => rmii_ref_clk,
	        rmii_crsdv   => rmii_crsdv ,
	        rmii_rstN    => rmii_rstN ,

            mac_addr     => mac_addr,
            ip_addr      => ip_addr,
            ipam_select  => USE_IPAM,
            ipb_in       => ipb_in,
            ipb_out      => ipb_out
            );

    leds(3 downto 2) <= '0' & userled;
    phy_rst          <= not phy_rst_e;

    mac_addr <= MAC_ADDRESS;
    ip_addr <= X"c0a8c82" & dip_sw; -- 192.168.200.32+n

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

    payload : entity work.payload
        port map(
            ipb_clk  => clk_ipb,
            ipb_rst  => rst_ipb,
            ipb_in   => ipb_out,
            ipb_out  => ipb_in,
            clk      => clk_aux,
            rst      => rst_aux,
            nuke     => nuke,
            soft_rst => soft_rst,
            userled  => userled
            );

end rtl;

