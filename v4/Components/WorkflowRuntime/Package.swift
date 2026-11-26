// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "WorkflowRuntime",
  platforms: [.macOS(.v14)],
  products: [.library(name: "WorkflowRuntime", targets: ["WorkflowRuntime"])],
  targets: [.target(name: "WorkflowRuntime", path: "Sources")],
)
