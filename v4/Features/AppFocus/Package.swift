// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AppFocusFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "AppFocusFeature", targets: ["AppFocusFeature"])],
  dependencies: [
    .package(path: "../../Components/ApplicationCatalog"),
    .package(path: "../../Components/AccessibilitySystem"),
    .package(path: "../../Components/Commands"),
    .package(path: "../System"),
    .package(path: "../WindowTiling"),
  ],
  targets: [
    .target(name: "AppFocusFeature", dependencies: [
      "ApplicationCatalog", .product(name: "WindowTilingFeature", package: "WindowTiling"),
    ], path: "Sources"),
    .testTarget(name: "AppFocusFeatureTests", dependencies: [
      "AppFocusFeature", "ApplicationCatalog", "AccessibilitySystem", "Commands",
      .product(name: "SystemFeature", package: "System"),
      .product(name: "WindowTilingFeature", package: "WindowTiling"),
    ], path: "Tests"),
  ],
)
