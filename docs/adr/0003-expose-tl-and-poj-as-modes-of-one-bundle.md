---
status: accepted
---

# Expose TL and POJ as modes of one input-method bundle

Tâi-lô and POJ are two modes of one Taigi Telex application bundle, backed by a shared mode-aware composition engine. The bundle's XML/plist configuration maps these modes to distinct user-selectable macOS input sources with stable identifiers.

This provides one installation and shared lifecycle while allowing users to select either orthography through macOS. Pending composition is committed before switching modes. Additional orthographies should reuse this model only while the shared engine remains clearer than separate implementations.
