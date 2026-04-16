---
name: i-am-lazy
description: Delegation mode - autonomously complete remaining work when user steps away. Use when user explicitly mentions "i-am-lazy" or asks Claude to take over and finish the work autonomously. Do NOT trigger on generic "幫我做", "你來決定", or other vague delegation requests.
---

# TL Daily I-Am-Lazy (Delegation Mode)

當使用者與 agent 討論完重要決策後，將剩餘工作全權交給 agent 自主完成。適用於使用者需要暫時離開的場景。

## Prerequisites

1. 對話中已有足夠的上下文，agent 能從對話歷史中辨識出具體的待辦工作
2. 若 agent 無法從對話中辨識出任何具體工作項目（例如使用者一開口就觸發此 skill），應回覆說明上下文不足，請使用者先描述要做的事，然後停止執行

## 授權範圍

使用者主動觸發此 skill 即視為授權委任，不需額外確認：

- 盤點出的工作項目，視為已獲得明確指示
- agent 在這些工作項目的範圍內可自由執行修改、建立檔案、commit 等操作
- 授權範圍內的操作包含 push 到 remote
- 超出列出範圍的操作，仍需遵循 CLAUDE.md 的「只查不改原則」

## Step 1: 盤點工作並直接開始

從對話上下文整理出所有待完成的工作項目，以清單方式列出。每項簡要描述要做什麼與預期產出。

列出清單後直接建立 task list 並開始執行，不等使用者確認。

## Step 2: 逐項執行

將清單建立為 task list，依序完成每項工作。每項做到完成狀態：code 寫好、測試通過、commit 完成。

每完成一項 task 輸出一行簡短進度，格式：`[2/5] 完成：xxx`

失敗處理：

- 測試失敗：嘗試修復，若修復後仍失敗，記錄失敗原因，標記該 task 為 blocked，繼續執行其他 task
- 技術性阻礙（缺少權限、外部依賴不可用等）：記錄問題，標記為 blocked，繼續其他 task
- 所有 blocked task 會列入完成報告的 TODO 中

## Step 3: 遇到決策時反思

執行過程中碰到需要判斷的事情時：

1. 記錄可選方案
2. 從以下來源推測使用者偏好：
   - 當前對話脈絡
   - `docs/daily/{YYYY-MM}/` 日記（若專案有此慣例）
   - CLAUDE.md 規則與 agent memory 中的使用者偏好
3. 寫出反思，說明為什麼選擇該方案
4. 若專案有 `docs/daily/{YYYY-MM}/` 慣例，將反思寫入日記
5. 依反思結論自行決定，繼續執行

## Step 4: 完成報告

全部工作完成後，在對話中列出完成報告：

```
## 完成報告

### 已完成
- [1] xxx
- [2] xxx

### 自主決策
- 決策 1：選擇 A 而非 B（理由：...）

### TODO（請確認）
- [ ] 確認 xxx 的行為是否符合預期
- [ ] blocked task：xxx（原因：...）
```

## 不在範圍內

- 不直接修改既有的 CLAUDE.md 規則，但若執行過程中發現規則不合理，可在完成報告的 TODO 中列出修改建議
- 不提供排程或定時執行功能
- 不處理需要外部人員介入的工作
