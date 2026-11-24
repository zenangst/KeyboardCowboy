// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowTilingFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowTilingFeature", targets: ["WindowTilingFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "WindowTilingFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "WindowTilingFeatureTests", dependencies: ["WindowTilingFeature", "AccessibilitySystem"], path: "Tests"),
  ],
)
