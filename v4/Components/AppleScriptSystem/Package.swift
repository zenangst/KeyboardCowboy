// swift-tools-version: 6.3

import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "AppleScriptSystem",
  platforms: [.macOS(.v14)],
  products: [.library(name: "AppleScriptSystem", targets: ["AppleScriptSystem"])],
  dependencies: [.package(path: "../CowboyCore")],
  targets: [
    .target(name: "AppleScriptSystem", dependencies: ["CowboyCore"], path: "Sources", linkerSettings: linkerSettings),
    .testTarget(name: "AppleScriptSystemTests", dependencies: ["AppleScriptSystem", "CowboyCore"], path: "Tests"),
  ]
)
