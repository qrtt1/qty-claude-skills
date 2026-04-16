---
name: md2clip
description: Deploy md2clip — a CLI tool that converts markdown (stdin) to rich text on the macOS clipboard, formatted so Notion interprets it as proper blocks (headings, lists, tables) instead of a code block or flat text. Trigger when user wants to set up md2clip, install the markdown-to-clipboard tool, or asks how to paste markdown into Notion with proper formatting.
---

# TL Util md2clip Setup

部署 `md2clip` 到 `~/bin/md2clip`。

用途：將 markdown 轉成 Notion 可正確解析的 rich text，貼上後 H1/H2/list/table 都會變成對應的 Notion block，不會退化成 code block 或純文字。

**Asset 位置**（與本 SKILL.md 同目錄下的 `assets/`）：
- `assets/md2clip`

---

## Phase 0: Pre-check

確認 `~/bin/` 存在且在 PATH 中：

```bash
ls ~/bin/ 2>/dev/null || echo "~/bin not found"
echo $PATH | tr ':' '\n' | grep -q "$HOME/bin" && echo "in PATH" || echo "NOT in PATH"
```

- `~/bin/` 不存在 → 建立並提醒使用者將 `$HOME/bin` 加入 PATH
- 不在 PATH → 提醒使用者在 shell 設定檔加入 `export PATH="$HOME/bin:$PATH"`

確認 `uv` 可用：

```bash
which uv && uv --version
```

`uv` 不可用 → 列出安裝建議（`brew install uv` 或 `curl -LsSf https://astral.sh/uv/install.sh | sh`），結束。

---

## Phase 1: 部署 md2clip

比對現有版本與 asset：

```bash
diff ~/bin/md2clip <skill-assets>/md2clip && echo "NO_DIFF" || echo "HAS_DIFF"
```

- 無差異 → 印「md2clip 已是最新版，跳過」
- 有差異或不存在 → 備份後部署：

```bash
[ -f ~/bin/md2clip ] && cp ~/bin/md2clip ~/bin/md2clip.bak
cp <skill-assets>/md2clip ~/bin/md2clip
chmod +x ~/bin/md2clip
```

---

## Phase 2: Verify

```bash
diff ~/bin/md2clip <skill-assets>/md2clip && echo "OK"
[ -x ~/bin/md2clip ] && echo "executable OK"
```

冒煙測試（確認能執行、依賴自動安裝）：

```bash
printf "# Hello\n\n- a\n- b\n" | ~/bin/md2clip
```

預期：stderr 印出 `Copied (N chars md → N chars html)`，exit code 0。

---

## 使用方式

```bash
cat file.md | md2clip          # 轉整份檔案
printf "# Title\n\n內文\n" | md2clip  # 轉字串
```

複製後直接貼到 Notion，H1/H2/list/table 會自動轉成對應的 Notion block。

---

## 技術說明（供日後維護參考）

Notion 的 HTML paste 只有在剪貼簿包含 Chromium 來源 type（`org.chromium.source-url`）時才會把 HTML element 轉成 Notion block。少了這個 type，Notion 把整段 HTML 當作 rich text string，heading 退化成 bold，table 壓成一行。

md2clip 在剪貼簿同時放四個 type：
- `public.html` — 轉換後的 HTML
- `public.utf8-plain-text` — 原始 markdown（純文字 fallback）
- `org.chromium.source-url` — 讓 Notion 進入 block 轉換模式
- `org.chromium.internal.source-rfh-token` — Chromium 附帶的 token（值不重要）
