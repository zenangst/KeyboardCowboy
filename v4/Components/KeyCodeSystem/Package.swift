// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "KeyCodeSystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "KeyCodeSystem", targets: ["KeyCodeSystem"])],
  targets: [
    .target(name: "KeyCodeSystem", path: "Sources"),
    .testTarget(name: "KeyCodeSystemTests", dependencies: ["KeyCodeSystem"], path: "Tests",
                resources: [.copy("Fixtures")]),
  ],
)
