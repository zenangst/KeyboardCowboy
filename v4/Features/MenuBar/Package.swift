// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MenuBarFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "MenuBarFeature", targets: ["MenuBarFeature"])],
  targets: [.target(name: "MenuBarFeature", path: "Sources")]
)
