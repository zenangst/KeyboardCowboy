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
    .package(path: "../Applications"),
  ],
  targets: [
    .target(name: "WorkspacesFeature", dependencies: ["ApplicationCatalog", "Commands"], path: "Sources"),
    .testTarget(
      name: "WorkspacesFeatureTests",
      dependencies: [
        "WorkspacesFeature", "ApplicationCatalog", "Commands", "UserSpace",
        .product(name: "ApplicationsFeature", package: "Applications"),
      ],
      path: "Tests",
    ),
  ],
)
