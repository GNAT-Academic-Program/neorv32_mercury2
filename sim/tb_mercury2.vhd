-- Smoke test: boot the board top and print what the bootloader sends on UART0.
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_mercury2 is
end entity;

architecture sim of tb_mercury2 is

  constant bit_time_c : time := 1 sec / 19200; -- bootloader baud rate

  signal clk    : std_ulogic := '0';
  signal txd    : std_ulogic;
  signal leds   : std_ulogic_vector(2 downto 0);
  signal clk_en : std_ulogic;

begin

  clk <= not clk after 10 ns; -- 50 MHz

  dut: entity work.neorv32_mercury2_top
  port map (
    clk_i       => clk,
    rstn_i      => '1',
    gpio_o      => leds,
    uart0_txd_o => txd,
    uart0_rxd_i => '1',
    clk_en_o    => clk_en
  );

  -- UART receiver: one output line per received text line, prefixed with "UART: ".
  uart_rx: process
    variable l : line;
    variable c : std_ulogic_vector(7 downto 0);
  begin
    wait until falling_edge(txd);
    wait for bit_time_c * 1.5;
    for i in 0 to 7 loop
      c(i) := txd;
      wait for bit_time_c;
    end loop;
    if c = x"0A" then
      if l = null then
        write(l, string'(""));
      end if;
      write(output, "UART: " & l.all & LF);
      deallocate(l);
    elsif c /= x"0D" then
      write(l, character'val(to_integer(unsigned(c))));
    end if;
  end process;

  led_watch: process(leds(0))
  begin
    if leds(0) = '1' then
      report "status LED on";
    end if;
  end process;

end architecture;
