---
name: qrcode
description: Generate a QR code in the terminal from any string or URL. Use when the user asks to make a QR code, display a QR code in the terminal, or convert a string/URL into a scannable QR code. Also triggers when the user uses pipe syntax like "command | qrcode" or "查網路狀態 | qrcode" — treat the left side as the string or command whose output to encode.
---

# tl-util-qrcode

## Usage

```bash
uv run --with qrcode scripts/gen_qrcode.py "<string>"
```

The script path is relative to this skill's base directory. Use the absolute path if running from elsewhere.

The output is ASCII art printed to stdout, suitable for terminal display and scanning with a phone.

This skill is one-time and contextual. Do not automatically reuse it for subsequent responses unless the user explicitly requests it again.
