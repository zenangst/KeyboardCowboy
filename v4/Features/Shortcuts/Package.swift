// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ShortcutsFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ShortcutsFeature", targets: ["ShortcutsFeature"])],
  dependencies: [.package(path: "../../Components/CowboyCore")],
  targets: [
    .target(name: "ShortcutsFeature", dependencies: ["CowboyCore"], path: "Sources"),
    .testTarget(name: "ShortcutsFeatureTests", dependencies: ["CowboyCore", "ShortcutsFeature"], path: "Tests"),
  ]
)
