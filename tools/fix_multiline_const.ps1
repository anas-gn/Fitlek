$root = "C:\Users\hp\Desktop\Fitlek\lib"

function Remove-ConstBeforeThemeBlocks($text) {
    $widgets = @('Text','Icon','Container','BoxDecoration','Padding','Row','Column','Center','Expanded','ListTile','SnackBar','Divider','CircularProgressIndicator','Scaffold','DecoratedBox','AnimatedContainer','GestureDetector','ListView','SingleChildScrollView','RefreshIndicator','InputDecoration','OutlineInputBorder','RoundedRectangleBorder','LinearGradient','RadialGradient','Align','Wrap','Stack','Positioned','SizedBox','Card','Material','InkWell','Opacity','FadeTransition','SlideTransition','RichText','TextSpan','Checkbox','Switch','Radio','Chip','FilterChip','ActionChip','ElevatedButton','OutlinedButton','TextButton','FloatingActionButton','AppBar','SliverToBoxAdapter','SliverList','SliverGrid','Tab','TabBar','TabBarView','DefaultTextStyle','Theme','Builder')
    foreach ($w in $widgets) {
        $pattern = "const\s+($w)\("
        $matches = [regex]::Matches($text, $pattern)
        for ($i = $matches.Count - 1; $i -ge 0; $i--) {
            $m = $matches[$i]
            $start = $m.Index
            $snippet = $text.Substring($start, [Math]::Min(1200, $text.Length - $start))
            if ($snippet -match 'Theme\.of\(context\)|context\.fitlek') {
                $text = $text.Remove($start, 6) # remove 'const '
            }
        }
    }
    return $text
}

# Fix helper methods missing context
$fixes = @{
    'lib\screens\ENG\clientBooking.dart' = @{
        'Widget _infoRow(IconData icon, String label, String value,' = 'Widget _infoRow(BuildContext context, IconData icon, String label, String value,'
        '_infoRow(Icons.' = '_infoRow(context, Icons.'
    }
}

Get-ChildItem -Path $root -Recurse -Filter *.dart | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $original = $text
    $text = Remove-ConstBeforeThemeBlocks $text
    if ($text -ne $original) {
        [IO.File]::WriteAllText($_.FullName, $text)
        Write-Output "Unconst: $($_.Name)"
    }
}
