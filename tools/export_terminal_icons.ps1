param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

Add-Type -AssemblyName System.Drawing

$names = @(
    'mail', 'album', 'shop',
    'cases', 'minigame', 'system',
    'folder_mail', 'folder_document', 'folder_archive'
)

$resolvedInput = [System.IO.Path]::GetFullPath($InputPath)
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null
$source = [System.Drawing.Bitmap]::FromFile($resolvedInput)

try {
    $cellWidth = [int]($source.Width / 3)
    $cellHeight = [int]($source.Height / 3)
    for ($index = 0; $index -lt $names.Count; $index++) {
        $column = $index % 3
        $row = [int][Math]::Floor($index / 3)
        $left = $column * $cellWidth
        $top = $row * $cellHeight
        $right = $left + $cellWidth
        $bottom = $top + $cellHeight
        $minX = $right
        $minY = $bottom
        $maxX = $left - 1
        $maxY = $top - 1

        for ($y = $top; $y -lt $bottom; $y++) {
            for ($x = $left; $x -lt $right; $x++) {
                if ($source.GetPixel($x, $y).A -le 12) {
                    continue
                }
                $minX = [Math]::Min($minX, $x)
                $minY = [Math]::Min($minY, $y)
                $maxX = [Math]::Max($maxX, $x)
                $maxY = [Math]::Max($maxY, $y)
            }
        }

        if ($maxX -lt $minX -or $maxY -lt $minY) {
            throw "No visible pixels found in icon cell $index"
        }

        $sourceRect = [System.Drawing.Rectangle]::FromLTRB($minX, $minY, $maxX + 1, $maxY + 1)
        $scale = [Math]::Min(188.0 / $sourceRect.Width, 188.0 / $sourceRect.Height)
        $width = [Math]::Max(1, [int][Math]::Round($sourceRect.Width * $scale))
        $height = [Math]::Max(1, [int][Math]::Round($sourceRect.Height * $scale))
        $destinationRect = [System.Drawing.Rectangle]::new(
            [int]((256 - $width) / 2),
            [int]((256 - $height) / 2),
            $width,
            $height
        )

        $output = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($output)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($source, $destinationRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            $output.Save(
                [System.IO.Path]::Combine($resolvedOutput, $names[$index] + '.png'),
                [System.Drawing.Imaging.ImageFormat]::Png
            )
        }
        finally {
            $graphics.Dispose()
            $output.Dispose()
        }
    }
}
finally {
    $source.Dispose()
}
