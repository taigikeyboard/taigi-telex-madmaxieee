// swift-tools-version:5.9
// This Package.swift supports Swift Testing and sourcekit-lsp.
// The actual build system is CMake - see README.md for build instructions.

import PackageDescription

let package = Package(
  name: "TaigiTelex",
  platforms: [
    .macOS(.v11)
  ],
  targets: [
    // Library target for testing (core logic only)
    .target(
      name: "TaigiTelexLib",
      path: "src/lib",
      swiftSettings: []
    ),
    .target(
      name: "TaigiTelexAdapter",
      dependencies: ["TaigiTelexLib"],
      path: "src/adapter",
      swiftSettings: []
    ),
    // Test target
    .testTarget(
      name: "TaigiTelexTests",
      dependencies: ["TaigiTelexLib", "TaigiTelexAdapter"],
      path: "test"
    ),
    // Executable target for LSP support (includes all files)
    .executableTarget(
      name: "TaigiTelex",
      dependencies: ["TaigiTelexLib", "TaigiTelexAdapter"],
      path: "src",
      exclude: ["adapter", "lib"],
      swiftSettings: []
    ),
    // Fuzz test executable (not run by `swift test`)
    .executableTarget(
      name: "FuzzTests",
      dependencies: ["TaigiTelexLib"],
      path: "fuzz",
      swiftSettings: []
    ),
  ]
)
