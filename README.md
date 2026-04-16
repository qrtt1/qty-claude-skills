# qty-claude-skills

個人日常使用的 Claude Code skills，以及一份實際在跑的 CLAUDE.md——記錄了讓 AI agent 寫日誌、開工回顧、delegation 等工作習慣。有興趣的人可以參考看看。

## Install

```bash
claude plugin marketplace add https://github.com/qrtt1/qty-claude-skills
claude plugin install qty-util@qty-claude-skills
claude plugin install qty-daily@qty-claude-skills
```

## Skills

### qty-util

| Skill | Description |
|-------|-------------|
| md2clip | Convert markdown to rich text on macOS clipboard, for pasting into Notion with proper block formatting |
| init | Initialize a new project with git, venv, .gitignore, and CLAUDE.md |

### qty-daily

| Skill | Description |
|-------|-------------|
| standup | Daily standup - scan recent work, pending plans, and suggest next steps |
| i-am-lazy | Delegation mode - autonomously complete remaining work when user steps away |
