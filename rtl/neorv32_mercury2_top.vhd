-- ================================================================================ --
-- NEORV32 on the MicroNova Mercury 2 (Artix-7, FTG256)                             --
-- -------------------------------------------------------------------------------- --
-- Board top. This file is the SoC contract: everything the software side depends   --
-- on (clock, memory sizes, ISA, enabled peripherals) is decided here and nowhere   --
-- else. Change a value here, release a new bitstream.                              --
-- -------------------------------------------------------------------------------- --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_mercury2_top is
  generic (
    CLOCK_FREQUENCY : natural := 50_000_000; -- on-board oscillator, used directly (no PLL)
    IMEM_SIZE       : natural := 128*1024;   -- instruction memory in bytes, base 0x00000000
    DMEM_SIZE       : natural := 64*1024     -- data memory in bytes, base 0x80000000
  );
  port (
    -- Port names match neorv32_test_setup_bootloader so constraints carry over unchanged.
    clk_i       : in  std_ulogic;                    -- 50 MHz oscillator
    rstn_i      : in  std_ulogic;                    -- external reset, low-active, pulled up in the XDC
    gpio_o      : out std_ulogic_vector(2 downto 0); -- the three user LEDs; gpio_o(0) is the bootloader status LED
    uart0_txd_o : out std_ulogic;                    -- to FT2232H channel B
    uart0_rxd_i : in  std_ulogic;                    -- from FT2232H channel B
    -- Mercury 2 specific.
    clk_en_o    : out std_ulogic                     -- oscillator enable, held high
  );
end entity;

architecture rtl of neorv32_mercury2_top is

  -- Power-on reset. The module has no push button, so reset is generated here:
  -- hold reset for 2**15 clock cycles (0.66 ms at 50 MHz) after configuration.
  -- Pulling rstn_i low restarts the count, so a wire to GND works as a reset button.
  signal por_cnt : unsigned(15 downto 0) := (others => '0');
  signal rst_ext : std_ulogic_vector(1 downto 0) := (others => '0'); -- rstn_i synchronizer
  signal rstn    : std_ulogic := '0';

  signal gpio_out : std_ulogic_vector(31 downto 0);

begin

  clk_en_o <= '1';

  reset_generator: process(clk_i)
  begin
    if rising_edge(clk_i) then
      rst_ext <= rst_ext(0) & rstn_i;
      if rst_ext(1) = '0' then
        por_cnt <= (others => '0');
      elsif por_cnt(por_cnt'left) = '0' then
        por_cnt <= por_cnt + 1;
      end if;
      rstn <= por_cnt(por_cnt'left);
    end if;
  end process;

  -- The SoC --------------------------------------------------------------------------------
  neorv32_top_inst: neorv32_top
  generic map (
    -- Clocking --
    CLOCK_FREQUENCY  => CLOCK_FREQUENCY,
    -- Boot: stock UART bootloader (19200 8N1) --
    BOOT_MODE_SELECT => 0,
    -- ISA: rv32imc_zicsr_zicntr_zifencei --
    RISCV_ISA_C      => true,
    RISCV_ISA_M      => true,
    RISCV_ISA_Zicntr => true,
    -- Memories --
    IMEM_EN          => true,
    IMEM_SIZE        => IMEM_SIZE,
    DMEM_EN          => true,
    DMEM_SIZE        => DMEM_SIZE,
    -- Peripherals --
    IO_GPIO_NUM      => 3,
    IO_CLINT_EN      => true,
    IO_UART0_EN      => true
  )
  port map (
    clk_i       => clk_i,
    rstn_i      => rstn,
    gpio_o      => gpio_out,
    uart0_txd_o => uart0_txd_o,
    uart0_rxd_i => uart0_rxd_i
  );

  gpio_o <= gpio_out(2 downto 0);

end architecture;
