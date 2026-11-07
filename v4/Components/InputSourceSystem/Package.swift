// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "InputSourceSystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "InputSourceSystem", targets: ["InputSourceSystem"])],
  targets: [.target(name: "InputSourceSystem", path: "Sources")]
)
