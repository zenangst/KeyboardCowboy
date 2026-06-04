// swift-tools-version: 6.3

import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "AppBundle",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "v4", targets: ["AppTarget"]),
  ],
  dependencies: [
    .package(url: "git@github.com:johnno1962/HotSwiftUI.git", exact: "1.2.4"),
  ],
  targets: [
    .executableTarget(
      name: "AppTarget",
      dependencies: [],
      path: "Sources",
      linkerSettings: linkerSettings,
    ),
  ],
)
