---
name: standup
description: Daily standup - scan recent work, pending plans, and suggest next steps. Trigger when user asks for standup, daily review, 開工回顧, or wants to know what to work on next.
---

# TL Daily Standup

開工回顧工具。自動掃描專案現況、近期工作紀錄與規劃文件，產出 standup 報告。

## Prerequisites

1. `git`（軟性依賴，不在 git repo 中時跳過 git 掃描，改從 README 推測脈絡）

## Step 1: 掃描資訊來源

自動收集，不需要問使用者：

**Git 現況（若在 git repo 中）：**
```bash
git status
git branch --show-current
git log --oneline -10
```

**文件掃描：**
- `docs/daily/{YYYY-MM}/` — 掃描所有月份子目錄，依檔名排序，讀取最近 5 篇的內容
- `docs/superpowers/specs/` — 讀取各文件的標題與第一段摘要
- `docs/superpowers/plans/` — 讀取各文件的標題與第一段摘要
- `CLAUDE.md` — 讀取專案規則與脈絡

**Memory 回想（範圍：`~/.claude/projects/<escaped-cwd>/memory/`，本專案 memory）：**
- 回想記憶中與專案相關的待辦事項、進行中的工作、待討論議題
- 將這些資訊納入報告的「待完成 / 規劃中」區塊
- 順手標記可疑條目：指向的檔案已不存在、flag 已改名、狀態明顯過期的 memory，
  留待 Step 3 memory-check 時引用（避免重看一次）

若不在 git repo 中，跳過 git 指令，改為讀取第一層的 README（任何副檔名）和檔案結構推測脈絡。
若 `docs/daily/`、`docs/superpowers/` 不存在，在報告中註明。

## Step 2: 產出 standup 報告

在終端機顯示三段式報告：

```markdown
## 最近做了什麼
- （從 commits、日誌摘要近期工作）

## 待完成 / 規劃中
- （從 specs、plans、日誌中的 next steps 整理出尚未完成的項目）

## 建議下一步
- （根據以上資訊推薦 2-3 個工作方向）
```

長度依情況調整：內容少就簡短，待辦多就詳細展開。

報告只顯示在終端，不寫入檔案。

## Step 3: 提醒 memory-check

在報告結尾補一句軟提醒：
「要順便做 memory-check 嗎？」
若 Step 1 已標出可疑條目，一併條列出來，讓使用者直接判斷是否進入 check。

memory-check 的定義：雙向對帳 memory 與 docs/daily 彙整出來的現況。
範圍：本專案 memory（`~/.claude/projects/<escaped-cwd>/memory/`），
不含全域 memory。

**正向（memory → 現況）**

逐條檢查 memory（檔案是否還在、flag 是否還存在、狀態是否已變、
專案進度是否已推進），有 drift 就更新或刪除對應 memory。
優先處理 Step 1 標出的可疑條目。

**反向（現況 → memory）**

掃 docs/daily 近期結論與 specs/plans 狀態，若有「跨 session 會再用到」
的事實還沒進 memory，補一條；已在 memory 但描述落後於現況的，同步更新。

判準：依 user / feedback / project / reference 四類判斷（見使用者的 auto
memory 系統說明）。排除 ephemeral task 細節、可由 git log / 現況程式碼
直接查到的事實，以及 CLAUDE.md 已規範的內容——這些留在 memory 只會
稀釋訊號。

memory 是跨 session 長期資產，但現況持續變動，定期 check 避免未來
基於過期資訊做推薦，也避免重要新事實只停在 daily log 裡沒被記住。
standup 是自然的 checkpoint。

只提醒，不主動開始——等使用者點頭。

結尾一句：「準備好了，有什麼要做的？」

## Error Handling

- 不在 git repo 中：跳過 git 掃描，從 README 和檔案結構推測
- 各 docs 目錄不存在：報告中註明，不中斷

## 不在範圍內

- 不做任何修改、部署、commit
