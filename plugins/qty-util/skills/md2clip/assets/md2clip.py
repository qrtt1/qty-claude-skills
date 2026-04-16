#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["markdown", "pyobjc-framework-Cocoa"]
# ///
"""Convert markdown from stdin to rich text on clipboard (macOS).

Usage:
    cat file.md | md2clip
    echo "# Hello" | md2clip
"""
import sys
import markdown
from AppKit import NSPasteboard, NSPasteboardTypeHTML, NSPasteboardTypeString

md_text = sys.stdin.read()
body = markdown.markdown(
    md_text,
    extensions=["fenced_code", "tables"],
)
html = f"<meta charset='utf-8'><html><head></head><body>{body}</body></html>"

pb = NSPasteboard.generalPasteboard()
pb.clearContents()
pb.setString_forType_(html, NSPasteboardTypeHTML)
pb.setString_forType_(md_text, NSPasteboardTypeString)
pb.setString_forType_("https://claude.ai/", "org.chromium.source-url")
pb.setString_forType_("fake-token", "org.chromium.internal.source-rfh-token")

print(f"Copied ({len(md_text)} chars md → {len(html)} chars html)", file=sys.stderr)
