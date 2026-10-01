# Serial console to the NEORV32 UART (FT2232H channel B) on Windows.
# Do not run this file directly: use console.bat, which starts it the right way.
#   .\console\console.bat              finds the port on its own
#   .\console\console.bat COM4         uses this port
#   .\console\console.bat COM4 115200  uses this port and this baud rate
param([string]$Port, [int]$Baud = 19200)

if (-not $Port) {
  # Channel B of an FTDI chip: its device id ends with "B\0000".
  $ports = @(Get-PnpDevice -Class Ports -PresentOnly | Where-Object { $_.InstanceId -like "FTDIBUS\*B\0000" })

  if ($ports.Count -eq 0) {
    $chip = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like "USB\VID_0403*" })
    if ($chip.Count -eq 0) {
      Write-Host "ERROR: the board is not seen by Windows."
      Write-Host "Plug it in. In a virtual machine, attach the USB device to the machine again."
    } else {
      Write-Host "ERROR: the board is plugged in but has no serial port."
      Write-Host "Windows must be told once to create it:"
      Write-Host "  1. Open Device Manager, then 'Universal Serial Bus controllers'."
      Write-Host "  2. Double-click 'USB Serial Converter B'."
      Write-Host "  3. In the 'Advanced' tab, check 'Load VCP'. Click OK."
      Write-Host "  4. Unplug the board, plug it back in, run this again."
    }
    exit 1
  }

  if ($ports.Count -gt 1) {
    Write-Host "More than one board found. Run again with the port of your board, for example:"
    Write-Host "  .\console\console.bat COM4"
    Write-Host ""
    $ports | ForEach-Object { Write-Host "  $($_.FriendlyName)" }
    exit 1
  }

  if ($ports[0].FriendlyName -match "\((COM\d+)\)") {
    $Port = $Matches[1]
  } else {
    Write-Host "ERROR: could not read the port number of '$($ports[0].FriendlyName)'."
    Write-Host "Run again with the port, for example: .\console\console.bat COM4"
    exit 1
  }
}

$serial = New-Object System.IO.Ports.SerialPort $Port, $Baud, "None", 8, "One"
try {
  $serial.Open()
} catch {
  Write-Host "ERROR: cannot open $Port. Another program is using it, or it does not exist."
  Write-Host "Close the other program (another console window, PuTTY, Tera Term), then run this again."
  exit 1
}

Write-Host "Connected to $Port at $Baud baud. Press Escape to quit."
Write-Host "At the bootloader prompt, press r to restart it and see its banner."
Write-Host ""

try {
  while ($true) {
    if ($serial.BytesToRead) { Write-Host -NoNewline $serial.ReadExisting() }
    if ([Console]::KeyAvailable) {
      $key = [Console]::ReadKey($true)
      if ($key.Key -eq "Escape") { break }
      $serial.Write([string]$key.KeyChar)
    }
    Start-Sleep -Milliseconds 20
  }
} finally {
  $serial.Close()
  Write-Host ""
}