# Chuẩn hoá 8 ảnh screenshot cho Google Play
#
# Vì sao cần script này
# ---------------------
# Play Console từ chối screenshot điện thoại nếu CẠNH DÀI vượt quá 2 lần
# cạnh ngắn. Ảnh gốc 1080x2400 có tỉ lệ 2400/1080 = 2,22 → vượt giới hạn.
# (Tỉ lệ 9:16 chỉ là yêu cầu thêm cho recommendation, không phải điều kiện
#  publish.)
#
# Cách xử lý: cắt 110px status bar rồi nới 2 bên cho đúng 2:1.
# - Cắt status bar vì Play khuyến nghị: "Edit excess elements in the
#   notification bar before submitting. Do not show service providers or
#   notifications." Ảnh gốc lộ thông báo Zalo.
# - Nới 2 bên thay vì cắt tiếp chiều cao, để KHÔNG mất nội dung app —
#   nếu cắt thêm sẽ cắt vào thanh điều hướng dưới cùng.
#
# Chạy:  powershell -ExecutionPolicy Bypass -File tool\prep_store_screenshots.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$rawDir     = 'store-assets\raw'
$outDir     = 'store-assets\phone-screenshots'
$cropTop    = 110                 # chiều cao thanh status bar
$bgColor    = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$jpegQuality = 92

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$files = Get-ChildItem $rawDir -Filter '*.jpg' | Sort-Object Name
foreach ($f in $files) {
    $src = [System.Drawing.Image]::FromFile($f.FullName)
    try {
        $contentH = $src.Height - $cropTop

        # Rộng mới = contentH / 2 để đạt đúng tỉ lệ 2:1.
        $newW = [int][math]::Floor($contentH / 2)
        if ($newW -lt $src.Width) {
            throw "Sau khi cắt, chiều cao $contentH quá thấp so với chiều rộng $($src.Width). Không thể đạt 2:1 mà không làm méo ảnh."
        }
        $padTotal = $newW - $src.Width
        $padLeft  = [int][math]::Floor($padTotal / 2)
        $padRight = $padTotal - $padLeft

        $bmp = New-Object System.Drawing.Bitmap($newW, $contentH)
        try {
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                # Nền nới: trắng — khớp màu AppBar của app.
                $g.Clear($bgColor)
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                # Vẽ nội dung đã cắt status bar, canh giữa trong khung mới.
                $g.DrawImage(
                    $src,
                    (New-Object System.Drawing.Rectangle($padLeft, 0, $src.Width, $contentH)),
                    (New-Object System.Drawing.Rectangle(0, $cropTop, $src.Width, $contentH)),
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            } finally { $g.Dispose() }

            $outName = $f.Name -replace '^app-img-', 'closy-screenshot-'
            $outPath = Join-Path $outDir $outName

            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
                     Where-Object { $_.MimeType -eq 'image/jpeg' }
            $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
                [System.Drawing.Imaging.Encoder]::Quality, $jpegQuality)
            $bmp.Save($outPath, $codec, $ep)

            $ratio = $bmp.Height / $bmp.Width
            $ok = if ($ratio -le 2.0) { 'OK' } else { 'LOI' }
            "{0,-34} {1}x{2}  ti-le={3:N3}  {4}" -f $outName, $bmp.Width, $bmp.Height, $ratio, $ok
        } finally { $bmp.Dispose() }
    } finally { $src.Dispose() }
}

Write-Host ''
Write-Host 'Kiem tra cuoi: phai trien 2:1 (ti-le <= 2.0) va ngan 3840px.'
