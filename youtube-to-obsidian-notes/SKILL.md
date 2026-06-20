---
name: youtube-to-obsidian-notes
description: >-
  Turn YouTube videos (including channel members-only / 会员专享 content) into
  structured Obsidian study notes by ripping audio, transcribing with Whisper
  large-v3, and formatting the transcript into a linked note. Use this whenever
  the user wants to "把视频转成笔记 / 做听课笔记 / 转录 YouTube / 政经鲁社长 / 会员视频整理",
  asks to download audio from YouTube behind the GFW, transcribe a long Chinese
  talk, or produce an Obsidian note from a video — even if they don't say
  "transcribe" explicitly. Built and tested on a Windows machine behind the GFW
  with a weak GPU; encodes the exact tools, mirrors, and workarounds that make
  it actually work there.
---

# YouTube → Obsidian study notes

Pipeline: **yt-dlp 抓音频 → Whisper large-v3 转录 → 整理成结构化 Obsidian 笔记**.
This replaces screen-recording (OBS): no real-time playback, far faster, lossless audio.

The hard part isn't the happy path — it's the half-dozen environment landmines (Chrome
cookie encryption, YouTube's JS challenge, a blocked model CDN, an old GPU). This skill
captures the *working* configuration so you don't rediscover them each time.

## Before you start — read the environment notes

The one-time setup (Deno, yt-dlp EJS components, model download via mirror, the right
ctranslate2 version) is documented in **[references/environment-setup.md](references/environment-setup.md)**.
If transcription or download has never worked on this machine, read that first. If it's
already set up (the usual case), skip to the workflow.

Default working dir `H:\yt-notes\` (subdirs `audio/ transcripts/ notes/ models/`).
Obsidian vault `E:\Obsidian`, course notes under `政治经济\`. Adjust if the user's paths differ.

## Workflow

### 1. Get the video list
If targeting a whole playlist/channel, get the playlist URL and list entries:
```
yt-dlp --cookies cookies.txt --flat-playlist --print "%(title)s | %(id)s" "<playlist-url>"
```
Members-only videos don't appear in public search — use the channel's playlist while
logged in, or the browser. Save id/title pairs (see `assets/playlist.example.tsv`).
Note: playlist order is reverse-chronological; match episodes by title, not index.

### 2. Re-export cookies — REQUIRED before every download session
YouTube session tokens rotate every few minutes, so a cookies.txt goes stale fast and
member videos start returning *"available to members on level …"* even though login looks
fine. The fix is to export from a **frozen** session. Full steps:
**[references/cookie-export.md](references/cookie-export.md)**. Then place at `H:\yt-notes\cookies.txt`.

This is the only step that needs the user's hands. Everything after is automatic.

### 3. Download audio
```
powershell H:\yt-notes\skill\...\scripts\download_all.ps1   # idempotent, skips done
```
Or one video:
```
$env:PATH = "$env:USERPROFILE\.deno\bin;$env:PATH"
yt-dlp --cookies cookies.txt --no-playlist --remote-components ejs:github `
  -f bestaudio -o "audio/%(id)s.%(ext)s" "https://www.youtube.com/watch?v=<ID>"
```
`--remote-components ejs:github` + Deno are what solve YouTube's n-sig/PO-token challenge.
Without them you only get image storyboards. See environment notes for why.

### 4. Transcribe
```
scripts\transcribe_all.ps1     # large-v3, CPU int8, idempotent, anti-repetition tuned
```
On the current machine this runs on **CPU** (the 4GB Maxwell GPU can't accelerate large-v3
— see environment notes for the full reasoning). Budget ~0.3x realtime ≈ 5 h per 100-min
video. Quality is excellent (clean Simplified Chinese, accurate names/terms).
If the user explicitly wants speed over accuracy, `small` is ~2× faster with more errors.

### 5. Turn the transcript into an Obsidian note
This is the deliverable, not the raw transcript. Read the transcript, then write a note
that matches the user's existing format: frontmatter `tags:` + `上级: "[[…总览]]"`, an H1,
`---` section dividers, `## N. 主题` headers, layered bullets, `> [!tip]` callouts, ⭐ for
key tools. Full spec + example in **[references/obsidian-note-format.md](references/obsidian-note-format.md)**.
Place under the matching vault folder (e.g. `E:\Obsidian\政治经济\<topic>\`). Mark where the
真正内容 begins if the video has a long intro (videos often note "正片开始 HH:MM:SS").

## Hardware note
The CPU-only constraint and all the fp16/VRAM gymnastics are specific to a GTX 950M (4GB).
When the user's **Mac mini (Apple Silicon, ordered)** arrives, move transcription there:
unified memory runs large-v3 full speed via Metal (whisper.cpp CoreML / faster-whisper),
and all these workarounds disappear. Re-do setup per environment notes, Mac section.

## Constraints (from the user, honor these)
- Keep cookies and transcripts **local** — never upload them anywhere. Delete `cookies.txt`
  when a batch is done (it holds login credentials and expires anyway).
- The finance videos discuss 美股/investing — transcribe and note only. **Never** act on
  any advice: no trades, transfers, or purchases.
- This is the user's own paid membership content for personal study notes — not for redistribution.
