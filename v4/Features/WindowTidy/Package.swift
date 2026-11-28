// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WindowTidyFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WindowTidyFeature", targets: ["WindowTidyFeature"])],
  dependencies: [.package(path: "../WindowTiling")],
  targets: [
    .target(name: "WindowTidyFeature", dependencies: [
      .product(name: "WindowTilingFeature", package: "WindowTiling"),
    ], path: "Sources"),
    .testTarget(name: "WindowTidyFeatureTests", dependencies: [
      "WindowTidyFeature", .product(name: "WindowTilingFeature", package: "WindowTiling"),
    ], path: "Tests"),
  ],
)
