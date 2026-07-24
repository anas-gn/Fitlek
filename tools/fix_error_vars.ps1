$root = "C:\Users\hp\Desktop\Fitlek\lib"

Get-ChildItem -Path $root -Recurse -Filter *.dart | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $original = $text

    # Fix invalid const Theme.of(context)
    $text = $text -replace 'const\s+Theme\.of\(context\)', 'Theme.of(context)'

    # Fix _error state variable wrongly replaced (not color usages)
    $text = $text -replace 'String\?\s+context\.fitlek\.error', 'String? _error'
    $text = $text -replace 'context\.fitlek\.error\s*=', '_error ='
    $text = $text -replace 'context\.fitlek\.error\s*!=', '_error !='
    $text = $text -replace 'context\.fitlek\.error\s*==', '_error =='
    $text = $text -replace 'context\.fitlek\.error!', '_error!'
    $text = $text -replace 'Text\(_error!', 'Text(_error!'  # no-op safety
    $text = $text -replace 'Text\(context\.fitlek\.error', 'Text(_error'
    $text = $text -replace 'context\.fitlek\.error \?\?', '_error ??'
    $text = $text -replace 'if \(context\.fitlek\.error != null\)', 'if (_error != null)'
    $text = $text -replace 'if \(!_loading && _error == null\)', 'if (!_loading && _error == null)'
    $text = $text -replace 'if \(context\.fitlek\.error != null\)', 'if (_error != null)'

    if ($text -ne $original) {
        [IO.File]::WriteAllText($_.FullName, $text)
        Write-Output "Fixed: $($_.Name)"
    }
}
