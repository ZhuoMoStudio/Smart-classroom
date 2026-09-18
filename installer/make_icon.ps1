# ============================================================================
#  make_icon.ps1
#
#  Generates windows\runner\resources\app_icon.ico from the PNG source in
#  assets\wallpapers\app_icon.png.
#
#  Why generated instead of committed:
#    - runner\Runner.rc references resources\app_icon.ico, and
#      installer\*.iss use it as SetupIconFile. Both need a real .ico.
#    - An .ico is binary; keeping a single PNG source plus this script in the
#      repository keeps the tree reviewable and the icon reproducible.
#
#  Output is a PNG-compressed ICO (supported since Windows Vista) containing
#  256/64/48/32/16 px entries, saved as 32bpp.
#
#  Usage:  pwsh -File installer\make_icon.ps1
# ============================================================================
param(
  [string]$Source = "assets\wallpapers\app_icon.png",
  [string]$Dest   = "windows\runner\resources\app_icon.ico"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $Source)) { throw "Icon source not found: $Source" }

$destDir = Split-Path -Parent $Dest
if ($destDir -and -not (Test-Path $destDir)) {
  New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$sizes = @(256, 64, 48, 32, 16)
$entries = @()

$srcImage = [System.Drawing.Image]::FromFile((Resolve-Path $Source).Path)
try {
  # Centre-crop to a square so the icon is never stretched.
  $side = [Math]::Min($srcImage.Width, $srcImage.Height)
  $offX = [int](($srcImage.Width  - $side) / 2)
  $offY = [int](($srcImage.Height - $side) / 2)

  $square = New-Object System.Drawing.Bitmap($side, $side)
  $g = [System.Drawing.Graphics]::FromImage($square)
  $g.DrawImage(
    $srcImage,
    (New-Object System.Drawing.Rectangle(0, 0, $side, $side)),
    (New-Object System.Drawing.Rectangle($offX, $offY, $side, $side)),
    [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()

  foreach ($s in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($s, $s)
    $gg = [System.Drawing.Graphics]::FromImage($bmp)
    $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gg.DrawImage($square, 0, 0, $s, $s)
    $gg.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $entries += , @($s, $ms.ToArray())
    $bmp.Dispose()
    $ms.Dispose()
  }
  $square.Dispose()
}
finally {
  $srcImage.Dispose()
}

# ---- Assemble the ICO container ----
# 6-byte header, then one 16-byte directory entry per image, then the payloads.
$out = New-Object System.IO.MemoryStream
$w = New-Object System.IO.BinaryWriter($out)

$w.Write([UInt16]0)             # reserved, must be 0
$w.Write([UInt16]1)             # type: 1 = icon
$w.Write([UInt16]$entries.Count)

$offset = 6 + 16 * $entries.Count
foreach ($e in $entries) {
  $size = [int]$e[0]
  $data = [byte[]]$e[1]
  $dim = if ($size -ge 256) { 0 } else { $size }   # 0 means 256 in the ICO format

  $w.Write([Byte]$dim)            # width
  $w.Write([Byte]$dim)            # height
  $w.Write([Byte]0)               # palette colour count (0 = truecolour)
  $w.Write([Byte]0)               # reserved
  $w.Write([UInt16]1)             # colour planes
  $w.Write([UInt16]32)            # bits per pixel
  $w.Write([UInt32]$data.Length)  # bytes of image data
  $w.Write([UInt32]$offset)       # offset of image data
  $offset += $data.Length
}
foreach ($e in $entries) { $w.Write([byte[]]$e[1]) }
$w.Flush()

$destPath = Join-Path (Get-Location).Path $Dest
[System.IO.File]::WriteAllBytes($destPath, $out.ToArray())
$w.Dispose()
$out.Dispose()

$info = Get-Item $destPath
Write-Host ("Wrote {0} ({1} bytes, sizes {2})" -f $Dest, $info.Length, ($sizes -join '/'))
