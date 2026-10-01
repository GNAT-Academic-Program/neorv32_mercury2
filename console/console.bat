@echo off
rem Serial console to the NEORV32 UART on Windows. Works in PowerShell and cmd.
rem   .\console\console.bat              finds the port on its own
rem   .\console\console.bat COM4         uses this port
rem   .\console\console.bat COM4 115200  uses this port and this baud rate
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0console.ps1" %*