// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ShortcutsFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ShortcutsFeature", targets: ["ShortcutsFeature"])],
  dependencies: [
    .package(path: "../../Components/Commands"),
    .package(path: "../../Components/ProcessSystem"),
    .package(path: "../../Components/RuntimeEnvironment"),
  ],
  targets: [
    .target(name: "ShortcutsFeature", dependencies: ["Commands", "ProcessSystem", "RuntimeEnvironment"], path: "Sources"),
    .testTarget(name: "ShortcutsFeatureTests", dependencies: ["Commands", "ProcessSystem", "ShortcutsFeature"], path: "Tests"),
  ],
)
