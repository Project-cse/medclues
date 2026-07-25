# Copies API URL from mobile/.env into flutter_mobile/.env
$mobileEnv = Join-Path $PSScriptRoot "..\mobile\.env"
$flutterEnv = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $mobileEnv)) {
  Write-Error "Missing $mobileEnv"
  exit 1
}
$url = (Get-Content $mobileEnv | Where-Object { $_ -match '^EXPO_PUBLIC_API_URL=(.+)$' } | ForEach-Object {
  if ($_ -match '^EXPO_PUBLIC_API_URL=(.+)$') { $Matches[1].Trim() }
}) | Select-Object -First 1
if (-not $url) {
  Write-Error "EXPO_PUBLIC_API_URL not found in mobile/.env"
  exit 1
}
$webLine = ""
$existing = if (Test-Path $flutterEnv) { Get-Content $flutterEnv -Raw } else { "" }
if ($existing -match 'API_BASE_URL_WEB=(\S+)') {
  $webLine = "API_BASE_URL_WEB=$($Matches[1])`n"
} else {
  $webLine = "API_BASE_URL_WEB=http://localhost:5000`n"
}
@"
# Synced from mobile/.env — update mobile/.env then re-run sync_env.ps1
API_BASE_URL=$url
$webLine
"@ | Set-Content -Path $flutterEnv -Encoding UTF8
Write-Host "Updated flutter_mobile/.env -> API_BASE_URL=$url"
