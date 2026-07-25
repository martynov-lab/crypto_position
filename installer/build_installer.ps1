# Builds the Flutter Windows release and packages it with Inno Setup.
# Usage: pwsh installer\build_installer.ps1 [-SkipFlutterBuild]

param([switch]$SkipFlutterBuild)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$issFile = Join-Path $PSScriptRoot 'cryptovit.iss'

$iscc = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
    throw "ISCC.exe not found. Install Inno Setup 6: winget install --id JRSoftware.InnoSetup --source winget"
}

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml')
$version = ($pubspec | Select-String '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim().Split('+')[0]

# Screener server host and token, passed to the build as --dart-define.
# See packages\screener\lib\src\screener_config.dart. build.env is gitignored:
# the token must not be committed.
$envFile = Join-Path $PSScriptRoot 'build.env'
if (-not $SkipFlutterBuild -and -not (Test-Path $envFile)) {
    throw "$envFile not found. Copy build.env.example to build.env and fill in ARB_TOKEN."
}

$defineArgs = @()
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Z_]+)\s*=\s*(.*)$') {
            $defineArgs += "--dart-define=$($Matches[1])=$($Matches[2].Trim())"
        }
    }
}

if (-not $SkipFlutterBuild) {
    Write-Host "Building Flutter Windows release..."
    & flutter build windows --release @defineArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed" }
}

$releaseDir = Join-Path $repoRoot 'build\windows\x64\runner\Release'
if (-not (Test-Path (Join-Path $releaseDir 'crypto_position.exe'))) {
    throw "Release build not found in $releaseDir"
}

Write-Host "Compiling installer for version $version..."
& $iscc "/DAppVersion=$version" $issFile
if ($LASTEXITCODE -ne 0) { throw "ISCC failed" }

Write-Host "Installer: $(Join-Path $repoRoot "build\installer\Cryptovit-$version-windows-x64-setup.exe")"
