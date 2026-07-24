$root = "C:\Users\hp\Desktop\Fitlek\lib"

function Fix-ConstTheme($text) {
    # Remove const before expressions using Theme.of(context) or context.fitlek
    $patterns = @(
        'const\s+TextStyle\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+Icon\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+Icon\(([^)]*context\.fitlek[^)]*)\)',
        'const\s+BoxDecoration\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+BoxDecoration\(([^)]*context\.fitlek[^)]*)\)',
        'const\s+CircularProgressIndicator\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+Scaffold\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+Center\(\s*child:\s*CircularProgressIndicator\(([^)]*Theme\.of\(context\)[^)]*)\)\s*\)',
        'const\s+Padding\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+Divider\(([^)]*Theme\.of\(context\)[^)]*)\)',
        'const\s+SnackBar\(([^)]*Theme\.of\(context\)[^)]*)\)'
    )
    foreach ($p in $patterns) {
        $text = [regex]::Replace($text, $p, { param($m) $m.Value -replace '^const\s+', '' })
    }

    # Multi-line const widgets - broader pass on single lines
    $lines = $text -split "`n"
    $out = @()
    foreach ($line in $lines) {
        if ($line -match '^\s*const\s+' -and ($line -match 'Theme\.of\(context\)' -or $line -match 'context\.fitlek')) {
            $line = $line -replace '(\s*)const\s+', '$1'
        }
        $out += $line
    }
    return ($out -join "`n")
}

# Fix coachNavbar import
$coachNav = Join-Path $root "components\ENG\coachNavbar.dart"
if (Test-Path $coachNav) {
    $t = [IO.File]::ReadAllText($coachNav)
    $t = $t.Replace("import '../theme/fitlek_theme_extension.dart';", "import '../../theme/fitlek_theme_extension.dart';")
    [IO.File]::WriteAllText($coachNav, $t)
}

$changed = 0
Get-ChildItem -Path $root -Recurse -Filter *.dart | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $fixed = Fix-ConstTheme $text
    if ($fixed -ne $text) {
        [IO.File]::WriteAllText($_.FullName, $fixed)
        $changed++
    }
}
Write-Output "Fixed const in $changed files"
