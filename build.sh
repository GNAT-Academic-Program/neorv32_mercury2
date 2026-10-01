#!/usr/bin/env bash
# Build the bitstream on Linux.
#   ./build.sh        100T (default)
#   ./build.sh 35t    35T
# Vivado is found on its own. To force one, set VIVADO to the full path of the vivado launcher.
set -euo pipefail

variant=${1:-100t}
here=$(cd "$(dirname "$0")" && pwd)

if [ -z "${VIVADO:-}" ]; then
  if command -v vivado >/dev/null 2>&1; then
    VIVADO=$(command -v vivado)
  else
    # Newest install found in the usual places, old layout (Vivado/<ver>) and new (<ver>/Vivado).
    VIVADO=$(ls -d \
      {/tools,/opt,"$HOME"}/{Xilinx,AMDDesignTools}/Vivado/*/bin/vivado \
      {/tools,/opt,"$HOME"}/{Xilinx,AMDDesignTools}/*/Vivado/bin/vivado \
      2>/dev/null | sort -V | tail -n 1 || true)
  fi
fi

if [ -z "${VIVADO:-}" ] || [ ! -x "$VIVADO" ]; then
  echo "Vivado not found."
  echo "Set VIVADO to the full path of the launcher, for example:"
  echo "  VIVADO=/tools/Xilinx/2026.1/Vivado/bin/vivado ./build.sh"
  exit 1
fi

echo "Using $VIVADO"
cd "$here/vivado/mercury2"
"$VIVADO" -mode batch -nojournal -nolog -source create_project.tcl -tclargs "$variant"
