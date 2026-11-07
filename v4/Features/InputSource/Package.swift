// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "InputSourceFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "InputSourceFeature", targets: ["InputSourceFeature"])],
  targets: [.target(name: "InputSourceFeature", path: "Sources")]
)
