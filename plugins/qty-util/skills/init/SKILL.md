---
name: init
description: Initialize a new project with git, venv, .gitignore, and CLAUDE.md. Trigger when user says "init", "初始化專案", or asks to set up a new project from scratch with standard structure.
---

# TL Util Init

通用的專案初始化工具。處理新專案開始時的重複性設定：git repo、Python venv、.gitignore、CLAUDE.md 與日記機制。

## Prerequisites

1. `git` installed（硬性依賴，未安裝則中止）
2. `python3`（軟性依賴，未安裝則跳過 venv 建立）

## Step 1: 檢查 Git repo

執行 `git rev-parse --git-dir` 確認當前目錄與 git repo 的關係：

- 不在任何 git repo 中 → `git init`
- 已在 git repo 中，且 `.git` 就在當前目錄 → 告知使用者，跳過
- 已在 git repo 中，但 `.git` 在上層目錄（當前目錄是某個 git repo 的子目錄）→ 明確告知使用者目前位於哪個 repo 的子目錄下，詢問是否要在當前目錄建立獨立的 git repo
  - 使用者回答「否」→ 跳過，繼續 Step 2

## Step 2: 建立 Python venv

- 檢查 `venv/` 是否已存在
- 已存在 → 告知使用者，跳過
- 不存在 → `python3 -m venv venv`

## Step 3: 產生 .gitignore

偵測目前環境，根據線索組合 `.gitignore` 內容：

| 線索 | 加入的規則 |
|------|-----------|
| venv 存在 | `venv/`、`__pycache__/`、`*.pyc`、`.Python`、`*.egg-info/`、`dist/`、`build/` |
| `package.json` 存在 | `node_modules/`、`.npm`、`.next/`、`dist/` |
| `go.mod` 存在 | `vendor/` |
| 一律包含 | `.env`、`.DS_Store`、`*.log`、`.claude/settings.local.json` |

可根據其他偵測到的線索追加對應規則。

若 `.gitignore` 已存在：
- 顯示將新增的項目（排除已存在的行）
- 問使用者要覆蓋還是合併
- 合併 = 將新項目 append 到檔案尾端，去除重複行

若不存在：直接建立。

## Step 4: 詢問專案目標，產生 CLAUDE.md

問使用者：「這個專案的目標是什麼？有沒有特別的原則或限制？」

等使用者回答後，根據回答產生 CLAUDE.md。固定包含以下區段：

### 4a: 專案說明

根據使用者描述的目標撰寫。

### 4b: 重要規則

```markdown
## 重要規則

### 簡單方案優先
有多種實作方式時，選最簡單、moving parts 最少的方案。不確定使用者想要哪種做法時，先用 2 句話描述方案再動手，不要直接蓋複雜版本。

### CLI 指令驗證
執行不熟悉或本次對話中沒用過的 CLI flag 前，先跑 `<command> --help` 確認該 flag 存在。不要憑記憶猜測 flag 名稱。

### 只查不改原則
沒有明確指示時，只能進行查詢動作，不做任何變更或刪除行為。
- 查詢部署狀態、設定：✓ 允許
- 分析與記錄：✓ 允許
- 修改 workflow、scripts：✗ 需明確指示
- 刪除檔案或設定：✗ 需明確指示
```

### 4c: 工作環境

```markdown
## 工作環境
- 專案內有 venv 時，優先使用專案的 venv
- 永遠以 project root 作為工作目錄
```

### 4d: 日記機制

```markdown
## 學到新東西就記日記
工作過程中，只要學到新知識、發現重要資訊、做出決策，就立即記錄到 docs/daily/ 目錄：
- 目錄按月份分：`docs/daily/yyyy-mm/`
- 檔名格式：`docs/daily/yyyy-mm/yyyy-mm-dd-<number>-<subject>.md`
- 同一天有多個記錄時，使用遞增的編號（01, 02, 03...）
- 不要等到「階段性完成」才記錄，學到了就寫下來
- 這是 public repo，日記內容不可包含 sensitive data
```

### 4e: Retrospective 原則

```markdown
## Retrospective
- 工作過程中適時將學到的重點整理進 CLAUDE.md
- 修改 CLAUDE.md 前須獲得使用者同意
- 發現重要規則時，詢問是否加入 CLAUDE.md
```

### 4f: 常用縮寫

```markdown
## 常用縮寫
- `ddd` → 工作一個段落了，寫 daily log
- `gg` → 用 `git grep` 快速查詢
```

### 4g: currentDate

```markdown
# currentDate
Today's date is YYYY-MM-DD.
```

此區段由 Claude Code 框架自動注入當天日期。

---

若 CLAUDE.md 已存在 → 顯示現有內容與新內容的差異，問使用者要合併還是覆蓋。

最後建立 `docs/daily/` 目錄。

## Step 5: 完成摘要

列出所做的事情，例如：

```
初始化完成：
- [x] git repo（已存在 / 新建立）
- [x] Python venv（已存在 / 新建立）
- [x] .gitignore（新建立 / 已合併）
- [x] CLAUDE.md（新建立）
- [x] docs/daily/ 目錄

檔案尚未 commit，你可以自行決定何時 commit。
```

## Error Handling

- `git` 未安裝：告知使用者需要先安裝 git，中止流程
- `python3` 未安裝：告知使用者，跳過 Step 2，繼續其餘步驟
- 目錄無寫入權限：告知使用者，中止流程

## 不在範圍內

- 不安裝任何 Python 套件
- 不建立 Dockerfile 或部署相關檔案
- 不自動 commit，使用者自行決定 commit 時機
