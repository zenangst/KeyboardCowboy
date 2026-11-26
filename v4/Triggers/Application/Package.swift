// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ApplicationTriggers",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ApplicationTriggers", targets: ["ApplicationTriggers"])],
  targets: [
    .target(name: "ApplicationTriggers", path: "Sources"),
    .testTarget(name: "ApplicationTriggersTests", dependencies: ["ApplicationTriggers"], path: "Tests"),
  ],
)
