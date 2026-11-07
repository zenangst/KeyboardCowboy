// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "KeyboardFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "KeyboardFeature", targets: ["KeyboardFeature"])],
  targets: [.target(name: "KeyboardFeature", path: "Sources")]
)
