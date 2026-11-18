// swift-tools-version: 6.3

import Foundation
import PackageDescription

var linkerSettings: [LinkerSetting] {
  let isInjectionRunning = ProcessInfo.processInfo.environment["RUNNING_VIA_INJECTION_NEXT"] != nil
  return isInjectionRunning ? [.unsafeFlags(["-Xlinker", "-interposable"])] : []
}

let package = Package(
  name: "AppleScriptRuntime",
  platforms: [.macOS(.v14)],
  products: [.library(name: "AppleScriptRuntime", targets: ["AppleScriptRuntime"])],
  dependencies: [.package(path: "../RuntimeEnvironment")],
  targets: [
    .target(name: "AppleScriptRuntime", dependencies: ["RuntimeEnvironment"], path: "Sources", linkerSettings: linkerSettings),
    .testTarget(name: "AppleScriptRuntimeTests", dependencies: ["AppleScriptRuntime"], path: "Tests"),
  ],
)
