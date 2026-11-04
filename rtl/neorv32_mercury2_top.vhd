-- ================================================================================ --
-- NEORV32 on the MicroNova Mercury 2 (Artix-7, FTG256)                             --
-- -------------------------------------------------------------------------------- --
-- The plain bitstream: neorv32_mercury2_soc with XBUS off and nothing attached.    --
-- The SoC contract lives in neorv32_mercury2_soc.vhd; this file only wires the     --
-- SoC to the module's pins. A project writes its own version of this file.         --
-- -------------------------------------------------------------------------------- --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;

entity neorv32_mercury2_top is
  port (
    clk_i       : in  std_ulogic;                    -- 50 MHz oscillator
    rstn_i      : in  std_ulogic;                    -- external reset, low-active, pulled up in the XDC
    gpio_o      : out std_ulogic_vector(2 downto 0); -- the three user LEDs; gpio_o(0) is the bootloader status LED
    uart0_txd_o : out std_ulogic;                    -- to FT2232H channel B
    uart0_rxd_i : in  std_ulogic;                    -- from FT2232H channel B
    clk_en_o    : out std_ulogic                     -- oscillator enable, held high
  );
end entity;

architecture rtl of neorv32_mercury2_top is

  signal gpio_out : std_ulogic_vector(31 downto 0);

begin

  soc: entity work.neorv32_mercury2_soc
  port map (
    clk_i       => clk_i,
    rstn_i      => rstn_i,
    gpio_o      => gpio_out,
    uart0_txd_o => uart0_txd_o,
    uart0_rxd_i => uart0_rxd_i,
    clk_en_o    => clk_en_o
  );

  gpio_o <= gpio_out(2 downto 0);

end architecture;
