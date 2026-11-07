// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ShortcutsFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ShortcutsFeature", targets: ["ShortcutsFeature"])],
  targets: [.target(name: "ShortcutsFeature", path: "Sources")]
)
