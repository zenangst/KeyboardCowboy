// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MenuBarFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "MenuBarFeature", targets: ["MenuBarFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "MenuBarFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "MenuBarFeatureTests", dependencies: ["MenuBarFeature"], path: "Tests"),
  ]
)
