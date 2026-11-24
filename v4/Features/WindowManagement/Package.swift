// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowManagementFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowManagementFeature", targets: ["WindowManagementFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "WindowManagementFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "WindowManagementFeatureTests", dependencies: ["WindowManagementFeature"], path: "Tests"),
  ],
)
