#!/usr/bin/env bash
# The NEORV32 submodule must sit exactly on the tag named in NEORV32_VERSION,
# and the hardware version constant (what the mimpid CSR returns) must match it.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
want=$(tr -d '[:space:]' < "$root/NEORV32_VERSION")

have=$(git -C "$root/neorv32" describe --tags --exact-match 2>/dev/null || echo "no tag")
if [ "$have" != "$want" ]; then
  echo "FAIL: submodule is at '$have', NEORV32_VERSION says '$want'"
  exit 1
fi

# v1.13.6 -> 01130600
IFS=. read -r major minor patch <<< "${want#v}"
mimpid=$(printf '%02d%02d%02d00' "$major" "$minor" "$patch")
if ! grep -qi "hw_version_c.*x\"$mimpid\"" "$root/neorv32/rtl/core/neorv32_package.vhd"; then
  echo "FAIL: hw_version_c in neorv32_package.vhd is not 0x$mimpid"
  exit 1
fi

echo "OK: NEORV32 $want, mimpid = 0x$mimpid"
