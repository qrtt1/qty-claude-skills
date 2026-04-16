# qty-claude-skills - Claude Code 專案說明

公開發布的 Claude Code skills 集合。從 `twjug-lite-infra` 畢業、穩定且無敏感內容的 skill 移至此 repo。

工作日誌寫在 `twjug-lite-infra`（private），不寫在這裡。

## 簡單方案優先

有多種實作方式時，選最簡單、moving parts 最少的方案。不確定使用者想要哪種做法時，先用 2 句話描述方案再動手，不要直接蓋複雜版本。

## CLI 指令驗證

執行不熟悉或本次對話中沒用過的 CLI flag 前，先跑 `<command> --help` 確認該 flag 存在。不要憑記憶猜測 flag 名稱。

## Skill 發布原則

移入此 repo 的 skill 應符合：
1. 功能穩定，短期內不會大改
2. 無敏感內容（internal URL、公司名稱、私人 token 等）
3. 通用性夠，對其他人也有意義

## 規則管理

發現重要規則時，詢問是否加入 CLAUDE.md。
