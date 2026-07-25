# Updates EXPO_PUBLIC_API_URL in mobile/.env from your active Wi-Fi IPv4.
$mobileRoot = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $mobileRoot ".env"
$envExample = Join-Path $mobileRoot ".env.example"
if (-not (Test-Path $envFile)) {
  Copy-Item $envExample $envFile
}

$ip = (Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notmatch "^127\." -and
    $_.PrefixOrigin -ne "WellKnown"
  } |
  Sort-Object -Property InterfaceMetric |
  Select-Object -First 1).IPAddress

if (-not $ip) {
  Write-Error "No LAN IPv4 found. Connect to Wi-Fi and run ipconfig."
  exit 1
}

$url = "http://${ip}:5000"
$content = Get-Content $envFile -Raw
if ($content -match "EXPO_PUBLIC_API_URL=.*") {
  $content = $content -replace "EXPO_PUBLIC_API_URL=.*", "EXPO_PUBLIC_API_URL=$url"
} else {
  $content = "EXPO_PUBLIC_API_URL=$url`n" + $content
}
Set-Content -Path $envFile -Value $content.TrimEnd() -NoNewline
Write-Host "Set EXPO_PUBLIC_API_URL=$url"
Write-Host "Restart Expo: npx expo start -c"
Write-Host "Backend must listen on all interfaces:"
Write-Host "  python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload"
