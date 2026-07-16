$ErrorActionPreference = 'Stop'
$project = 'C:\Users\kisha\OneDrive\Desktop\projects\lightfan controler'
$sdkDir = Join-Path $project '.flutter'

Write-Host "Fetching Flutter release manifest..."
$json = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json' -UseBasicParsing
$stable = $json.releases | Where-Object { $_.channel -eq 'stable' } | Select-Object -First 1
$base = $json.base_url.TrimEnd('/')
$url = "$base/$($stable.archive)"
$zip = Join-Path $project 'flutter.zip'

Write-Host "Downloading Flutter $($stable.version) from $url"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

Write-Host "Extracting to $sdkDir ..."
Expand-Archive -Path $zip -DestinationPath $sdkDir -Force
Remove-Item $zip

Write-Host "Flutter extracted. Version:"
& "$sdkDir\flutter\bin\flutter.bat" --version
Write-Host "DONE_INSTALL"
