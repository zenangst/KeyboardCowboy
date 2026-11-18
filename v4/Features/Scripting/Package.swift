// swift-tools-version: 6.3

import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "ScriptingFeature",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "ScriptingFeature",
      targets: ["ScriptingFeature"],
    ),
  ],
  dependencies: [
    .package(path: "../../Components/RuntimeEnvironment"),
    .package(path: "../../Components/AppleScriptRuntime"),
    .package(path: "../../Components/FileSystem"),
    .package(path: "../../Components/ProcessSystem"),
  ],
  targets: [
    .target(
      name: "ScriptingFeature",
      dependencies: [
        .product(name: "RuntimeEnvironment", package: "RuntimeEnvironment"),
        .product(name: "AppleScriptRuntime", package: "AppleScriptRuntime"),
        .product(name: "FileSystem", package: "FileSystem"),
        .product(name: "ProcessSystem", package: "ProcessSystem"),
      ],
      path: "Sources",
      linkerSettings: linkerSettings,
    ),
    .testTarget(
      name: "ScriptingFeatureTests",
      dependencies: ["AppleScriptRuntime", "FileSystem", "ProcessSystem", "ScriptingFeature"],
      path: "Tests",
    ),
  ],
)
