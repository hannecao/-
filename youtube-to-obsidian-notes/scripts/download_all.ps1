# Batch download audio for all 11 videos (idempotent: skips already-downloaded)
$ErrorActionPreference = 'Continue'
$env:PATH = (Join-Path $env:USERPROFILE ".deno\bin") + ";" + $env:PATH
$root = "H:\yt-notes"
$cookies = "$root\cookies.txt"
$audioDir = "$root\audio"

# ordered list: id, label (for logging)
$videos = @(
    @{id="etrf9iTQ9FM"; name="06-美股投资策略"},
    @{id="gsQmoXbF4hs"; name="05-石头贷款400亿"},
    @{id="-oWVzjpjklw"; name="07-政治力学牛鲁三定律"},
    @{id="qhMZ8_nzizs"; name="04-美股框架策略二"},
    @{id="6qyUlohNtdg"; name="03-美股框架策略上"},
    @{id="ViFeFrH1j90"; name="10-社会关系开拓维护2"},
    @{id="bFLvb0j-rwk"; name="11-如何拓展社会关系"},
    @{id="Zoum-Ev3SJg"; name="中南海的湖北佬"},
    @{id="HY2a3o9CVZQ"; name="AI产业链相关企业分析"},
    @{id="PwP1Z8b4oe8"; name="王岐山和三家证券公司"},
    @{id="ps8ZcRGOu_0"; name="AI产业链代表企业下"}
)

foreach ($v in $videos) {
    $existing = Get-ChildItem "$audioDir\$($v.id).*" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -ne '.part' }
    if ($existing) {
        Write-Host "[SKIP] $($v.id) $($v.name) already downloaded"
        continue
    }
    Write-Host "[DL]   $($v.id) $($v.name) ..."
    yt-dlp --cookies $cookies --no-playlist --remote-components ejs:github `
        -f bestaudio --no-progress `
        -o "$audioDir/%(id)s.%(ext)s" `
        "https://www.youtube.com/watch?v=$($v.id)" 2>&1 |
        Where-Object { $_ -match 'ERROR|Destination|has already|Downloading webpage' } | Select-Object -Last 3
    Write-Host "[DONE] $($v.id)"
}
Write-Host "==== ALL DOWNLOADS COMPLETE ===="
Get-ChildItem $audioDir -File | Where-Object { $_.Extension -in '.webm','.m4a','.opus','.mp3' } |
    ForEach-Object { "{0}  {1} MB" -f $_.Name, [math]::Round($_.Length/1MB,1) }
