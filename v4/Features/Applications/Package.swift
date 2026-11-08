// swift-tools-version: 6.3

import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "ApplicationsFeature",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "ApplicationsFeature",
      targets: ["ApplicationsFeature"],
    ),
  ],
  dependencies: [
    .package(path: "../../Components/CowboyCore"),
    .package(path: "../../Components/Commands"),
    .package(path: "../../Components/UserSpace"),
    .package(path: "../../Components/ApplicationSystem"),
    .package(path: "../../Components/AppleScriptSystem"),
    .package(path: "../../Components/FileSystem"),
    .package(path: "../../Components/ProcessSystem"),
  ],
  targets: [
    .target(
      name: "ApplicationsFeature",
      dependencies: [
        .product(name: "CowboyCore", package: "CowboyCore"),
        .product(name: "Commands", package: "Commands"),
        .product(name: "UserSpace", package: "UserSpace"),
        .product(name: "ApplicationSystem", package: "ApplicationSystem"),
        .product(name: "AppleScriptSystem", package: "AppleScriptSystem"),
        .product(name: "FileSystem", package: "FileSystem"),
        .product(name: "ProcessSystem", package: "ProcessSystem"),
      ],
      path: "Sources",
      linkerSettings: linkerSettings,
    ),
    .testTarget(
      name: "ApplicationsFeatureTests",
      dependencies: ["CowboyCore", "Commands", "UserSpace", "ApplicationSystem", "AppleScriptSystem", "FileSystem", "ProcessSystem", "ApplicationsFeature"],
      path: "Tests",
    ),
  ],
)
