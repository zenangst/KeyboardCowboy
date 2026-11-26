// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WorkflowRuntime",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WorkflowRuntime", targets: ["WorkflowRuntime"])],
  dependencies: [
    .package(path: "../Commands"),
    .package(path: "../../Triggers/Application"),
  ],
  targets: [
    .target(name: "WorkflowRuntime", dependencies: ["Commands"], path: "Sources"),
    .testTarget(
      name: "WorkflowRuntimeTests",
      dependencies: ["WorkflowRuntime", "Commands", .product(name: "ApplicationTriggers", package: "Application")],
      path: "Tests",
    ),
  ],
)
