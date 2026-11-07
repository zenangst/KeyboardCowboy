// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "OpenFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "OpenFeature", targets: ["OpenFeature"])],
  dependencies: [.package(path: "../../Components/CowboyCore")],
  targets: [
    .target(name: "OpenFeature", dependencies: ["CowboyCore"], path: "Sources"),
    .testTarget(name: "OpenFeatureTests", dependencies: ["OpenFeature", "CowboyCore"], path: "Tests"),
  ]
)
