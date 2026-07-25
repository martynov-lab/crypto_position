# Builds the release artifacts: the Windows installer and the Android APK.
# Both get the screener settings from installer\build.env as --dart-define.
# Usage: pwsh scripts\build_release.ps1 [-Target all|windows|android]

param([ValidateSet('all', 'windows', 'android')][string]$Target = 'all')

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $repoRoot 'build\release'

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml')
$version = ($pubspec | Select-String '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim().Split('+')[0]

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$artifacts = @()

if ($Target -in @('all', 'windows')) {
    & pwsh -NoProfile -File (Join-Path $repoRoot 'installer\build_installer.ps1')
    if ($LASTEXITCODE -ne 0) { throw "Windows installer build failed" }
    $artifacts += Join-Path $outDir "Cryptovit-$version-windows-x64-setup.exe"
}

if ($Target -in @('all', 'android')) {
    $envFile = Join-Path $repoRoot 'installer\build.env'
    if (-not (Test-Path $envFile)) {
        throw "$envFile not found. Copy installer\build.env.example to build.env and fill in ARB_TOKEN."
    }

    $defineArgs = @()
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Z_]+)\s*=\s*(.*)$') {
            $defineArgs += "--dart-define=$($Matches[1])=$($Matches[2].Trim())"
        }
    }

    Write-Host "Building Android APK..."
    & flutter build apk --release @defineArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed" }

    $apk = Join-Path $outDir "Cryptovit-$version-android.apk"
    Copy-Item (Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-release.apk') $apk -Force
    $artifacts += $apk
}

Write-Host ""
Write-Host "Artifacts in $outDir :"
foreach ($a in $artifacts) {
    Write-Host ("  {0}  ({1:N1} MB)" -f (Split-Path $a -Leaf), ((Get-Item $a).Length / 1MB))
}
