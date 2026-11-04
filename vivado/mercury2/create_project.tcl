# Build the plain NEORV32 Mercury 2 bitstream: the SoC with nothing attached.
#
# Do not call this directly. Use build.sh (Linux) or build.bat (Windows) at the
# root of the repo: they find Vivado and pass the variant (100t or 35t).
#
# Default variant is the 100T. Output: neorv32_mercury2_<variant>.bit next to this script.
#
# This file is also the model for a project's own create_project.tcl: source
# board.tcl, call board_project, add your own top, RTL and XDC, call board_build.

set variant "100t"
if { $argc > 0 } { set variant [string tolower [lindex $argv 0]] }

set here [file dirname [file normalize [info script]]]
source $here/board.tcl

board_project $variant $here/work
add_files $here/../../rtl/neorv32_mercury2_top.vhd
board_build neorv32_mercury2_top $here neorv32_mercury2_$variant
