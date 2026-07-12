---
status: accepted
---

# Use CMake for app builds and SwiftPM for tests

CMake with Ninja is the authoritative build path for the complete macOS input-method bundle and package. SwiftPM provides the source graph needed for tests, fuzzing, and editor tooling; the two source graphs are synchronized manually.

This was a pragmatic choice rather than a claim that CMake is optimal: Neovim is the primary development environment, Xcode projects are intentionally avoided, CMake was the known non-Xcode route for building the full app, and SwiftPM was needed for tests. The decision may be revisited if a simpler non-Xcode build can produce the bundle, resources, and packages while supporting tests and editor tooling.

## Consequences

Changes to targets, source files, platform versions, or compiler settings may need corresponding updates in both `CMakeLists.txt` and `Package.swift`. Passing `swift test` does not replace validating the authoritative CMake build.
