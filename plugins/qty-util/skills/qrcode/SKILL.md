---
name: qrcode
description: Generate a QR code in the terminal from any string or URL. Use when the user asks to make a QR code, display a QR code in the terminal, or convert a string/URL into a scannable QR code.
---

# tl-util-qrcode

## Usage

```bash
uv run --with qrcode scripts/gen_qrcode.py "<string>"
```

The script path is relative to this skill's base directory. Use the absolute path if running from elsewhere.

The output is ASCII art printed to stdout, suitable for terminal display and scanning with a phone.

After running the command, always embed the full output inside a fenced code block in your text response so it is visible without expanding the tool result panel.

This skill is one-time and contextual. Do not automatically reuse it for subsequent responses unless the user explicitly requests it again.
