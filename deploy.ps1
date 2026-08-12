# Amar Hisab – Production deploy helper for Windows (PowerShell 5.1+).
# Mirrors deploy.sh but uses only PowerShell-calls so it can run unmolested on
# a Windows-only build box.
# Usage:
#   .\deploy.ps1 -Version "1.0.0"
# Optional flags:
#   -SkipAndroid   Skip the APK build (fast iteration)
#   -SkipWindows   Skip the Windows desktop build
#   -SkipDocker    Do not build the docker images

[CmdletBinding()]
param(
  [string]$Version    = $(Get-Date -Format 'yyyyMMdd-HHmmss'),
  [switch]$SkipAndroid,
  [switch]$SkipWindows,
  [switch]$SkipDocker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Step([string]$Message) { Write-Host "==> $Message" -ForegroundColor Cyan }
function Warn([string]$Message) { Write-Host "==> WARNING: $Message" -ForegroundColor Yellow }
function Err([string]$Message)  { Write-Host "==> ERROR: $Message"   -ForegroundColor Red }

# Sanity check: Dart & Flutter on PATH (assumed pre-installed).
foreach ($bin in 'dart','flutter') {
  if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) {
    Err "$bin not on PATH"; exit 1
  }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $ScriptDir

$DistDir = Join-Path $ScriptDir "dist\amar-hisab-$Version"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

try {
  # ------------------------------------------------------------------ backend
  Step "Backend: dart pub get"
  dart pub get | Out-Host

  Step "Backend: build_runner (clean build)"
  dart run build_runner build --delete-conflicting-outputs | Out-Host

  Step "Backend: AOT compile exe"
  dart compile exe "bin\server.dart" -o (Join-Path $DistDir 'server.exe') | Out-Host

  # ------------------------------------------------------------------ flutter
  Push-Location (Join-Path $ScriptDir 'flutter_app')
  try {
    Step "Flutter: pub get"
    flutter pub get | Out-Host

    Step "Flutter: build web"
    flutter build web --dart-define=AMAR_HISAB_ENV=production --base-href=/ | Out-Host

    if (-not $SkipAndroid) {
      Step "Flutter: build Android (release)"
      flutter build apk --release --dart-define=AMAR_HISAB_ENV=production | Out-Host
    }

    if (-not $SkipWindows) {
      Step "Flutter: build Windows (release)"
      flutter build windows --dart-define=AMAR_HISAB_ENV=production | Out-Host
    }
  } finally { Pop-Location }

  # ---------------------------------------------------------------- packaging
  Step "Packaging -> $DistDir"
  New-Item -ItemType Directory -Force -Path "$DistDir\web-app" | Out-Null
  Copy-Item -Recurse -Force "flutter_app\build\web\*" "$DistDir\web-app\"

  if ((-not $SkipAndroid) -and (Test-Path "flutter_app\build\app\outputs\flutter-apk")) {
    New-Item -ItemType Directory -Force -Path "$DistDir\apk" | Out-Null
    Copy-Item -Force -Recurse "flutter_app\build\app\outputs\flutter-apk\*.apk" "$DistDir\apk\"
  }
  if ((-not $SkipWindows) -and (Test-Path "flutter_app\build\windows\x64\runner\Release")) {
    New-Item -ItemType Directory -Force -Path "$DistDir\windows-app" | Out-Null
    Copy-Item -Force -Recurse "flutter_app\build\windows\x64\runner\Release\*" "$DistDir\windows-app\"
  }

  Copy-Item -Force 'Dockerfile','docker-compose.prod.yml','.env.prod' $DistDir

  # ------------------------------------------------------------------- docker
  if (-not $SkipDocker) {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
      Step "Docker: build backend image (optional – compose up also builds)"
      docker build -t "amarhisab/backend:$Version" -f Dockerfile . | Out-Host
      Step "Docker: build sync image"
      docker build -t "amarhisab/sync:$Version" -f cloud/sync/Dockerfile cloud/sync | Out-Host
    } else {
      Warn "docker not on PATH – skipping image build"
    }
  }

  "Amar Hisab release v$Version built on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')" |
    Out-File -FilePath (Join-Path $DistDir 'VERSION.txt') -Encoding utf8

  Step "Release packaged in $DistDir"
  Step "Bring the stack up:  docker compose -f docker-compose.prod.yml up -d --build"
} finally { Pop-Location }
