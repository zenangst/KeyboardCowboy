// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "SystemFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "SystemFeature", targets: ["SystemFeature"])],
  targets: [.target(name: "SystemFeature", path: "Sources")]
)
