// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "MachPortSystem",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "MachPortSystem", targets: ["MachPortSystem"]),
    .executable(name: "EventTapProbe", targets: ["EventTapProbe"]),
  ],
  targets: [
    .target(name: "MachPortSystem", path: "Sources"),
    .executableTarget(name: "EventTapProbe", dependencies: ["MachPortSystem"], path: "Tools/EventTapProbe"),
    .testTarget(name: "MachPortSystemTests", dependencies: ["MachPortSystem"], path: "Tests"),
  ],
)
