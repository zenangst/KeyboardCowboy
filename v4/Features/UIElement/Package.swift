// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "UIElementFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "UIElementFeature", targets: ["UIElementFeature"])],
  targets: [.target(name: "UIElementFeature", path: "Sources")]
)
