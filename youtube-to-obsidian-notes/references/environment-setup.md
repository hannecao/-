# Environment setup & gotchas (one-time)

Everything here was learned the hard way getting this to work on a Windows 10 machine
behind the GFW with a GTX 950M (4 GB). If you're on a fresh machine, replicate this.

## Tooling already present (verify with `Get-Command`)
- `yt-dlp` (keep recent), `ffmpeg`/`ffprobe`, Python 3.11
- `whisper` (openai-whisper) and `whisper-ctranslate2` (faster-whisper CLI)
- A Clash-style proxy at `127.0.0.1:7897` (http_proxy/https_proxy + WinINET). curl and
  yt-dlp use it automatically; it's what lets large downloads cross the GFW.

## 1. Deno + yt-dlp EJS components (for YouTube downloads)
YouTube now requires solving a JS "n-sig" challenge and a PO token. yt-dlp delegates this
to a JS runtime. Node is **not** enough — it needs **Deno**.
- Install Deno (no admin needed). The official `irm …install.ps1` script failed here
  because of an incompatible bundled curl flag; instead download the zip directly:
  ```
  Invoke-WebRequest https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip -OutFile $env:TEMP\deno.zip
  Expand-Archive $env:TEMP\deno.zip $env:USERPROFILE\.deno\bin -Force
  ```
- Put `%USERPROFILE%\.deno\bin` on PATH before running yt-dlp.
- Pass `--remote-components ejs:github` so yt-dlp fetches its official EJS solver scripts
  and runs them under Deno. **This needs the user's OK** (it executes external JS) — Claude
  Code's auto classifier blocks it until authorized. Without it you only get image
  storyboards ("Only images are available").

## 2. Whisper model download — HuggingFace LFS is blocked, use a mirror
`cdn-lfs.huggingface.co` (where the big `model.bin` lives) is blocked by the GFW; small
files come through but the 3 GB model stalls. `python huggingface_hub` did not honor the
proxy reliably. What works: download model files directly from **hf-mirror.com** with curl
(which uses the system proxy), into a local folder, then point Whisper at that folder.
```
$base="https://hf-mirror.com/Systran/faster-whisper-large-v3/resolve/main"
foreach($f in "config.json","preprocessor_config.json","tokenizer.json","vocabulary.json","model.bin"){
  curl.exe -sL "$base/$f" -o "H:\yt-notes\models\faster-whisper-large-v3\$f" }
```
Watch for 0-byte small files (transient 308→huggingface.co redirect) — just re-fetch them.
Then use `whisper-ctranslate2 --model_directory <folder>` (NOT `--model`, which only takes
built-in names). `modelscope.cn` is another reachable mirror if hf-mirror is down.

## 3. ctranslate2 version must match the GPU driver / CUDA
`pip install whisper-ctranslate2` pulls **ctranslate2 4.x (CUDA 12)**. The 950M's driver
(511.79 / CUDA 11.6) is too old → `CUDA driver version is insufficient`. Pin the CUDA-11
build instead, without disturbing av/faster-whisper:
```
pip install --no-deps "ctranslate2==3.24.0"
```
ctranslate2 3.24 needs cuDNN 8; torch already ships it — add `…\site-packages\torch\lib`
to PATH so it's found.

## 4. This GPU can't run large-v3 — use CPU
Even with the CUDA-11 ctranslate2, the GTX 950M (Maxwell, CC 5.0) **refuses int8 and
float16** ("does not support efficient … computation"), and large-v3 in float32 needs ~6 GB
(card has 4, and Windows WDDM only exposes ~3.2 GB to one process) → OOM. So:
- **faster-whisper large-v3 runs on CPU** (`--device cpu --compute_type int8 --threads 8`).
  ~0.3× realtime. Best quality. This is the recommended default.
- openai-whisper `medium` *can* run on the GPU only if you load it fp16 (load on CPU,
  `.half()`, set every `nn.LayerNorm` back to `.float()` — whisper's LayerNorm wants fp32 —
  then `.to("cuda")`; see `scripts/transcribe_ow.py`). But on the 950M it's **no faster than
  large-v3 on CPU and lower quality**, so don't bother on this machine.

## 5. Whisper flags that matter
- `--condition_on_previous_text False` — kills the repetition/looping hallucination at
  segment boundaries (otherwise you get the same sentence 3× near the end of long talks).
- `--vad_filter True` — skips silence/applause, saves time and avoids silence hallucinations.
- `--initial_prompt "…"` in **Simplified Chinese** with the speaker/topic — biases toward
  简体 (prevents drifting into traditional characters) and correct domain terms/names.

## Keeping the machine awake during long runs
A 5 h CPU job can be interrupted by display sleep. Hold the system awake from the same
process with `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED)` (see the launch
snippet in the transcribe scripts) — it auto-clears when the process exits, no settings change.

## Mac mini (Apple Silicon) — future
When it arrives, transcription moves there and all of §3/§4 vanish. Install
`pip install faster-whisper` (CTranslate2 has Apple-Silicon support) or build whisper.cpp
with Metal/CoreML; run large-v3 directly. Unified memory easily holds large-v3.
