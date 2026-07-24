$root = "C:\Users\hp\Desktop\Fitlek\lib"
$skip = @('app_colors.dart','app_theme.dart','fitlek_theme_extension.dart','theme_service.dart','theme_selector.dart','fitlek_logo.dart','colors.dart')

$colorConstPatterns = @(
    '(?m)^const _lime\s*=.*\r?\n',
    '(?m)^const _limeDark\s*=.*\r?\n',
    '(?m)^const _dark\s*=.*\r?\n',
    '(?m)^const _darkElev2\s*=.*\r?\n',
    '(?m)^const _darkElev3\s*=.*\r?\n',
    '(?m)^const _card\s*=.*\r?\n',
    '(?m)^const _cardBorder\s*=.*\r?\n',
    '(?m)^const _card2\s*=.*\r?\n',
    '(?m)^const _border\s*=.*\r?\n',
    '(?m)^const _textPrimary\s*=.*\r?\n',
    '(?m)^const _textSecondary\s*=.*\r?\n',
    '(?m)^const _textMuted\s*=.*\r?\n',
    '(?m)^const _muted\s*=.*\r?\n',
    '(?m)^const _white\s*=.*\r?\n',
    '(?m)^const _success\s*=.*\r?\n',
    '(?m)^const _errorRed\s*=.*\r?\n',
    '(?m)^const _error\s*=.*\r?\n'
)

$replacements = [ordered]@{
    'Color\(0xFFC6F135\)' = 'Theme.of(context).colorScheme.primary'
    'Color\(0xFFA3FF12\)' = 'Theme.of(context).colorScheme.primary'
    'Color\(0xFF9BC420\)' = 'Theme.of(context).colorScheme.primary'
    'Color\(0xFFD1F96B\)' = 'Theme.of(context).colorScheme.primary'
    '\b_limeDark\b' = 'Theme.of(context).colorScheme.primary'
    '\b_lime\b' = 'Theme.of(context).colorScheme.primary'
    '\b_darkElev3\b' = 'context.fitlek.card2'
    '\b_darkElev2\b' = 'context.fitlek.card'
    '\b_card2\b' = 'context.fitlek.card2'
    '\b_cardBorder\b' = 'context.fitlek.border'
    '\b_card\b' = 'context.fitlek.card'
    '\b_border\b' = 'context.fitlek.border'
    '\b_textPrimary\b' = 'Theme.of(context).colorScheme.onSurface'
    '\b_textSecondary\b' = 'context.fitlek.textSecondary'
    '\b_textMuted\b' = 'context.fitlek.textMuted'
    '\b_muted\b' = 'context.fitlek.textMuted'
    '\b_white\b' = 'Theme.of(context).colorScheme.onPrimary'
    '\b_success\b' = 'context.fitlek.success'
    '\b_errorRed\b' = 'context.fitlek.error'
    '\b_error\b' = 'context.fitlek.error'
    '\b_dark\b' = 'Theme.of(context).scaffoldBackgroundColor'
    'backgroundColor:\s*Colors\.black' = 'backgroundColor: Theme.of(context).scaffoldBackgroundColor'
    'CircularProgressIndicator\(color:\s*Color\(0xFFC6F135\)\)' = 'CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)'
    'CircularProgressIndicator\(color:\s*Color\(0xFFA3FF12\)\)' = 'CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)'
}

function Get-ImportPath($file) {
    $rel = $file.FullName.Substring($root.Length + 1)
    $depth = ($rel -split '\\').Count - 1
    return ('../' * $depth) + 'theme/fitlek_theme_extension.dart'
}

$changed = @()
Get-ChildItem -Path $root -Recurse -Filter *.dart | ForEach-Object {
    if ($skip -contains $_.Name) { return }
    $text = [IO.File]::ReadAllText($_.FullName)
    if ($text -notmatch 'const _lime|Color\(0xFFC6F135\)|Color\(0xFFA3FF12\)|const _dark|Colors\.black|class FitlekColors \{') { return }

    $original = $text
    foreach ($pat in $colorConstPatterns) {
        $text = [regex]::Replace($text, $pat, '')
    }

    if ($text -notmatch 'fitlek_theme_extension\.dart') {
        $imp = "import '$((Get-ImportPath $_))';`n"
        if ($text -match '(?ms)^(import .+?;\s*)+') {
            $text = [regex]::Replace($text, '(?ms)(^(?:import .+?;\s*)+)', "`$0$imp", 1)
        } else {
            $text = $imp + $text
        }
    }

    foreach ($key in $replacements.Keys) {
        $text = [regex]::Replace($text, $key, $replacements[$key])
    }

    if ($_.Name -eq 'coachProfile.dart' -and $text -match 'class FitlekColors \{') {
        $text = [regex]::Replace($text, '(?ms)class FitlekColors \{.*?\}\r?\n\r?\n', '')
        $text = $text.Replace('FitlekColors.', 'context.fitlek.')
        $text = $text.Replace('context.fitlek.bg', 'Theme.of(context).scaffoldBackgroundColor')
        $text = $text.Replace('context.fitlek.lime', 'Theme.of(context).colorScheme.primary')
        $text = $text.Replace('context.fitlek.limeDim', 'context.fitlek.primaryDim')
        $text = $text.Replace('context.fitlek.textPrimary', 'Theme.of(context).colorScheme.onSurface')
    }

    if ($text -ne $original) {
        [IO.File]::WriteAllText($_.FullName, $text)
        $changed += $_.FullName.Substring($root.Length + 4)
    }
}

Write-Output "Migrated $($changed.Count) files"
$changed | ForEach-Object { Write-Output "  - $_" }
