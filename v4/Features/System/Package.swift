// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "SystemFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "SystemFeature", targets: ["SystemFeature"])],
  dependencies: [
    .package(path: "../Applications"),
    .package(path: "../Scripting"),
    .package(path: "../../Components/AccessibilitySystem"),
    .package(path: "../../Components/ApplicationCatalog"),
    .package(path: "../../Components/Commands"),
    .package(path: "../../Components/UserSpace"),
  ],
  targets: [
    .target(
      name: "SystemFeature",
      dependencies: [
        .product(name: "ApplicationsFeature", package: "Applications"),
        .product(name: "ScriptingFeature", package: "Scripting"),
        "AccessibilitySystem",
        "ApplicationCatalog",
        "Commands",
        "UserSpace",
      ],
      path: "Sources",
    ),
    .testTarget(
      name: "SystemFeatureTests",
      dependencies: ["SystemFeature", "Commands", "UserSpace", .product(name: "ScriptingFeature", package: "Scripting")],
      path: "Tests",
    ),
  ],
)
