// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AccessibilitySystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "AccessibilitySystem", targets: ["AccessibilitySystem"])],
  targets: [.target(name: "AccessibilitySystem", path: "Sources")]
)
