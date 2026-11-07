// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "BuiltInFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "BuiltInFeature", targets: ["BuiltInFeature"])],
  targets: [.target(name: "BuiltInFeature", path: "Sources")]
)
