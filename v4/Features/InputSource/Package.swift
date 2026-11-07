// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "InputSourceFeature",
  platforms: [.macOS(.v14)],
  products: [.library(name: "InputSourceFeature", targets: ["InputSourceFeature"])],
  dependencies: [.package(path: "../../Components/InputSourceSystem")],
  targets: [
    .target(name: "InputSourceFeature", dependencies: ["InputSourceSystem"], path: "Sources"),
    .testTarget(name: "InputSourceFeatureTests", dependencies: ["InputSourceFeature", "InputSourceSystem"], path: "Tests"),
  ]
)
