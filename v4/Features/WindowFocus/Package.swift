// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowFocusFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowFocusFeature", targets: ["WindowFocusFeature"])],
  targets: [.target(name: "WindowFocusFeature", path: "Sources")]
)
