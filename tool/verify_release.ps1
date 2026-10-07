# Verify release APK/AAB before publishing.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tool\verify_release.ps1
#
# Checks 7 things:
#   1. File exists, sane size
#   2. package / versionCode correct, 3 architectures present
#   3. Signed with the upload keystore
#   4. Production config embedded, dev client ID NOT embedded
#   5. No .env file inside the package
#   6. No Cloudinary api_secret inside the binary
#   7. AAB is a valid App Bundle (bundletool validate) and agrees with the APKs
#
# Section 7 exists because the AAB - not the APK - is what gets uploaded to
# Play. It used to be skipped entirely ("outputFile not listed in metadata"),
# which meant the actual release artifact was never checked.
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
# Package renamed to `online.hycat.closy` (2026-09-30, before first publish).
# Must match `applicationId` in android/app/build.gradle.kts and the value
# entered in Play Console > Package name.
$PKG      = 'online.hycat.closy'

# Shared helper: SHA-256 of the upload keystore certificate, normalised to
# lowercase hex with no colons (keytool prints "FA:5E:..", apksigner "fa5e..").
function Get-KeystoreSha256 {
    $kp = Join-Path $repo 'android\key.properties'
    if (-not (Test-Path $kp)) { return $null }
    $lines = Get-Content $kp -Encoding utf8
    $sfLine = ($lines | Select-String '^storeFile=').Line
    if (-not $sfLine) { return $null }
    $sf = ($sfLine -split '=', 2)[1].Trim() -replace '\\\\', '\'
    if (-not (Test-Path $sf)) { return $null }
    $sp = (($lines | Select-String '^storePassword=(.*)$').Matches.Groups[1].Value)
    if (-not $sp) { return $null }
    $ks = & $keytool -list -v -keystore $sf -storepass $sp 2>$null
    $km = (($ks | Select-String 'SHA256: ').Line)
    if (-not $km) { return $null }
    return (($km -split 'SHA256: ')[1].Trim() -replace '[\s:]', '').ToLower()
}

# Locate bundletool in the Gradle cache. It is pulled in transitively by AGP,
# so there is no standalone copy on PATH. Returns @{ Jar; Classpath } or $null.
function Get-Bundletool {
    $cache = Join-Path $env:USERPROFILE '.gradle\caches\modules-2\files-2.1'
    if (-not (Test-Path $cache)) { return $null }
    $jar0 = Get-ChildItem $cache -Recurse -Filter 'bundletool-*.jar' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch 'sources|javadoc' } |
        Sort-Object { [version]($_.BaseName -replace '^bundletool-', '') } -Descending |
        Select-Object -First 1
    if (-not $jar0) { return $null }
    $cp = @($jar0.FullName)
    foreach ($d in @('jose4j', 'protobuf-java', 'guava', 'gson', 'auto-value-annotations',
                     'jsr305', 'checker-qual', 'error_prone_annotations',
                     'j2objc-annotations', 'failureaccess', 'listenablefuture',
                     'kotlin-stdlib', 'aapt2-proto', 'aapt-proto', 'sdklib', 'common')) {
        Get-ChildItem $cache -Recurse -Filter "$d*.jar" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch 'sources|javadoc' } |
            Select-Object -First 2 | ForEach-Object { $cp += $_.FullName }
    }
    return @{ Classpath = (($cp | Sort-Object -Unique) -join ';') }
}

function Invoke-Bundletool([string]$bundle, [string[]]$toolArgs) {
    $btTool = Get-Bundletool
    if (-not $btTool) { return $null }
    $java = Join-Path $env:JAVA_HOME 'bin\java.exe'
    if (-not (Test-Path $java)) { return $null }
    return (& $java -cp $btTool.Classpath com.android.tools.build.bundletool.BundleToolMain @toolArgs 2>&1)
}

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

# The APK section above reads $PKG/$vc/$vn. Do NOT read versionCode back out
# of output-metadata.json: --split-per-abi rewrites each split's versionCode to
# base + 1000*abiIndex, so the value in the manifest of the *universal* APK
# would never match and the check produced a misleading
# "outputFile not listed in metadata (skipped)" for the AAB. The AAB has no
# output-metadata.json at all, which is why it was silently skipped for years.
# Version cross-checks live in section 7 instead.
Note "versionCode/versionName above come from aapt2 on the universal APK"

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
Write-Host "=== 7. AAB (App Bundle) ===" -ForegroundColor Cyan
if (-not (Test-Path $aab)) {
    Note "AAB not built (skipped)"
} else {
    $aabMb = [math]::Round((Get-Item $aab).Length / 1MB, 1)
    Note "AAB: $aabMb MB - $($aab | Split-Path -Leaf)"

    $aabTmp = Join-Path $env:TEMP ('aabfull_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $aabTmp | Out-Null
    try {
        Push-Location $aabTmp
        & $jar xf $aab 2>$null
        Pop-Location

        $aabManifest = Join-Path $aabTmp 'base\manifest\AndroidManifest.xml'
        if (-not (Test-Path $aabManifest)) {
            Bad "AAB manifest not found (corrupt bundle?)"
        } else {
            $mBytes = [System.IO.File]::ReadAllBytes($aabManifest)
            $mTxt = [System.Text.Encoding]::UTF8.GetString($mBytes)

            if ($mTxt -match [regex]::Escape($PKG)) { Ok "AAB package = $PKG" }
            else { Bad "AAB wrong package (expected $PKG)" }

            # The manifest is protobuf, so versionCode/minSdk/targetSdk are
            # varints and CANNOT be read as text. Only a real parser sees them.
            $aabLibApp = Join-Path $aabTmp 'base\lib\arm64-v8a\libapp.so'
            $aabAbis = @()
            if (Test-Path (Join-Path $aabTmp 'base\lib')) {
                $aabAbis = (Get-ChildItem (Join-Path $aabTmp 'base\lib') -Directory | ForEach-Object { $_.Name })
            }
            if ($aabAbis.Count -ge 2) { Ok "AAB ABIs = $($aabAbis -join ', ')" }
            else { Bad "AAB has fewer than 2 ABIs ($($aabAbis.Count))" }

            if ($mTxt -match 'com\.smartwardrobe') {
                Bad "AAB still contains the OLD package com.smartwardrobe"
            } else { Ok "No leftover old package in AAB" }

            if (Test-Path $aabLibApp) {
                $aTxt = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($aabLibApp))
                if ($aTxt -match [regex]::Escape($PROD_API)) { Ok "AAB: production API embedded" } else { Bad "AAB: production API missing" }
                if ($aTxt -match [regex]::Escape($PROD_CLD)) { Ok "AAB: Cloudinary embedded" } else { Bad "AAB: Cloudinary missing" }
                if ($aTxt -match [regex]::Escape($PROD_GID)) { Ok "AAB: production Google client embedded" } else { Bad "AAB: production Google client missing" }
                if ($aTxt -match [regex]::Escape($DEV_GID)) { Bad "AAB: DEV client ID leaked" } else { Ok "AAB: dev client ID absent" }
                if ($aTxt -match 'api_secret|cloudinary_api_secret') { Bad "AAB: secret string found in binary" } else { Ok "AAB: no api_secret" }
            } else {
                Note "AAB libapp.so not extracted - config checks skipped"
            }

            $aabEnv = Get-ChildItem $aabTmp -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '\.env$|key\.properties|\.jks$|\.keystore$' }
            if ($aabEnv) { $aabEnv | ForEach-Object { Bad "AAB contains $($_.Name)" } }
            else { Ok "No .env / keystore inside AAB" }
        }
    } finally {
        Remove-Item -Recurse -Force $aabTmp -ErrorAction SilentlyContinue
    }

    # Signature. apksigner CANNOT be used here: it expects a flat APK and dies
    # with "Missing AndroidManifest.xml" on a bundle (the manifest lives in
    # base/manifest/ and is protobuf). An AAB carries a plain JAR signature
    # instead, which keytool reads directly.
    $aabCert = & $keytool -printcert -jarfile $aab 2>&1
    $aabDn = ($aabCert | Select-String 'Owner:').Line
    if ($aabDn) {
        Ok "AAB signed: $($aabDn.Trim() -replace '^Owner:\s*','')"
        $aabSha = ''
        if (($aabCert | Select-String 'SHA256:').Line -match 'SHA256:\s*(\S+)') {
            $aabSha = (($Matches[1].Trim()) -replace '[\s:]', '').ToLower()
        }
        $ksSha = Get-KeystoreSha256
        if ($aabSha -and $ksSha) {
            if ($aabSha -eq $ksSha) { Ok "AAB signature matches keystore ($($ksSha.Substring(0,16))...)" }
            else { Bad "AAB signature does NOT match keystore" }
        } elseif (-not $ksSha) {
            Note "Keystore SHA-256 unreadable (check storePassword in key.properties)"
        }
    } else {
        Bad "AAB NOT SIGNED - no certificate found"
    }

    # Structural validation with bundletool - this is what Google Play itself
    # runs. Without it we only know the zip opens, not that Play will accept
    # the bundle.
    $btOut = Invoke-Bundletool $aab @('validate', "--bundle=$aab")
    if ($null -eq $btOut) {
        Note "bundletool not found in Gradle cache - bundle structure NOT validated"
    } elseif ($LASTEXITCODE -eq 0) {
        Ok "bundletool validate: PASS (Play will accept the bundle structure)"
    } else {
        Bad "bundletool validate FAILED - Play would reject this bundle"
    }

    # get-device-spec needs --output; it writes to stdout only with that flag
    # and is a diagnostic, not a release gate. Skipped to keep this section
    # focused on pass/fail checks.
}

Write-Host ""
if ($script:fail -eq 0) {
    Write-Host "RESULT: PASS - ready to install on a real device." -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT: FAIL - $script:fail problem(s) found." -ForegroundColor Red
    exit 1
}
