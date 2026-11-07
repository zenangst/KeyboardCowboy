// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowTilingFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowTilingFeature", targets: ["WindowTilingFeature"])],
  targets: [.target(name: "WindowTilingFeature", path: "Sources")]
)
