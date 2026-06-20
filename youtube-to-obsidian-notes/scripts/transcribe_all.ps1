# Batch transcribe all downloaded audio with local large-v3 (int8) on GPU.
# Idempotent: skips audio whose transcript already exists.
$ErrorActionPreference = 'Continue'
$root      = "H:\yt-notes"
$audioDir  = "$root\audio"
$outDir    = "$root\transcripts"
$model     = "$root\models\faster-whisper-large-v3"
$device    = "cpu"             # GPU(950M) driver too old for ctranslate2 CUDA -> use CPU
$compute   = "int8"
$prompt    = "以下是政经鲁社长的简体中文内部分享，内容涉及美股投资、政治经济与社会关系。"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$audios = Get-ChildItem $audioDir -File | Where-Object { $_.Extension -in '.webm','.m4a','.opus','.mp3' } | Sort-Object Name
foreach ($a in $audios) {
    $id  = $a.BaseName
    $txt = Join-Path $outDir "$id.txt"
    if (Test-Path $txt) { Write-Host "[SKIP] $id (transcript exists)"; continue }
    Write-Host "[TRANSCRIBE] $id  ($([math]::Round($a.Length/1MB,0)) MB) ..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    whisper-ctranslate2 $a.FullName `
        --model_directory $model --language zh --device $device --compute_type $compute --threads 8 `
        --output_dir $outDir --output_format all `
        --initial_prompt $prompt --vad_filter True --condition_on_previous_text False
    $sw.Stop()
    Write-Host ("[DONE] {0} in {1} min" -f $id, [math]::Round($sw.Elapsed.TotalMinutes,1))
}
Write-Host "==== ALL TRANSCRIPTIONS COMPLETE ===="
