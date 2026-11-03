# Optional artwork tool; pre-generated assets are checked in for normal builds.
# Requires ImageMagick with SVG support on PATH.
$ErrorActionPreference = 'Stop'
$images = Join-Path $PSScriptRoot '../src/assets/img'
$source = Join-Path $images 'rvm-windows-icon.svg'
$preview = Join-Path $images 'rvm-windows-icon.png'
$icon = Join-Path $images 'rvm-windows.ico'
& magick -background none -density 384 $source -resize 1024x1024 $preview
if ($LASTEXITCODE -ne 0) { throw 'Could not render icon preview.' }
& magick $preview -define icon:auto-resize=256,128,64,48,32,24,16 $icon
if ($LASTEXITCODE -ne 0) { throw 'Could not generate Windows icon.' }
