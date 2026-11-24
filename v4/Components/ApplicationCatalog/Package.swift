// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ApplicationCatalog",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "ApplicationCatalog", targets: ["ApplicationCatalog"]),
    .library(name: "Apps", targets: ["Apps"]),
  ],
  targets: [
    .target(name: "ApplicationCatalog", path: "Sources"),
    // Compatibility for the legacy app. New clients use ApplicationCatalog.
    .target(name: "Apps", dependencies: ["ApplicationCatalog"], path: "Compatibility"),
    .testTarget(name: "ApplicationCatalogTests", dependencies: ["ApplicationCatalog"], path: "Tests"),
  ],
)
