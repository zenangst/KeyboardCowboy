// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "KeyboardFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "KeyboardFeature", targets: ["KeyboardFeature"])],
  dependencies: [.package(path: "../../Components/MachPortSystem")],
  targets: [
    .target(
      name: "KeyboardFeature",
      dependencies: ["MachPortSystem"],
      path: "Sources"),
    .testTarget(
      name: "KeyboardFeatureTests",
      dependencies: [
        "KeyboardFeature",
        "MachPortSystem",
      ],
      path: "Tests"),
  ],
)
