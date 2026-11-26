// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "KeyboardTriggers",
  platforms: [.macOS(.v14)],
  products: [.library(name: "KeyboardTriggers", targets: ["KeyboardTriggers"])],
  targets: [.target(name: "KeyboardTriggers", path: "Sources")],
)
