# Vivado helpers for the Mercury 2 SoC. Sourced, never run directly.
#
#   board_project <variant> <workdir>
#       Creates the Vivado project for the 100t or 35t module in <workdir>, adds the
#       NEORV32 core (library neorv32), the SoC entity and the module's pin
#       constraints. Nothing else: no top is set, so the caller adds its own top
#       (and RTL and XDC) afterwards.
#
#   board_build <top> <outdir> <name>
#       Sets <top> as the top entity, runs synthesis, implementation and bitstream
#       generation, and copies the result to <outdir>/<name>.bit.
#
# This repo's own create_project.tcl calls both with neorv32_mercury2_top.
# A project repo that takes this repo as a submodule does the same from its own
# create_project.tcl, with its own top in between:
#
#   source <submodule>/vivado/mercury2/board.tcl
#   board_project $variant $here/work
#   add_files $here/../../rtl/my_project_top.vhd
#   add_files -fileset constrs_1 $here/my_pins.xdc
#   board_build my_project_top $here my_project_$variant

set board_here    [file dirname [file normalize [info script]]]
set board_root    [file normalize $board_here/../..]
set board_neorv32 $board_root/neorv32

proc board_part {variant} {
  switch [string tolower $variant] {
    "100t"  { return "xc7a100tftg256-1" }
    "35t"   { return "xc7a35tftg256-1" }
    default { error "unknown variant '$variant', use 100t or 35t" }
  }
}

proc board_project {variant workdir} {
  global board_here board_root board_neorv32

  if { ![file exists $board_neorv32/rtl/core/neorv32_top.vhd] } {
    error "NEORV32 sources not found under $board_neorv32. Run: git submodule update --init --recursive"
  }

  set part [board_part $variant]

  # Create and clear the work directory
  file mkdir $workdir
  set files [glob -nocomplain "$workdir/*"]
  if {[llength $files] != 0} {
    puts "deleting contents of $workdir"
    file delete -force {*}$files
  }

  create_project -part $part mercury2_[string tolower $variant] $workdir
  set_property target_language VHDL [current_project]

  ## Core: NEORV32, in its own library
  add_files [glob $board_neorv32/rtl/core/*.vhd]
  set_property library neorv32 [get_files [glob $board_neorv32/rtl/core/*.vhd]]

  ## The SoC
  add_files $board_root/rtl/neorv32_mercury2_soc.vhd

  ## The module's pins
  add_files -fileset constrs_1 $board_here/mercury2.xdc
}

proc board_build {top outdir name} {
  set_property top $top [current_fileset]
  update_compile_order -fileset sources_1

  launch_runs impl_1 -to_step write_bitstream -jobs 4
  wait_on_run impl_1

  if { [get_property PROGRESS [get_runs impl_1]] != "100%" } {
    error "implementation failed, see [get_property DIRECTORY [get_runs impl_1]]/runme.log"
  }

  set bit [get_property DIRECTORY [get_runs impl_1]]/$top.bit
  file copy -force $bit $outdir/$name.bit
  puts "bitstream: $outdir/$name.bit"
}
