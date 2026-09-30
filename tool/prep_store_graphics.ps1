# Sinh 2 tài nguyên BẮT BUỘC cho Google Play từ logo sẵn có
#
#   1. App icon        512 x 512  PNG 32-bit, CÓ alpha, <= 1 MB
#   2. Feature graphic 1024 x 500  PNG/JPEG, <= 1 MB
#
# Vì sao cắt từ logo-full.png (512x512) chứ không dùng ic_launcher.png:
# launcher icon lớn nhất chỉ 192x192, nâng lên 512 sẽ nhòe hẳn. Logo gốc đã
# 512x512 nên giữ được độ nét.
#
# App icon chỉ dùng phần ký hiệu "C" (không kèm chữ CLOSY): Play hiển thị icon
# trong danh sách chỉ ~48px, chữ ở cỡ đó không đọc được.
#
# Chạy: powershell -ExecutionPolicy Bypass -File tool\prep_store_graphics.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$logoPath = 'assets\images\logo-full.png'
$outDir   = 'store-assets'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

# Vùng ký hiệu "C" trong logo 512x512 (đo từ alpha channel: nội dung
# nằm trong x 102..410, y 66..340; cắt rộng rải cho sạch mép).
$markSrc = New-Object System.Drawing.Rectangle(90, 48, 336, 292)

$logo = [System.Drawing.Image]::FromFile($logoPath)
try {
    # ---------- 1. App icon 512 x 512 ----------
    # Nội dung chiếm ~82% khung, chừa lề an toàn vì Play cắt bo tròn.
    $icon = New-Object System.Drawing.Bitmap(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g = [System.Drawing.Graphics]::FromImage($icon)
        try {
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $dest = New-Object System.Drawing.Rectangle(46, 46, 420, 420)
            $g.DrawImage($logo, $dest, $markSrc, [System.Drawing.GraphicsUnit]::Pixel)
        } finally { $g.Dispose() }

        $iconPath = Join-Path $outDir 'play-icon-512.png'
        $icon.Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $len = [math]::Round((Get-Item $iconPath).Length / 1KB)
        "app-icon-512.png          {0}x{1}  32-bit ARGB  {2} KB" -f $icon.Width, $icon.Height, $len
        if ($len -gt 1024) { "  CANH BAO: > 1MB, nen giam chat luong" }
    } finally { $icon.Dispose() }

    # ---------- 2. Feature graphic 1024 x 500 ----------
    # Nền kem #FAF8F5 (Quiet Luxury) + logo dang vi (kí hiệu + chữ) canh giữa.
    $fg = New-Object System.Drawing.Bitmap(1024, 500, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g = [System.Drawing.Graphics]::FromImage($fg)
        try {
            $g.Clear([System.Drawing.Color]::FromArgb(255, 250, 248, 245))
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            # Toan bo logo (kí hiệu + chữ CLOSY): vung x 102..410, y 66..415.
            $fullSrc = New-Object System.Drawing.Rectangle(96, 58, 322, 358)
            # Cao logo ~330px trong khung 500px, canh giữa.
            $dest = New-Object System.Drawing.Rectangle(347, 85, 330, 330)
            $g.DrawImage($logo, $dest, $fullSrc, [System.Drawing.GraphicsUnit]::Pixel)
        } finally { $g.Dispose() }

        $fgPath = Join-Path $outDir 'play-feature-graphic-1024x500.png'
        $fg.Save($fgPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $len = [math]::Round((Get-Item $fgPath).Length / 1KB)
        "play-feature-graphic      {0}x{1}          {2} KB" -f $fg.Width, $fg.Height, $len
        if ($len -gt 1024) { "  CANH BAO: > 1MB" }
    } finally { $fg.Dispose() }
} finally { $logo.Dispose() }

Write-Host ''
Write-Host 'Yeu cau Play: icon 512x512 PNG co alpha <=1MB; feature graphic 1024x500 <=1MB.'
