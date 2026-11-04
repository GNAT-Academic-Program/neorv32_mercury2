#!/usr/bin/env bash
# Smoke test with GHDL: the board top boots and the bootloader banner comes out of UART0.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
build=$here/build
export NEORV32_HOME=$root/neorv32

mkdir -p "$build"
cd "$build"

flags="--std=08 --workdir=$build -P$build"

# Core files in the order given by the pinned NEORV32 release.
core_files=$(sed "s|\$NEORV32_HOME|$NEORV32_HOME|" "$NEORV32_HOME/rtl/file_list_core.f")
ghdl -a $flags --work=neorv32 $core_files
ghdl -a $flags "$root/rtl/neorv32_mercury2_soc.vhd" "$root/rtl/neorv32_mercury2_top.vhd" \
              "$here/tb_mercury2.vhd" "$here/tb_xbus.vhd"
ghdl -e $flags tb_mercury2

# The composition path: the SoC with XBUS on and a slave attached must elaborate.
# Not run; the bootloader never touches XBUS, so running it would prove nothing more.
ghdl -e $flags tb_xbus
echo "PASS: SoC with XBUS_EN => true elaborates"

ghdl -r $flags tb_mercury2 --stop-time="${STOP_TIME:-40ms}" --ieee-asserts=disable | tee sim.log

if grep -q "UART: .*NEORV32" sim.log; then
  echo "PASS: bootloader banner seen on UART0"
else
  echo "FAIL: no bootloader banner on UART0"
  exit 1
fi
