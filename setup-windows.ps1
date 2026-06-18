$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

$flutter = "C:\Tools\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    throw "Flutter SDK was not found at C:\Tools\flutter."
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example."
}

& $flutter pub get
& $flutter doctor
