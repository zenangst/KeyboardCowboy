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
    .package(path: "../CowboyCore"),
    .package(url: "git@github.com:johnno1962/HotSwiftUI.git", exact: "1.2.4"),
  ],
  targets: [
    .target(
      name: "ScriptingFeature",
      dependencies: [
        .product(name: "CowboyCore", package: "CowboyCore"),
        .product(name: "HotSwiftUI", package: "HotSwiftUI"),
      ],
      path: "Sources",
      linkerSettings: linkerSettings,
    ),
    .testTarget(
      name: "ScriptingFeatureTests",
      dependencies: ["CowboyCore", "ScriptingFeature"],
      path: "Tests",
    ),
  ],
)
