// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AccessibilitySystem",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "AccessibilitySystem", targets: ["AccessibilitySystem"]),
    .executable(name: "WindowObservationProbe", targets: ["WindowObservationProbe"]),
  ],
  targets: [
    .target(name: "AccessibilitySystem", path: "Sources"),
    .executableTarget(name: "WindowObservationProbe", dependencies: ["AccessibilitySystem"],
                      path: "Tools/WindowObservationProbe"),
    .testTarget(name: "AccessibilitySystemTests", dependencies: ["AccessibilitySystem"], path: "Tests"),
  ],
)
