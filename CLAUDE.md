# qty-claude-skills - Claude Code 專案說明

這個 repo 收錄個人日常使用的 Claude Code skills。CLAUDE.md 記錄的是這裡實際在跑的工作習慣，有興趣的人可以參考看看。

工作過程中讓 AI agent 記日誌是這裡的習慣，standup 也會掃這些日誌做開工回顧。

## 簡單方案優先

有多種實作方式時，選最簡單、moving parts 最少的方案。不確定使用者想要哪種做法時，先用 2 句話描述方案再動手，不要直接蓋複雜版本。

## CLI 指令驗證

執行不熟悉或本次對話中沒用過的 CLI flag 前，先跑 `<command> --help` 確認該 flag 存在。不要憑記憶猜測 flag 名稱。

## 只查不改原則

沒有明確指示時，只能進行查詢動作，不做任何變更或刪除行為。

## 學到新東西就記日記

工作過程中，只要學到新知識、發現重要資訊、做出決策，就立即記錄到 `docs/daily/` 目錄：
- 目錄按月份分：`docs/daily/yyyy-mm/`
- 檔名格式：`yyyy-mm-dd-<number>-<subject>.md`
- 同一天有多個記錄時，使用遞增的編號（01, 02, 03...）

不要等到「階段性完成」才記錄，學到了就寫下來。
日記中若有明確的「下次從這裡開始」的內容，同步存入記憶。
注意：這是 public repo，日記內容不可包含 sensitive data。

## daily 與 notes 的分流

`docs/daily/` 是工作軌跡，按時間讀。`docs/notes/` 是參考資料，按主題查，不具時序意義。

- 放 daily：決策、盤點、retro、memory sync、「下次從這裡開始」類的交接
- 放 notes：外部文章讀書筆記、工具用法備忘、概念整理、純參考性資料

## Plugin 目錄結構規則

Claude Code 只會在 `<plugin-root>/skills/<skill-name>/SKILL.md` 路徑下搜尋 skills。每個 plugin 子目錄內必須有 `skills/` 這一層：

```
plugins/<plugin-name>/
├── .claude-plugin/plugin.json
└── skills/
    └── <skill-name>/
        └── SKILL.md
```

## Skill 機密保護原則

建立或審查 Skill 時，須檢查是否有 sensitive data（token、API key、密碼等）洩漏風險：
- 讀取含機密的設定檔時，不得使用 Read tool，改用 Bash + jq 只擷取非敏感欄位
- Setup 流程中，引導使用者自行編輯檔案填入機密，不要求在對話中貼上

## 常用縮寫

- `ddd` → 工作一個段落了，寫 daily log，寫完直接 commit 並 push，不用問
- `push` → commit 並 push（不只是 push），看到這個字就把當前變更一起提交推送
- `retro` → 對照文件與現況，找出 drift 並提出修正清單

## 規則管理

發現重要規則時，詢問是否加入 CLAUDE.md。
