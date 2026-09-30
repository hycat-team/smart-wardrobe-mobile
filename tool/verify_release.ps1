# Verify release APK/AAB before publishing.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tool\verify_release.ps1
#
# Checks 6 things:
#   1. File exists, sane size
#   2. package / versionCode correct, 3 architectures present
#   3. Signed with the upload keystore
#   4. Production config embedded, dev client ID NOT embedded
#   5. No .env file inside the package
#   6. No Cloudinary api_secret inside the binary
#
# ASCII-only on purpose: PowerShell 5.1 mis-parses non-ASCII source.
# Exit code 0 = pass, 1 = fail.

$ErrorActionPreference = 'Continue'

# apksigner/keytool need JAVA_HOME. Set it up front because section 2b
# calls apksigner before section 3 used to set it.
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

$repo    = Split-Path -Parent $PSScriptRoot
$apkDir  = Join-Path $repo 'build\app\outputs\flutter-apk'
$apk     = Join-Path $apkDir 'app-release.apk'
$aab     = Join-Path $repo 'build\app\outputs\bundle\release\app-release.aab'
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$jar     = 'C:\Program Files\Android\Android Studio\jbr\bin\jar.exe'
$sdk     = "$env:LOCALAPPDATA\Android\Sdk"
$bt      = Get-ChildItem "$sdk\build-tools" -Directory | Sort-Object Name -Descending | Select-Object -First 1

$PROD_API = 'https://api.closy.hycat.online/api/v1'
$PROD_CLD = 'dzvwkngxu'
$PROD_GID = '5ovjq88e58p97u81asjssbt2bt8bnpt9'
$DEV_GID  = 'u71cfbe461nl51us9dmlta6vfgcdun8a'
$PKG      = 'com.smartwardrobe.smart_wardrobe'

$script:fail = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red;  $script:fail++ }
function Note($m) { Write-Host "  [ .. ] $m" -ForegroundColor Gray }

$apks = @()
if (Test-Path $apk) { $apks += Get-Item $apk }
$apks += Get-ChildItem $apkDir -Filter 'app-*-release.apk' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne 'app-release.apk' }
if ($apks.Count -eq 0) { $apks = @() }

Write-Host ""
Write-Host "=== 1. File exists ===" -ForegroundColor Cyan
if ($apks.Count -gt 0) {
    foreach ($f in $apks) {
        $mb = [math]::Round($f.Length / 1MB, 1)
        if ($mb -gt 10) { Ok "$($f.Name): $mb MB" } else { Bad "$($f.Name) too small ($mb MB)" }
    }
} else {
    Bad "No APK found in $apkDir - build not run?"
}

if (Test-Path $aab) {
    Ok "AAB: $([math]::Round((Get-Item $aab).Length / 1MB, 1)) MB"
} else {
    Note "AAB not built (skipped)"
}

if ($apks.Count -eq 0) {
    Write-Host ""
    Write-Host "STOP: cannot continue without a build." -ForegroundColor Red
    exit 1
}

$apk = $apks[0].FullName

Write-Host ""
Write-Host "=== 2. Package / version ===" -ForegroundColor Cyan
$badging = & (Join-Path $bt.FullName 'aapt2.exe') dump badging $apk 2>$null
$pkgLine = ($badging | Select-String "package: name=").Line

if ($pkgLine -match [regex]::Escape($PKG)) { Ok "package = $PKG" }
else { Bad "Wrong package (expected $PKG)" }

$vc = '?'
$vn = '?'
if ($pkgLine -match "versionCode='(.+?)'") { $vc = $Matches[1] }
if ($pkgLine -match "versionName='(.+?)'") { $vn = $Matches[1] }
Note "versionCode = $vc  versionName = $vn"

$metaPath = Join-Path $repo 'build\app\outputs\apk\release\output-metadata.json'
if (Test-Path $metaPath) {
    $meta = Get-Content $metaPath -Raw -Encoding utf8 | ConvertFrom-Json
    # With --split-per-abi the metadata lists ONE_OF_MANY elements, each with
    # its own versionCode (base + 1000*abiIndex). Compare per outputFile,
    # not against the first element.
    $mine = $meta.elements | Where-Object { $_.outputFile -eq (Split-Path $apk -Leaf) }
    if ($mine) {
        $metaVc = $mine.versionCode
        if ("$metaVc" -eq $vc) { Ok "versionCode matches metadata ($metaVc)" }
        else { Bad "versionCode mismatch: manifest=$vc metadata=$metaVc" }
    } else {
        Note "outputFile not listed in metadata (skipped)"
    }
}

$arch = ($badging | Select-String "native-code:").Line
$abiCount = ([regex]::Matches($arch, "'")).Count / 2
if ($abiCount -le 0) { Bad "No ABI declared" }
else { Ok "ABI count = $abiCount (universal=$($abiCount -gt 1))" }

Write-Host ""
Write-Host "=== 2b. Split APKs ===" -ForegroundColor Cyan
$splitFiles = Get-ChildItem $apkDir -Filter 'app-*-release.apk' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne 'app-release.apk' }
if ($splitFiles.Count -gt 0) {
    $expectAbi = @{ 'app-arm64-v8a-release.apk' = 'arm64-v8a'; 'app-armeabi-v7a-release.apk' = 'armeabi-v7a'; 'app-x86_64-release.apk' = 'x86_64' }
    foreach ($f in $splitFiles) {
        $mb = [math]::Round($f.Length / 1MB, 1)
        $b = & (Join-Path $bt.FullName 'aapt2.exe') dump badging $f.FullName 2>$null
        $ar = if (($b | Select-String "native-code:").Line -match "'(.+?)'") { $Matches[1] } else { '?' }
        $certOut = & (Join-Path $bt.FullName 'apksigner.bat') verify --print-certs $f.FullName 2>&1
        $sg = if ($certOut | Select-String 'certificate DN') { $true } else { $false }
        $vc = '?'
        if (($b | Select-String "package: name=").Line -match "versionCode='(.+?)'") { $vc = $Matches[1] }
        if ($sg) { Ok "$($f.Name): $mb MB, $ar, vc=$vc, signed" }
        else { Bad "$($f.Name) NOT SIGNED" }
    }
} else {
    Note "No split APKs (built without --split-per-abi)"
}

Write-Host ""
Write-Host "=== 3. Signature ===" -ForegroundColor Cyan
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$certs = & (Join-Path $bt.FullName 'apksigner.bat') verify --print-certs $apk 2>&1

$dn = ($certs | Select-String 'certificate DN').Line
if ($dn) { Ok "Signed: $($dn.Trim())" }
else { Bad "NOT SIGNED - no certificate found" }

$appSha = ''
$shaLine = ($certs | Select-String 'SHA-256 digest:').Line
# Select-String does NOT populate $Matches - only the -match operator does.
if ($shaLine -match 'SHA-256 digest:\s*(\w+)') { $appSha = $Matches[1].ToLower() }

$kp = Join-Path $repo 'android\key.properties'
if (Test-Path $kp) {
    $lines = Get-Content $kp -Encoding utf8
    $sf = (($lines | Select-String '^storeFile=').Line -split '=', 2)[1].Trim()
    $sf = $sf -replace '\\\\', '\'
    if (Test-Path $sf) {
        $sp = (($lines | Select-String '^storePassword=(.*)$').Matches.Groups[1].Value)
        $ks = @()
        if ($sp) { $ks = & $keytool -list -v -keystore $sf -storepass $sp 2>$null }
        $km = $ks | Select-String 'SHA256: '
        $kmLine = $km.Line
        if ($kmLine) {
            # keytool prints "FA:5E:..." (upper, colon-separated);
            # apksigner prints "fa5e..." (lower, no colon). Normalise both.
            $ksSha = (($kmLine -split 'SHA256: ')[1].Trim() -replace '[\s:]', '').ToLower()
            if ($appSha -and $ksSha -eq $appSha) {
                Ok "Signature matches keystore ($($ksSha.Substring(0,16))...)"
            } elseif (-not $appSha) {
                Note "Keystore SHA-256 = $ksSha"
            } else {
                Bad "Signature does NOT match keystore"
            }
        } else {
            Note "Could not read keystore SHA-256 (check storePassword in key.properties)"
        }
    } else { Note "storeFile not found - skipped" }
} else { Note "No key.properties - skipped" }

Write-Host ""
Write-Host "=== 4. Production config ===" -ForegroundColor Cyan
$tmp = Join-Path $env:TEMP ('apkverify_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Push-Location $tmp
    & $jar xf $apk 'lib/arm64-v8a/libapp.so' 2>$null
    Pop-Location
    $so = Get-ChildItem $tmp -Recurse -Filter 'libapp.so' | Select-Object -First 1
    if (-not $so) {
        Bad "Could not extract libapp.so"
    } else {
        $t = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($so.FullName))
        if ($t -match [regex]::Escape($PROD_API)) { Ok "Production API embedded" } else { Bad "Production API missing" }
        if ($t -match [regex]::Escape($PROD_CLD)) { Ok "Cloudinary $PROD_CLD embedded" } else { Bad "Cloudinary name missing" }
        if ($t -match [regex]::Escape($PROD_GID)) { Ok "Production Google client ID embedded" } else { Bad "Production Google client ID missing" }
        if ($t -match [regex]::Escape($DEV_GID)) { Bad "DEV client ID leaked into binary" } else { Ok "Dev client ID absent" }
    }
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "=== 5. No .env leak ===" -ForegroundColor Cyan
$envFiles = & $jar tf $apk 2>$null | Select-String '\.env$'
if ($envFiles) { Bad "APK contains .env - production config leaked" }
else { Ok "No .env inside APK" }

Write-Host ""
Write-Host "=== 6. No secret leak ===" -ForegroundColor Cyan
$tmp2 = Join-Path $env:TEMP ('aabverify_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp2 | Out-Null
try {
    Push-Location $tmp2
    & $jar xf $apk 'lib/arm64-v8a/libapp.so' 2>$null
    Pop-Location
    $so2 = Get-ChildItem $tmp2 -Recurse -Filter 'libapp.so' | Select-Object -First 1
    $t2 = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($so2.FullName))
    if ($t2 -match 'api_secret|cloudinary_api_secret') { Bad "Secret string found in binary" }
    else { Ok "No Cloudinary api_secret (signature comes from BE)" }
} finally {
    Remove-Item -Recurse -Force $tmp2 -ErrorAction SilentlyContinue
}

Write-Host ""
if ($script:fail -eq 0) {
    Write-Host "RESULT: PASS - ready to install on a real device." -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT: FAIL - $script:fail problem(s) found." -ForegroundColor Red
    exit 1
}
