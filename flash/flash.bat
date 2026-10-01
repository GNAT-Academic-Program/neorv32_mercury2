@echo off
setlocal
if "%~1"=="" (
  echo Usage: flash.bat bitstream.bit
  exit /b 1
)
if not exist "%SystemRoot%\System32\ftd2xx.dll" (
  echo ERROR: FTDI driver is not installed on this machine.
  echo 1. Download the CDM setup executable from https://ftdichip.com/drivers/d2xx-drivers/
  echo 2. Run it, then unplug and replug the board.
  echo 3. Run flash.bat again.
  exit /b 1
)
"%~dp0mercury2_prog.exe" -w "%~1"