# neorv32_mercury2

NEORV32 RISC-V softcore for the MicroNova Mercury 2 (Artix-7).

This repository contains the FPGA side of the GAP NEORV32 stack. The Ada runtime and drivers are maintained separately and target the SoC configuration defined here.

## NEORV32 version

This repository currently uses **NEORV32 v1.13.6**.

The version is recorded in two places:

- `neorv32/` is a git submodule checked out at the corresponding tag.
- `NEORV32_VERSION` contains the expected tag. CI checks that the submodule matches it.

Software built for this platform should use the NEORV32 sources included in this repository. In particular:

- SVD: `neorv32/sw/svd/neorv32.svd`
- Image generator: `neorv32/sw/image_gen/`

This keeps the hardware and software sides on the same NEORV32 version.

## SoC configuration

The SoC configuration is defined in `rtl/neorv32_mercury2_top.vhd`.

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
| `uart0_txd_o` / `uart0_rxd_i` | N11 / E11 | FT2232H channel B, the second USB serial port |
| `rstn_i` | C12 | FPGA-direct I/O 0, pulled up. Short to GND to reset |

The Mercury 2 module does not have a push button connected to this design, so reset is generated inside the FPGA at power-up.

To reset the system manually and return to the bootloader, briefly connect DIO 0 to GND.

## Get the sources

```sh
git clone --recurse-submodules https://github.com/GNAT-Academic-Program/neorv32_mercury2.git
```

If the repository was cloned without `--recurse-submodules`, initialize the submodule with:

```sh
git submodule update --init
```

## Build the bitstream

Building requires Vivado. The free edition supports both Mercury 2 FPGA sizes.

Vivado does not need to be on `PATH`; the build scripts look for an installed version automatically.

Prebuilt bitstreams are also attached to GitHub releases, so building locally is not required if you only want to use the board.

Run the appropriate command from the root of the repository.

### Linux, 100T

```sh
./build.sh 100t
```

### Linux, 35T

```sh
./build.sh 35t
```

### Windows, 100T

```bat
build.bat 100t
```

### Windows, 35T

```bat
build.bat 35t
```

The generated bitstream is:

```text
vivado/mercury2/neorv32_mercury2_100t.bit
```

or:

```text
vivado/mercury2/neorv32_mercury2_35t.bit
```

The FPGA size must be specified explicitly because the two boards require different bitstreams.

### If Vivado is not found

If Vivado is installed in a location the script does not detect, set `VIVADO` to the launcher path before running the build.

Linux:

```sh
export VIVADO=/tools/Xilinx/2026.1/Vivado/bin/vivado
```

Windows:

```bat
set VIVADO=C:\Vivado\2026.1\Vivado\bin\vivado.bat
```

On Windows, point `VIVADO` to `bin\vivado.bat`. The `vivado.exe` under `bin\unwrapped` is not the normal launcher and can fail because of missing runtime DLLs.

## Load the bitstream on the board

Connect the Mercury 2 using its USB cable, then run the appropriate command from the root of the repository.

The examples below use the 35T bitstream. For a 100T board, replace the filename with `neorv32_mercury2_100t.bit`.

### Windows

The command works from both PowerShell and `cmd`:

```bat
.\flash\flash.bat vivado\mercury2\neorv32_mercury2_35t.bit
```

### Linux

```sh
sh flash/flash.sh vivado/mercury2/neorv32_mercury2_35t.bit
```

The Linux programmer uses `sudo` to access the board and may ask for your password.

### Expected output

The programmer should report `Found flash`, show programming progress up to 100%, and then print the programming time.

Programming can take up to about a minute.

The bitstream is written to the board's flash memory, so the FPGA loads it again after power is removed and restored.

### Using a prebuilt bitstream

If you downloaded a bitstream from a GitHub release, save it locally and pass that file directly to the flash script.

Windows:

```bat
.\flash\flash.bat neorv32_mercury2_35t.bit
```

Linux:

```sh
sh flash/flash.sh neorv32_mercury2_35t.bit
```

### Troubleshooting

If Windows reports:

```text
FTDI driver is not installed
```

install the FTDI D2XX/CDM driver from:

https://ftdichip.com/drivers/d2xx-drivers/

Then unplug and reconnect the board before trying again.

If the programmer reports:

```text
No Mercury 2 FPGA board found
```

check the USB connection and make sure another application is not currently using the board, such as Vivado Hardware Manager or a serial terminal connected to the relevant FTDI interface.

On Linux, the programmer temporarily unloads the FTDI serial driver while writing the flash. Other FTDI serial ports on the machine may therefore disappear for a few seconds and return when programming completes.

### Programmer

`flash/mercury2_prog.exe` and `flash/mercury2_prog` are unmodified binaries from:

https://github.com/micro-nova/mercury2_prog

They correspond to commit `fb3118b`.

Copyright 2019 MicroNova LLC, MIT license.

## First boot

1. Load the bitstream onto the board.
2. Open the second USB serial port at **19200 8N1**.
3. Reset or power-cycle the board if necessary.

The bootloader should print:

```text
NEORV32 Bootloader
```

LED 0 also blinks roughly twice per second while the bootloader is running.

If LED 0 remains continuously on instead of blinking, the bootloader has likely stopped before reaching its normal loop.

## Simulation

Simulation currently runs on Linux. On Windows, WSL can be used.

GHDL is required.

```sh
./sim/run.sh
```

The test boots the Mercury 2 top-level design in GHDL and checks that the NEORV32 bootloader banner is emitted through UART0.

A complete simulation takes about three minutes.

CI runs the same test on every push.

## Updating NEORV32

When moving this platform to a newer NEORV32 release:

1. Update the submodule:

   ```sh
   git -C neorv32 fetch --tags
   git -C neorv32 checkout <new tag>
   ```

2. Update `NEORV32_VERSION`.

3. Update the version documented in this README.

4. Run:

   ```sh
   ./scripts/check_pin.sh
   ./sim/run.sh
   ```

5. Rebuild the bitstream and test it on the board.

6. Publish a new release once the hardware configuration has been validated.

The shell commands above can be run from Git Bash or WSL on Windows.

The software side should then regenerate its register definitions from the updated SVD and update the expected `mimpid` value.

## Repository layout

```text
neorv32/                        NEORV32 pinned submodule
rtl/neorv32_mercury2_top.vhd   board top and SoC configuration
build.sh, build.bat             Linux and Windows build launchers
vivado/mercury2/                Vivado project script and constraints
flash/                          flash scripts and mercury2_prog
sim/                            GHDL smoke test
scripts/check_pin.sh            NEORV32 version check
```

The repository layout follows the general structure used by
[neorv32-setups](https://github.com/stnolting/neorv32-setups): the same submodule name and location, the same board-directory depth, and compatible top-level port naming.

This should also make it relatively straightforward to contribute the Mercury 2 setup upstream later if desired.

## License

BSD-3-Clause, matching NEORV32.