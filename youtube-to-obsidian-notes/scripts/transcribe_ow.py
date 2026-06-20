import sys, time, whisper, torch

audio   = sys.argv[1]
out_txt = sys.argv[2]
model_name = sys.argv[3] if len(sys.argv) > 3 else "medium"

t0 = time.time()
# Load on CPU, convert to fp16, THEN move to GPU so only ~1.5GB ever hits VRAM
# (Windows WDDM limits this 4GB card to ~3.2GB usable; fp32 load would OOM).
model = whisper.load_model(model_name, device="cpu")
model = model.half()
# whisper's LayerNorm computes in fp32 by design; keep those params fp32 to avoid dtype clash
for m in model.modules():
    if isinstance(m, torch.nn.LayerNorm):
        m.float()
model = model.to("cuda")
print("MODEL_LOADED", model_name, round(time.time()-t0,1), "s", flush=True)

t1 = time.time()
r = model.transcribe(
    audio, language="zh", fp16=True, verbose=False,
    condition_on_previous_text=False,
    initial_prompt="以下是政经鲁社长的简体中文内部分享，内容涉及美股投资、巴菲特、价值投资、政治经济。",
)
with open(out_txt, "w", encoding="utf-8") as f:
    for seg in r["segments"]:
        f.write(seg["text"].strip() + "\n")
print("TRANSCRIBE_DONE", round(time.time()-t1,1), "s for audio", flush=True)
