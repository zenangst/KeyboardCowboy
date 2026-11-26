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
    .package(path: "../Components/KeyCodeSystem"),
    .package(path: "../Components/MachPortSystem"),
    .package(path: "../Components/Commands"),
    .package(path: "../Features/Open"),
    .package(path: "../Features/Keyboard"),
    .package(path: "../Features/Mouse"),
    .package(path: "../Features/Text"),
    .package(path: "../Features/UIAutomation"),
    .package(path: "../Features/WindowFocus"),
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
        "KeyCodeSystem",
        "MachPortSystem",
        .product(name: "KeyboardFeature", package: "Keyboard"),
        .product(name: "MouseFeature", package: "Mouse"),
        .product(name: "TextFeature", package: "Text"),
        .product(name: "UIAutomationFeature", package: "UIAutomation"),
        .product(name: "WindowFocusFeature", package: "WindowFocus"),
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
    .testTarget(
      name: "HostInputTests",
      dependencies: [
        "HostInput",
        "AccessibilitySystem",
        "KeyCodeSystem",
        "MachPortSystem",
        .product(name: "KeyboardFeature", package: "Keyboard"),
        .product(name: "TextFeature", package: "Text"),
      ],
    ),
    .testTarget(name: "HostOpenTests", dependencies: ["HostOpen", "Commands"]),
  ],
)
