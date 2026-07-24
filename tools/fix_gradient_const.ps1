$root = "C:\Users\hp\Desktop\Fitlek\lib"

Get-ChildItem -Path $root -Recurse -Filter *.dart | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $original = $text

    # Remove const from LinearGradient/RadialGradient with theme colors
    $text = [regex]::Replace($text, 'const\s+(LinearGradient|RadialGradient)\(', '$1(')

    # Remove const from color lists containing Theme.of or context.fitlek
    $text = [regex]::Replace($text, 'const\s+(\[[^\]]*Theme\.of\(context\)[^\]]*\])', '$1')
    $text = [regex]::Replace($text, 'const\s+(\[[^\]]*context\.fitlek[^\]]*\])', '$1')

    # Fix colorScheme.primaryDim -> context.fitlek.primaryDim
    $text = $text -replace 'Theme\.of\(context\)\.colorScheme\.primaryDim', 'context.fitlek.primaryDim'

    # Fix _color reference in clientForgot if any remain
    $text = $text -replace '\b_color\b(?!\w)', '_strengthColor(context)'

    if ($text -ne $original) {
        [IO.File]::WriteAllText($_.FullName, $text)
        Write-Output $_.Name
    }
}
