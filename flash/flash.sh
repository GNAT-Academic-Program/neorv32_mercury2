#!/bin/sh
[ -n "$1" ] || { echo "Usage: sh flash.sh bitstream.bit"; exit 1; }
here=$(dirname "$0")
chmod +x "$here/mercury2_prog"
sudo rmmod ftdi_sio 2>/dev/null
sudo "$here/mercury2_prog" -w "$1"
status=$?
sudo modprobe ftdi_sio
exit $status