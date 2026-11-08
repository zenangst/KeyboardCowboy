// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MachPortSystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "MachPortSystem", targets: ["MachPortSystem"])],
  targets: [.target(name: "MachPortSystem", path: "Sources")]
)
