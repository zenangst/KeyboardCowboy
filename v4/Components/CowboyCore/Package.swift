// swift-tools-version: 6.3
import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "CowboyCore",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "CowboyCore",
      targets: ["CowboyCore"],
    ),
  ],
  targets: [
    .target(
      name: "CowboyCore",
      path: "Sources",
      linkerSettings: linkerSettings,
    ),
    .testTarget(
      name: "CowboyCoreTests",
      dependencies: ["CowboyCore"],
      path: "Tests",
    ),
  ],
)
