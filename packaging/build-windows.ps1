param(
    [string]$OutputDir = "."
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Vehicle Counter - Windows Distribution Build" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir"
Write-Host ""

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

Write-Host "[1/3] Building Flutter web..." -ForegroundColor Yellow
$FrontendDir = Join-Path $RootDir "frontend"
$WebBuildDir = Join-Path $FrontendDir "build\web"

if (-not (Test-Path $WebBuildDir)) {
    Write-Host "Running: flutter build web --release"
    Push-Location $FrontendDir
    flutter build web --release
    Pop-Location
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Flutter build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Web build already exists, skipping..."
}
Write-Host "[OK] Flutter web build complete" -ForegroundColor Green
Write-Host ""

Write-Host "[2/3] Installing Python dependencies..." -ForegroundColor Yellow
$BackendDir = Join-Path $RootDir "backend"
$RequirementsFile = Join-Path $BackendDir "requirements.txt"

Push-Location $BackendDir
pip install -r $RequirementsFile -q
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Dependency installation failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host "[OK] Dependencies installed" -ForegroundColor Green
Write-Host ""

Write-Host "[3/3] Building EXE with PyInstaller..." -ForegroundColor Yellow
Push-Location $RootDir

$SpecFile = Join-Path $ScriptDir "vehicle-counter-windows.spec"

pyinstaller `
  --noconfirm `
  --distpath (Join-Path $OutputDir "dist") `
  --workpath (Join-Path $OutputDir "build") `
  $SpecFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] PyInstaller build failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
Write-Host "[OK] Build complete" -ForegroundColor Green
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
$ExePath = Join-Path $OutputDir "dist\VehicleCounter.exe"
Write-Host "Executable: $ExePath" -ForegroundColor Green
Write-Host ""
Write-Host "To run:" -ForegroundColor Yellow
Write-Host "  Double-click: $ExePath"
Write-Host ""
