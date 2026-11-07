// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "OpenFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "OpenFeature", targets: ["OpenFeature"])],
  targets: [
    .target(name: "OpenFeature", path: "Sources"),
    .testTarget(name: "OpenFeatureTests", dependencies: ["OpenFeature"], path: "Tests"),
  ]
)
