// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "KeyboardTriggers",
  platforms: [.macOS(.v14)],
  products: [.library(name: "KeyboardTriggers", targets: ["KeyboardTriggers"])],
  dependencies: [
    .package(path: "../../Components/KeyCodeSystem"),
    .package(path: "../../Components/MachPortSystem"),
  ],
  targets: [
    .target(name: "KeyboardTriggers", dependencies: ["KeyCodeSystem"], path: "Sources"),
    .testTarget(
      name: "KeyboardTriggersTests",
      dependencies: ["KeyboardTriggers", "MachPortSystem"],
      path: "Tests",
    ),
  ],
)
