---
status: accepted
---

# Isolate composition logic from InputMethodKit

Taiwanese transliteration and composition logic lives in a framework-independent core library. The engine owns raw composition state, derives display text, and emits semantic results such as update, commit, passthrough, and commit-and-update; the InputMethodKit controller translates those results into macOS client operations.

This boundary keeps domain behavior deterministic and testable without running an input-method process. Platform event handling remains in the controller, while orthographic rules and composition state transitions remain in the core library.
