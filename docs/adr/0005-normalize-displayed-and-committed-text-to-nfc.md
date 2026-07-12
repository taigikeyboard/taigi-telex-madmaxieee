---
status: accepted
---

# Normalize displayed and committed text to NFC

Taigi Telex normalizes every transformed result to Unicode NFC at the return seam of `TelexRules.transform`. The engine uses that result for both marked composition display and transformed committed output.

NFC gives applications, pasteboards, documents, and other input-method consumers a stable interoperable representation. It precomposes available characters rather than exposing decomposed sequences that may render or compare inconsistently outside the input method.

Canonical normalization does not discard marks without a precomposed form. For example, POJ `o` followed by U+0358 COMBINING DOT ABOVE RIGHT and U+0304 COMBINING MACRON is emitted as U+014D (`ō`) followed by U+0358. This preserves the required POJ orthography while providing a stable scalar representation.

Normalizing at the shared transform return ensures displayed composition and committed transformed text have the same NFC contract without adding InputMethodKit-specific behavior.
