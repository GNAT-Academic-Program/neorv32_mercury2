@echo off
rem Build the bitstream on Windows.
rem   build.bat 100t
rem   build.bat 35t
rem Vivado is found on its own. To force one, set VIVADO to the full path of vivado.bat.
setlocal

set "VARIANT=%~1"
if /i "%VARIANT%"=="100t" goto variant_ok
if /i "%VARIANT%"=="35t" goto variant_ok
echo Say which FPGA is on your Mercury 2:
echo   build.bat 100t
echo   build.bat 35t
exit /b 1

:variant_ok

if defined VIVADO goto run

for /f "delims=" %%i in ('where vivado.bat 2^>nul') do (
  set "VIVADO=%%i"
  goto run
)

rem Newest install found in the usual places, old layout (Vivado\<ver>) and new (<ver>\Vivado).
for %%r in ("C:\Xilinx" "C:\AMDDesignTools" "C:\Vivado") do (
  for /d %%v in ("%%~r\Vivado\*") do if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
  for /d %%v in ("%%~r\*") do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO=%%v\Vivado\bin\vivado.bat"
)
if defined VIVADO goto run

echo Vivado not found.
echo Set VIVADO to the full path of vivado.bat, for example:
echo   set VIVADO=C:\Vivado\2026.1\Vivado\bin\vivado.bat
exit /b 1

:run
echo Using %VIVADO%
pushd "%~dp0vivado\mercury2"
call "%VIVADO%" -mode batch -nojournal -nolog -source create_project.tcl -tclargs %VARIANT%
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%