// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "OpenFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "OpenFeature", targets: ["OpenFeature"])],
  dependencies: [.package(path: "../../Components/Commands")],
  targets: [
    .target(name: "OpenFeature", dependencies: ["Commands"], path: "Sources"),
    .testTarget(name: "OpenFeatureTests", dependencies: ["OpenFeature", "Commands"], path: "Tests"),
  ]
)
