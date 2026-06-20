# Re-exporting YouTube cookies (required before each download session)

## Why
YouTube's session tokens (`__Secure-3PSIDTS` etc.) **rotate every few minutes**. If you
export cookies while your normal Chrome keeps using the account, the export is invalidated
almost immediately and member videos start failing with *"This video is available to this
channel's members on level: 核心会员"* — even though you ARE a member. The first download may
succeed (token still fresh), then everything fails. The cure is to freeze a session.

Also note: Chrome 127+ uses **App-Bound Encryption**, so `yt-dlp --cookies-from-browser
chrome` fails with `Failed to decrypt with DPAPI`. You must export to a cookies.txt file
with an extension instead.

## Steps (frozen incognito session)
1. Install the **Get cookies.txt LOCALLY** extension (open-source, local-only).
2. Chrome → **Ctrl+Shift+N** for an Incognito window. (Enable the extension in incognito
   first: `chrome://extensions` → that extension → "Allow in Incognito".)
3. In incognito, open `https://www.youtube.com`, **log in** to the member account, and open
   one member video to confirm it plays.
4. Click the extension → **Export** → saves `www.youtube.com_cookies.txt` (usually to
   `Downloads`).
5. Copy it to `H:\yt-notes\cookies.txt`.
6. **Close the incognito window immediately** and don't touch it again — this freezes the
   session so the tokens stop rotating.

The exported file holds login credentials — keep it local, and delete it when the batch is done.

## Verifying it works
```
$env:PATH = "$env:USERPROFILE\.deno\bin;$env:PATH"
yt-dlp --cookies H:\yt-notes\cookies.txt --no-playlist --remote-components ejs:github `
  -F "https://www.youtube.com/watch?v=<member-video-id>"
```
If you see audio formats listed → good. If "available to members on level …" → the cookie
went stale; re-export with the frozen-incognito method above.
