// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "UIAutomationFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "UIAutomationFeature", targets: ["UIAutomationFeature"])],
  dependencies: [.package(path: "../../Components/AccessibilitySystem")],
  targets: [
    .target(name: "UIAutomationFeature", dependencies: ["AccessibilitySystem"], path: "Sources"),
    .testTarget(name: "UIAutomationFeatureTests", dependencies: ["UIAutomationFeature"], path: "Tests"),
  ],
)
