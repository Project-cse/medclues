# MediChain+ Flutter (Chrome). API URL from flutter_mobile/.env (sync with mobile/.env).
# Requires FastAPI: cd ..\fastapi_back; python main.py

Set-Location $PSScriptRoot
& "$PSScriptRoot\sync_env.ps1"
flutter run -d chrome
