# Download the fonts the Typst CV builds need into fonts\.
# Windows equivalent of fetch-fonts.sh — same list, same destination.
# Run once after cloning; fonts\ is gitignored. Safe to re-run.
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dest = Join-Path $root 'fonts'
$list = Join-Path $here 'fonts.txt'

if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

foreach ($line in Get-Content $list) {
    $url = ($line -replace '#.*$', '').Trim()
    if ($url -eq '') { continue }

    $name = Split-Path -Leaf $url
    $file = Join-Path $dest $name

    if ((Test-Path $file) -and ((Get-Item $file).Length -gt 0)) {
        Write-Host "  have $name"
        continue
    }

    Write-Host "  get  $name"
    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
}

Write-Host "Fonts ready in $dest"
