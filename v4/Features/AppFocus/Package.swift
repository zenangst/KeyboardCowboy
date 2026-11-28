// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AppFocusFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "AppFocusFeature", targets: ["AppFocusFeature"])],
  dependencies: [
    .package(path: "../../Components/ApplicationCatalog"),
    .package(path: "../WindowTiling"),
  ],
  targets: [
    .target(name: "AppFocusFeature", dependencies: [
      "ApplicationCatalog", .product(name: "WindowTilingFeature", package: "WindowTiling"),
    ], path: "Sources"),
    .testTarget(name: "AppFocusFeatureTests", dependencies: [
      "AppFocusFeature", "ApplicationCatalog", .product(name: "WindowTilingFeature", package: "WindowTiling"),
    ], path: "Tests"),
  ],
)
