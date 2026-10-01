# Build the NEORV32 Mercury 2 bitstream.
#
# Do not call this directly. Use build.sh (Linux) or build.bat (Windows) at the
# root of the repo: they find Vivado and pass the variant (100t or 35t).
#
# Default variant is the 100T. Output: neorv32_mercury2_<variant>.bit next to this script.

set variant "100t"
if { $argc > 0 } { set variant [lindex $argv 0] }

switch $variant {
  "100t"  { set a7part "xc7a100tftg256-1" }
  "35t"   { set a7part "xc7a35tftg256-1" }
  default { error "unknown variant '$variant', use 100t or 35t" }
}

set here    [file dirname [file normalize [info script]]]
set neorv32 [file normalize $here/../../neorv32]
set a7prj   neorv32_mercury2_$variant

if { ![file exists $neorv32/rtl/core/neorv32_top.vhd] } {
  error "NEORV32 sources not found. Run: git submodule update --init"
}

# Create and clear output directory
set outputdir $here/work
file mkdir $outputdir
set files [glob -nocomplain "$outputdir/*"]
if {[llength $files] != 0} {
  puts "deleting contents of $outputdir"
  file delete -force {*}$files
}

# Create project
create_project -part $a7part $a7prj $outputdir
set_property target_language VHDL [current_project]

# Define filesets

## Core: NEORV32
add_files [glob $neorv32/rtl/core/*.vhd]
set_property library neorv32 [get_files [glob $neorv32/rtl/core/*.vhd]]

## Design: board top
add_files $here/../../rtl/neorv32_mercury2_top.vhd
set_property top neorv32_mercury2_top [current_fileset]

## Constraints
add_files -fileset constrs_1 [glob $here/*.xdc]

# Run synthesis, implementation and bitstream generation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if { [get_property PROGRESS [get_runs impl_1]] != "100%" } {
  error "implementation failed, see $outputdir/$a7prj.runs/impl_1/runme.log"
}

file copy -force $outputdir/$a7prj.runs/impl_1/neorv32_mercury2_top.bit $here/$a7prj.bit
puts "bitstream: $here/$a7prj.bit"
