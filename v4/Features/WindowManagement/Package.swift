// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowManagementFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowManagementFeature", targets: ["WindowManagementFeature"])],
  targets: [.target(name: "WindowManagementFeature", path: "Sources")]
)
