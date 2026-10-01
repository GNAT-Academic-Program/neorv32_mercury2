# neorv32_mercury2

NEORV32 RISC-V softcore on the MicroNova Mercury 2 (Artix-7). One board, one
NEORV32 version, one SoC configuration. Nothing else.

This repo is the hardware half of the GAP NEORV32 stack. The Ada runtime and
drivers live in their own crates and are written against the bitstream built
here.

## The rule

NEORV32 is pinned to **v1.13.6**. The pin lives here and only here:

- `neorv32/` is a git submodule sitting on that tag.
- `NEORV32_VERSION` names the tag. CI fails if the submodule is anywhere else.

Nobody downloads NEORV32 from upstream. Software is built against the
`neorv32/` folder of this repo (SVD file: `neorv32/sw/svd/neorv32.svd`, image
generator: `neorv32/sw/image_gen/`).

## SoC contract

Everything below is set in `rtl/neorv32_mercury2_top.vhd`. Software may rely on it.

| Item | Value |
|---|---|
| NEORV32 version | v1.13.6, `mimpid` CSR reads `0x01130600` |
| Clock | 50 MHz |
| ISA | `rv32imc_zicsr_zicntr_zifencei` |
| Instruction memory | 128 KB at `0x00000000` |
| Data memory | 64 KB at `0x80000000` |
| Boot | stock UART bootloader, 19200 8N1 |
| Peripherals | GPIO (3 outputs), UART0, CLINT, SYSINFO |

Board wiring:

| Signal | FPGA pin | Goes to |
|---|---|---|
| `clk_i` | N14 | 50 MHz oscillator |
| `gpio_o[0..2]` | M1, A14, A13 | user LEDs. LED 0 is the bootloader status LED |
| `uart0_txd_o` / `uart0_rxd_i` | N11 / E11 | FT2232H channel B (the second USB serial port) |
| `rstn_i` | C12 | FPGA-direct I/O 0, pulled up. Short to GND to reset |

The module has no push button, so reset is generated inside the FPGA at power
up. To reset by hand (to get back to the bootloader), touch DIO 0 to GND.

## Get the sources

```
git clone --recurse-submodules https://github.com/GNAT-Academic-Program/neorv32_mercury2
```

If you already cloned without the flag: `git submodule update --init`.

## Build the bitstream

Needs Vivado (the free edition covers both FPGA sizes).

```
cd vivado/mercury2
vivado -mode batch -nojournal -nolog -source create_project.tcl               # 100T
vivado -mode batch -nojournal -nolog -source create_project.tcl -tclargs 35t  # 35T
```

Result: `vivado/mercury2/neorv32_mercury2_<variant>.bit`.

Students do not need to do this. Prebuilt bitstreams are attached to each
GitHub release.

## First boot

1. Load the bitstream on the board.
2. Open the second USB serial port at 19200 8N1.
3. The bootloader prints `NEORV32 Bootloader` and LED 0 turns on.

## Simulation

```
./sim/run.sh
```

Boots the board top in GHDL and checks that the bootloader banner comes out of
UART0. Takes about three minutes. CI runs it on every push.

## Moving to a new NEORV32 version

Once a year, in one commit:

1. `git -C neorv32 fetch --tags && git -C neorv32 checkout <new tag>`
2. Write the new tag in `NEORV32_VERSION`.
3. Update the version in this README.
4. `./scripts/check_pin.sh && ./sim/run.sh`
5. Rebuild, test on the board, publish a new release.

The software side then regenerates its registers from the new SVD and updates
its expected `mimpid` value.

## Layout

```
neorv32/                        NEORV32, pinned submodule
rtl/neorv32_mercury2_top.vhd    board top, the SoC contract
vivado/mercury2/                build script and constraints
sim/                            GHDL smoke test
scripts/check_pin.sh            version pin check
```

The layout follows [neorv32-setups](https://github.com/stnolting/neorv32-setups):
same submodule name and position, same depth for the board folder, same port
names as the stock bootloader test setup. Contributing the board upstream later
is a copy of `vivado/mercury2/`.

## License

BSD-3-Clause, same as NEORV32.
