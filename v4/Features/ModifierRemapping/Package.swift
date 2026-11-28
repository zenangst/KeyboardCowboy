// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ModifierRemappingFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ModifierRemappingFeature", targets: ["ModifierRemappingFeature"])],
  targets: [
    .target(name: "ModifierRemappingFeature", path: "Sources"),
    .testTarget(name: "ModifierRemappingFeatureTests", dependencies: ["ModifierRemappingFeature"], path: "Tests"),
  ],
)
