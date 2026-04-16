---
name: md2clip
description: Convert markdown to rich text on the macOS clipboard, formatted so Notion interprets it as proper blocks (headings, lists, tables) instead of a code block or flat text. Trigger when user wants to copy markdown to clipboard for Notion, or asks to paste markdown into Notion with proper formatting.
---

# TL Util md2clip

將 markdown 轉成 Notion 可正確解析的 rich text 並放到剪貼簿。貼上後 H1/H2/list/table 都會變成對應的 Notion block。

**Asset 位置**（與本 SKILL.md 同目錄下的 `assets/`）：
- `assets/md2clip.py`

---

## 使用

確認 `uv` 可用，然後直接從 asset 執行：

```bash
which uv || echo "uv not found — install: brew install uv"
```

執行轉換（`<skill-base-dir>` 是本 SKILL.md 所在目錄）：

```bash
cat <file.md> | uv run --script <skill-base-dir>/assets/md2clip.py
```

或傳入字串：

```bash
printf "# Title\n\n內文\n" | uv run --script <skill-base-dir>/assets/md2clip.py
```

預期：stderr 印出 `Copied (N chars md → N chars html)`，exit code 0。複製後直接貼到 Notion。

---

## 技術說明（供日後維護參考）

Notion 的 HTML paste 只有在剪貼簿包含 Chromium 來源 type（`org.chromium.source-url`）時才會把 HTML element 轉成 Notion block。少了這個 type，Notion 把整段 HTML 當作 rich text string，heading 退化成 bold，table 壓成一行。

md2clip 在剪貼簿同時放四個 type：
- `public.html` — 轉換後的 HTML
- `public.utf8-plain-text` — 原始 markdown（純文字 fallback）
- `org.chromium.source-url` — 讓 Notion 進入 block 轉換模式
- `org.chromium.internal.source-rfh-token` — Chromium 附帶的 token（值不重要）
