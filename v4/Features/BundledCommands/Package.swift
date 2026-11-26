// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "BundledCommandsFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "BundledCommandsFeature", targets: ["BundledCommandsFeature"])],
  dependencies: [
    .package(path: "../../Components/ApplicationCatalog"),
    .package(path: "../../Components/Commands"),
  ],
  targets: [
    .target(name: "BundledCommandsFeature", dependencies: ["ApplicationCatalog", "Commands"], path: "Sources"),
    .testTarget(name: "BundledCommandsFeatureTests", dependencies: ["BundledCommandsFeature", "ApplicationCatalog", "Commands"],
                path: "Tests"),
  ],
)
