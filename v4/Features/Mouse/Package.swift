// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MouseFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "MouseFeature", targets: ["MouseFeature"])],
  targets: [.target(name: "MouseFeature", path: "Sources")]
)
