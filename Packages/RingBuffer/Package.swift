// swift-tools-version:6.0
import PackageDescription

let mainTarget = "RingBuffer"
let package = Package(
  name: mainTarget,
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: mainTarget, targets: [mainTarget]),
  ],
  targets: [
    .target(name: mainTarget, dependencies: []),
    .testTarget(
      name: "\(mainTarget)Tests",
      dependencies: [Target.Dependency.target(name: mainTarget)],
    ),
  ],
)
