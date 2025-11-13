# Crop and resize screenshots to 1280x800 for Chrome Web Store
Add-Type -AssemblyName System.Drawing

$targetWidth = 1280
$targetHeight = 800
$targetRatio = $targetWidth / $targetHeight  # 16:10 = 1.6

Get-ChildItem "*.png" | Where-Object { $_.Name -notlike "*-resized.png" } | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)

    $sourceWidth = $img.Width
    $sourceHeight = $img.Height

    # Calculate crop dimensions to maintain 16:10 aspect ratio
    $sourceRatio = $sourceWidth / $sourceHeight

    if ($sourceRatio -gt $targetRatio) {
        # Source is wider - crop width (keep full height)
        $cropHeight = $sourceHeight
        $cropWidth = [int]($cropHeight * $targetRatio)
        $cropX = [int](($sourceWidth - $cropWidth) / 2)
        $cropY = 0
    } else {
        # Source is taller - crop height (keep full width)
        $cropWidth = $sourceWidth
        $cropHeight = [int]($cropWidth / $targetRatio)
        $cropX = 0
        $cropY = [int](($sourceHeight - $cropHeight) / 2)
    }

    # Create cropped bitmap
    $croppedImg = New-Object System.Drawing.Bitmap($cropWidth, $cropHeight)
    $cropGraphics = [System.Drawing.Graphics]::FromImage($croppedImg)
    $cropGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Draw cropped section
    $srcRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropWidth, $cropHeight)
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $cropWidth, $cropHeight)
    $cropGraphics.DrawImage($img, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

    # Create final resized bitmap
    $finalImg = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
    $finalGraphics = [System.Drawing.Graphics]::FromImage($finalImg)
    $finalGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Draw resized image
    $finalGraphics.DrawImage($croppedImg, 0, 0, $targetWidth, $targetHeight)

    # Save with -resized suffix
    $newPath = $_.FullName -replace '\.png$', '-resized.png'
    $finalImg.Save($newPath, [System.Drawing.Imaging.ImageFormat]::Png)

    # Clean up
    $finalGraphics.Dispose()
    $finalImg.Dispose()
    $cropGraphics.Dispose()
    $croppedImg.Dispose()
    $img.Dispose()

    Write-Output "Cropped and resized $($_.Name) from ${sourceWidth}x${sourceHeight} to ${targetWidth}x${targetHeight}"
}

Write-Output "`nDone! All screenshots cropped and resized to ${targetWidth}x${targetHeight}"
