## MicroNova Mercury 2 (XC7A35T / XC7A100T, FTG256). Same pinout for both variants.
## Top entity: neorv32_mercury2_top
## Pin source: LiteX-Boards platform file micronova_mercury2.py. Check against the
## Mercury 2 reference manual before trusting a pin that is not yet proven on hardware.

## Configuration bank voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock: 50 MHz oscillator
set_property -dict { PACKAGE_PIN N14  IOSTANDARD LVCMOS33 } [get_ports { clk_i }];
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports { clk_i }];

## Oscillator enable (driven high by the top)
set_property -dict { PACKAGE_PIN H16  IOSTANDARD LVCMOS33 } [get_ports { clk_en_o }];

## User LEDs
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports { gpio_o[0] }]; # user_led 0, bootloader status LED
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33 } [get_ports { gpio_o[1] }]; # user_led 1
set_property -dict { PACKAGE_PIN A13  IOSTANDARD LVCMOS33 } [get_ports { gpio_o[2] }]; # user_led 2

## USB-UART: FT2232H channel B
set_property -dict { PACKAGE_PIN N11  IOSTANDARD LVCMOS33 } [get_ports { uart0_txd_o }]; # BDBUS1, FTDI RXD
set_property -dict { PACKAGE_PIN E11  IOSTANDARD LVCMOS33 } [get_ports { uart0_rxd_i }]; # BDBUS0, FTDI TXD

## Reset: FPGA-direct I/O 0, pulled up. Leave open to run, short to GND to reset.
set_property -dict { PACKAGE_PIN C12  IOSTANDARD LVCMOS33  PULLUP true } [get_ports { rstn_i }]; # DIO 0
