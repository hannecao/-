# Obsidian note format

The deliverable is a **structured study note**, not the raw transcript. Match the user's
existing course-note style (observed in `E:\Obsidian\政治经济\社会关系开拓和维护\`).

## Frontmatter + structure
```markdown
---
tags: [听课笔记, <主题词>, <主题词>]
上级: "[[<专题> · 总览]]"
---

# <序号/标题，如 ① 九大方法（社长主讲）>

<一段引言：用一两句话点出这节的主旨和定义。>

---

## 1. <小节主题> —— <一句话副标题>

<提炼后的要点，不是逐字稿。>

- **关键词**：解释。
  - 次级要点；
  - 次级要点。
- **另一个关键词**：解释。

> [!tip] 核心
> 这一节最该记住的一句话。

---

## 2. <下一节> …
```

## Principles
- **Rewrite, don't dump.** Compress the transcript into layered bullets and short
  paragraphs. Cut filler ("嗯""那个""掌声"), keep the substance, structure, and the
  speaker's actual framework/terms.
- Use `## N. 主题` numbered sections following the talk's flow.
- Bold the **key terms / 关键词**; nest sub-points with indentation.
- `> [!tip] 核心` callouts for the one-line takeaway of a section; `> [!warning]` / `> [!note]`
  where useful.
- ⭐ to flag the single most important tool/framework in the note.
- Keep everything **Simplified Chinese**, consistent with the source.
- Fix obvious transcription errors of names/terms from context (e.g. 巴菲特, 比尔·阿克曼,
  标普500, 价值投资) — these matter for searchable notes.

## Placement & linking
- Put the note in the matching vault folder, e.g. a new `<topic>\` under `政治经济\`,
  parallel to existing topic folders.
- If a topic has multiple episodes, create a `<专题> · 总览.md` MOC that links each episode
  note, and point each note's `上级:` at it (mirror the 社会关系 folder's pattern).
- If the video has a long intro, note where 正片 begins (videos often say "正片开始 HH:MM:SS").
