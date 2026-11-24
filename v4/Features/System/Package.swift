// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "SystemFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "SystemFeature", targets: ["SystemFeature"])],
  dependencies: [
    .package(path: "../Applications"),
    .package(path: "../../Components/Commands"),
    .package(path: "../../Components/UserSpace"),
  ],
  targets: [
    .target(
      name: "SystemFeature",
      dependencies: [
        .product(name: "ApplicationsFeature", package: "Applications"),
        "Commands",
        "UserSpace",
      ],
      path: "Sources",
    ),
    .testTarget(
      name: "SystemFeatureTests",
      dependencies: ["SystemFeature", "Commands", "UserSpace"],
      path: "Tests",
    ),
  ],
)
