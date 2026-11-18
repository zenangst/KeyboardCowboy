// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ShortcutsFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ShortcutsFeature", targets: ["ShortcutsFeature"])],
  dependencies: [.package(path: "../../Components/RuntimeEnvironment"), .package(path: "../../Components/ProcessSystem")],
  targets: [
    .target(name: "ShortcutsFeature", dependencies: ["RuntimeEnvironment", "ProcessSystem"], path: "Sources"),
    .testTarget(name: "ShortcutsFeatureTests", dependencies: ["ProcessSystem", "ShortcutsFeature"], path: "Tests"),
  ]
)
