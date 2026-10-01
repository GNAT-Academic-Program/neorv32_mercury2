#!/usr/bin/env bash
# Serial console to the NEORV32 UART (FT2232H channel B) on Linux.
#   bash console/console.sh                      finds the port on its own
#   bash console/console.sh /dev/ttyUSB1         uses this port
#   bash console/console.sh /dev/ttyUSB1 115200  uses this port and this baud rate
port=${1:-}
baud=${2:-19200}

if [ -z "$port" ]; then
  # Channel B of an FTDI chip is USB interface 1: its name ends with "-if01-port0".
  shopt -s nullglob
  found=(/dev/serial/by-id/*-if01-port0)
  if [ ${#found[@]} -eq 0 ]; then
    echo "ERROR: no serial port found for the board."
    echo "Plug it in. If you just flashed it, bring the serial ports back with:"
    echo "  sudo modprobe ftdi_sio"
    exit 1
  fi
  if [ ${#found[@]} -gt 1 ]; then
    echo "More than one board found. Run again with the port of your board, one of:"
    for p in "${found[@]}"; do echo "  bash $0 $p"; done
    exit 1
  fi
  port=${found[0]}
fi

if [ ! -e "$port" ]; then
  echo "ERROR: $port does not exist."
  exit 1
fi
if [ ! -r "$port" ] || [ ! -w "$port" ]; then
  echo "ERROR: no permission on $port. Run again with sudo:"
  echo "  sudo bash $0 $port $baud"
  exit 1
fi

exec 3<>"$port"
if ! stty -F "$port" "$baud" cs8 -cstopb -parenb raw -echo; then
  echo "ERROR: cannot configure $port."
  exit 1
fi

echo "Connected to $port at $baud baud. Press Escape to quit."
echo "At the bootloader prompt, press r to restart it and see its banner."
echo

cat <&3 &
reader=$!
trap 'kill "$reader" 2>/dev/null; echo' EXIT

while IFS= read -rsn1 key; do
  [ "$key" = $'\e' ] && break
  [ -z "$key" ] && key=$'\n'
  printf '%s' "$key" >&3
done