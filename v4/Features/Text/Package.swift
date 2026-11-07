// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "TextFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "TextFeature", targets: ["TextFeature"])],
  targets: [.target(name: "TextFeature", path: "Sources")]
)
