// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WorkspacesFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WorkspacesFeature", targets: ["WorkspacesFeature"])],
  dependencies: [
    .package(path: "../../Components/ApplicationCatalog"),
    .package(path: "../../Components/Commands"),
    .package(path: "../../Components/UserSpace"),
    .package(path: "../../Components/AccessibilitySystem"),
    .package(path: "../Applications"),
    .package(path: "../System"),
    .package(path: "../WindowTiling"),
  ],
  targets: [
    .target(name: "WorkspacesFeature", dependencies: ["ApplicationCatalog", "Commands"], path: "Sources"),
    .testTarget(
      name: "WorkspacesFeatureTests",
      dependencies: [
        "WorkspacesFeature",
        "ApplicationCatalog",
        "Commands",
        "UserSpace",
        "AccessibilitySystem",
        .product(name: "ApplicationsFeature", package: "Applications"),
        .product(name: "SystemFeature", package: "System"),
        .product(name: "WindowTilingFeature", package: "WindowTiling"),
      ],
      path: "Tests",
    ),
  ],
)
