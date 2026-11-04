-- Elaboration check for the composition path: the SoC with XBUS_EN => true and a
-- one-register slave at 0x90000000, the way a project top wires things.
-- Elaborated by run.sh, not run.
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;

entity tb_xbus is
end entity;

architecture sim of tb_xbus is

  signal clk    : std_ulogic := '0';
  signal rstn   : std_ulogic;
  signal gpio_o : std_ulogic_vector(31 downto 0);
  signal pwm_o  : std_ulogic_vector(31 downto 0);
  signal txd, clk_en : std_ulogic;

  signal adr, wdat, rdat : std_ulogic_vector(31 downto 0);
  signal sel  : std_ulogic_vector(3 downto 0);
  signal we, stb, cyc, ack : std_ulogic;

  signal reg : std_ulogic_vector(31 downto 0) := (others => '0');

begin

  clk <= not clk after 10 ns;

  dut: entity work.neorv32_mercury2_soc
  generic map (
    GPIO_NUM => 8,
    PWM_NUM  => 1,
    XBUS_EN  => true
  )
  port map (
    clk_i       => clk,
    rstn_i      => '1',
    gpio_o      => gpio_o,
    gpio_i      => (others => '0'),
    pwm_o       => pwm_o,
    uart0_txd_o => txd,
    uart0_rxd_i => '1',
    clk_en_o    => clk_en,
    rstn_o      => rstn,
    xbus_adr_o  => adr,
    xbus_dat_o  => wdat,
    xbus_we_o   => we,
    xbus_sel_o  => sel,
    xbus_stb_o  => stb,
    xbus_cyc_o  => cyc,
    xbus_dat_i  => rdat,
    xbus_ack_i  => ack,
    xbus_err_i  => '0'
  );

  -- One 32-bit register at 0x90000000, acknowledged the cycle after the strobe.
  slave: process(clk)
  begin
    if rising_edge(clk) then
      ack <= '0';
      if rstn = '0' then
        reg <= (others => '0');
      elsif cyc = '1' and stb = '1' and adr = x"90000000" then
        if we = '1' then
          reg <= wdat;
        end if;
        ack <= '1';
      end if;
    end if;
  end process;

  rdat <= reg;

end architecture;
