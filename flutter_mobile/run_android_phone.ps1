# Run MediChain+ on a USB-connected Android phone (Option B).
# Prerequisites: USB debugging on, backend on port 5000, same Wi-Fi as PC.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Detect PC LAN IP (Wi-Fi)
$ip = (Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notmatch '^169\.' } |
  Select-Object -First 1).IPAddress

if (-not $ip) {
  Write-Error "Could not detect LAN IP. Set API_BASE_URL manually in assets/config.env"
  exit 1
}

$configPath = Join-Path $PSScriptRoot "assets\config.env"
$content = Get-Content $configPath -Raw
$content = $content -replace 'API_BASE_URL=https?://[^\s#]+', "API_BASE_URL=http://${ip}:5000"
Set-Content -Path $configPath -Value $content.TrimEnd() -Encoding UTF8 -NoNewline
Add-Content -Path $configPath -Value ""
Write-Host "API_BASE_URL -> http://${ip}:5000" -ForegroundColor Green
Write-Host "Backend must be running: cd fastapi_back; python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload"
Write-Host ""

flutter devices
Write-Host ""
flutter run
