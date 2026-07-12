---
status: accepted
---

# Register the input method as zh-Hant

Taigi Telex declares `zh-Hant` as its intended language even though it produces Latin-script Taiwanese romanization. This makes macOS list it under Traditional Chinese and enables the expected Caps Lock switching behavior for a Chinese input method.

The metadata is intentionally less precise than the output repertoire. Removing this workaround requires verifying that input-source discovery and Caps Lock switching continue to work on supported macOS versions.
