// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "BundledCommandsFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "BundledCommandsFeature", targets: ["BundledCommandsFeature"])],
  targets: [.target(name: "BundledCommandsFeature", path: "Sources")]
)
