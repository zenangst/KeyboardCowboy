// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MouseFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "MouseFeature", targets: ["MouseFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "MouseFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "MouseFeatureTests", dependencies: ["MouseFeature"], path: "Tests"),
  ]
)
