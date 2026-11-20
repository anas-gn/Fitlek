$ErrorActionPreference='Stop'
$dir='lib/l10n'
foreach($loc in 'en','fr'){
  $out=[ordered]@{}
  $base=Get-Content "$dir/base_$loc.json" -Raw -Encoding UTF8 | ConvertFrom-Json
  $base.PSObject.Properties | % { $out[$_.Name]=$_.Value }
  Get-ChildItem "$dir/parts/*.$loc.json" | sort Name | % {
    $j=Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $j.PSObject.Properties | % { if($out.Contains($_.Name) -and $_.Name -notlike '@@*'){ Write-Warning "dup $($_.Name) in $($_.Name)" } ; $out[$_.Name]=$_.Value }
  }
  $json=$out | ConvertTo-Json -Depth 20
  [IO.File]::WriteAllText((Resolve-Path $dir).Path+"/app_$loc.arb",$json,(New-Object Text.UTF8Encoding $false))
}
flutter gen-l10n
