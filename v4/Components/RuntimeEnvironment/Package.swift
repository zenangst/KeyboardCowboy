// swift-tools-version: 6.3
import PackageDescription

let package = Package(
  name: "RuntimeEnvironment",
  platforms: [.macOS(.v14)],
  products: [.library(name: "RuntimeEnvironment", targets: ["RuntimeEnvironment"])],
  targets: [
    .target(name: "RuntimeEnvironment", path: "Sources"),
    .testTarget(name: "RuntimeEnvironmentTests", dependencies: ["RuntimeEnvironment"], path: "Tests"),
  ],
)
