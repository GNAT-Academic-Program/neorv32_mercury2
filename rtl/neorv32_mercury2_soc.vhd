-- ================================================================================ --
-- NEORV32 SoC for the MicroNova Mercury 2 (Artix-7, FTG256)                        --
-- -------------------------------------------------------------------------------- --
-- This entity is the SoC contract: everything the software side depends on         --
-- (clock, memory sizes, ISA, enabled peripherals) is decided here and nowhere      --
-- else. Change a value here, release a new bitstream.                              --
--                                                                                  --
-- It is also the piece other repos compose with. A project puts this entity in     --
-- its own top next to its own logic, with XBUS_EN => true, and attaches its logic  --
-- to the xbus_* ports. The project owns every address the SoC does not implement   --
-- internally: NEORV32 forwards all such accesses to XBUS. Projects use             --
-- 0x90000000 and up, by convention. An access nobody acknowledges ends in a bus    --
-- error after XBUS_TIMEOUT clock cycles; the CPU traps instead of hanging.         --
--                                                                                  --
-- neorv32_mercury2_top is this entity with XBUS off and nothing attached.          --
-- -------------------------------------------------------------------------------- --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_mercury2_soc is
  generic (
    CLOCK_FREQUENCY : natural := 50_000_000; -- on-board oscillator, used directly (no PLL)
    IMEM_SIZE       : natural := 128*1024;   -- instruction memory in bytes, base 0x00000000
    DMEM_SIZE       : natural := 64*1024;    -- data memory in bytes, base 0x80000000
    -- What a project may grow. The plain bitstream keeps the defaults.
    GPIO_NUM        : natural range 3 to 32 := 3;  -- GPIO pairs; gpio_o(2 downto 0) are the LEDs, the rest is for a project
    PWM_NUM         : natural range 0 to 32 := 0;  -- PWM channels, for a project (a speaker, a backlight)
    XBUS_EN         : boolean := false;            -- bring the external bus out, for a project's logic
    XBUS_TIMEOUT    : natural := 2048              -- clock cycles before an unacknowledged XBUS access errors out
  );
  port (
    -- Port names match neorv32_test_setup_bootloader so constraints carry over unchanged.
    clk_i       : in  std_ulogic;                      -- 50 MHz oscillator
    rstn_i      : in  std_ulogic;                      -- external reset, low-active, pulled up in the XDC
    gpio_o      : out std_ulogic_vector(31 downto 0);  -- gpio_o(0) is the bootloader status LED; (GPIO_NUM-1 downto 0) are live
    gpio_i      : in  std_ulogic_vector(31 downto 0) := (others => 'L'); -- (GPIO_NUM-1 downto 0) are live
    pwm_o       : out std_ulogic_vector(31 downto 0);  -- (PWM_NUM-1 downto 0) are live
    uart0_txd_o : out std_ulogic;                      -- to FT2232H channel B
    uart0_rxd_i : in  std_ulogic;                      -- from FT2232H channel B
    -- Mercury 2 specific.
    clk_en_o    : out std_ulogic;                      -- oscillator enable, held high
    -- Clean reset for project logic: low during the power-on reset and while rstn_i is low.
    rstn_o      : out std_ulogic;
    -- External bus (pipelined Wishbone subset, see the NEORV32 datasheet, "XBUS").
    -- Only driven when XBUS_EN = true. Flat signals on purpose: a slave written in
    -- Verilog or SystemVerilog connects to them directly.
    xbus_adr_o  : out std_ulogic_vector(31 downto 0);  -- address
    xbus_dat_o  : out std_ulogic_vector(31 downto 0);  -- write data
    xbus_we_o   : out std_ulogic;                      -- 1 = write, 0 = read
    xbus_sel_o  : out std_ulogic_vector(3 downto 0);   -- byte enables
    xbus_stb_o  : out std_ulogic;                      -- strobe: a transfer is requested this cycle
    xbus_cyc_o  : out std_ulogic;                      -- cycle valid
    xbus_dat_i  : in  std_ulogic_vector(31 downto 0) := (others => 'L'); -- read data, sampled with ack
    xbus_ack_i  : in  std_ulogic := 'L';               -- transfer done
    xbus_err_i  : in  std_ulogic := 'L'                -- transfer failed
  );
end entity;

architecture rtl of neorv32_mercury2_soc is

  -- Power-on reset. The module has no push button, so reset is generated here:
  -- hold reset for 2**15 clock cycles (0.66 ms at 50 MHz) after configuration.
  -- Pulling rstn_i low restarts the count, so a wire to GND works as a reset button.
  signal por_cnt : unsigned(15 downto 0) := (others => '0');
  signal rst_ext : std_ulogic_vector(1 downto 0) := (others => '0'); -- rstn_i synchronizer
  signal rstn    : std_ulogic := '0';

begin

  clk_en_o <= '1';
  rstn_o   <= rstn;

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
    -- ISA: rv32imac_zicsr_zicntr_zifencei (A = Zaamo + Zalrsc) --
    RISCV_ISA_C      => true,
    RISCV_ISA_M      => true,
    RISCV_ISA_Zaamo  => true,
    RISCV_ISA_Zalrsc => true,
    RISCV_ISA_Zicntr => true,
    -- Memories --
    IMEM_EN          => true,
    IMEM_SIZE        => IMEM_SIZE,
    DMEM_EN          => true,
    DMEM_SIZE        => DMEM_SIZE,
    -- External bus, for a project's logic --
    XBUS_EN          => XBUS_EN,
    XBUS_TIMEOUT     => XBUS_TIMEOUT,
    -- Peripherals --
    IO_GPIO_NUM      => GPIO_NUM,
    IO_PWM_NUM       => PWM_NUM,
    IO_CLINT_EN      => true,
    IO_UART0_EN      => true
  )
  port map (
    clk_i       => clk_i,
    rstn_i      => rstn,
    gpio_o      => gpio_o,
    gpio_i      => gpio_i,
    pwm_o       => pwm_o,
    uart0_txd_o => uart0_txd_o,
    uart0_rxd_i => uart0_rxd_i,
    xbus_adr_o  => xbus_adr_o,
    xbus_dat_o  => xbus_dat_o,
    xbus_we_o   => xbus_we_o,
    xbus_sel_o  => xbus_sel_o,
    xbus_stb_o  => xbus_stb_o,
    xbus_cyc_o  => xbus_cyc_o,
    xbus_dat_i  => xbus_dat_i,
    xbus_ack_i  => xbus_ack_i,
    xbus_err_i  => xbus_err_i
  );

end architecture;
