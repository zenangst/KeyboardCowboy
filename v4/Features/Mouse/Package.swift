// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MouseFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "MouseFeature", targets: ["MouseFeature"])],
  dependencies: [
    .package(path: "../../Components/AccessibilitySystem"),
    .package(path: "../../Components/Commands"),
  ],
  targets: [
    .target(name: "MouseFeature", dependencies: ["AccessibilitySystem", "Commands"], path: "Sources"),
    .testTarget(name: "MouseFeatureTests", dependencies: ["MouseFeature", "Commands"], path: "Tests"),
  ],
)
