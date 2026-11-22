// swift-tools-version: 6.3

import Foundation
import PackageDescription

let infoPlist = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .appending(path: "Resources/Info.plist")
  .path()

let package = Package(
  name: "KeyboardCowboyService",
  platforms: [.macOS(.v14)],
  products: [.executable(name: "KeyboardCowboy", targets: ["ServiceApp"])],
  dependencies: [
    .package(path: "../Components/AccessibilitySystem"),
    .package(path: "../Components/AppleScriptRuntime"),
    .package(path: "../Components/MachPortSystem"),
    .package(path: "../Components/Commands"),
    .package(path: "../Features/Open"),
    .package(path: "../Features/Text"),
  ],
  targets: [
    .executableTarget(
      name: "ServiceApp",
      dependencies: ["HostInput", "HostOpen"],
      path: "Sources",
      linkerSettings: [.unsafeFlags([
        "-Xlinker", "-sectcreate",
        "-Xlinker", "__TEXT",
        "-Xlinker", "__info_plist",
        "-Xlinker", infoPlist,
      ])],
    ),
    .target(
      name: "HostInput",
      dependencies: [
        "AccessibilitySystem",
        "MachPortSystem",
        .product(name: "TextFeature", package: "Text"),
      ],
      path: "RuntimeInput",
    ),
    .target(
      name: "HostOpen",
      dependencies: [
        "AppleScriptRuntime",
        "Commands",
        .product(name: "OpenFeature", package: "Open"),
      ],
      path: "RuntimeOpen",
    ),
    .testTarget(name: "HostInputTests", dependencies: ["HostInput"]),
    .testTarget(name: "HostOpenTests", dependencies: ["HostOpen", "Commands"]),
  ],
)
