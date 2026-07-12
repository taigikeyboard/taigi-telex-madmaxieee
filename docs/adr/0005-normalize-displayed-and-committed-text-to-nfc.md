---
status: accepted
---

# Normalize displayed and committed text to NFC

Both marked composition text and committed output are normalized to Unicode NFC. NFC precomposes characters where possible while retaining combining marks that have no precomposed representation, including POJ's U+0358 COMBINING DOT ABOVE RIGHT.

For example, POJ `o` followed by U+0358 and U+0304 is emitted as U+014D (`ō`) followed by U+0358. This provides a consistent external text contract without losing orthographic marks required by TL or POJ.

## Implementation status

The decision is accepted, but implementation is pending. The current engine can still emit decomposed sequences; normalization must be applied to both displayed composition and committed text.
