param(
  [switch]$SkipFrontend = $false,
  [switch]$SkipVenv = $false
)

# Builds the production artifacts for the single-port "prod" flow:
#   1) builds the React frontend           -> frontend/dist
#   2) ensures the Python venv exists       -> .venv (+ pip install requirements)
# Unlike the Java reference projects the Python backend needs no compilation or
# jar packaging, so the only real artifact is frontend/dist. Run this after
# changing frontend or backend dependencies. The dev flow (start-dev.cmd) is
# unaffected — this only produces what start-prod.cmd runs.

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptRoot 'frontend'
$distDir = Join-Path $frontendDir 'dist'
$venvPython = Join-Path $scriptRoot '.venv\Scripts\python.exe'
$requirements = Join-Path $scriptRoot 'requirements.txt'

if (-not (Test-Path $frontendDir)) { throw "Frontend directory not found: $frontendDir" }

# ── Frontend build ───────────────────────────────────────────────────────────
if (-not $SkipFrontend) {
  Write-Host "Building frontend..."
  Push-Location $frontendDir
  try {
    if (-not (Test-Path 'node_modules')) {
      Write-Host "node_modules not found - running npm install..."
      & npm install
      if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
    }
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "Frontend build failed" }
  } finally {
    Pop-Location
  }
  if (-not (Test-Path $distDir)) { throw "Build finished but dist not found: $distDir" }
} else {
  Write-Host "Skipping frontend build (-SkipFrontend)."
}

# ── Python venv (stand-in for the Java jar packaging step) ───────────────────
if (-not $SkipVenv) {
  if (-not (Test-Path $venvPython)) {
    Write-Host "Creating virtual environment (.venv)..."
    & python -m venv (Join-Path $scriptRoot '.venv')
    if ($LASTEXITCODE -ne 0) { throw "python -m venv failed" }
  }
  if (Test-Path $requirements) {
    Write-Host "Installing backend dependencies (requirements.txt)..."
    & $venvPython -m pip install --disable-pip-version-check -r $requirements
    if ($LASTEXITCODE -ne 0) { throw "pip install failed" }
  } else {
    Write-Host "requirements.txt not found - skipping dependency install."
  }
} else {
  Write-Host "Skipping venv setup (-SkipVenv)."
}

Write-Host ""
Write-Host "==============================================="
Write-Host " Production artifacts ready"
Write-Host "   Frontend: $distDir"
Write-Host "   Backend : $venvPython"
Write-Host " Launch with start-prod.cmd"
Write-Host "==============================================="
