// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowFocusFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowFocusFeature", targets: ["WindowFocusFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "WindowFocusFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "WindowFocusFeatureTests", dependencies: ["AccessibilitySystem", "WindowFocusFeature"], path: "Tests"),
  ]
)
