# Capture Android logcat while reproducing the Google Sign-In failure.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tool\capture_google_login_log.ps1
#         powershell -ExecutionPolicy Bypass -File tool\capture_google_login_log.ps1 -Seconds 90
#
# What it does:
#   1. Locates adb (works even when it is not in PATH)
#   2. Checks a device is connected
#   3. Clears the log, then records for N seconds (default 45)
#   4. Prints only the lines that matter for Google Sign-In
#
# During the capture you must: open the app, tap "Continue with Google",
# pick an account, wait ~10s. Do NOT tap anything else.
#
# ASCII-only on purpose: PowerShell 5.1 mis-parses non-ASCII source.

param(
    [int]$Seconds = 45,
    [string]$Package = 'online.hycat.closy'
)

$ErrorActionPreference = 'Continue'

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$adb = Join-Path $sdk 'platform-tools\adb.exe'

if (-not (Test-Path $adb)) {
    Write-Host "adb not found at $adb" -ForegroundColor Red
    Write-Host "Install Android SDK Platform-Tools, or set `$env:ANDROID_HOME." -ForegroundColor Yellow
    exit 1
}

Write-Host "adb: $adb" -ForegroundColor DarkGray

# --- 1. device check --------------------------------------------------------
$devices = & $adb devices 2>&1 | Select-Object -Skip 1 |
    Where-Object { $_ -match '\sdevice$' }

if (-not $devices) {
    Write-Host ""
    Write-Host "NO DEVICE CONNECTED" -ForegroundColor Red
    Write-Host ""
    Write-Host "On the phone:" -ForegroundColor Yellow
    Write-Host "  1. Settings > About phone > tap 'Build number' 7 times"
    Write-Host "  2. Settings > Developer options > USB debugging = ON"
    Write-Host "  3. Plug in the USB cable, tick 'Always allow' on the popup"
    Write-Host ""
    Write-Host "Current state:" -ForegroundColor DarkGray
    & $adb devices 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    exit 1
}

Write-Host ""
Write-Host "Device: OK" -ForegroundColor Green

# Is the app installed? Its absence changes the diagnosis completely.
$installed = & $adb shell pm path $Package 2>&1
if ($installed -match 'package:') {
    Write-Host "App installed: yes" -ForegroundColor Green
} else {
    Write-Host "App NOT installed on this device (package $Package)" -ForegroundColor Yellow
    Write-Host "  - if you are testing the Play build, install it from Play first" -ForegroundColor Yellow
}

# --- 1b. which key actually signs the installed app? -----------------------
# This is the single most useful fact when debugging OAuth 12500 /
# UNREGISTERED_ON_API_CONSOLE. Google matches the SHA-1 of the *signing
# certificate of the running app* against the fingerprints registered in the
# OAuth client - not against what Play Console shows under "App signing key".
# For an app that has not enabled Play App Signing yet, Play signs with the
# shared key whose DN is "CN=Android, O=Google Inc.".
Write-Host ""
Write-Host "Signing certificate of the installed app:" -ForegroundColor Cyan

# Force a real array: without @() a single match collapses to a bare string and
# indexing [0] then yields a char, which breaks .Trim().
$apkPaths = @(& $adb shell pm path $Package 2>&1 |
    Where-Object { $_ -match 'base\.apk' } |
    ForEach-Object { ($_ -replace 'package:', '').Trim() } |
    Where-Object { $_ -ne '' })

if ($apkPaths.Count -gt 0) {
    $pullDir = Join-Path $env:TEMP 'closy-cert'
    New-Item -ItemType Directory -Path $pullDir -Force | Out-Null
    $apkOut = Join-Path $pullDir 'base.apk'
    & $adb pull $apkPaths[0] $apkOut 2>&1 | Out-Null

    $btDir = Get-ChildItem "$sdk\build-tools" -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    $apksigner = if ($btDir) { Join-Path $btDir.FullName 'apksigner.bat' } else { $null }

    if ($apksigner -and (Test-Path $apksigner)) {
        $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
        $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
        $certOut = & $apksigner verify --print-certs $apkOut 2>&1

        # Only "Signer #1" lines matter; skip "Source Stamp Signer" (Play's own).
        $dn = ($certOut | Select-String 'Signer #1 certificate DN').Line
        $sha1 = ($certOut | Select-String 'Signer #1 certificate SHA-1').Line
        if ($dn -and $sha1) {
            $sha1Val = (($sha1 -split ':\s*')[1]).Trim()
            Write-Host "  DN    : $(($dn -split ':\s*', 2)[1].Trim())" -ForegroundColor White
            Write-Host "  SHA-1 : $sha1Val" -ForegroundColor White
            if ($dn -match 'CN=Android.*O=Google Inc') {
                Write-Host "  -> Google Play SHARED key: Play App Signing is NOT enabled." -ForegroundColor Yellow
                Write-Host "     Register this SHA-1 in the OAuth client, or enrol in Play App Signing." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  (could not read certificate)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  (apksigner not found)" -ForegroundColor Yellow
    }
    Remove-Item $pullDir -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "  (app not installed on this device)" -ForegroundColor Yellow
}

# --- 2. capture -------------------------------------------------------------
$logFile = Join-Path $PSScriptRoot '..\build\play-login.log'
New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

Write-Host ""
Write-Host "Clearing log..." -ForegroundColor DarkGray
& $adb logcat -c 2>&1 | Out-Null

Write-Host "Recording for $Seconds seconds." -ForegroundColor Cyan
Write-Host ">>> NOW: open the app, tap 'Continue with Google', pick an account, wait 10s." -ForegroundColor White
Write-Host ""

$job = Start-Job -ScriptBlock {
    param($exe)
    & $exe logcat -v time 2>&1
} -ArgumentList $adb

$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    Start-Sleep -Milliseconds 500
    $left = [int]($Seconds - $sw.Elapsed.TotalSeconds)
    if ($left % 10 -eq 0 -and $left -gt 0) {
        Write-Host "  ... $left s left" -ForegroundColor DarkGray
    }
}

Stop-Job $job -ErrorAction SilentlyContinue
$all = Receive-Job $job -ErrorAction SilentlyContinue
Remove-Job $job -Force -ErrorAction SilentlyContinue

$all | Out-File -FilePath $logFile -Encoding utf8
Write-Host ""
Write-Host "Saved: $logFile ($($all.Count) lines total)" -ForegroundColor Green

# --- 3. filter to the useful part ------------------------------------------
$pattern = 'Credential|GoogleSignIn|GoogleAuth|GoogleIdToken|Identity|AuthService|Exception|denied|DENIED|error|Error|12500|authenticat'
$hits = $all | Where-Object { $_ -match $pattern }

Write-Host ""
if ($hits) {
    Write-Host "=== $((($hits).Count)) relevant lines ===" -ForegroundColor Cyan
    $hits | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "NO RELEVANT LINES FOUND" -ForegroundColor Red
    Write-Host "The log was empty or had nothing matching the filter." -ForegroundColor Yellow
    Write-Host "Full log is at $logFile - send that file instead." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Send $logFile to the agent." -ForegroundColor White
