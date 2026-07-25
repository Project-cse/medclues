# Print SHA-1 / SHA-256 for Firebase Google Sign-In (debug keystore).
# Add SHA-1 in: Firebase Console → mediclues-e39db → Project settings → Your apps → Android

$keytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
if (-not (Test-Path $keytool)) {
    $keytool = "keytool"
}

$keystore = "$env:USERPROFILE\.android\debug.keystore"
if (-not (Test-Path $keystore)) {
    Write-Error "Debug keystore not found at $keystore. Build the app once with flutter run."
    exit 1
}

Write-Host "`n=== Android debug fingerprints (for Firebase) ===" -ForegroundColor Cyan
& $keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android |
    Select-String -Pattern "SHA1:|SHA256:"

Write-Host "`nSteps:" -ForegroundColor Yellow
Write-Host "1. https://console.firebase.google.com → mediclues-e39db"
Write-Host "2. Project settings → Your apps → com.medichain.medichain_mobile"
Write-Host "3. Add fingerprint → paste SHA-1 above"
Write-Host "4. Download google-services.json → replace android\app\google-services.json"
Write-Host "5. Authentication → Sign-in method → enable Google"
Write-Host "6. flutter clean && flutter run`n"
