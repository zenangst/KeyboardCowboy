// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "UIElementFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "UIElementFeature", targets: ["UIElementFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "UIElementFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "UIElementFeatureTests", dependencies: ["UIElementFeature"], path: "Tests"),
  ],
)
